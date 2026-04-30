.intel_syntax noprefix
.section .text
.global decoder_entry
# --- PROLOGUE_INSERT ---
decoder_entry:
    push r14
    pop r14

    lea rdi, [rip + encoded_data]   # pointeur d'entrée (changement de registre)
    lea rsi, [rip + outbuf]        # pointeur de sortie
    lea rdx, [rip + keywords]      # table des mots-clés

main_loop:
    movzx eax, byte ptr [rdi]
    test al, al
    jz finish

    cmp al, ' '
    je skip_sep

    # décodage nibble haut
    call decode_nibble
    mov bl, al
    shl bl, 4

    # sauter le '-'
    inc rdi

    # décodage nibble bas
    call decode_nibble
    or bl, al

    # écrire l'octet
    mov byte ptr [rsi], bl
    inc rsi

    jmp main_loop

skip_sep:
    inc rdi
    jmp main_loop

finish:
    lea rax, [rip + outbuf]
    jmp rax

decode_nibble:
    push rcx
    push r8
    push r9
    push r10

    movzx eax, byte ptr [rdi]
    movzx ecx, byte ptr [rdi + 1]
    movzx r8d, byte ptr [rdi + 2]

    xor r9d, r9d           # index = 0
.search_loop:
    cmp r9d, 16
    jge .nf

    # (index * 3) avec shl + add pour varier
    mov r10, r9
    shl r10, 1
    add r10, r9

    # Comparaison des 3 caractères (ordre inversé pour polymorphisme)
    cmp r8b, byte ptr [rdx + r10 + 2]
    jne .next
    cmp cl, byte ptr [rdx + r10 + 1]
    jne .next
    cmp al, byte ptr [rdx + r10]
    jne .next

    mov eax, r9d
    jmp .done
.next:
    inc r9d
    jmp .search_loop
.nf:
    xor eax, eax
.done:
    add rdi, 3
    pop r10
    pop r9
    pop r8
    pop rcx
    ret

keywords:
    .ascii "UwUOwOTwT>w<^w^QwQPwPRwRSwSVwVXwXYwYZwZNwNMwMLwL"

encoded_data:
    .asciz "__ENCODED_DATA__"

outbuf:
    .space 4096
