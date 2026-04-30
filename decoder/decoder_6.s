# REVERSE_DECODER
.intel_syntax noprefix
.section .text
.global decoder_entry
# --- PROLOGUE_INSERT ---
decoder_entry:
    nop
    lea rdi, [rip + encoded_data]
    lea rsi, [rip + outbuf]
    lea rdx, [rip + keywords]

    xor r9d, r9d
main_loop:
    movzx eax, byte ptr [rdi]
    test al, al
    jz finish_decode
    cmp al, ' '
    je skip_sep

    call decode_nibble
    mov bl, al
    shl bl, 4
    inc rdi
    call decode_nibble
    or bl, al
    mov [rsi + r9], bl
    inc r9
    jmp main_loop

skip_sep:
    inc rdi
    jmp main_loop

finish_decode:
    lea r8, [rip + outbuf]
    lea rcx, [r8 + r9 - 1]
.reverse_loop:
    cmp r8, rcx
    jge done_reverse
    mov al, [r8]
    mov bl, [rcx]
    mov [r8], bl
    mov [rcx], al
    inc r8
    dec rcx
    jmp .reverse_loop

done_reverse:
    lea rax, [rip + outbuf]
    jmp rax

decode_nibble:
    push rcx
    push r8
    push r10

    movzx eax, byte ptr [rdi]
    movzx ecx, byte ptr [rdi + 1]
    movzx r8d, byte ptr [rdi + 2]

    xor r10d, r10d
.search_loop:
    cmp r10d, 16
    jge .nf
    mov r11, r10
    shl r11, 1
    add r11, r10

    cmp r8b, byte ptr [rdx + r11 + 2]
    jne .next
    cmp cl, byte ptr [rdx + r11 + 1]
    jne .next
    cmp al, byte ptr [rdx + r11]
    jne .next

    mov eax, r10d
    jmp .done
.next:
    inc r10d
    jmp .search_loop
.nf:
    xor eax, eax
.done:
    add rdi, 3
    pop r10
    pop r8
    pop rcx
    ret

keywords:
    .ascii "UwUOwOTwT>w<^w^QwQPwPRwRSwSVwVXwXYwYZwZNwNMwMLwL"
encoded_data:
    .asciz "__ENCODED_DATA__"
outbuf:
    .space 4096
