"""Generate command for the UwU CLI."""

try:
    from ..core import encode_hex_string
    from ..generator import build_asm
except ImportError:
    from core import encode_hex_string
    from generator import build_asm


def configure_parser(parser):
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--hex", help="Shellcode hex string, ex: '\\x48\\x31\\xc0'")
    group.add_argument("--uwu", help="Chaîne UwU déjà encodée")
    parser.add_argument("-o", "--out", default="out.bin", help="Fichier binaire de sortie")
    parser.add_argument("--dryrun", action="store_true", help="Affiche l'ASM généré sans compiler")
    parser.set_defaults(func=run)


def run(args):
    encoded = encode_hex_string(args.hex) if args.hex else args.uwu
    build_asm(encoded, args.out, dryrun=args.dryrun)
    return 0
