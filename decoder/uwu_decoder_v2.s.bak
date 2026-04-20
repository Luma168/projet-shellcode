# =============================================================================
# UwU Decoder v2 - x86_64 Linux (GAS)
# =============================================================================
# Variante avec algorithme différent:
# - Recherche des keywords en sens inverse (15 → 0)
# - Utilise des registres différents
# - Construit la sortie différemment
#
# Compile:
#   as --64 uwu_decoder_v2.s -o uwu_decoder_v2.o
#   ld uwu_decoder_v2.o -o uwu_decoder_v2
# =============================================================================

.intel_syntax noprefix

.section .data
    # Table keywords inversée (on cherche de 15 à 0)
    keywords:
        .ascii "UwU"        # 0x0
        .ascii "OwO"        # 0x1
        .ascii "TwT"        # 0x2
        .ascii ">w<"        # 0x3
        .ascii "^w^"        # 0x4
        .ascii "QwQ"        # 0x5
        .ascii "PwP"        # 0x6
        .ascii "RwR"        # 0x7
        .ascii "SwS"        # 0x8
        .ascii "VwV"        # 0x9
        .ascii "XwX"        # 0xa
        .ascii "YwY"        # 0xb
        .ascii "ZwZ"        # 0xc
        .ascii "NwN"        # 0xd
        .ascii "MwM"        # 0xe
        .ascii "LwL"        # 0xf

    encoded_data:
        .asciz "MwM-YwY OwO-NwN QwQ-MwM ^w^-SwS >w<-OwO NwN-TwT YwY-TwT UwU-MwM ^w^-SwS >w<-OwO LwL-LwL ^w^-UwU LwL-MwM ZwZ-RwR ^w^-SwS >w<-OwO ZwZ-UwU LwL-MwM ZwZ-UwU UwU-LwL UwU-QwQ ^w^-SwS >w<-OwO ZwZ-UwU ^w^-SwS >w<-OwO LwL-LwL YwY-UwU >w<-ZwZ UwU-LwL UwU-QwQ MwM-SwS NwN-MwM LwL-LwL LwL-LwL LwL-LwL ^w^-SwS PwP-QwQ PwP-ZwZ PwP-ZwZ PwP-LwL TwT-ZwZ TwT-UwU RwR-RwR PwP-LwL RwR-TwT PwP-ZwZ PwP-^w^ TwT-OwO UwU-XwX"

    hex_table:
        .ascii "0123456789abcdef"
    
    prefix_slash:
        .byte '\\'
    prefix_x:
        .byte 'x'

.section .bss
    .lcomm buffer, 4096
    .lcomm temp_byte, 1

.section .text
    .global _start

_start:
    # Registres utilisés différemment:
    # rbx = source pointer
    # r15 = dest pointer
    # r14 = keywords base
    # r10 = byte accumulateur
    
    lea rbx, [rip + encoded_data]
    lea r15, [rip + buffer]
    lea r14, [rip + keywords]
    
    xor r10, r10

main_loop:
    # Charger et tester fin de chaîne
    xor rax, rax
    mov al, [rbx]
    cmp al, 0
    je output_result
    
    # Test séparateur byte (espace) - méthode différente
    sub al, 0x20            # 0x20 = espace
    jz next_char            # Si zéro, c'était un espace
    add al, 0x20            # Restaurer
    
    # Décoder premier keyword (nibble haut)
    call find_keyword_reverse
    mov r10b, al
    shl r10b, 4             # Shift nibble haut
    
    # Passer le séparateur '-'
    inc rbx
    
    # Décoder second keyword (nibble bas)
    call find_keyword_reverse
    or r10b, al             # Combiner les nibbles
    
    # Écrire \x en utilisant des moves séparés
    lea rdi, [rip + prefix_slash]
    mov al, [rdi]
    mov [r15], al
    inc r15
    
    lea rdi, [rip + prefix_x]
    mov al, [rdi]
    mov [r15], al
    inc r15
    
    # Convertir et écrire les 2 chars hex
    # Nibble haut
    mov al, r10b
    shr al, 4
    lea rdi, [rip + hex_table]
    xor rcx, rcx
    mov cl, al
    mov al, [rdi + rcx]
    mov [r15], al
    inc r15
    
    # Nibble bas
    mov al, r10b
    and al, 0x0F
    xor rcx, rcx
    mov cl, al
    mov al, [rdi + rcx]
    mov [r15], al
    inc r15
    
    jmp main_loop

next_char:
    inc rbx
    jmp main_loop

output_result:
    # Newline
    mov byte ptr [r15], 0x0A
    inc r15
    
    # Calculer taille
    lea rsi, [rip + buffer]
    mov rdx, r15
    sub rdx, rsi
    
    # Syscall write
    mov rax, 1
    mov rdi, 1
    syscall
    
    # Syscall exit
    xor rdi, rdi
    mov rax, 60
    syscall

# =============================================================================
# find_keyword_reverse: Cherche keyword de 15 vers 0 (inverse de v1)
# Input: rbx = pointeur vers keyword
# Output: al = nibble value, rbx += 3
# =============================================================================
find_keyword_reverse:
    push r8
    push r9
    push r11
    push r12
    
    # Charger les 3 caractères à chercher
    xor r11, r11
    xor r12, r12
    xor r8, r8
    
    mov r11b, [rbx]         # char 1
    mov r12b, [rbx + 1]     # char 2
    mov r8b, [rbx + 2]      # char 3
    
    # Commencer à 15 et descendre (différent de v1)
    mov r9, 15

.search_loop:
    cmp r9, 0
    jl .not_found
    
    # Calculer offset: r9 * 3
    mov rax, r9
    lea rax, [rax + rax*2]  # rax = r9 * 3
    
    # Comparer caractère par caractère
    xor rcx, rcx
    mov cl, [r14 + rax]
    cmp r11b, cl
    jne .continue
    
    mov cl, [r14 + rax + 1]
    cmp r12b, cl
    jne .continue
    
    mov cl, [r14 + rax + 2]
    cmp r8b, cl
    jne .continue
    
    # Trouvé!
    mov rax, r9
    jmp .found

.continue:
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
