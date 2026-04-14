; =============================================================================
; exit_clean.s — Shellcode template x86_64 Linux
; =============================================================================
; Description : Appelle exit(0) proprement sans laisser de trace.
;               Utile pour tester le pipeline encode/decode sans crash.
;
; Syscall     : exit (60)
; Taille      : ~6 bytes
; Null bytes  : aucun
;
; Compilation :
;   nasm -f elf64 exit_clean.s -o exit_clean.o
;   ld exit_clean.o -o exit_clean
;   objcopy --dump-section .text=exit_clean.bin exit_clean
;
; Ou via build.sh fourni dans ce dossier.
; =============================================================================

section .text
global _start

_start:
    xor edi, edi        ; rdi = 0  → code de sortie = 0
                        ; (xor edi évite les null bytes vs mov rdi, 0)

    push 60             ; numéro syscall exit = 60
    pop rax             ; rax = 60 (sans null bytes)

    syscall             ; exit(0)
