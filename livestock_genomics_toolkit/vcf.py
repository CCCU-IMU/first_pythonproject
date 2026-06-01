"""Small VCF utilities for teaching and lightweight validation workflows.

The implementations are intentionally conservative and dependency-free. They
support diploid, biallelic VCF records and are meant for quick checks,
examples, and reproducible teaching material rather than replacing specialist
tools such as PLINK, vcftools, bcftools, ADMIXTURE, or selscan.
"""

from __future__ import annotations

from collections import defaultdict
from dataclasses import dataclass
import gzip
import math
from pathlib import Path
from typing import Iterable, Sequence


@dataclass(frozen=True)
class Variant:
    chrom: str
    pos: int
    identifier: str
    ref: str
    alt: str
    genotypes: tuple[str, ...]


@dataclass(frozen=True)
class WindowStat:
    chrom: str
    start: int
    end: int
    n_sites: int
    value: float


@dataclass(frozen=True)
class FstRecord:
    chrom: str
    pos: int
    identifier: str
    fst: float
    pop1_alt_frequency: float
    pop2_alt_frequency: float


def _open_text(path: str | Path):
    path = Path(path)
    if path.suffix == ".gz":
        return gzip.open(path, "rt", encoding="utf-8")
    return path.open("r", encoding="utf-8")


def parse_vcf(path: str | Path) -> tuple[list[str], list[Variant]]:
    """Parse a small diploid VCF into sample names and variant records."""

    samples: list[str] = []
    variants: list[Variant] = []

    with _open_text(path) as handle:
        for raw_line in handle:
            line = raw_line.rstrip("\n")
            if not line or line.startswith("##"):
                continue
            if line.startswith("#CHROM"):
                fields = line.split("\t")
                samples = fields[9:]
                continue
            if line.startswith("#"):
                continue

            fields = line.split("\t")
            if len(fields) < 8:
                continue
            chrom, pos, identifier, ref, alt = fields[:5]
            genotypes = tuple(fields[9:]) if len(fields) > 9 else tuple()
            variants.append(
                Variant(
                    chrom=chrom,
                    pos=int(pos),
                    identifier=identifier,
                    ref=ref,
                    alt=alt,
                    genotypes=genotypes,
                )
            )

    return samples, variants


def genotype_allele_counts(genotype: str) -> tuple[int, int] | None:
    """Return reference and alternate allele counts for a diploid genotype."""

    call = genotype.split(":", 1)[0].replace("|", "/")
    if "." in call:
        return None

    alleles = call.split("/")
    if len(alleles) != 2:
        return None

    ref_count = 0
    alt_count = 0
    for allele in alleles:
        if allele == "0":
            ref_count += 1
        elif allele == "1":
            alt_count += 1
        else:
            return None
    return ref_count, alt_count


def load_population_map(path: str | Path) -> dict[str, str]:
    """Load sample-to-population mapping from TSV.

    Supported formats:
    - headered: FID/IID/Group, Sample/Population, or similar names
    - headerless: sample group
    - headerless: fid sample group
    """

    rows = [
        line.rstrip("\n").split("\t")
        for line in Path(path).read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]
    if not rows:
        raise ValueError(f"Population file is empty: {path}")

    first = [cell.strip().lower() for cell in rows[0]]
    has_header = any(name in first for name in ("sample", "iid", "population", "group", "pop"))
    data_rows = rows[1:] if has_header else rows

    if has_header:
        sample_index = _first_index(first, ("iid", "sample", "sample_id", "id"), default=0)
        group_index = _first_index(first, ("group", "population", "pop", "breed"), default=len(first) - 1)
    elif len(rows[0]) >= 3:
        sample_index = 1
        group_index = 2
    else:
        sample_index = 0
        group_index = 1

    mapping: dict[str, str] = {}
    for row in data_rows:
        if len(row) <= max(sample_index, group_index):
            continue
        sample = row[sample_index].strip()
        group = row[group_index].strip()
        if sample and group:
            mapping[sample] = group
    return mapping


def _first_index(names: Sequence[str], candidates: Iterable[str], default: int) -> int:
    for candidate in candidates:
        if candidate in names:
            return names.index(candidate)
    return default


