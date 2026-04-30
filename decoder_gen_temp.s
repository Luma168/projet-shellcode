# DOUBLE_XOR_DECODER
.intel_syntax noprefix
.section .text
.global decoder_entry
push r15
    pop r15
    xor r15, r15
    xor r15, r15
    push r15
    pop r15
decoder_entry:
    push rbx
    pop rbx

    lea rdi, [rip + encoded_data]
    lea rsi, [rip + outbuf]
    lea rdx, [rip + keywords]
    mov cl, byte ptr [rip + xor_key]

    xor r9, r9
main_loop:
    movzx eax, byte ptr [rdi]
    test al, al
    jz finish
    cmp al, ' '
    je skip_sep

    call decode_nibble
    mov bl, al
    shl bl, 4
    inc rdi
    call decode_nibble
    or bl, al
    xor bl, cl
    mov [rsi], bl
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

    xor r9d, r9d
.search_loop:
    cmp r9d, 16
    jge .nf

    mov r10, r9
    shl r10, 1
    add r10, r9

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
xor_key:
    .byte 122
encoded_data:
    .asciz "OwO-UwU ^w^-PwP TwT-TwT OwO-UwU QwQ-UwU TwT-QwQ RwR-QwQ RwR-LwL"
outbuf:
    .space 4096
