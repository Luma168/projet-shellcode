"""Central CLI entrypoint for UwU tooling."""

import argparse
import sys

from encoder.commands import encode, generate


def build_parser():
    parser = argparse.ArgumentParser(
        prog="uwu-cli",
        description="Outils CLI pour encoder un shellcode et générer un décodeur UwU.",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p_encode = sub.add_parser(
        "encode",
        help="Encode une chaîne hex en UwU",
        description="Encode un shellcode hexadécimal (ou un fichier texte) en format UwU.",
    )
    encode.configure_parser(p_encode)

    p_generate = sub.add_parser(
        "generate",
        help="Génère un shellcode binaire décodeur",
        description="Génère un stub ASM qui décode du UwU puis saute vers le payload.",
    )
    generate.configure_parser(p_generate)

    return parser


def main(argv=None):
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        return args.func(args)
    except (ValueError, KeyError, RuntimeError) as exc:
        print(f"[!] Erreur: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
