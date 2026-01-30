#!/usr/bin/env python3
"""
UwU Shellcode Encoder/Decoder CLI
"""

import argparse
import subprocess
import sys
import tempfile
import shutil
from pathlib import Path

# Chemin du projet
PROJECT_DIR = Path(__file__).parent
ENCODER_PATH = PROJECT_DIR / "encoder" / "uwu_encoder.py"
DECODER_ASM = PROJECT_DIR / "decoder" / "uwu_decoder.s"


def load_keywords():
    """Charge la table de correspondance."""
    import json
    keywords_file = PROJECT_DIR / "keywords.json"
    with open(keywords_file, "r") as f:
        config = json.load(f)
    return config["nibble_to_keyword"], config.get("separator", "-"), config.get("byte_separator", " ")


def encode_shellcode(hex_string):
    """Encode un shellcode hex en format UwU."""
    nibble_to_keyword, separator, byte_separator = load_keywords()
    
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


def cmd_encode(args):
    """Commande encode: hex -> UwU"""
    # Lire le shellcode
    if args.shellcode:
        hex_input = args.shellcode
    elif args.file:
        with open(args.file, "r") as f:
            hex_input = f.read().strip()
    else:
        print("Erreur: spécifier -s/--shellcode ou -f/--file", file=sys.stderr)
        sys.exit(1)
    
    # Encoder
    try:
        encoded = encode_shellcode(hex_input)
    except Exception as e:
        print(f"Erreur d'encodage: {e}", file=sys.stderr)
        sys.exit(1)
    
    # Sortie
    if args.output:
        with open(args.output, "w") as f:
            f.write(encoded + "\n")
        print(f"[+] Encodé dans {args.output}", file=sys.stderr)
    else:
        print(encoded)


def cmd_decode(args):
    """Commande decode: compile et exécute le décodeur ASM."""
    # Lire la chaîne UwU
    if args.encoded:
        uwu_input = args.encoded
    elif args.file:
        with open(args.file, "r") as f:
            uwu_input = f.read().strip()
    else:
        print("Erreur: spécifier -e/--encoded ou -f/--file", file=sys.stderr)
        sys.exit(1)
    
    # Choisir la version du décodeur
    version = args.version if args.version else "1"
    if version == "1":
        decoder_src = PROJECT_DIR / "decoder" / "uwu_decoder.s"
    elif version == "2":
        decoder_src = PROJECT_DIR / "decoder" / "uwu_decoder_v2.s"
    elif version == "3":
        decoder_src = PROJECT_DIR / "decoder" / "uwu_decoder_v3.s"
    else:
        print(f"Erreur: version {version} inconnue (1, 2 ou 3)", file=sys.stderr)
        sys.exit(1)
    
    if not decoder_src.exists():
        print(f"Erreur: {decoder_src} non trouvé", file=sys.stderr)
        sys.exit(1)
    
    # Créer un fichier temporaire avec la chaîne encodée modifiée
    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir = Path(tmpdir)
        
        # Lire le source ASM
        with open(decoder_src, "r") as f:
            asm_content = f.read()
        
        # Remplacer encoded_data
        # Chercher la ligne encoded_data et la remplacer
        lines = asm_content.split("\n")
        new_lines = []
        for line in lines:
            if "encoded_data:" in line:
                new_lines.append("    encoded_data:")
            elif ".asciz" in line and "encoded_data" not in line:
                # C'est la ligne après encoded_data:, on la remplace
                # Mais on doit vérifier si c'est bien celle-là
                if new_lines and "encoded_data:" in new_lines[-1]:
                    new_lines.append(f'        .asciz "{uwu_input}"')
                else:
                    new_lines.append(line)
            else:
                new_lines.append(line)
        
        # Écrire le fichier ASM modifié
        tmp_asm = tmpdir / "decoder.s"
        with open(tmp_asm, "w") as f:
            f.write("\n".join(new_lines))
        
        tmp_obj = tmpdir / "decoder.o"
        tmp_bin = tmpdir / "decoder"
        
        # Compiler
        print(f"[*] Compilation avec décodeur v{version}...", file=sys.stderr)
        
        result = subprocess.run(
            ["as", "--64", str(tmp_asm), "-o", str(tmp_obj)],
            capture_output=True, text=True
        )
        if result.returncode != 0:
            print(f"Erreur assemblage:\n{result.stderr}", file=sys.stderr)
            sys.exit(1)
        
        result = subprocess.run(
            ["ld", str(tmp_obj), "-o", str(tmp_bin)],
            capture_output=True, text=True
        )
        if result.returncode != 0:
            print(f"Erreur link:\n{result.stderr}", file=sys.stderr)
            sys.exit(1)
        
        # Exécuter
        print(f"[*] Exécution...", file=sys.stderr)
        result = subprocess.run([str(tmp_bin)], capture_output=True, text=True)
        
        if result.returncode != 0:
            print(f"Erreur exécution (code {result.returncode})", file=sys.stderr)
        
        decoded = result.stdout.strip()
        
        # Sortie
        if args.output:
            with open(args.output, "w") as f:
                f.write(decoded + "\n")
            print(f"[+] Décodé dans {args.output}", file=sys.stderr)
        else:
            print(decoded)


def main():
    parser = argparse.ArgumentParser(
        description="UwU Shellcode Encoder/Decoder",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Exemples:
  # Encoder un shellcode
  %(prog)s encode -s '\\x48\\x31\\xc0'
  %(prog)s encode -f shellcode.txt -o encoded.uwu
  
  # Décoder (compile et exécute le décodeur ASM)
  %(prog)s decode -e '^w^-SwS >w<-OwO ZwZ-UwU'
  %(prog)s decode -f encoded.uwu -v 2
        """
    )
    
    subparsers = parser.add_subparsers(dest="command", help="Commandes")
    
    # Encode
    enc = subparsers.add_parser("encode", help="Encoder shellcode hex -> UwU")
    enc.add_argument("-s", "--shellcode", help="Shellcode en hex (ex: '\\x48\\x31\\xc0')")
    enc.add_argument("-f", "--file", help="Fichier contenant le shellcode hex")
    enc.add_argument("-o", "--output", help="Fichier de sortie")
    
    # Decode
    dec = subparsers.add_parser("decode", help="Décoder UwU -> hex (via ASM)")
    dec.add_argument("-e", "--encoded", help="Chaîne UwU encodée")
    dec.add_argument("-f", "--file", help="Fichier contenant la chaîne UwU")
    dec.add_argument("-o", "--output", help="Fichier de sortie")
    dec.add_argument("-v", "--version", choices=["1", "2", "3"], default="1",
                     help="Version du décodeur ASM (1, 2 ou 3)")
    
    args = parser.parse_args()
    
    if args.command == "encode":
        cmd_encode(args)
    elif args.command == "decode":
        cmd_decode(args)
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
