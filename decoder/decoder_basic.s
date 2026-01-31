.intel_syntax noprefix
.section .text
.global decoder_entry
decoder_entry:
    xor r10, r10
    xchg r10, r10
    push r10
    pop r10

    lea r11, [rip + encoded_data]
    lea r14, [rip ]
    lea r12, [rip + keywords]

main_loop:
    movzx eax, byte ptr [r11]
    test al, al
    jz finish

    cmp al, ' '
    je skip_sep

    # decode high nibble
    call decode_nibble
    mov bl, al
    shl bl, 4

    # skip '-'
    inc r11

    # decode low nibble
    call decode_nibble
    or bl, al

    # store byte
    mov byte ptr [r14], bl
    inc r14

    jmp main_loop

skip_sep:
    inc r11
    jmp main_loop

finish:
    # jump to decoded buffer
    lea rax, [rip ]
    jmp rax

decode_nibble:
    push rbx
    push rcx
    push rdx
    push rsi

    movzx eax, byte ptr [r11]
    movzx ecx, byte ptr [r11 + 1]
    movzx edx, byte ptr [r11 + 2]

    xor rsi, rsi
.search_loop:
    cmp rsi, 16
    jge .nf

    lea rdi, [rsi + rsi*2]
    # compare 3 chars
    cmp al, byte ptr [r12 + rdi]
    jne .next
    cmp cl, byte ptr [r12 + rdi + 1]
    jne .next
    cmp dl, byte ptr [r12 + rdi + 2]
    jne .next

    mov eax, esi
    jmp .done
.next:
    inc rsi
    jmp .search_loop
.nf:
    xor eax, eax
.done:
    add r11, 3
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

# ---- data (kept in .text so objcopy --only-section=.text captures it) ----
keywords:
    .ascii "UwUOwOTwT>w<^w^QwQPwPRwRSwSVwVXwXYwYZwZNwNMwMLwL"

encoded_data:
    .asciz "^w^-SwS >w<-OwO ZwZ-UwU YwY-UwU >w<-ZwZ ^w^-SwS >w<-OwO LwL-LwL ^w^-UwU YwY-RwR UwU-RwR UwU-LwL UwU-QwQ"



