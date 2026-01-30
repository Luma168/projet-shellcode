; =============================================================================
; UwU Decoder - x86_64 Linux
; =============================================================================
; Décode une chaîne UwU et affiche le shellcode en hexadécimal.
;
; Compile:
;   nasm -f elf64 uwu_decoder.asm -o uwu_decoder.o
;   ld uwu_decoder.o -o uwu_decoder
;
; Usage:
;   ./uwu_decoder
;   (la chaîne encodée est dans encoded_data, à modifier avant compilation)
;
; Output: \x48\x31\xc0...
; =============================================================================

BITS 64

section .data
    ; Table des keywords (16 * 3 = 48 bytes)
    ; Index = valeur du nibble (0-15)
    keywords:
        db "UwU"    ; 0x0
        db "OwO"    ; 0x1
        db "TwT"    ; 0x2
        db ">w<"    ; 0x3
        db "^w^"    ; 0x4
        db "QwQ"    ; 0x5
        db "PwP"    ; 0x6
        db "RwR"    ; 0x7
        db "SwS"    ; 0x8
        db "VwV"    ; 0x9
        db "XwX"    ; 0xa
        db "YwY"    ; 0xb
        db "ZwZ"    ; 0xc
        db "NwN"    ; 0xd
        db "MwM"    ; 0xe
        db "LwL"    ; 0xf

    ; Séparateurs
    nibble_sep: db '-'
    byte_sep: db ' '

    ; Chaîne UwU à décoder (MODIFIER ICI)
    encoded_data: db "^w^-SwS >w<-OwO ZwZ-UwU", 0
    
    ; Format de sortie
    hex_prefix: db "\x"
    hex_chars: db "0123456789abcdef"
    newline: db 10

section .bss
    output_buffer: resb 4096    ; Buffer pour la sortie hex

section .text
    global _start

_start:
    ; r12 = pointeur lecture (encoded_data)
    ; r13 = pointeur écriture (output_buffer)
    ; r14 = adresse keywords
    lea r12, [rel encoded_data]
    lea r13, [rel output_buffer]
    lea r14, [rel keywords]

decode_loop:
    ; Lire caractère courant
    movzx eax, byte [r12]
    test al, al
    jz print_output             ; Fin de chaîne
    
    ; Sauter les espaces (séparateur d'octets)
    cmp al, ' '
    je skip_byte_sep
    
    ; Décoder nibble haut
    call decode_nibble
    mov bl, al                  ; Sauvegarder nibble haut
    shl bl, 4
    
    ; Sauter le '-'
    inc r12
    
    ; Décoder nibble bas
    call decode_nibble
    or bl, al                   ; Combiner: (high << 4) | low
    
    ; Écrire "\x" dans le buffer
    mov byte [r13], '\'
    inc r13
    mov byte [r13], 'x'
    inc r13
    
    ; Convertir l'octet en hex et écrire
    mov al, bl
    shr al, 4                   ; Nibble haut
    lea rcx, [rel hex_chars]
    movzx eax, byte [rcx + rax]
    mov [r13], al
    inc r13
    
    mov al, bl
    and al, 0x0F                ; Nibble bas
    movzx eax, byte [rcx + rax]
    mov [r13], al
    inc r13
    
    jmp decode_loop

skip_byte_sep:
    inc r12
    jmp decode_loop

print_output:
    ; Ajouter newline
    mov byte [r13], 10
    inc r13
    
    ; Calculer la longueur
    lea rax, [rel output_buffer]
    sub r13, rax                ; r13 = longueur
    
    ; write(1, output_buffer, len)
    mov rax, 1                  ; syscall write
    mov rdi, 1                  ; stdout
    lea rsi, [rel output_buffer]
    mov rdx, r13                ; longueur
    syscall
    
    ; exit(0)
    mov rax, 60
    xor rdi, rdi
    syscall

; =============================================================================
; decode_nibble: Convertit un keyword (3 chars) en nibble (0-15)
; Input:  r12 = pointeur vers keyword
; Output: al = valeur du nibble, r12 avancé de 3
; =============================================================================
decode_nibble:
    push rcx
    push rdx
    push r8
    push r9
    
    ; Charger les 3 caractères
    movzx eax, byte [r12]
    movzx ecx, byte [r12+1]
    movzx edx, byte [r12+2]
    
    xor r8, r8                  ; index = 0

.search:
    cmp r8, 16
    jge .not_found
    
    ; Offset = index * 3
    mov r9, r8
    lea r9, [r9 + r9*2]
    
    ; Comparer
    cmp al, byte [r14 + r9]
    jne .next
    cmp cl, byte [r14 + r9 + 1]
    jne .next
    cmp dl, byte [r14 + r9 + 2]
    jne .next
    
    ; Trouvé
    mov rax, r8
    jmp .done

.next:
    inc r8
    jmp .search

.not_found:
    xor eax, eax

.done:
    add r12, 3
    pop r9
    pop r8
    pop rdx
    pop rcx
    ret
