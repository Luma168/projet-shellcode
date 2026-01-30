#!/usr/bin/env python3
"""
UwU Encoder - Convertit un shellcode hex en format UwU
"""

import json
import sys
from pathlib import Path


def load_keywords(keywords_file=None):
    """Charge la table de correspondance nibble -> keyword."""
    if keywords_file is None:
        keywords_file = Path(__file__).parent.parent / "keywords.json"
    
    with open(keywords_file, "r") as f:
        config = json.load(f)
    
    return config["nibble_to_keyword"], config.get("separator", "-"), config.get("byte_separator", " ")


def encode(hex_string, keywords_file=None):
    """
    Encode un shellcode hex en format UwU.
    
    Args:
        hex_string: Shellcode en hex (ex: "\\x48\\x31\\xc0" ou "4831c0")
        keywords_file: Fichier JSON de keywords (optionnel)
    
    Returns:
        Chaîne encodée en UwU
    """
    nibble_to_keyword, separator, byte_separator = load_keywords(keywords_file)
    
    # Nettoyer la chaîne hex
    hex_clean = hex_string.replace("\\x", "").replace("0x", "").replace(" ", "").strip()
    
    if len(hex_clean) % 2 != 0:
        raise ValueError("La chaîne hex doit avoir une longueur paire")
    
    encoded_bytes = []
    for i in range(0, len(hex_clean), 2):
        high = hex_clean[i].lower()
        low = hex_clean[i + 1].lower()
        
        high_kw = nibble_to_keyword[high]
        low_kw = nibble_to_keyword[low]
        
        encoded_bytes.append(f"{high_kw}{separator}{low_kw}")
    
    return byte_separator.join(encoded_bytes)


def main():
    """Point d'entrée CLI."""
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <shellcode_hex> [output_file]")
        print(f"Example: {sys.argv[0]} '\\x48\\x31\\xc0'")
        sys.exit(1)
    
    hex_input = sys.argv[1]
    
    # Si c'est un fichier, lire son contenu
    if Path(hex_input).exists():
        with open(hex_input, "r") as f:
            hex_input = f.read().strip()
    
    encoded = encode(hex_input)
    
    # Sortie
    if len(sys.argv) >= 3:
        with open(sys.argv[2], "w") as f:
            f.write(encoded)
        print(f"[+] Écrit dans {sys.argv[2]}", file=sys.stderr)
    else:
        print(encoded)


if __name__ == "__main__":
    main()
