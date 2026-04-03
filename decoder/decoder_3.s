.intel_syntax noprefix
.section .text
.global decoder_entry

decoder_entry:

    cld

    # ---- polymorphic entry junk ----
rdtsc
xor eax, eax
    test al, 1
    jz  path_A
    jmp path_B

path_A:
    xchg r14, r14
    push r14
    pop  r14
    jmp init

path_B:
    xor r14, r14
    add r14, 0
    jmp init

# ----------------------------------
init:
    lea r13, [rip + encoded_data]
    lea r15, [rip + outbuf]
    lea r11, [rip + keywords]

main_loop:

    mov al, [r13]
    test al, al
    je finish

    cmp al, ' '
    je skip_sep

    call decode_nibble
    mov bl, al
    shl bl, 4

    inc r13

    call decode_nibble
    or bl, al

    mov [r15], bl
    add r15, 1

    jmp main_loop

skip_sep:
    add r13, 1
    jmp main_loop

finish:
    lea rax, [rip + outbuf]
    jmp rax

# ==================================================
# POLYMORPHIC decode_nibble
# ==================================================
decode_nibble:

    push rbx
    push rcx
    push rdx
    push rsi

    # -------- safe polymorphic selector --------
    push rax
    push rdx
    rdtsc
    and eax, 1
    mov r8d, eax        # store variant safely
    pop rdx
    pop rax

    # -------- load bytes AFTER rdtsc --------
    mov al, [r13]
    mov cl, [r13+1]
    mov dl, [r13+2]

    xor rsi, rsi

    test r8d, r8d
    jz variant_A
    jmp variant_B

# -------- Variant A --------
variant_A:
.loop_A:
    cmp rsi, 15
    ja  .nf

    lea rdi, [rsi + rsi*2]

    mov bl, [r11 + rdi]
    cmp al, bl
    jne .next_A
    mov bl, [r11 + rdi + 1]
    cmp cl, bl
    jne .next_A
    mov bl, [r11 + rdi + 2]
    cmp dl, bl
    jne .next_A

    mov eax, esi
    jmp .done

.next_A:
    inc rsi
    jmp .loop_A

# -------- Variant B --------
variant_B:
.loop_B:
    cmp rsi, 15
    ja  .nf

    mov rdi, rsi
    shl rdi, 1
    add rdi, rsi

    mov bl, [r11 + rdi]
    cmp al, bl
    jne .next_B
    mov bl, [r11 + rdi + 1]
    cmp cl, bl
    jne .next_B
    mov bl, [r11 + rdi + 2]
    cmp dl, bl
    jne .next_B

    mov eax, esi
    jmp .done

.next_B:
    inc rsi
    jmp .loop_B

.nf:
    xor eax, eax

.done:
    add r13, 3

    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

# -------- Variant A (lea) --------
search_A:
    cmp rsi, 15
    ja  not_found

    lea rdi, [rsi + rsi*2]

    mov bl, [r11 + rdi]
    cmp al, bl
    jne next_A
    mov bl, [r11 + rdi + 1]
    cmp cl, bl
    jne next_A
    mov bl, [r11 + rdi + 2]
    cmp dl, bl
    jne next_A

    mov eax, esi
    jmp done

next_A:
    inc rsi
    jmp search_A

# -------- Variant B (shl+add) ----
search_B:
    cmp rsi, 15
    ja  not_found

    mov rdi, rsi
    shl rdi, 1
    add rdi, rsi

    mov bl, [r11 + rdi]
    cmp al, bl
    jne next_B
    mov bl, [r11 + rdi + 1]
    cmp cl, bl
    jne next_B
    mov bl, [r11 + rdi + 2]
    cmp dl, bl
    jne next_B

    mov eax, esi
    jmp done

next_B:
    add rsi, 1
    jmp search_B

# -------- Common --------
not_found:
    xor eax, eax

done:
    add r13, 3

    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

# ==================================================
# DATA (unchanged layout)
# ==================================================
keywords:
    .ascii "UwUOwOTwT>w<^w^QwQPwPRwRSwSVwVXwXYwYZwZNwNMwMLwL"

encoded_data:
    .asciz "MwM-YwY OwO-NwN QwQ-MwM ^w^-SwS >w<-OwO NwN-TwT YwY-TwT UwU-MwM ^w^-SwS >w<-OwO LwL-LwL ^w^-UwU LwL-MwM ZwZ-RwR ^w^-SwS >w<-OwO ZwZ-UwU LwL-MwM ZwZ-UwU UwU-LwL UwU-QwQ ^w^-SwS >w<-OwO ZwZ-UwU ^w^-SwS >w<-OwO LwL-LwL YwY-UwU >w<-ZwZ UwU-LwL UwU-QwQ MwM-SwS NwN-MwM LwL-LwL LwL-LwL LwL-LwL ^w^-SwS PwP-QwQ PwP-ZwZ PwP-ZwZ PwP-LwL TwT-ZwZ TwT-UwU RwR-RwR PwP-LwL RwR-TwT PwP-ZwZ PwP-^w^ TwT-OwO UwU-XwX"

outbuf:
    .space 4096