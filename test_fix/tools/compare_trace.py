#!/usr/bin/env python3
import argparse
import pathlib


def load_trace(path: pathlib.Path):
    rows = []
    with path.open("r", encoding="ascii") as f:
        for ln in f:
            ln = ln.strip()
            if (not ln) or ln.startswith("#"):
                continue
            parts = ln.split()
            if len(parts) != 11:
                raise ValueError(f"bad trace line in {path}: {ln}")
            row = (
                int(parts[0], 16),
                int(parts[1], 16),
                int(parts[2], 16),
                int(parts[3], 16),
                int(parts[4], 16),
                int(parts[5], 16),
                int(parts[6], 16),
                int(parts[7], 16),
                int(parts[8], 16),
                int(parts[9], 10),
                int(parts[10], 16),
            )
            rows.append(row)
    return rows


def row_str(row):
    return (
        f"pc={row[0]:08x} insn={row[1]:08x} rd={row[2]:02x} rdw={row[3]:08x} "
        f"maddr={row[4]:08x} rmask={row[5]:x} wmask={row[6]:x} "
        f"mr={row[7]:08x} mw={row[8]:08x} trap={row[9]} cause={row[10]:08x}"
    )


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rtl", required=True)
    ap.add_argument("--ref", required=True)
    args = ap.parse_args()

    rtl = load_trace(pathlib.Path(args.rtl))
    ref = load_trace(pathlib.Path(args.ref))

    n = min(len(rtl), len(ref))
    for i in range(n):
        if rtl[i] != ref[i]:
            print(f"[cmp] mismatch at index {i}")
            print(f"[cmp] rtl: {row_str(rtl[i])}")
            print(f"[cmp] ref: {row_str(ref[i])}")
            return 1

    if len(rtl) != len(ref):
        print(f"[cmp] length mismatch rtl={len(rtl)} ref={len(ref)}")
        return 1

    if not rtl:
        print("[cmp] empty trace")
        return 1

    print(f"[cmp] trace match: {len(rtl)} commits")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
