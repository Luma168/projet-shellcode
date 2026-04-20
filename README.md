# UwU Shellcode Encoder/Decoder

CLI Python modulaire + décodeur ASM pour obfusquer du shellcode avec des mots-clés kawaii.

## CLI officielle

Le point d'entrée principal est `uwu_cli.py`.

```bash
# Aide globale
python uwu_cli.py -h

# Aide détaillée par commande
python uwu_cli.py encode -h
python uwu_cli.py generate -h

# Encodage hex -> UwU
python uwu_cli.py encode 4831c0
python uwu_cli.py encode '\x48\x31\xc0' -o output.uwu

# Génération d'un binaire décodeur
python uwu_cli.py generate --hex 4831c0 -o out.bin
python uwu_cli.py generate --uwu "^w^-SwS >w<-OwO ZwZ-UwU" --dryrun
```

## Structure

```text
projet-shellcode/
├── uwu_cli.py
├── encoder/
│   ├── cli.py
│   ├── core.py
│   ├── generator.py
│   └── commands/
│       ├── encode.py
│       └── generate.py
├── decoder/
│   ├── uwu_decoder.s
│   ├── decoder_2.s
│   └── decoder_3.s
├── examples/
├── keywords.json
└── tester.c
```

## Décodeur ASM (manuel)

Tu peux toujours utiliser `decoder/uwu_decoder.s` manuellement:

```bash
as --64 decoder/uwu_decoder.s -o decoder/uwu_decoder.o
ld decoder/uwu_decoder.o -o decoder/uwu_decoder
./decoder/uwu_decoder
```

## Table de correspondance

| Nibble | Keyword | Nibble | Keyword |
|--------|---------|--------|---------|
| 0      | UwU     | 8      | SwS     |
| 1      | OwO     | 9      | VwV     |
| 2      | TwT     | a      | XwX     |
| 3      | >w<     | b      | YwY     |
| 4      | ^w^     | c      | ZwZ     |
| 5      | QwQ     | d      | NwN     |
| 6      | PwP     | e      | MwM     |
| 7      | RwR     | f      | LwL     |
