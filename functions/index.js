const { onCall, HttpsError } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
admin.initializeApp();

const DEEPSEEK_API_KEY = process.env.DEEPSEEK_API_KEY; // Note: Utilisé pour SiliconFlow
const DEEPSEEK_API_URL = "https://api.siliconflow.com/v1/chat/completions";

// 1. Ajout du timeout à 120 secondes
exports.generateQuiz = onCall({ cors: true, maxInstances: 10, timeoutSeconds: 120 }, async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "Seuls les utilisateurs connectés peuvent générer des quiz.");
    }
    try {
        const data = request.data;
        const prompt = data.prompt;
        const systemMessage = data.systemMessage || "Tu es un générateur de quiz JSON strict.";

        // Correction du modèle par défaut et validation sticte pour des raisons de coût
        const allowedModels = [
            "Qwen/Qwen2.5-32B-Instruct",
            "mistralai/Mistral-Nemo-Instruct-2407"
        ];
        let model = data.model || "Qwen/Qwen2.5-32B-Instruct";
        if (!allowedModels.includes(model)) {
            model = "Qwen/Qwen2.5-32B-Instruct";
        }
        const temperature = data.temperature !== undefined ? data.temperature : 0.3;

        if (!prompt) {
            throw new HttpsError("invalid-argument", "Missing prompt parameter");
        }

        const uid = request.auth.uid;
        const db = admin.firestore();
        const userRef = db.collection('users').doc(uid);

        await db.runTransaction(async (transaction) => {
            const userDoc = await transaction.get(userRef);
            if (!userDoc.exists) {
                throw new HttpsError("permission-denied", "Utilisateur introuvable.");
            }

            const userData = userDoc.data();
            const isVip = userData.isVip === true;

            const now = new Date();
            const lastDailyReset = userData.lastDailyReset ? userData.lastDailyReset.toDate() : new Date(0);
            const lastMonthlyReset = userData.lastMonthlyReset ? userData.lastMonthlyReset.toDate() : new Date(0);

            let currentDailyCount = userData.dailyGenerationsCount || 0;
            let currentMonthlyCount = userData.monthlyGenerationsCount || 0;
            let updates = {};

            if (now.getDate() !== lastDailyReset.getDate() ||
                now.getMonth() !== lastDailyReset.getMonth() ||
                now.getFullYear() !== lastDailyReset.getFullYear()) {
                currentDailyCount = 0;
                updates.lastDailyReset = admin.firestore.FieldValue.serverTimestamp();
            }
            if (now.getMonth() !== lastMonthlyReset.getMonth() ||
                now.getFullYear() !== lastMonthlyReset.getFullYear()) {
                currentMonthlyCount = 0;
                updates.lastMonthlyReset = admin.firestore.FieldValue.serverTimestamp();
            }

            const canGenerate = isVip ? (currentDailyCount < 30) : (currentMonthlyCount < 20);
            if (!canGenerate) {
                throw new HttpsError("resource-exhausted", "Vous avez atteint votre limite de générations. Devenez VIP ou attendez la réinitialisation.");
            }

            if (isVip) {
                updates.dailyGenerationsCount = currentDailyCount + 1;
            } else {
                updates.monthlyGenerationsCount = currentMonthlyCount + 1;
            }

            transaction.update(userRef, updates);
        });

        logger.info("Calling SiliconFlow API with model", model);

        const response = await fetch(DEEPSEEK_API_URL, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "Authorization": `Bearer ${DEEPSEEK_API_KEY}`,
            },
            body: JSON.stringify({
                model: model,
                temperature: temperature,
                messages: [
                    { role: "system", content: systemMessage },
                    { role: "user", content: prompt },
                ],
            }),
        });

        if (!response.ok) {
            const errorText = await response.text();
            logger.error("SiliconFlow API Error:", errorText);
            throw new HttpsError("internal", `SiliconFlow API returned status: ${response.status}`);
        }

        return await response.json();
    } catch (error) {
        logger.error("Error generating quiz", error);
        throw new HttpsError("internal", error.message || "Error calling AI provider.");
    }
});

const PIXABAY_API_KEY = process.env.PIXABAY_API_KEY;

