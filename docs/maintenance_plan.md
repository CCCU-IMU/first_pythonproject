# Maintenance Plan

## Current Goal

Turn a collection of useful local bioinformatics scripts into a reusable, public, beginner-friendly script library for population genetics analysis and visualization.

## Phase 1: Repository Hygiene

- Add README, license, contribution rules, dependency notes, and CI.
- Keep private raw data, large intermediate result folders, and local-only files out of git.
- Preserve validated legacy scripts, but label them as templates until parameterized.

## Phase 2: Reproducible Examples

- Add small synthetic VCF and population metadata.
- Provide runnable examples for VCF summary statistics, PCA SVG plotting, FST plotting, and enrichment-style figures.
- Add expected output checks for maintained Python functions.

## Phase 3: Script Parameterization

- Convert hard-coded file paths in R/Python scripts into command line parameters.
- Standardize output directory handling.
- Add clear error messages for missing input columns, missing packages, and empty result tables.

## Phase 4: Research Group Usability

- Maintain bilingual documentation where useful.
- Add "which script should I use?" decision tables for common analysis questions.
- Add examples for cattle/sheep genomics without exposing private datasets.

## Phase 5: Open Source Readiness

- Use GitHub issues to track script conversion tasks.
- Tag releases after documented examples run on clean machines.
- Add citation and acknowledgement guidance if the library becomes used in papers or student training.
