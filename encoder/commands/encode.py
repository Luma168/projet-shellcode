"""Encode command for the UwU CLI."""

import sys

try:
    from ..core import encode_hex_string, read_text_or_file
except ImportError:
    from core import encode_hex_string, read_text_or_file


def configure_parser(parser):
    parser.add_argument(
        "input",
        help="Chaîne hex (\\x48\\x31...) ou chemin vers fichier texte",
    )
    parser.add_argument("-o", "--output", help="Fichier de sortie (sinon stdout)")
    parser.add_argument("-k", "--keywords", help="Chemin vers keywords.json personnalisé")
    parser.set_defaults(func=run)


def run(args):
    hex_input = read_text_or_file(args.input)
    encoded = encode_hex_string(hex_input, keywords_file=args.keywords)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(encoded)
        print(f"[+] Écrit dans {args.output}", file=sys.stderr)
        return 0

    print(encoded)
    return 0
