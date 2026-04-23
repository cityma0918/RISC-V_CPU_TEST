#!/usr/bin/env python3
import argparse
import pathlib
import sys


SIGNATURE_ADDR = 0x00001000
PASS_VALUE = 1


def u32(x):
    return x & 0xFFFFFFFF


def s32(x):
    x &= 0xFFFFFFFF
    return x if x < 0x80000000 else x - 0x100000000


def sext(x, bits):
    mask = (1 << bits) - 1
    x &= mask
    sign = 1 << (bits - 1)
    return u32((x ^ sign) - sign)


def imm_i(insn):
    return sext(insn >> 20, 12)


def imm_s(insn):
    value = ((insn >> 25) << 5) | ((insn >> 7) & 0x1F)
    return sext(value, 12)


def imm_b(insn):
    value = (
        (((insn >> 31) & 0x1) << 12) |
        (((insn >> 7) & 0x1) << 11) |
        (((insn >> 25) & 0x3F) << 5) |
        (((insn >> 8) & 0xF) << 1)
    )
    return sext(value, 13)


def imm_u(insn):
    return u32(insn & 0xFFFFF000)


def imm_j(insn):
    value = (
        (((insn >> 31) & 0x1) << 20) |
        (((insn >> 12) & 0xFF) << 12) |
        (((insn >> 20) & 0x1) << 11) |
        (((insn >> 21) & 0x3FF) << 1)
    )
    return sext(value, 21)


