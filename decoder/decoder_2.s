.intel_syntax noprefix
.section .text
.global decoder_entry

decoder_entry:

    cld                  # ensure DF=0 for safe forward writes
    xchg r14, r14        # small metamorphic junk instruction
    push r14
    pop r14

    lea r13, [rip + encoded_data]   # input pointer
    lea r15, [rip + outbuf]         # output pointer
    lea r11, [rip + keywords]       # keywords table

main_loop:

    mov al, [r13]
    test al, al
    je finish

    cmp al, ' '
    je skip_sep

    call decode_nibble
    mov bl, al
    shl bl, 4                # high nibble

    inc r13

    call decode_nibble
    or bl, al                 # combine low nibble

    mov [r15], bl
    add r15, 1                # metamorphic variant of inc

    jmp main_loop

skip_sep:
    add r13, 1
    jmp main_loop

finish:
    lea rax, [rip + outbuf]   # jump to decoded payload
    jmp rax

# --------------------------------------------------
decode_nibble:

    push rbx
    push rcx
    push rdx
    push rsi                 # preserve same registers as original

    mov al,  [r13]
    mov cl,  [r13+1]
    mov dl,  [r13+2]

    xor rsi, rsi              # index = 0

.search_loop:

    cmp rsi, 15
    ja  .nf                   # different opcode form

    # rdi = rsi * 3 using shl+add (metamorphic variant)
    mov rdi, rsi
    shl rdi, 1
    add rdi, rsi

    mov bl, byte ptr [r11 + rdi]
    cmp al, bl
    jne .next

    mov bl, byte ptr [r11 + rdi + 1]
    cmp cl, bl
    jne .next

    mov bl, byte ptr [r11 + rdi + 2]
    cmp dl, bl
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

# --------------------------------------------------
# ASCII Keywords table (16*3)
keywords:
    .ascii "UwUOwOTwT>w<^w^QwQPwPRwRSwSVwVXwXYwYZwZNwNMwMLwL"

# --------------------------------------------------
# Encoded UwU payload
encoded_data:
    .asciz "MwM-YwY OwO-NwN QwQ-MwM ^w^-SwS >w<-OwO NwN-TwT YwY-TwT UwU-MwM ^w^-SwS >w<-OwO LwL-LwL ^w^-UwU LwL-MwM ZwZ-RwR ^w^-SwS >w<-OwO ZwZ-UwU LwL-MwM ZwZ-UwU UwU-LwL UwU-QwQ ^w^-SwS >w<-OwO ZwZ-UwU ^w^-SwS >w<-OwO LwL-LwL YwY-UwU >w<-ZwZ UwU-LwL UwU-QwQ MwM-SwS NwN-MwM LwL-LwL LwL-LwL LwL-LwL ^w^-SwS PwP-QwQ PwP-ZwZ PwP-ZwZ PwP-LwL TwT-ZwZ TwT-UwU RwR-RwR PwP-LwL RwR-TwT PwP-ZwZ PwP-^w^ TwT-OwO UwU-XwX"

# --------------------------------------------------
# Output buffer (decoded binary)
outbuf:
    .space 4096