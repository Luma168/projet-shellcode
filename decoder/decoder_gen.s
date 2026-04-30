
    .intel_syntax noprefix
    .section .text
    .global decoder_entry
# --- PROLOGUE_INSERT ---
decoder_entry:
    inc r14
    dec r14
    push r14
    pop r14

    lea r13, [rip + encoded_data]
    lea r15, [rip + outbuf]
    lea r11, [rip + keywords]

main_loop:
    movzx eax, byte ptr [r13]
    test al, al
    jz finish

    cmp al, ' '
    je skip_sep

    # decode high nibble
    call decode_nibble
    mov bl, al
    shl bl, 4

    # skip '-'
    inc r13

    # decode low nibble
    call decode_nibble
    or bl, al

    # store byte
    mov byte ptr [r15], bl
    inc r15

    jmp main_loop

skip_sep:
    inc r13
    jmp main_loop

finish:
    # jump to decoded buffer
    lea rax, [rip + outbuf]
    jmp rax

decode_nibble:
    push rbx
    push rcx
    push rdx
    push rsi

    movzx eax, byte ptr [r13]
    movzx ecx, byte ptr [r13 + 1]
    movzx edx, byte ptr [r13 + 2]

    xor rsi, rsi
.search_loop:
    cmp rsi, 16
    jge .nf

    lea rdi, [rsi + rsi*2]
    # compare 3 chars
    cmp al, byte ptr [r11 + rdi]
    jne .next
    cmp cl, byte ptr [r11 + rdi + 1]
    jne .next
    cmp dl, byte ptr [r11 + rdi + 2]
    jne .next

    mov eax, esi
    jmp .done
.next:
    inc rsi
    jmp .search_loop
.nf:
    xor eax, eax
.done:
    add r13, 3
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

# ---- data (kept in .text so objcopy --only-section=.text captures it) ----
keywords:
    .ascii "UwUOwOTwT>w<^w^QwQPwPRwRSwSVwVXwXYwYZwZNwNMwMLwL"

encoded_data:
    .asciz "__ENCODED_DATA__"
    
outbuf:
    .space 4096

    