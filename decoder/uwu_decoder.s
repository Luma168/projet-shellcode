# =============================================================================
# UwU Decoder - x86_64 Linux (GAS/AT&T syntax)
# =============================================================================
# Décode une chaîne UwU et affiche le shellcode en hexadécimal.
#
# Compile:
#   as --64 uwu_decoder.s -o uwu_decoder.o
#   ld uwu_decoder.o -o uwu_decoder
#
# Ou avec gcc:
#   gcc -nostdlib -no-pie uwu_decoder.s -o uwu_decoder
#
# Usage:
#   ./uwu_decoder
#
# Output: \x48\x31\xc0...
# =============================================================================

.intel_syntax noprefix      # Utiliser syntaxe Intel (plus lisible) dans GAS
                            # Commenter cette ligne pour syntaxe AT&T pure

.section .data
    # Table des keywords (16 * 3 = 48 bytes)
    keywords:
        .ascii "UwU"        # 0x0
        .ascii "OwO"        # 0x1
        .ascii "TwT"        # 0x2
        .ascii ">w<"        # 0x3
        .ascii "^w^"        # 0x4
        .ascii "QwQ"        # 0x5
        .ascii "PwP"        # 0x6
        .ascii "RwR"        # 0x7
        .ascii "SwS"        # 0x8
        .ascii "VwV"        # 0x9
        .ascii "XwX"        # 0xa
        .ascii "YwY"        # 0xb
        .ascii "ZwZ"        # 0xc
        .ascii "NwN"        # 0xd
        .ascii "MwM"        # 0xe
        .ascii "LwL"        # 0xf

    # Chaîne UwU à décoder (MODIFIER ICI)
    encoded_data:
        .asciz "MwM-YwY OwO-NwN QwQ-MwM ^w^-SwS >w<-OwO NwN-TwT YwY-TwT UwU-MwM ^w^-SwS >w<-OwO LwL-LwL ^w^-UwU LwL-MwM ZwZ-RwR ^w^-SwS >w<-OwO ZwZ-UwU LwL-MwM ZwZ-UwU UwU-LwL UwU-QwQ ^w^-SwS >w<-OwO ZwZ-UwU ^w^-SwS >w<-OwO LwL-LwL YwY-UwU >w<-ZwZ UwU-LwL UwU-QwQ MwM-SwS NwN-MwM LwL-LwL LwL-LwL LwL-LwL ^w^-SwS PwP-QwQ PwP-ZwZ PwP-ZwZ PwP-LwL TwT-ZwZ TwT-UwU RwR-RwR PwP-LwL RwR-TwT PwP-ZwZ PwP-^w^ TwT-OwO UwU-XwX"
    
    # Table de conversion hex
    hex_chars:
        .ascii "0123456789abcdef"

.section .bss
    .lcomm output_buffer, 4096

.section .text
    .global _start

_start:
    # r12 = pointeur lecture (encoded_data)
    # r13 = pointeur écriture (output_buffer)
    # r14 = adresse keywords
    lea r12, [rip + encoded_data]
    lea r13, [rip + output_buffer]
    lea r14, [rip + keywords]

decode_loop:
    # Lire caractère courant
    movzx eax, byte ptr [r12]
    test al, al
    jz print_output

    # Sauter les espaces
    cmp al, ' '
    je skip_byte_sep

    # Décoder nibble haut
    call decode_nibble
    mov bl, al
    shl bl, 4

    # Sauter le '-'
    inc r12

    # Décoder nibble bas
    call decode_nibble
    or bl, al

    # Écrire "\x" dans le buffer
    mov byte ptr [r13], '\\'
    inc r13
    mov byte ptr [r13], 'x'
    inc r13

    # Convertir nibble haut en hex
    mov al, bl
    shr al, 4
    lea rcx, [rip + hex_chars]
    movzx eax, byte ptr [rcx + rax]
    mov [r13], al
    inc r13

    # Convertir nibble bas en hex
    mov al, bl
    and al, 0x0F
    movzx eax, byte ptr [rcx + rax]
    mov [r13], al
    inc r13

    jmp decode_loop

skip_byte_sep:
    inc r12
    jmp decode_loop

print_output:
    # Ajouter newline
    mov byte ptr [r13], 10
    inc r13

    # Calculer longueur
    lea rax, [rip + output_buffer]
    sub r13, rax

    # write(1, output_buffer, len)
    mov rax, 1              # syscall write
    mov rdi, 1              # stdout
    lea rsi, [rip + output_buffer]
    mov rdx, r13
    syscall

    # exit(0)
    mov rax, 60
    xor rdi, rdi
    syscall

# =============================================================================
# decode_nibble: Convertit keyword (3 chars) en nibble (0-15)
# =============================================================================
decode_nibble:
    push rcx
    push rdx
    push r8
    push r9

    movzx eax, byte ptr [r12]
    movzx ecx, byte ptr [r12+1]
    movzx edx, byte ptr [r12+2]

    xor r8, r8              # index = 0

.search:
    cmp r8, 16
    jge .not_found

    # Offset = index * 3
    mov r9, r8
    lea r9, [r9 + r9*2]

    # Comparer les 3 chars
    cmp al, byte ptr [r14 + r9]
    jne .next
    cmp cl, byte ptr [r14 + r9 + 1]
    jne .next
    cmp dl, byte ptr [r14 + r9 + 2]
    jne .next

    # Trouvé
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
