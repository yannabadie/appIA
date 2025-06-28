import re

# Lis le fichier web_ui_streamlit.py existant
with open("web_ui_streamlit.py", "r", encoding="utf-8") as f:
    content = f.read()

# Corrige les styles, double unsafe_allow_html, appels ._repr_markdown_(), etc.
content = re.sub(r',\s*unsafe_allow_html=True\s*,\s*unsafe_allow_html=True', ', unsafe_allow_html=True', content)
content = re.sub(r'\._repr_markdown_\(\)', '', content)
content = re.sub(r'height\s*=\s*\d+', 'height=80', content)
content = re.sub(r'(st\.text_area\(.*?)(height\s*=\s*\d+)', r'\1height=80', content)
content = re.sub(r'(\s+)f\'<div class="chat-bubble \{who\}">\{icon\} ', r'\1', content)
content = re.sub(r'st\.experimental_rerun\(\)', '', content)

# Enregistre le fichier corrigé
with open("web_ui_streamlit.py", "w", encoding="utf-8") as f:
    f.write(content)

print("✅ Correction terminée sur web_ui_streamlit.py. Code nettoyé, prêt à exécution.")
