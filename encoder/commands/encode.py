"""Encode command for the UwU CLI."""

import sys

try:
    from ..core import encode_hex_string, read_text_or_file
except ImportError:
    from core import encode_hex_string, read_text_or_file


def configure_parser(parser):
    parser.add_argument(
        "input",
        help="Hex string (\\x48\\x31...) or path to a text file",
    )
    parser.add_argument("-o", "--output", help="Output file (defaults to stdout)")
    parser.add_argument("-k", "--keywords", help="Path to a custom keywords.json file")
    parser.set_defaults(func=run)


def run(args):
    hex_input = read_text_or_file(args.input)
    encoded = encode_hex_string(hex_input, keywords_file=args.keywords)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(encoded)
        print(f"[+] Wrote to {args.output}", file=sys.stderr)
        return 0

    print(encoded)
    return 0
