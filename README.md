# UwU Shellcode Encoder/Decoder

Encodeur Python et décodeur ASM pour obfusquer du shellcode avec des mots-clés kawaii.

## Structure

```
uwu_shellcode_encoder/
├── cli.py                  # CLI principale
├── encoder/
│   └── uwu_encoder.py      # Module encodeur
├── decoder/
│   ├── uwu_decoder.s       # Décodeur v1 (recherche ascendante)
│   ├── uwu_decoder_v2.s    # Décodeur v2 (recherche descendante)
│   └── uwu_decoder_v3.s    # Décodeur v3 (signature 32-bit)
├── keywords.json           # Table de correspondance
└── README.md
```

## CLI

### Encoder (hex → UwU)

```bash
# Depuis argument
python3 cli.py encode -s '\x48\x31\xc0'

# Depuis fichier
python3 cli.py encode -f shellcode.txt

# Vers fichier
python3 cli.py encode -s '\x48\x31\xc0' -o encoded.uwu
```

### Décoder (UwU → hex)

Le décodage compile et exécute automatiquement le décodeur ASM.

```bash
# Depuis argument
python3 cli.py decode -e '^w^-SwS >w<-OwO ZwZ-UwU'

# Depuis fichier
python3 cli.py decode -f encoded.uwu

# Choisir la version du décodeur (1, 2 ou 3)
python3 cli.py decode -e '^w^-SwS >w<-OwO' -v 2

# Vers fichier
python3 cli.py decode -f encoded.uwu -o shellcode.txt
```

**Exemple:**
```
$ python3 cli.py encode -s '\x48\x31\xc0'
^w^-SwS >w<-OwO ZwZ-UwU

$ python3 cli.py decode -e '^w^-SwS >w<-OwO ZwZ-UwU'
\x48\x31\xc0
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

### Version 3 (`uwu_decoder_v3.s`)

- **Signature 32-bit** : combine les 3 caractères en un seul mot (`char0 | char1<<8 | char2<<16`)
- **Comparaison unique** : compare la signature en une seule instruction `cmp` au lieu de 3
- **Table pré-calculée** : utilise une table de signatures `.long` au lieu de `.ascii`
- **Registres** : `r8` (source), `r9` (destination), `r10` (table), `r11` (accumulateur)

### Compilation

```bash
# Version 1
as --64 decoder/uwu_decoder.s -o decoder/uwu_decoder.o
ld decoder/uwu_decoder.o -o decoder/uwu_decoder

# Version 2
as --64 decoder/uwu_decoder_v2.s -o decoder/uwu_decoder_v2.o
ld decoder/uwu_decoder_v2.o -o decoder/uwu_decoder_v2

# Version 3
as --64 decoder/uwu_decoder_v3.s -o decoder/uwu_decoder_v3.o
ld decoder/uwu_decoder_v3.o -o decoder/uwu_decoder_v3
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
