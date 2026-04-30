"""Encodeur double-XOR : XOR le shellcode, puis encode en UwU normal."""

import random
from .core import load_keywords, normalize_hex_string

def double_xor_encode(hex_string, xor_key, keywords_file=None):
    nibble_to_kw, sep, byte_sep = load_keywords(keywords_file)
    hex_clean = normalize_hex_string(hex_string)

    encoded_bytes = []
    for i in range(0, len(hex_clean), 2):
        byte_val = int(hex_clean[i:i+2], 16)
        xored = byte_val ^ xor_key
        high = (xored >> 4) & 0xF
        low = xored & 0xF
        high_kw = nibble_to_kw[f"{high:x}"]
        low_kw = nibble_to_kw[f"{low:x}"]
        encoded_bytes.append(f"{high_kw}{sep}{low_kw}")
    return byte_sep.join(encoded_bytes)
