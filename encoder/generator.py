"""ASM stub generation utilities."""

import random
import shlex
import subprocess
from pathlib import Path


def choose_regs():
    pool = ["r10", "r11", "r12", "r13", "r14", "r15"]
    random.shuffle(pool)
    return pool[:4]


def build_asm(encoded, out_path, dryrun=False, xor_key=None, reverse=False, double_xor_key=None):
    decoder_folder = Path("decoder")
    s_files = list(decoder_folder.glob("*.s"))

    required_marker = None
    if xor_key is not None:
        required_marker = "# XOR_DECODER"
    elif reverse:
        required_marker = "# REVERSE_DECODER"
    elif double_xor_key is not None:
        required_marker = "# DOUBLE_XOR_DECODER"

    if required_marker:
        filtered = []
        for f in s_files:
            if required_marker in f.read_text():
                filtered.append(f)
        if not filtered:
            raise FileNotFoundError(f"Aucun décodeur trouvé avec le marqueur {required_marker}")
        s_files = filtered
    else:
        # Exclure les décodeurs spéciaux (qui ont un marqueur)
        normal = []
        for f in s_files:
            content = f.read_text()
            if not any(m in content for m in ["# XOR_DECODER",
                                              "# REVERSE_DECODER",
                                              "# DOUBLE_XOR_DECODER"]):
                normal.append(f)
        if normal:
            s_files = normal

    asm_path = random.choice(s_files)
    asm = asm_path.read_text()

    # prologue métamorphique
    regs = choose_regs()
    r_tmp = regs[0]
    junk = []
    for _ in range(random.randint(1, 4)):
        seq = random.choice([
            f"push {r_tmp}\n    pop {r_tmp}",
            f"xor {r_tmp}, {r_tmp}",
            f"inc {r_tmp}\n    dec {r_tmp}",
        ])
        junk.append(seq)
    prologue = "\n    ".join(junk)

    # Appliquer les transformations d’encodage
    if reverse:
        from .reverse_uwu import reverse_uwu_encode
        encoded = reverse_uwu_encode(encoded)
    elif double_xor_key is not None:
        from .double_uwu import double_xor_encode
        encoded = double_xor_encode(encoded, double_xor_key)
        asm = asm.replace(".byte 0x00", f".byte {double_xor_key}")
    elif xor_key is not None:
        from .xor_uwu import xor_encode_uwu
        encoded = xor_encode_uwu(encoded, xor_key)
        asm = asm.replace(".byte 0x00", f".byte {xor_key}")

    # Injections finales
    asm = asm.replace("# --- PROLOGUE_INSERT ---", prologue)
    asm = asm.replace("__ENCODED_DATA__", encoded.replace('"', "'"))

    out_asm = Path("decoder_gen_temp.s")
    out_asm.write_text(asm)

    if dryrun:
        print(asm)
        return out_asm

    obj = Path("decoder_gen.o")
    bin_out = Path(out_path)

    cmds = [
        ["gcc", "-nostdlib", "-no-pie", "-c", str(out_asm), "-o", str(obj)],
        ["objcopy", "--only-section=.text", "-O", "binary", str(obj), str(bin_out)],
    ]
    for cmd in cmds:
        print("Running:", " ".join(shlex.quote(c) for c in cmd))
        subprocess.check_call(cmd)

    print(f"Wrote shellcode binary to: {bin_out}")
    return bin_out
