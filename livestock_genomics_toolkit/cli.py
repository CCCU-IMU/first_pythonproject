"""Command line interface for the maintained Python helpers."""

from __future__ import annotations

import argparse
from pathlib import Path

from . import svg
from .vcf import (
    fst_between_populations,
    load_population_map,
    nucleotide_diversity,
    parse_vcf,
    tajimas_d,
    write_fst,
    write_window_stats,
)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="livestock-genomics-toolkit",
        description="Bioinformatics analysis and visualization helpers.",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    vcf_stats = subparsers.add_parser("vcf-stats", help="Calculate lightweight VCF summary statistics")
    vcf_stats.add_argument("--vcf", required=True, help="Input VCF or VCF.GZ")
    vcf_stats.add_argument("--populations", required=True, help="Sample population TSV")
    vcf_stats.add_argument("--outdir", required=True, help="Output directory")
    vcf_stats.add_argument("--window-size", type=int, default=10000)
    vcf_stats.add_argument("--fst", nargs=2, metavar=("POP1", "POP2"), help="Optional pair for FST")
    vcf_stats.set_defaults(func=_vcf_stats)

    pca = subparsers.add_parser("plot-pca", help="Render PLINK eigenvec PCA as SVG")
    pca.add_argument("--eigenvec", required=True)
    pca.add_argument("--populations", required=True)
    pca.add_argument("--out", required=True)
    pca.set_defaults(func=_plot_pca)

    line = subparsers.add_parser("plot-line", help="Render a TSV numeric x/y table as SVG")
    line.add_argument("--table", required=True)
    line.add_argument("--x", required=True)
    line.add_argument("--y", required=True)
    line.add_argument("--out", required=True)
    line.add_argument("--title", default="Line plot")
    line.set_defaults(func=_plot_line)

    args = parser.parse_args(argv)
    args.func(args)
    return 0


def _vcf_stats(args: argparse.Namespace) -> None:
    outdir = Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    samples, variants = parse_vcf(args.vcf)
    populations = load_population_map(args.populations)

    pi_rows = nucleotide_diversity(variants, args.window_size)
    tajima_rows = tajimas_d(variants, len(samples), args.window_size)
    write_window_stats(outdir / "pi.tsv", pi_rows, "pi")
    write_window_stats(outdir / "tajimas_d.tsv", tajima_rows, "tajimas_d")

    if args.fst:
        pop1, pop2 = args.fst
        fst_rows = fst_between_populations(variants, samples, populations, pop1, pop2)
        write_fst(outdir / f"fst_{pop1}_vs_{pop2}.tsv", fst_rows)

    print(f"Parsed {len(samples)} samples and {len(variants)} variants")
    print(f"Wrote results to {outdir}")


def _plot_pca(args: argparse.Namespace) -> None:
    svg.plot_pca(args.eigenvec, args.populations, args.out)
    print(f"Wrote {args.out}")


def _plot_line(args: argparse.Namespace) -> None:
    rows = svg.read_tsv(args.table)
    svg.plot_line(rows, args.x, args.y, args.out, args.title)
    print(f"Wrote {args.out}")
