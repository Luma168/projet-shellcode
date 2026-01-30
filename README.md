# UwU Shellcode Encoder/Decoder

Encodeur Python et décodeur ASM pour obfusquer du shellcode avec des mots-clés kawaii.

## Structure

```
uwu_shellcode_encoder/
├── encoder/
│   └── uwu_encoder.py      # Encodeur Python (hex → UwU)
├── decoder/
│   ├── uwu_decoder.s       # Décodeur v1 (recherche ascendante)
│   └── uwu_decoder_v2.s    # Décodeur v2 (recherche descendante)
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

## Décodeur (ASM x86_64 GAS)

Convertit du format UwU en shellcode hex.

### Utilisation

1. **Modifier la chaîne à décoder** dans `decoder/uwu_decoder.s` :
   ```asm
   encoded_data:
       .asciz "^w^-SwS >w<-OwO ZwZ-UwU"
   ```

2. **Compiler** :
   ```bash
   as --64 decoder/uwu_decoder.s -o decoder/uwu_decoder.o
   ld decoder/uwu_decoder.o -o decoder/uwu_decoder
   ```
   
   Ou avec gcc :
   ```bash
   gcc -nostdlib -no-pie decoder/uwu_decoder.s -o decoder/uwu_decoder
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

## Variantes du décodeur

Deux versions du décodeur sont disponibles pour rendre l'analyse plus difficile. Elles produisent le même résultat mais utilisent des approches différentes.

### Version 1 (`uwu_decoder.s`)

- **Recherche ascendante** : parcourt les keywords de 0 à 15
- **Registres** : `r12` (source), `r13` (destination), `r14` (table)
- **Test espace** : comparaison directe `cmp al, ' '`
- **Écriture préfixe** : `mov byte ptr` direct

### Version 2 (`uwu_decoder_v2.s`)

- **Recherche descendante** : parcourt les keywords de 15 à 0
- **Registres** : `rbx` (source), `r15` (destination), `r14` (table)
- **Test espace** : soustraction `sub al, 0x20` puis test zero
- **Écriture préfixe** : via `lea` et indirection mémoire

### Compilation

```bash
# Version 1
as --64 decoder/uwu_decoder.s -o decoder/uwu_decoder.o
ld decoder/uwu_decoder.o -o decoder/uwu_decoder

# Version 2
as --64 decoder/uwu_decoder_v2.s -o decoder/uwu_decoder_v2.o
ld decoder/uwu_decoder_v2.o -o decoder/uwu_decoder_v2
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
