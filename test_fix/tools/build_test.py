#!/usr/bin/env python3
import argparse
import pathlib
import subprocess


def run(cmd):
    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    if proc.returncode != 0:
        print(proc.stdout, end="")
        raise SystemExit(proc.returncode)
    return proc.stdout


def bin_to_word_hex(bin_path: pathlib.Path, hex_path: pathlib.Path, pad_words: int):
    data = bin_path.read_bytes()
    if len(data) % 4:
        data += bytes(4 - (len(data) % 4))

    used_words = len(data) // 4
    with hex_path.open("w", encoding="ascii") as f:
        for i in range(0, len(data), 4):
            w = data[i] | (data[i + 1] << 8) | (data[i + 2] << 16) | (data[i + 3] << 24)
            f.write(f"{w:08x}\n")
        for _ in range(used_words, pad_words):
            f.write("00000000\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("asm", help="Path to .S test file")
    ap.add_argument("--out-dir", default="build/tests", help="Output directory")
    ap.add_argument("--linker", default="tests/linker.ld", help="Linker script path")
    ap.add_argument("--prefix", default="riscv64-unknown-elf", help="Toolchain prefix")
    ap.add_argument("--pad-words", type=int, default=4096, help="Pad output hex to this many 32-bit words")
    args = ap.parse_args()

    asm_path = pathlib.Path(args.asm)
    out_dir = pathlib.Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    stem = asm_path.stem
    elf = out_dir / f"{stem}.elf"
    binf = out_dir / f"{stem}.bin"
    hexf = out_dir / f"{stem}.hex"
    dis = out_dir / f"{stem}.dis"
    mapf = out_dir / f"{stem}.map"

    gcc = f"{args.prefix}-gcc"
    objcopy = f"{args.prefix}-objcopy"
    objdump = f"{args.prefix}-objdump"

    run([
        gcc,
        "-march=rv32i",
        "-mabi=ilp32",
        "-nostdlib",
        "-nostartfiles",
        "-Wl,--build-id=none",
        f"-Wl,-Map={mapf}",
        "-T",
        args.linker,
        "-o",
        str(elf),
        str(asm_path),
    ])

    run([objcopy, "-O", "binary", str(elf), str(binf)])
    dis.write_text(run([objdump, "-d", str(elf)]), encoding="utf-8")

    bin_to_word_hex(binf, hexf, args.pad_words)
    print(str(hexf))


if __name__ == "__main__":
    main()