def _windows(variants: Sequence[Variant], window_size: int) -> dict[tuple[str, int], list[Variant]]:
    grouped: dict[tuple[str, int], list[Variant]] = defaultdict(list)
    for variant in variants:
        start = ((variant.pos - 1) // window_size) * window_size + 1
        grouped[(variant.chrom, start)].append(variant)
    return grouped


def nucleotide_diversity(variants: Sequence[Variant], window_size: int = 10000) -> list[WindowStat]:
    """Calculate a simple per-window pi estimate."""

    results: list[WindowStat] = []
    for (chrom, start), window_variants in sorted(_windows(variants, window_size).items()):
        total_pi = 0.0
        observed_sites = 0
        for variant in window_variants:
            ref_count = 0
            alt_count = 0
            for genotype in variant.genotypes:
                counts = genotype_allele_counts(genotype)
                if counts is None:
                    continue
                ref_count += counts[0]
                alt_count += counts[1]
            allele_count = ref_count + alt_count
            if allele_count == 0:
                continue
            p_alt = alt_count / allele_count
            total_pi += 2 * p_alt * (1 - p_alt)
            observed_sites += 1

        if observed_sites:
            results.append(
                WindowStat(
                    chrom=chrom,
                    start=start,
                    end=start + window_size - 1,
                    n_sites=observed_sites,
                    value=total_pi / observed_sites,
                )
            )
    return results


def tajimas_d(variants: Sequence[Variant], sample_count: int, window_size: int = 10000) -> list[WindowStat]:
    """Calculate a compact teaching-oriented Tajima's D approximation."""

    chromosome_count = sample_count * 2
    if chromosome_count < 2:
        raise ValueError("At least two diploid samples are required")

    a1 = sum(1 / i for i in range(1, chromosome_count))
    a2 = sum(1 / (i * i) for i in range(1, chromosome_count))
    b1 = (chromosome_count + 1) / (3 * (chromosome_count - 1))
    b2 = 2 * (chromosome_count**2 + chromosome_count + 3) / (
        9 * chromosome_count * (chromosome_count - 1)
    )
    c1 = b1 - 1 / a1
    c2 = b2 - (chromosome_count + 2) / (a1 * chromosome_count) + a2 / (a1 * a1)
    e1 = c1 / a1
    e2 = c2 / (a1 * a1 + a2)

    results: list[WindowStat] = []
    for (chrom, start), window_variants in sorted(_windows(variants, window_size).items()):
        segregating_sites = 0
        pi_sum = 0.0
        for variant in window_variants:
            ref_count = 0
            alt_count = 0
            for genotype in variant.genotypes:
                counts = genotype_allele_counts(genotype)
                if counts is None:
                    continue
                ref_count += counts[0]
                alt_count += counts[1]
            if ref_count > 0 and alt_count > 0:
                segregating_sites += 1
                allele_count = ref_count + alt_count
                p_alt = alt_count / allele_count
                pi_sum += 2 * p_alt * (1 - p_alt)

        if segregating_sites < 2:
            continue

        theta_w = segregating_sites / a1
        variance = e1 * segregating_sites + e2 * segregating_sites * (segregating_sites - 1)
        value = (pi_sum - theta_w) / math.sqrt(variance) if variance > 0 else 0.0
        results.append(
            WindowStat(
                chrom=chrom,
                start=start,
                end=start + window_size - 1,
                n_sites=segregating_sites,
                value=value,
            )
        )
    return results


def fst_between_populations(
    variants: Sequence[Variant],
    samples: Sequence[str],
    population_map: dict[str, str],
    pop1: str,
    pop2: str,
) -> list[FstRecord]:
    """Calculate a simple per-site FST estimate between two populations."""

    sample_to_index = {sample: index for index, sample in enumerate(samples)}
    pop1_indices = [
        sample_to_index[sample]
        for sample, group in population_map.items()
        if group == pop1 and sample in sample_to_index
    ]
    pop2_indices = [
        sample_to_index[sample]
        for sample, group in population_map.items()
        if group == pop2 and sample in sample_to_index
    ]
    if not pop1_indices or not pop2_indices:
        raise ValueError(f"Missing samples for {pop1!r} or {pop2!r}")

    records: list[FstRecord] = []
    for variant in variants:
        pop1_ref, pop1_alt = _count_population_alleles(variant, pop1_indices)
        pop2_ref, pop2_alt = _count_population_alleles(variant, pop2_indices)
        pop1_total = pop1_ref + pop1_alt
        pop2_total = pop2_ref + pop2_alt
        if pop1_total == 0 or pop2_total == 0:
            continue

        p1 = pop1_alt / pop1_total
        p2 = pop2_alt / pop2_total
        pooled = (pop1_alt + pop2_alt) / (pop1_total + pop2_total)
        ht = 2 * pooled * (1 - pooled)
        hs = (2 * p1 * (1 - p1) + 2 * p2 * (1 - p2)) / 2
        fst = max(0.0, (ht - hs) / ht) if ht > 0 else 0.0
        records.append(FstRecord(variant.chrom, variant.pos, variant.identifier, fst, p1, p2))
    return records


def _count_population_alleles(variant: Variant, indices: Sequence[int]) -> tuple[int, int]:
    ref_count = 0
    alt_count = 0
    for index in indices:
        if index >= len(variant.genotypes):
            continue
        counts = genotype_allele_counts(variant.genotypes[index])
        if counts is None:
            continue
        ref_count += counts[0]
        alt_count += counts[1]
    return ref_count, alt_count


def write_window_stats(path: str | Path, rows: Sequence[WindowStat], value_name: str) -> None:
    with Path(path).open("w", encoding="utf-8", newline="\n") as handle:
        handle.write(f"chrom\tstart\tend\tn_sites\t{value_name}\n")
        for row in rows:
            handle.write(f"{row.chrom}\t{row.start}\t{row.end}\t{row.n_sites}\t{row.value:.8g}\n")


def write_fst(path: str | Path, rows: Sequence[FstRecord]) -> None:
    with Path(path).open("w", encoding="utf-8", newline="\n") as handle:
        handle.write("chrom\tpos\tid\tfst\tpop1_alt_frequency\tpop2_alt_frequency\n")
        for row in rows:
            handle.write(
                f"{row.chrom}\t{row.pos}\t{row.identifier}\t{row.fst:.8g}\t"
                f"{row.pop1_alt_frequency:.8g}\t{row.pop2_alt_frequency:.8g}\n"
            )
