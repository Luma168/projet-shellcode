.intel_syntax noprefix
.section .text
.global _start

_start:
    xor r10, r10

    # r11 = input pointer
    lea r11, [rip + encoded_data]

    # r12 = keywords table
    lea r12, [rip + keywords]

    # r14 = output buffer (in .data section - writable)
    lea r14, [rip + decoded_buf]

main_loop:
    movzx eax, byte ptr [r11]
    test al, al
    jz finish

    cmp al, ' '
    je skip_sep

    # ---- high nibble ----
    call decode_nibble
    mov bl, al
    shl bl, 4

    # skip '-'
    inc r11

    # ---- low nibble ----
    call decode_nibble
    or bl, al

    # store decoded byte
    mov byte ptr [r14], bl
    inc r14

    jmp main_loop

skip_sep:
    inc r11
    jmp main_loop

finish:
    # mprotect(decoded_buf, 4096, PROT_READ|PROT_WRITE|PROT_EXEC)
    lea rdi, [rip + decoded_buf]
    and rdi, -4096          # align address to page boundary
    mov rax, 10             # mprotect syscall
    mov rsi, 4096           # length
    mov rdx, 7              # PROT_READ | PROT_WRITE | PROT_EXEC
    syscall

    # jump to decoded buffer
    lea rax, [rip + decoded_buf]
    jmp rax

# ------------------------------------
# decode_nibble
# in : r11 -> 3-byte encoded token
# out: al  = nibble value (0..15)
# ------------------------------------
decode_nibble:
    push rbx
    push rsi
    push rdi

    movzx eax, byte ptr [r11]
    movzx ecx, byte ptr [r11 + 1]
    movzx edx, byte ptr [r11 + 2]

    xor rsi, rsi          # nibble index = 0

.search_loop:
    cmp rsi, 16
    jge .not_found

    lea rdi, [rsi + rsi*2]   # rdi = rsi * 3

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

.not_found:
    xor eax, eax

.done:
    add r11, 3

    pop rdi
    pop rsi
    pop rbx
    ret

# ------------------------------------
# Data (kept in .text section)
# ------------------------------------
.section .text
keywords:
    .ascii "UwUOwOTwT>w<^w^QwQPwPRwRSwSVwVXwXYwYZwZNwNMwMLwL"

encoded_data:
    .asciz "MwM-YwY OwO-NwN QwQ-MwM ^w^-SwS >w<-OwO NwN-TwT YwY-TwT UwU-MwM ^w^-SwS >w<-OwO LwL-LwL ^w^-UwU LwL-MwM ZwZ-RwR ^w^-SwS >w<-OwO ZwZ-UwU LwL-MwM ZwZ-UwU UwU-LwL UwU-QwQ ^w^-SwS >w<-OwO ZwZ-UwU ^w^-SwS >w<-OwO LwL-LwL YwY-UwU >w<-ZwZ UwU-LwL UwU-QwQ MwM-SwS NwN-MwM LwL-LwL LwL-LwL LwL-LwL ^w^-SwS PwP-QwQ PwP-ZwZ PwP-ZwZ PwP-LwL TwT-ZwZ TwT-UwU RwR-RwR PwP-LwL RwR-TwT PwP-ZwZ PwP-^w^ TwT-OwO UwU-XwX"

# Output buffer for decoded shellcode (writable)
.section .data
decoded_buf:
    .space 4096

# Decoded payload (escaped representation)
payload_escaped:
    .asciz "\xeb\x1d\x5e\x48\x31\xd2\xb2\x0e\x48\x31\xff\x40\xfe\xc7\x48\x31\xc0\xfe\xc0\x0f\x05\x48\x31\xc0\x48\x31\xff\xb0\x3c\x0f\x05\xe8\xde\xff\xff\xff\x48\x65\x6c\x6c\x6f\x2c\x20\x77\x6f\x72\x6c\x64\x21\x0a"

# Decoded payload (raw bytes)
payload_bytes:
    .byte 0xeb,0x1d,0x5e,0x48,0x31,0xd2,0xb2,0x0e,0x48,0x31,0xff,0x40,0xfe,0xc7,0x48,0x31,0xc0,0xfe,0xc0,0x0f,0x05,0x48,0x31,0xc0,0x48,0x31,0xff,0xb0,0x3c,0x0f,0x05,0xe8,0xde,0xff,0xff,0xff,0x48,0x65,0x6c,0x6c,0x6f,0x2c,0x20,0x77,0x6f,0x72,0x6c,0x64,0x21,0x0a