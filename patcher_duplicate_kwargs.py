import glob, re

for filename in glob.glob("*.py"):
    with open(filename, "r", encoding="utf-8") as f:
        code = f.read()
    new_code = re.sub(r",\s*unsafe_allow_html=True\s*,\s*unsafe_allow_html=True", ", unsafe_allow_html=True", code)
    new_code = re.sub(r"unsafe_allow_html=True\s*,\s*unsafe_allow_html=True", "unsafe_allow_html=True", new_code)
    new_code = re.sub(r",\s*unsafe_allow_html=True\s*,", ", unsafe_allow_html=True,", new_code)
    if new_code != code:
        with open(filename, "w", encoding="utf-8") as f:
            f.write(new_code)
        print(f"✅ Patch appliqué à {filename}")
