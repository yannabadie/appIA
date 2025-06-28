import re

file = "web_ui_streamlit.py"

with open(file, encoding="utf-8") as f:
    content = f.read()

# Correction de la hauteur (on monte à 72px pour éviter les futurs warnings)
content = re.sub(
    r'st\.text_area\("Scénario/canevas \(optionnel\)",\s*height\s*=\s*\d+,\s*key="scenario"\)',
    'st.text_area("Scénario/canevas (optionnel)", height=72, key="scenario")',
    content,
)

# Patch bonus : correction anti-hauteur future sur toutes text_area avec height < 68
content = re.sub(
    r'st\.text_area\((.+?),\s*height\s*=\s*(\d{1,2})\s*,',
    lambda m: f'st.text_area({m.group(1)}, height=72,',
    content
)

with open(file, "w", encoding="utf-8") as f:
    f.write(content)

print("✅ Hauteur de st.text_area corrigée à 72px. Lance :\n    streamlit run web_ui_streamlit.py")
