# =============================================================================
# UwU Decoder v3 - x86_64 Linux (GAS)
# =============================================================================
# Variante avec méthode XOR + comparaison combinée:
# - Combine les 3 caractères en un seul mot 32-bit
# - Compare en une seule instruction au lieu de 3
# - Utilise une table de signatures pré-calculées
#
# Compile:
#   as --64 uwu_decoder_v3.s -o uwu_decoder_v3.o
#   ld uwu_decoder_v3.o -o uwu_decoder_v3
# =============================================================================

.intel_syntax noprefix

.section .data
    # Table des signatures (3 chars packed en 32-bit little-endian)
    # Chaque entrée = char0 | (char1 << 8) | (char2 << 16)
    signatures:
        .long 0x00557755     # "UwU" = 'U'|('w'<<8)|('U'<<16) = 0x55|0x7700|0x550000
        .long 0x004F774F     # "OwO"
        .long 0x00547754     # "TwT"
        .long 0x003C773E     # ">w<"
        .long 0x005E775E     # "^w^"
        .long 0x00517751     # "QwQ"
        .long 0x00507750     # "PwP"
        .long 0x00527752     # "RwR"
        .long 0x00537753     # "SwS"
        .long 0x00567756     # "VwV"
        .long 0x00587758     # "XwX"
        .long 0x00597759     # "YwY"
        .long 0x005A775A     # "ZwZ"
        .long 0x004E774E     # "NwN"
        .long 0x004D774D     # "MwM"
        .long 0x004C774C     # "LwL"

   encoded_data:
    .asciz "__ENCODED_DATA__"
    hex_lookup:
        .ascii "0123456789abcdef"

.section .bss
    .lcomm result_buf, 4096

.section .text
    .global _start
# --- PROLOGUE_INSERT ---
_start:
    # r8  = source ptr
    # r9  = dest ptr
    # r10 = signatures table
    # r11 = current byte accumulator
    
    lea r8, [rip + encoded_data]
    lea r9, [rip + result_buf]
    lea r10, [rip + signatures]

process_loop:
    # Lire premier char
    movzx eax, byte ptr [r8]
    test al, al
    jz finish_output
    
    # Skip espace avec XOR trick
    xor al, 0x20
    jz advance_skip
    
    # Décoder nibble haut
    call lookup_signature
    mov r11b, al
    shl r11b, 4
    
    # Skip le '-'
    inc r8
    
    # Décoder nibble bas
    call lookup_signature
    or r11b, al
    
    # Écrire sortie: construire "\xNN"
    # Utiliser push/pop pour stocker temporairement
    push r11
    
    mov byte ptr [r9], 0x5C     # '\'
    mov byte ptr [r9+1], 0x78   # 'x'
    add r9, 2
    
    # Nibble haut -> hex char
    pop rax
    push rax
    shr al, 4
    lea rcx, [rip + hex_lookup]
    movzx eax, byte ptr [rcx + rax]
    mov [r9], al
    inc r9
    
    # Nibble bas -> hex char  
    pop rax
    and al, 0x0F
    movzx eax, byte ptr [rcx + rax]
    mov [r9], al
    inc r9
    
    jmp process_loop

advance_skip:
    inc r8
    jmp process_loop

finish_output:
    # Ajouter newline
    mov byte ptr [r9], 0x0A
    inc r9
    
    # Calculer longueur totale
    lea rdx, [rip + result_buf]
    sub r9, rdx
    
    # write syscall
    mov rax, 1
    mov rdi, 1
    lea rsi, [rip + result_buf]
    mov rdx, r9
    syscall
    
    # exit syscall
    mov rax, 60
    xor rdi, rdi
    syscall

# =============================================================================
# lookup_signature: Trouve le nibble via comparaison de signature 32-bit
# Input: r8 = ptr vers 3 chars
# Output: al = nibble (0-15), r8 += 3
# =============================================================================
lookup_signature:
    push rbx
    push rcx
    push rdx
    
    # Construire la signature des 3 chars d'entrée
    # sig = char0 | (char1 << 8) | (char2 << 16)
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    
    mov al, [r8]            # char0
    mov bl, [r8 + 1]        # char1
    mov cl, [r8 + 2]        # char2
    
    shl ebx, 8              # char1 << 8
    shl ecx, 16             # char2 << 16
    
    or eax, ebx
    or eax, ecx             # eax = signature complète
    
    # Chercher dans la table (comparaison 32-bit unique)
    xor edx, edx            # index = 0

.sig_search:
    cmp edx, 16
    jge .sig_not_found
    
    # Comparer signature en une instruction
    cmp eax, dword ptr [r10 + rdx*4]
    je .sig_found
    
    inc edx
    jmp .sig_search

.sig_not_found:
    xor eax, eax
    jmp .sig_done

.sig_found:
    mov eax, edx            # nibble = index

.sig_done:
    add r8, 3
    
    pop rdx
    pop rcx
    pop rbx
    ret
