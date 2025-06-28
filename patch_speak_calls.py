def patch_speak_calls(data):
    """
    Remplace les anciens appels de synthèse vocale par speak(text, lang='fr')
    mais ne touche pas à la définition de la fonction speak elle-même.
    """
    # Motifs à remplacer (appels dans le code)
    motifs = [
        r"engine\.say\((.+?)\)",
        r"tts\.tts_to_file\(text=(.+?),\s*file_path=.+?\)",
        r"synthesiz[ea]_voice?\((.+?)\)",
        # Appel à speak mais PAS la définition !
        r"(?<!def )speak\((.+?)\)",
    ]
    for motif in motifs:
        def replacer(match):
            args = match.group(1).strip()
            # On ajoute lang='fr' UNIQUEMENT s'il n'est pas déjà dans les arguments
            if "lang=" not in args:
                # On vérifie que ce n'est pas vide pour éviter "speak(, lang='fr')"
                if args:
                    return f"speak({args}, lang='fr')"
                else:
                    return "speak(lang='fr')"
            else:
                return f"speak({args})"
        data = re.sub(motif, replacer, data)
    return data