class RefCPU:
    def __init__(self, mem_hex: pathlib.Path, mem_words: int):
        self.regs = [0] * 32
        self.pc = 0
        self.mem = bytearray(mem_words * 4)
        self.trace = []
        self.signature_value = 0
        self.load_hex(mem_hex)

    def load_hex(self, path: pathlib.Path):
        words = []
        with path.open("r", encoding="ascii") as f:
            for ln in f:
                ln = ln.strip()
                if ln:
                    words.append(int(ln, 16) & 0xFFFFFFFF)

        for i, word in enumerate(words):
            base = i * 4
            if base + 3 >= len(self.mem):
                break
            self.mem[base] = word & 0xFF
            self.mem[base + 1] = (word >> 8) & 0xFF
            self.mem[base + 2] = (word >> 16) & 0xFF
            self.mem[base + 3] = (word >> 24) & 0xFF

    def read8(self, addr):
        return self.mem[addr] if 0 <= addr < len(self.mem) else 0

    def read16(self, addr):
        return self.read8(addr) | (self.read8(addr + 1) << 8)

    def read32(self, addr):
        return (self.read8(addr) |
                (self.read8(addr + 1) << 8) |
                (self.read8(addr + 2) << 16) |
                (self.read8(addr + 3) << 24))

    def write8(self, addr, val):
        if 0 <= addr < len(self.mem):
            self.mem[addr] = val & 0xFF

    def write16(self, addr, val):
        self.write8(addr, val)
        self.write8(addr + 1, val >> 8)

    def write32(self, addr, val):
        self.write8(addr, val)
        self.write8(addr + 1, val >> 8)
        self.write8(addr + 2, val >> 16)
        self.write8(addr + 3, val >> 24)

    def step(self):
        pc = self.pc
        insn = self.read32(pc)
        opcode = insn & 0x7F
        rd = (insn >> 7) & 0x1F
        funct3 = (insn >> 12) & 0x7
        rs1 = (insn >> 15) & 0x1F
        rs2 = (insn >> 20) & 0x1F
        funct7 = (insn >> 25) & 0x7F

        r1 = self.regs[rs1]
        r2 = self.regs[rs2]

        rd_addr = 0
        rd_wdata = 0
        mem_addr = 0
        mem_rmask = 0
        mem_wmask = 0
        mem_rdata = 0
        mem_wdata = 0
        next_pc = u32(pc + 4)
        done = False

        if opcode == 0x37:
            rd_addr = rd
            rd_wdata = imm_u(insn)
        elif opcode == 0x17:
            rd_addr = rd
            rd_wdata = u32(pc + imm_u(insn))
        elif opcode == 0x6F:
            rd_addr = rd
            rd_wdata = u32(pc + 4)
            next_pc = u32(pc + imm_j(insn))
        elif opcode == 0x67:
            rd_addr = rd
            rd_wdata = u32(pc + 4)
            next_pc = u32((r1 + imm_i(insn)) & 0xFFFFFFFE)
        elif opcode == 0x63:
            take = False
            if funct3 == 0x0:
                take = (r1 == r2)
            elif funct3 == 0x1:
                take = (r1 != r2)
            elif funct3 == 0x4:
                take = (s32(r1) < s32(r2))
            elif funct3 == 0x5:
                take = (s32(r1) >= s32(r2))
            elif funct3 == 0x6:
                take = (u32(r1) < u32(r2))
            elif funct3 == 0x7:
                take = (u32(r1) >= u32(r2))
            else:
                raise RuntimeError(f"unsupported branch funct3 {funct3} at pc=0x{pc:08x}")
            if take:
                next_pc = u32(pc + imm_b(insn))
        elif opcode == 0x03:
            addr = u32(r1 + imm_i(insn))
            mem_addr = addr
            if funct3 == 0x0:
                byte = self.read8(addr)
                rd_addr = rd
                rd_wdata = sext(byte, 8)
                mem_rmask = 1 << (addr & 0x3)
                mem_rdata = rd_wdata
            elif funct3 == 0x1:
                half = self.read16(addr)
                rd_addr = rd
                rd_wdata = sext(half, 16)
                mem_rmask = 0x3 << (addr & 0x2)
                mem_rdata = rd_wdata
            elif funct3 == 0x2:
                word = self.read32(addr)
                rd_addr = rd
                rd_wdata = u32(word)
                mem_rmask = 0xF
                mem_rdata = rd_wdata
            elif funct3 == 0x4:
                byte = self.read8(addr)
                rd_addr = rd
                rd_wdata = u32(byte)
                mem_rmask = 1 << (addr & 0x3)
                mem_rdata = rd_wdata
            elif funct3 == 0x5:
                half = self.read16(addr)
                rd_addr = rd
                rd_wdata = u32(half)
                mem_rmask = 0x3 << (addr & 0x2)
                mem_rdata = rd_wdata
            else:
                raise RuntimeError(f"unsupported load funct3 {funct3} at pc=0x{pc:08x}")
        elif opcode == 0x23:
            addr = u32(r1 + imm_s(insn))
            mem_addr = addr
            mem_wdata = u32(r2)
            if funct3 == 0x0:
                self.write8(addr, r2)
                mem_wmask = 1 << (addr & 0x3)
            elif funct3 == 0x1:
                self.write16(addr, r2)
                mem_wmask = 0x3 << (addr & 0x2)
            elif funct3 == 0x2:
                self.write32(addr, r2)
                mem_wmask = 0xF
            else:
                raise RuntimeError(f"unsupported store funct3 {funct3} at pc=0x{pc:08x}")
            if addr == SIGNATURE_ADDR and mem_wmask == 0xF:
                self.signature_value = mem_wdata
                done = True
        elif opcode == 0x13:
            imm = imm_i(insn)
            rd_addr = rd
            if funct3 == 0x0:
                rd_wdata = u32(r1 + imm)
            elif funct3 == 0x2:
                rd_wdata = 1 if s32(r1) < s32(imm) else 0
            elif funct3 == 0x3:
                rd_wdata = 1 if u32(r1) < u32(imm) else 0
            elif funct3 == 0x4:
                rd_wdata = u32(r1 ^ imm)
            elif funct3 == 0x6:
                rd_wdata = u32(r1 | imm)
            elif funct3 == 0x7:
                rd_wdata = u32(r1 & imm)
            elif funct3 == 0x1:
                rd_wdata = u32(r1 << ((insn >> 20) & 0x1F))
            elif funct3 == 0x5:
                shamt = (insn >> 20) & 0x1F
                if funct7 == 0x00:
                    rd_wdata = u32(r1 >> shamt)
                elif funct7 == 0x20:
                    rd_wdata = u32(s32(r1) >> shamt)
                else:
                    raise RuntimeError(f"unsupported shift imm at pc=0x{pc:08x}")
            else:
                raise RuntimeError(f"unsupported op-imm funct3 {funct3} at pc=0x{pc:08x}")
        elif opcode == 0x33:
            rd_addr = rd
            if funct3 == 0x0:
                if funct7 == 0x00:
                    rd_wdata = u32(r1 + r2)
                elif funct7 == 0x20:
                    rd_wdata = u32(r1 - r2)
                else:
                    raise RuntimeError(f"unsupported add/sub funct7 at pc=0x{pc:08x}")
            elif funct3 == 0x1:
                rd_wdata = u32(r1 << (r2 & 0x1F))
            elif funct3 == 0x2:
                rd_wdata = 1 if s32(r1) < s32(r2) else 0
            elif funct3 == 0x3:
                rd_wdata = 1 if u32(r1) < u32(r2) else 0
            elif funct3 == 0x4:
                rd_wdata = u32(r1 ^ r2)
            elif funct3 == 0x5:
                if funct7 == 0x00:
                    rd_wdata = u32(r1 >> (r2 & 0x1F))
                elif funct7 == 0x20:
                    rd_wdata = u32(s32(r1) >> (r2 & 0x1F))
                else:
                    raise RuntimeError(f"unsupported shift funct7 at pc=0x{pc:08x}")
            elif funct3 == 0x6:
                rd_wdata = u32(r1 | r2)
            elif funct3 == 0x7:
                rd_wdata = u32(r1 & r2)
            else:
                raise RuntimeError(f"unsupported op funct3 {funct3} at pc=0x{pc:08x}")
        else:
            raise RuntimeError(f"unsupported opcode 0x{opcode:02x} at pc=0x{pc:08x}")

        if rd_addr != 0:
            self.regs[rd_addr] = u32(rd_wdata)
        self.regs[0] = 0

        self.trace.append((
            pc, insn, rd_addr, u32(rd_wdata), u32(mem_addr),
            mem_rmask & 0xF, mem_wmask & 0xF, u32(mem_rdata), u32(mem_wdata), 0, 0
        ))
        self.pc = next_pc
        return done


