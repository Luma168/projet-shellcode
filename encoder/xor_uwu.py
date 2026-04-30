"""XOR byte-level encoder, then UwU."""

import random
from .core import load_keywords, normalize_hex_string

def xor_encode_uwu(hex_string, xor_key, keywords_file=None):
    nibble_to_kw, sep, byte_sep = load_keywords(keywords_file)
    hex_clean = normalize_hex_string(hex_string)

    encoded_bytes = []
    for i in range(0, len(hex_clean), 2):
        byte_val = int(hex_clean[i:i+2], 16) ^ xor_key
        high = (byte_val >> 4) & 0xF
        low = byte_val & 0xF
        high_kw = nibble_to_kw["{:x}".format(high)]
        low_kw = nibble_to_kw["{:x}".format(low)]
        encoded_bytes.append(high_kw + sep + low_kw)
    return byte_sep.join(encoded_bytes)
