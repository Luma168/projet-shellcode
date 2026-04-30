"""Central CLI entrypoint for UwU tooling."""

import argparse
import sys

from encoder.commands import encode, generate


def build_parser():
    parser = argparse.ArgumentParser(
        prog="uwu-cli",
        description="CLI tools to encode shellcode and generate an UwU decoder.",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p_encode = sub.add_parser(
        "encode",
        help="Encode a hex string to UwU",
        description="Encode a hexadecimal shellcode string (or a text file) to UwU format.",
    )
    encode.configure_parser(p_encode)

    p_generate = sub.add_parser(
        "generate",
        help="Generate decoder shellcode binary",
        description="Generate an ASM stub that decodes UwU and jumps to the payload.",
    )
    generate.configure_parser(p_generate)

    return parser


def main(argv=None):
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        return args.func(args)
    except (ValueError, KeyError, RuntimeError) as exc:
        print(f"[!] Error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
