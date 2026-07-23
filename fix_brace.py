import sys

file_path = r"c:\Users\coren\AndroidStudioProjects\quizbot\lib\main.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

target = ");\n\n}\n\n\n// ============================================================"

if target in content:
    content = content.replace(target, ");\n  }\n}\n\n\n// ============================================================")
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("Fixed missing braces.")
else:
    # try with carriage returns
    target2 = ");\r\n\r\n}\r\n\r\n\r\n// ============================================================"
    if target2 in content:
        content = content.replace(target2, ");\r\n  }\r\n}\r\n\r\n\r\n// ============================================================")
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(content)
        print("Fixed missing braces (CRLF).")
    else:
        print("Still not found!")
