#!/usr/bin/env python3
import argparse
import pathlib
import re
import subprocess
import sys


ROOT = pathlib.Path(__file__).resolve().parents[1]


def run(cmd, cwd=None):
    proc = subprocess.run(cmd, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    if proc.returncode != 0:
        print(proc.stdout, end="")
        raise SystemExit(proc.returncode)
    return proc.stdout


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--test", required=True)
    ap.add_argument("--timeout", type=int, default=50000)
    ap.add_argument("--dual", action="store_true")
    ap.add_argument("--min-lane1-commits", type=int, default=0)
    ap.add_argument("--build-dir", default="build")
    ap.add_argument("--rebuild", action="store_true")
    args = ap.parse_args()

    test_path = (ROOT / args.test).resolve() if not pathlib.Path(args.test).is_absolute() else pathlib.Path(args.test)
    if not test_path.exists():
        raise SystemExit(f"test not found: {test_path}")

    build_dir = (ROOT / args.build_dir).resolve()
    tests_out = build_dir / "tests"
    run_out = build_dir / "run" / test_path.stem
    tests_out.mkdir(parents=True, exist_ok=True)
    run_out.mkdir(parents=True, exist_ok=True)

    simv = build_dir / "simv_local"
    if args.rebuild or (not simv.exists()):
        rtl_files = [str(p.relative_to(ROOT)) for p in sorted((ROOT / "rtl_us").glob("*.v"))]
        run([
            "iverilog",
            "-g2012",
            "-I",
            "rtl_us",
            "-o",
            str(simv),
            *rtl_files,
            "tb/tb_top_local.v",
        ], cwd=ROOT)

    run([
        sys.executable,
        "tools/build_test.py",
        str(test_path),
        "--out-dir",
        str(tests_out),
        "--linker",
        "tests/linker.ld",
    ], cwd=ROOT)

    memhex = tests_out / f"{test_path.stem}.hex"
    rtl_trace = run_out / "rtl_trace.log"
    ref_trace = run_out / "ref_trace.log"
    vcd_path = run_out / "wave.vcd"

    memhex_plus = pathlib.Path("build") / "tests" / f"{test_path.stem}.hex"
    rtl_trace_plus = pathlib.Path("build") / "run" / test_path.stem / "rtl_trace.log"
    vcd_plus = pathlib.Path("build") / "run" / test_path.stem / "wave.vcd"

    run([
        sys.executable,
        "tools/rv32i_ref_subset37.py",
        "--memhex",
        str(memhex),
        "--trace",
        str(ref_trace),
        "--max-steps",
        str(args.timeout),
    ], cwd=ROOT)

    sim_out = run([
        "vvp",
        str(simv),
        f"+memhex={memhex_plus}",
        f"+trace={rtl_trace_plus}",
        f"+vcd={vcd_plus}",
        f"+timeout={args.timeout}",
        f"+dual={1 if args.dual else 0}",
    ], cwd=ROOT)
    print(sim_out, end="")

    sig_m = re.search(r"\[tb\] signature value=(\d+)\s+cycles=(\d+)\s+lane1_commits=(\d+)", sim_out)
    if not sig_m:
        raise SystemExit("failed to parse simulation signature line")

    signature_value = int(sig_m.group(1))
    lane1_commits = int(sig_m.group(3))

    if signature_value != 1:
        raise SystemExit(f"simulation reported fail signature value={signature_value}")

    run([
        sys.executable,
        "tools/compare_trace.py",
        "--rtl",
        str(rtl_trace),
        "--ref",
        str(ref_trace),
    ], cwd=ROOT)

    if args.min_lane1_commits > 0 and lane1_commits < args.min_lane1_commits:
        raise SystemExit(
            f"lane1 commits too low for {test_path.name}: got {lane1_commits}, require >= {args.min_lane1_commits}"
        )

    print(f"[run_test_local] PASS {test_path.name} lane1={lane1_commits}")


if __name__ == "__main__":
    main()
