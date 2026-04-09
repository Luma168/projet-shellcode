#!/usr/bin/env python3
"""Core helpers for UwU encoding and input handling."""

import json
from pathlib import Path


DEFAULT_KEYWORDS_FILE = Path(__file__).resolve().parent.parent / "keywords.json"


def load_keywords(keywords_file=None):
    """Load nibble->keyword mapping and separators from JSON config."""
    path = Path(keywords_file) if keywords_file else DEFAULT_KEYWORDS_FILE
    with open(path, "r", encoding="utf-8") as f:
        config = json.load(f)
    return config["nibble_to_keyword"], config.get("separator", "-"), config.get("byte_separator", " ")


def normalize_hex_string(hex_string):
    """Normalize hex shellcode string by removing common prefixes/spaces."""
    hex_clean = hex_string.replace("\\x", "").replace("0x", "").replace(" ", "").strip()
    if len(hex_clean) % 2 != 0:
        raise ValueError("Hex string length must be even")
    return hex_clean


def encode_hex_string(hex_string, keywords_file=None):
    """Encode a hex shellcode string to UwU format."""
    nibble_to_keyword, separator, byte_separator = load_keywords(keywords_file)
    hex_clean = normalize_hex_string(hex_string)

    encoded_bytes = []
    for i in range(0, len(hex_clean), 2):
        high = hex_clean[i].lower()
        low = hex_clean[i + 1].lower()

        high_kw = nibble_to_keyword[high]
        low_kw = nibble_to_keyword[low]
        encoded_bytes.append(f"{high_kw}{separator}{low_kw}")
    return byte_separator.join(encoded_bytes)


def read_text_or_file(input_value):
    """Read content from file path if it exists, otherwise return raw text."""
    candidate = Path(input_value)
    if candidate.exists() and candidate.is_file():
        with open(candidate, "r", encoding="utf-8") as f:
            return f.read().strip()
    return input_value
