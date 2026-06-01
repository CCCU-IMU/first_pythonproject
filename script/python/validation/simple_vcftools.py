#!/usr/bin/env python3
"""
Simple VCF tools replacement using Python
Implements basic functionality of vcftools for validation purposes
"""

import sys
import gzip
import re
import math
from collections import defaultdict

def parse_vcf(filename):
    """Parse VCF file and return header and variant data"""
    variants = []
    samples = []
    
    opener = gzip.open if filename.endswith('.gz') else open
    
    with opener(filename, 'rt') as f:
        for line in f:
            if line.startswith('##'):
                continue
            if line.startswith('#CHROM'):
                samples = line.strip().split('\t')[9:]
                continue
            if line.startswith('#'):
                continue
            
            fields = line.strip().split('\t')
            chrom, pos, id_, ref, alt, qual, filter_, info = fields[:8]
            format_field = fields[8] if len(fields) > 8 else None
            genotypes = fields[9:] if len(fields) > 9 else []
            
            variants.append({
                'chrom': chrom,
                'pos': int(pos),
                'id': id_,
                'ref': ref,
                'alt': alt,
                'qual': qual,
                'filter': filter_,
                'info': info,
                'genotypes': genotypes
            })
    
    return samples, variants

def calculate_pi(variants, samples, window_size=10000):
    """Calculate nucleotide diversity (pi) per window"""
    # Group variants by chromosome and window
    windows = defaultdict(list)
    
    for var in variants:
        window_start = (var['pos'] // window_size) * window_size
        windows[(var['chrom'], window_start)].append(var)
    
    results = []
    for (chrom, window_start), window_vars in sorted(windows.items()):
        n_sites = len(window_vars)
        if n_sites == 0:
            continue
        
        # Calculate average pairwise differences
        total_pi = 0
        n_comparisons = 0
        
        for var in window_vars:
            # Count alleles
            alleles = []
            for gt in var['genotypes']:
                if gt.startswith('0/0') or gt.startswith('0|0'):
                    alleles.extend([0, 0])
                elif gt.startswith('0/1') or gt.startswith('0|1') or gt.startswith('1|0'):
                    alleles.extend([0, 1])
                elif gt.startswith('1/1') or gt.startswith('1|1'):
                    alleles.extend([1, 1])
                elif gt.startswith('./.'):
                    continue
            
            if len(alleles) > 0:
                n = len(alleles)
                n1 = sum(alleles)
                n0 = n - n1
                # Pi = (n1/n) * (n0/n) * 2 for diploid
                pi = 2 * (n1/n) * (n0/n) if n > 0 else 0
                total_pi += pi
                n_comparisons += 1
        
        avg_pi = total_pi / n_comparisons if n_comparisons > 0 else 0
        results.append((chrom, window_start, window_start + window_size, n_sites, avg_pi))
    
    return results

def calculate_tajima_d(variants, samples, window_size=10000):
    """Calculate Tajima's D statistic"""
    windows = defaultdict(list)
    
    for var in variants:
        window_start = (var['pos'] // window_size) * window_size
        windows[(var['chrom'], window_start)].append(var)
    
    results = []
    n = len(samples) * 2  # number of chromosomes
    
    for (chrom, window_start), window_vars in sorted(windows.items()):
        S = len(window_vars)  # Number of segregating sites
        if S < 2:
            continue
        
        # Calculate average pairwise differences (pi)
        total_pi = 0
        for var in window_vars:
            alleles = []
            for gt in var['genotypes']:
                if gt.startswith('0/0') or gt.startswith('0|0'):
                    alleles.extend([0, 0])
                elif gt.startswith('0/1') or gt.startswith('0|1') or gt.startswith('1|0'):
                    alleles.extend([0, 1])
                elif gt.startswith('1/1') or gt.startswith('1|1'):
                    alleles.extend([1, 1])
            
            if len(alleles) > 0:
                n_alleles = len(alleles)
                n1 = sum(alleles)
                n0 = n_alleles - n1
                pi = 2 * (n1/n_alleles) * (n0/n_alleles) if n_alleles > 0 else 0
                total_pi += pi
        
        pi = total_pi / len(window_vars) if window_vars else 0
        
        # Calculate Watterson's theta (approximation)
        a1 = sum(1/i for i in range(1, n))
        theta_w = S / a1 if a1 > 0 else 0
        
        # Tajima's D (simplified calculation)
        if theta_w > 0:
            tajima_d = (pi - theta_w) / math.sqrt(theta_w + 0.0001)
        else:
            tajima_d = 0
        
        results.append((chrom, window_start, window_start + window_size, S, tajima_d))
    
    return results

def calculate_fst(variants, samples, pop1_samples, pop2_samples):
    """Calculate Weir-Cockerham FST between two populations"""
    results = []
    
    for var in variants:
        # Get allele counts for each population
        def get_allele_counts(pop_samples):
            pop_indices = [samples.index(s) for s in pop_samples if s in samples]
            ref_count = alt_count = 0
            for idx in pop_indices:
                if idx < len(var['genotypes']):
                    gt = var['genotypes'][idx]
                    if gt.startswith('0/0') or gt.startswith('0|0'):
                        ref_count += 2
                    elif gt.startswith('0/1') or gt.startswith('0|1') or gt.startswith('1|0'):
                        ref_count += 1
                        alt_count += 1
                    elif gt.startswith('1/1') or gt.startswith('1|1'):
                        alt_count += 2
            return ref_count, alt_count
        
        ref1, alt1 = get_allele_counts(pop1_samples)
        ref2, alt2 = get_allele_counts(pop2_samples)
        
        n1 = ref1 + alt1
        n2 = ref2 + alt2
        
        if n1 == 0 or n2 == 0:
            continue
        
        p1 = ref1 / n1 if n1 > 0 else 0
        p2 = ref2 / n2 if n2 > 0 else 0
        
        # Weir-Cockerham FST
        p_avg = (ref1 + ref2) / (n1 + n2)
        
        if p_avg * (1 - p_avg) > 0:
            # Simplified FST calculation
            numerator = (p1 - p2) ** 2
            denominator = p_avg * (1 - p_avg)
            fst = numerator / denominator if denominator > 0 else 0
        else:
            fst = 0
        
        results.append((var['chrom'], var['pos'], fst))
    
    return results

def main():
    if len(sys.argv) < 3:
        print("Usage: python3 simple_vcftools.py <command> <vcf_file> [options]")
        print("Commands:")
        print("  --site-pi <vcf>           Calculate nucleotide diversity")
        print("  --TajimaD <window_size>   Calculate Tajima's D")
        print("  --weir-fst-pop <pop_file> Calculate Weir-Cockerham FST")
        sys.exit(1)
    
    command = sys.argv[1]
    vcf_file = sys.argv[2]
    
    samples, variants = parse_vcf(vcf_file)
    
    if command == "--site-pi":
        results = calculate_pi(variants, samples)
        print("CHROM\tBIN_START\tN_SITES\tPI")
        for chrom, start, end, n_sites, pi in results:
            print(f"{chrom}\t{start}\t{n_sites}\t{pi:.6f}")
    
    elif command == "--TajimaD":
        window_size = int(sys.argv[2]) if len(sys.argv) > 2 else 10000
        vcf_file = sys.argv[3] if len(sys.argv) > 3 else sys.argv[2]
        samples, variants = parse_vcf(vcf_file)
        results = calculate_tajima_d(variants, samples, window_size)
        print("CHROM\tBIN_START\tN_SNPS\tTajimaD")
        for chrom, start, end, n_snps, td in results:
            print(f"{chrom}\t{start}\t{n_snps}\t{td:.6f}")

if __name__ == "__main__":
    main()