exports.fetchPixabayImage = onCall({ cors: true, maxInstances: 10 }, async (request) => {
    if (!request.auth) {
        throw new HttpsError("unauthenticated", "Accès refusé.");
    }
    try {
        const query = request.data.query;

        if (!query) {
            throw new HttpsError("invalid-argument", "Missing query parameter.");
        }

        const url = `https://pixabay.com/api/?key=${PIXABAY_API_KEY}&q=${encodeURIComponent(query)}&image_type=photo&per_page=3&lang=fr`;
        const response = await fetch(url);

        if (!response.ok) {
            // 2. Gestion du Rate Limit (429) pour Pixabay
            if (response.status === 429) {
                logger.warn("Pixabay rate limit 429 reached, returning placeholder.");
                return { hits: [{ webformatURL: "https://via.placeholder.com/640x480.png?text=Image+Non+Disponible" }] };
            }
            const errorText = await response.text();
            logger.error("Pixabay API Error:", errorText);
            throw new HttpsError("internal", `Pixabay API returned status: ${response.status}`);
        }

        return await response.json();
    } catch (error) {
        logger.error("Error fetching image from Pixabay", error);
        throw new HttpsError("internal", "Error calling Pixabay API.");
    }
});

exports.submitGameResult = onCall({ cors: true, maxInstances: 10 }, async (request) => {
    const {
        gameType,
        quizId,
        gamesPlayed,
        pointsScored,
        playerScores,
        playerName,
        averageDifficulty,
        quizText,
        theme
    } = request.data;

    const uid = request.auth?.uid;
    if (!uid) {
        throw new HttpsError("unauthenticated", "User must be logged in");
    }

    const db = admin.firestore();
    const userRef = db.collection('users').doc(uid);

    return await db.runTransaction(async (transaction) => {
        const userDoc = await transaction.get(userRef);
        let userData = userDoc.exists ? userDoc.data() : { score: 0, iq: 100.0, totalGamesPlayed: 0 };

        let currentGlobalScore = userData.score || 0;
        let currentIQ = userData.iq !== undefined ? userData.iq : 100.0;
        let totalGamesPlayedCount = userData.totalGamesPlayed || 0;

        let pointsToAdd = 0;
        let wasWinnerThisGame = false;
        let successRate = 0.0;
        let isReplay = false;

        if (quizId) {
            const historySnapshot = await transaction.get(
                db.collection('userGameHistory')
                    .where('userId', '==', uid)
                    .where('quizId', '==', quizId)
                    .limit(1)
            );
            if (!historySnapshot.empty) {
                isReplay = true;
            }
        }

        if (gameType === 'online') {
            const userScore = playerScores[playerName] || 0;
            const scoresValues = Object.values(playerScores);
            const maxScore = scoresValues.length > 0 ? Math.max(...scoresValues) : 0;

            wasWinnerThisGame = (userScore === maxScore && scoresValues.length > 1 && userScore > 0);
            const pointsGained = scoresValues.length - 1;

            if (wasWinnerThisGame && pointsGained > 0 && !isReplay) {
                pointsToAdd = pointsGained;
            }

            let totalPossibleScore = 0;
            if (gamesPlayed && Array.isArray(gamesPlayed)) {
                gamesPlayed.forEach(g => {
                    const type = g.type || '';
                    if (type.includes('Memory')) {
                        const pairs = g.pairs ? g.pairs.length : (g.options ? g.options.length / 2 : 4);
                        totalPossibleScore += pairs * 15;
                    } else if (type.includes('Relier')) {
                        const pairs = g.pairs ? g.pairs.length : (g.options ? g.options.length : 4);
                        totalPossibleScore += pairs * 5;
                    } else if (type.includes('Pendu')) {
                        totalPossibleScore += 20;
                    } else if (type.includes('Mot Mystère') || type.includes('Mot Mystere')) {
                        totalPossibleScore += 25;
                    } else {
                        totalPossibleScore += 10;
                    }
                });
            }
            successRate = totalPossibleScore > 0 ? Math.min(1.0, userScore / totalPossibleScore) : 0.0;
        } else {
            pointsToAdd = isReplay ? 0 : pointsScored;
            let totalPossibleScore = 0;
            if (gamesPlayed && Array.isArray(gamesPlayed)) {
                gamesPlayed.forEach(g => {
                    const type = g.type || '';
                    if (type.includes('Relier')) {
                        const pairs = g.pairs ? g.pairs.length : (g.options ? g.options.length : 4);
                        totalPossibleScore += pairs;
                    } else if (type.includes('Quiz par Indices')) {
                        const clues = g.clues ? g.clues.length : 3;
                        totalPossibleScore += clues;
                    } else if (type.includes('Estimation')) {
                        totalPossibleScore += 2;
                    } else {
                        totalPossibleScore += 1;
                    }
                });
            }
            successRate = totalPossibleScore > 0 ? Math.min(1.0, pointsScored / totalPossibleScore) : 0.0;
        }

        let newIQ = currentIQ;

        if (gameType === 'online') {
            if (quizText && gamesPlayed && gamesPlayed.length > 0) {
                let expectedPerformance = 1.0 / (1.0 + Math.exp(-(currentIQ - 100.0) / 40.0));
                let actualPerformance = successRate;
                let difficultyMultiplier = 0.15 + Math.pow(averageDifficulty / 10.0, 1.4) * 2.2;

                let experienceFactor = totalGamesPlayedCount < 5 ? 3.0 : totalGamesPlayedCount < 20 ? 2.0 : totalGamesPlayedCount < 50 ? 1.4 : 1.0;
                let volatilityFactor = 1.0 + 0.6 * Math.min(1.2, Math.pow(Math.abs(currentIQ - 100.0) / 50.0, 0.7));
                let kFactor = 4.5 * experienceFactor * volatilityFactor;

                let gameTypes = new Set(gamesPlayed.map(g => g.type || ''));
                let diversityBonus = Math.min(1.5, Math.max(0.7, 0.7 + gameTypes.size * 0.08));
                let countWeight = Math.min(1.3, Math.max(0.6, 0.4 + gamesPlayed.length / 14.0));

                let performanceImpact = kFactor * (actualPerformance - expectedPerformance) * difficultyMultiplier * diversityBonus * countWeight;

                if (performanceImpact > 0 && currentIQ > 140) {
                    performanceImpact *= Math.max(0.3, 1.0 - (currentIQ - 140.0) / 60.0);
                } else if (performanceImpact < 0 && currentIQ < 70) {
                    performanceImpact *= Math.max(0.3, 1.0 - (70.0 - currentIQ) / 30.0);
                }

                if (isReplay && performanceImpact > 0) {
                    performanceImpact = 0;
                } else if (isReplay && performanceImpact < 0) {
                    performanceImpact *= 0.4;
                }

                performanceImpact = Math.min(5.0, Math.max(-5.0, performanceImpact));
                newIQ = Math.min(200.0, Math.max(50.0, currentIQ + performanceImpact));
            }
        } else {
            let difficultyMultiplier = 0.3 + (averageDifficulty / 10.0) * 1.7;
            let expectedPerformance = 0.5 + Math.max(-0.4, Math.min(0.4, (currentIQ - 100.0) / 200.0));
            let actualPerformance = successRate;

            let kFactor = (totalGamesPlayedCount < 10) ? 8.0 : (totalGamesPlayedCount < 30) ? 5.0 : 3.0;

            let countWeight = Math.min(3.0, Math.max(1.0, Math.sqrt(gamesPlayed ? gamesPlayed.length : 1)));
            let performanceImpact = kFactor * (actualPerformance - expectedPerformance) * difficultyMultiplier * countWeight;

            if (isReplay && performanceImpact > 0) {
                performanceImpact = 0;
            } else if (isReplay && performanceImpact < 0) {
                performanceImpact *= 0.5;
            }

            performanceImpact = Math.min(10.0, Math.max(-10.0, performanceImpact));

            newIQ = currentIQ + performanceImpact;
            newIQ = Math.max(50.0, Math.min(200.0, newIQ));
        }

        transaction.set(userRef, {
            score: currentGlobalScore + pointsToAdd,
            iq: newIQ,
            totalGamesPlayed: totalGamesPlayedCount + 1
        }, { merge: true });

        const historyRef = db.collection('userGameHistory').doc();
        transaction.set(historyRef, {
            userId: uid,
            quizId: quizId || null,
            averageDifficulty: averageDifficulty,
            playerName: playerName || null,
            quizText: quizText || null,
            gamesPlayed: gamesPlayed || [],
            userScore: gameType === 'online' ? (playerScores[playerName] || 0) : pointsScored,
            totalPlayers: gameType === 'online' ? Object.keys(playerScores).length : 1,
            gameType: gameType,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            theme: theme || 'Inconnu',
            successRate: successRate,
            wasWinner: wasWinnerThisGame,
            iqAfter: newIQ
        });

        if (theme) {
            const statsRef = db.collection('userStats').doc(uid);
            const statsDoc = await transaction.get(statsRef);
            let statsData = statsDoc.exists ? statsDoc.data() : {};
            let themeStats = statsData[theme] || { gamesPlayed: 0, weightedSuccessRate: 0.0 };

            const newGamesCount = themeStats.gamesPlayed + 1;
            const newWeightedSuccessRate = ((themeStats.weightedSuccessRate * themeStats.gamesPlayed) + successRate) / newGamesCount;

            statsData[theme] = {
                gamesPlayed: newGamesCount,
                weightedSuccessRate: newWeightedSuccessRate,
                lastPlayed: admin.firestore.FieldValue.serverTimestamp()
            };

            transaction.set(statsRef, statsData, { merge: true });
        }

        return {
            success: true,
            newIQ: newIQ,
            newScore: currentGlobalScore + pointsToAdd,
            pointsAdded: pointsToAdd,
            wasWinner: wasWinnerThisGame
        };
    });
});

