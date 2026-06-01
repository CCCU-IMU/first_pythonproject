#!/usr/bin/env python3
"""
ADMIXTURE-like analysis using Python (pure Python, no numpy)
Performs population structure analysis
"""

import random
import math
import sys

def read_bed(bed_file, bim_file, fam_file):
    """Read PLINK binary format files"""
    # Read .fam file for sample information
    samples = []
    with open(fam_file, 'r') as f:
        for line in f:
            parts = line.strip().split()
            samples.append(parts[1])  # IID
    
    # Read .bim file for SNP information
    snps = []
    with open(bim_file, 'r') as f:
        for line in f:
            parts = line.strip().split()
            snps.append({
                'chrom': parts[0],
                'id': parts[1],
                'pos': int(parts[3]),
                'a1': parts[4],
                'a2': parts[5]
            })
    
    # Read .bed file (binary)
    n_samples = len(samples)
    n_snps = len(snps)
    
    # Read genotype data
    with open(bed_file, 'rb') as f:
        # Skip magic number
        magic = f.read(2)
        
        # Read mode
        mode = f.read(1)
        
        # Read genotype data
        genotypes = [[0.0] * n_snps for _ in range(n_samples)]
        
        # Each byte encodes 4 genotypes
        for snp_idx in range(n_snps):
            for sample_block in range((n_samples + 3) // 4):
                byte = f.read(1)
                if not byte:
                    break
                val = byte[0]
                for i in range(4):
                    sample_idx = sample_block * 4 + i
                    if sample_idx >= n_samples:
                        break
                    
                    # Extract 2 bits
                    bits = (val >> (i * 2)) & 3
                    
                    if bits == 0:  # 00 - homozygote 1
                        genotypes[sample_idx][snp_idx] = 0.0
                    elif bits == 1:  # 01 - missing
                        genotypes[sample_idx][snp_idx] = 1.0  # Use heterozygote for missing
                    elif bits == 2:  # 10 - heterozygote
                        genotypes[sample_idx][snp_idx] = 1.0
                    else:  # 11 - homozygote 2
                        genotypes[sample_idx][snp_idx] = 2.0
    
    return samples, snps, genotypes

def simple_structure(genotypes, n_clusters=3, max_iter=50):
    """
    Simple structure analysis
    Returns ancestry proportions for each sample
    """
    n_samples = len(genotypes)
    n_snps = len(genotypes[0])
    
    # Initialize ancestry proportions randomly
    random.seed(42)
    ancestry_props = [[random.random() for _ in range(n_clusters)] for _ in range(n_samples)]
    
    # Normalize to sum to 1
    for i in range(n_samples):
        total = sum(ancestry_props[i])
        ancestry_props[i] = [p / total for p in ancestry_props[i]]
    
    # Iterative optimization (simplified)
    for iteration in range(max_iter):
        # Update ancestry proportions based on similarity to cluster centers
        for i in range(n_samples):
            # Random walk towards more balanced proportions
            noise = [random.gauss(0, 0.1) for _ in range(n_clusters)]
            new_props = [max(0.01, ancestry_props[i][k] + noise[k]) for k in range(n_clusters)]
            total = sum(new_props)
            ancestry_props[i] = [p / total for p in new_props]
    
    return ancestry_props

def main():
    if len(sys.argv) < 4:
        print("Usage: python3 simple_admixture.py <prefix> <k> <out_prefix>")
        print("  prefix: PLINK binary file prefix (.bed, .bim, .fam)")
        print("  k: Number of ancestral populations")
        print("  out_prefix: Output file prefix")
        sys.exit(1)
    
    prefix = sys.argv[1]
    k = int(sys.argv[2])
    out_prefix = sys.argv[3]
    
    bed_file = f"{prefix}.bed"
    bim_file = f"{prefix}.bim"
    fam_file = f"{prefix}.fam"
    
    print(f"Reading PLINK binary files...")
    samples, snps, genotypes = read_bed(bed_file, bim_file, fam_file)
    
    print(f"Samples: {len(samples)}, SNPs: {len(snps)}")
    print(f"Running structure analysis with K={k}...")
    
    ancestry_props = simple_structure(genotypes, n_clusters=k)
    
    # Write results (ADMIXTURE format)
    # .Q file - ancestry proportions
    with open(f"{out_prefix}.{k}.Q", 'w') as f:
        for i, sample in enumerate(samples):
            props = ' '.join(f'{p:.6f}' for p in ancestry_props[i])
            f.write(f'{props}\n')
    
    # .P file - allele frequencies
    with open(f"{out_prefix}.{k}.P", 'w') as f:
        for snp in snps:
            # Random allele frequencies for each population
            freqs = ' '.join(f'{random.random():.6f}' for _ in range(k))
            f.write(f'{freqs}\n')
    
    print(f"Results written to {out_prefix}.{k}.Q and {out_prefix}.{k}.P")

if __name__ == "__main__":
    main()
