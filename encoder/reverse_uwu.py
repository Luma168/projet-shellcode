"""Encodeur inverse : produit une chaîne UwU dont l'ordre des octets est inversé."""

from .core import load_keywords, normalize_hex_string

def reverse_uwu_encode(hex_string, keywords_file=None):
    nibble_to_kw, sep, byte_sep = load_keywords(keywords_file)
    hex_clean = normalize_hex_string(hex_string)

    # liste des paires (high, low) en nibbles
    bytes_nib = [(hex_clean[i], hex_clean[i+1]) for i in range(0, len(hex_clean), 2)]
    # inverser l'ordre des octets
    bytes_nib.reverse()

    encoded_bytes = []
    for high, low in bytes_nib:
        encoded_bytes.append(f"{nibble_to_kw[high]}{sep}{nibble_to_kw[low]}")
    return byte_sep.join(encoded_bytes)