def write_trace(path: pathlib.Path, rows):
    with path.open("w", encoding="ascii") as f:
        f.write("# RVFI-lite trace columns\n")
        f.write("# pc insn rd rd_wdata mem_addr mem_rmask mem_wmask mem_rdata mem_wdata trap trap_cause\n")
        f.write("# hex hex hex2 hex hex hex1 hex1 hex hex dec hex\n")
        for row in rows:
            f.write(
                f"{row[0]:08x} {row[1]:08x} {row[2]:02x} {row[3]:08x} {row[4]:08x} "
                f"{row[5]:x} {row[6]:x} {row[7]:08x} {row[8]:08x} {row[9]:d} {row[10]:08x}\n"
            )


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--memhex", required=True)
    ap.add_argument("--trace", required=True)
    ap.add_argument("--max-steps", type=int, default=50000)
    ap.add_argument("--mem-words", type=int, default=16384)
    args = ap.parse_args()

    cpu = RefCPU(pathlib.Path(args.memhex), args.mem_words)

    done = False
    for _ in range(args.max_steps):
        done = cpu.step()
        if done:
            break

    write_trace(pathlib.Path(args.trace), cpu.trace)

    if not done:
        print("[ref] TIMEOUT", file=sys.stderr)
        return 2

    print(f"[ref] signature value={cpu.signature_value} steps={len(cpu.trace)}")
    return 0 if cpu.signature_value == PASS_VALUE else 1


if __name__ == "__main__":
    raise SystemExit(main())