exports.abandonOnlineGame = onCall({ cors: true }, async (request) => {
    const { roomId, averageDifficulty = 5.0 } = request.data;
    const uid = request.auth?.uid;
    if (!uid) {
        throw new HttpsError("unauthenticated", "User must be logged in");
    }

    const db = admin.firestore();
    const userRef = db.collection('users').doc(uid);
    const roomRef = db.collection('onlineRooms').doc(roomId);

    return await db.runTransaction(async (transaction) => {
        const roomDoc = await transaction.get(roomRef);
        if (!roomDoc.exists) {
            throw new HttpsError("not-found", "La salle spécifiée n'existe pas.");
        }

        const roomData = roomDoc.data();
        const players = roomData.players || {};
        const isParticipant = Object.values(players).some(p => p.uid === uid);

        if (!isParticipant) {
            throw new HttpsError("permission-denied", "Vous n'êtes pas un participant de cette salle.");
        }

        const userDoc = await transaction.get(userRef);
        let userData = userDoc.exists ? userDoc.data() : { score: 0, iq: 100.0, totalGamesPlayed: 0 };

        let currentIQ = userData.iq !== undefined ? userData.iq : 100.0;
        let totalGamesPlayedCount = userData.totalGamesPlayed || 0;

        let expectedPerformance = 1.0 / (1.0 + Math.exp(-(currentIQ - 100.0) / 40.0));
        let actualPerformance = 0.0;
        let difficultyMultiplier = 0.15 + Math.pow(averageDifficulty / 10.0, 1.4) * 2.2;

        let experienceFactor = totalGamesPlayedCount < 5 ? 3.0 : totalGamesPlayedCount < 20 ? 2.0 : totalGamesPlayedCount < 50 ? 1.4 : 1.0;
        let volatilityFactor = 1.0 + 0.6 * Math.min(1.2, Math.pow(Math.abs(currentIQ - 100.0) / 50.0, 0.7));
        let kFactor = 4.5 * experienceFactor * volatilityFactor;

        let performanceImpact = kFactor * (actualPerformance - expectedPerformance) * difficultyMultiplier * 1.5;

        if (performanceImpact > 0 && currentIQ > 140) {
            performanceImpact *= Math.max(0.3, 1.0 - (currentIQ - 140.0) / 60.0);
        } else if (performanceImpact < 0 && currentIQ < 70) {
            performanceImpact *= Math.max(0.3, 1.0 - (70.0 - currentIQ) / 30.0);
        }

        performanceImpact = Math.min(5.0, Math.max(-5.0, performanceImpact));
        let newIQ = Math.min(200.0, Math.max(50.0, currentIQ + performanceImpact));

        transaction.set(userRef, {
            iq: newIQ,
            totalGamesPlayed: totalGamesPlayedCount + 1,
        }, { merge: true });

        const historyRef = db.collection('userGameHistory').doc();
        transaction.set(historyRef, {
            userId: uid,
            quizId: roomId,
            averageDifficulty: averageDifficulty,
            playerName: userData.username || null,
            quizText: null,
            gamesPlayed: [],
            userScore: 0,
            totalPlayers: 0,
            gameType: 'online',
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            theme: 'Abandon',
            successRate: 0.0,
            wasWinner: false,
            iqAfter: newIQ
        });

        return { success: true, newIQ: newIQ };
    });
});
