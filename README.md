# UwU Shellcode Encoder/Decoder

Encodeur Python et décodeur ASM pour obfusquer du shellcode avec des mots-clés kawaii.

## Structure

```
uwu_shellcode_encoder/
├── encoder/
│   └── uwu_encoder.py      # Encodeur Python (hex → UwU)
├── decoder/
│   └── uwu_decoder.asm     # Décodeur ASM (UwU → hex)
├── keywords.json           # Table de correspondance
└── README.md
```

## Encodeur (Python)

Convertit du shellcode hex en format UwU.

```bash
# Depuis argument
python3 encoder/uwu_encoder.py '\x48\x31\xc0'

# Depuis fichier
python3 encoder/uwu_encoder.py shellcode.txt

# Vers fichier
python3 encoder/uwu_encoder.py '\x48\x31\xc0' output.uwu
```

**Exemple:**
```
Input:  \x48\x31\xc0
Output: ^w^-SwS >w<-OwO ZwZ-UwU
```

## Décodeur (ASM x86_64)

Convertit du format UwU en shellcode hex.

### Utilisation

1. **Modifier la chaîne à décoder** dans `decoder/uwu_decoder.asm` :
   ```asm
   encoded_data: db "^w^-SwS >w<-OwO ZwZ-UwU", 0
   ```

2. **Compiler** :
   ```bash
   nasm -f elf64 decoder/uwu_decoder.asm -o decoder/uwu_decoder.o
   ld decoder/uwu_decoder.o -o decoder/uwu_decoder
   ```

3. **Exécuter** :
   ```bash
   ./decoder/uwu_decoder
   ```

**Exemple:**
```
Input:  ^w^-SwS >w<-OwO ZwZ-UwU
Output: \x48\x31\xc0
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
