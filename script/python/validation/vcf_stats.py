#!/usr/bin/env python3
"""
VCF统计工具 - 计算FST、Tajima's D、核苷酸多样性
"""

import sys
import gzip
from collections import defaultdict
import math

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

def get_genotype_counts(genotype_str):
    """Convert genotype string to allele counts"""
    if genotype_str.startswith('0/0') or genotype_str.startswith('0|0'):
        return (2, 0)  # 2 ref, 0 alt
    elif genotype_str.startswith('0/1') or genotype_str.startswith('0|1') or genotype_str.startswith('1|0'):
        return (1, 1)  # 1 ref, 1 alt
    elif genotype_str.startswith('1/1') or genotype_str.startswith('1|1'):
        return (0, 2)  # 0 ref, 2 alt
    else:
        return (0, 0)  # Missing

def calculate_pi(variants, samples, window_size=10000):
    """Calculate nucleotide diversity (pi) per window"""
    windows = defaultdict(list)
    
    for var in variants:
        window_start = (var['pos'] // window_size) * window_size
        windows[(var['chrom'], window_start)].append(var)
    
    results = []
    for (chrom, window_start), window_vars in sorted(windows.items()):
        n_sites = len(window_vars)
        if n_sites == 0:
            continue
        
        total_pi = 0
        for var in window_vars:
            ref_count = 0
            alt_count = 0
            valid_samples = 0
            
            for gt in var['genotypes']:
                r, a = get_genotype_counts(gt)
                if r + a > 0:
                    ref_count += r
                    alt_count += a
                    valid_samples += 1
            
            if valid_samples > 0:
                n = ref_count + alt_count
                p = ref_count / n
                q = alt_count / n
                pi = 2 * p * q
                total_pi += pi
        
        avg_pi = total_pi / n_sites if n_sites > 0 else 0
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
    
    # Calculate a1 (harmonic number)
    a1 = sum(1/i for i in range(1, n))
    a2 = sum(1/(i*i) for i in range(1, n))
    
    for (chrom, window_start), window_vars in sorted(windows.items()):
        S = len(window_vars)  # Number of segregating sites
        if S < 2:
            continue
        
        # Calculate average pairwise differences (pi)
        total_pi = 0
        for var in window_vars:
            ref_count = 0
            alt_count = 0
            
            for gt in var['genotypes']:
                r, a = get_genotype_counts(gt)
                ref_count += r
                alt_count += a
            
            n_alleles = ref_count + alt_count
            if n_alleles > 0:
                p = ref_count / n_alleles
                q = alt_count / n_alleles
                pi = 2 * p * q
                total_pi += pi
        
        avg_pi = total_pi / S if S > 0 else 0
        
        # Watterson's theta
        theta_w = S / a1 if a1 > 0 else 0
        
        # Variance of Tajima's D
        b1 = (n + 1) / (3 * (n - 1))
        b2 = 2 * (n*n + n + 3) / (9 * n * (n - 1))
        c1 = b1 - 1/a1
        c2 = b2 - (n + 2)/(a1 * n) + a2/(a1 * a1)
        e1 = c1 / a1
        e2 = c2 / (a1 * a1 + a2)
        
        # Tajima's D
        if e1 * S + e2 * S * (S - 1) > 0:
            denominator = math.sqrt(e1 * S + e2 * S * (S - 1))
            tajima_d = (avg_pi - theta_w) / denominator if denominator > 0 else 0
        else:
            tajima_d = 0
        
        results.append((chrom, window_start, window_start + window_size, S, tajima_d))
    
    return results

def load_population_map(pop_file):
    """Load population map from file"""
    pop_map = {}
    with open(pop_file, 'r') as f:
        next(f)  # Skip header
        for line in f:
            parts = line.strip().split('\t')
            if len(parts) >= 3:
                fid, iid, group = parts[:3]
                pop_map[iid] = group
    return pop_map

def calculate_fst(variants, samples, pop1_samples, pop2_samples):
    """Calculate Weir-Cockerham FST between two populations"""
    results = []
    
    # Get indices for each population
    pop1_indices = [samples.index(s) for s in pop1_samples if s in samples]
    pop2_indices = [samples.index(s) for s in pop2_samples if s in samples]
    
    for var in variants:
        # Count alleles for each population
        def get_allele_counts(indices):
            ref_count = 0
            alt_count = 0
            for idx in indices:
                if idx < len(var['genotypes']):
                    gt = var['genotypes'][idx]
                    r, a = get_genotype_counts(gt)
                    ref_count += r
                    alt_count += a
            return ref_count, alt_count
        
        ref1, alt1 = get_allele_counts(pop1_indices)
        ref2, alt2 = get_allele_counts(pop2_indices)
        
        n1 = ref1 + alt1
        n2 = ref2 + alt2
        
        if n1 == 0 or n2 == 0:
            continue
        
        p1 = ref1 / n1
        p2 = ref2 / n2
        
        # Average allele frequency
        p_avg = (ref1 + ref2) / (n1 + n2)
        
        # Weir-Cockerham FST (simplified)
        if p_avg * (1 - p_avg) > 0:
            # Hs (within-pop heterozygosity)
            hs = (p1 * (1 - p1) + p2 * (1 - p2)) / 2
            # Ht (total heterozygosity)
            ht = p_avg * (1 - p_avg)
            fst = (ht - hs) / ht if ht > 0 else 0
        else:
            fst = 0
        
        results.append((var['chrom'], var['pos'], fst))
    
    return results

def calculate_ihs(variants, samples):
    """Simplified iHS calculation"""
    # This is a simplified approximation of iHS
    results = []
    
    for i, var in enumerate(variants):
        # Calculate EHH for derived allele
        # Simplified: use distance to next variant with similar allele frequency
        
        # Get derived allele frequency
        alt_count = 0
        total_count = 0
        for gt in var['genotypes']:
            r, a = get_genotype_counts(gt)
            alt_count += a
            total_count += r + a
        
        if total_count > 0:
            daf = alt_count / total_count
        else:
            daf = 0
        
        # Calculate unstandardized iHS (simplified)
        # This is a placeholder - real iHS requires phased data and EHH calculation
        unstd_ihs = math.log((1 + abs(0.5 - daf)) / (0.01 + abs(0.5 - daf)))
        
        results.append((var['chrom'], var['pos'], var['id'], daf, unstd_ihs, unstd_ihs))
    
    return results

def main():
    if len(sys.argv) < 3:
        print("Usage: python3 vcf_stats.py <command> [options]")
        print("Commands:")
        print("  --site-pi <vcf> <out_prefix> [window_size]")
        print("  --TajimaD <vcf> <out_prefix> [window_size]")
        print("  --fst <vcf> <pop_file> <pop1> <pop2> <out_prefix>")
        print("  --ihs <vcf> <out_prefix>")
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == "--site-pi":
        vcf_file = sys.argv[2]
        out_prefix = sys.argv[3]
        window_size = int(sys.argv[4]) if len(sys.argv) > 4 else 10000
        
        samples, variants = parse_vcf(vcf_file)
        results = calculate_pi(variants, samples, window_size)
        
        with open(f"{out_prefix}.sites.pi", 'w') as f:
            f.write("CHROM\tBIN_START\tBIN_END\tN_SITES\tPI\n")
            for chrom, start, end, n_sites, pi in results:
                f.write(f"{chrom}\t{start}\t{end}\t{n_sites}\t{pi:.6f}\n")
        print(f"Nucleotide diversity written to {out_prefix}.sites.pi")
    
    elif command == "--TajimaD":
        vcf_file = sys.argv[2]
        out_prefix = sys.argv[3]
        window_size = int(sys.argv[4]) if len(sys.argv) > 4 else 10000
        
        samples, variants = parse_vcf(vcf_file)
        results = calculate_tajima_d(variants, samples, window_size)
        
        with open(f"{out_prefix}.Tajima.D", 'w') as f:
            f.write("CHROM\tBIN_START\tBIN_END\tN_SNPS\tTajimaD\n")
            for chrom, start, end, n_snps, td in results:
                f.write(f"{chrom}\t{start}\t{end}\t{n_snps}\t{td:.6f}\n")
        print(f"Tajima's D written to {out_prefix}.Tajima.D")
    
    elif command == "--fst":
        vcf_file = sys.argv[2]
        pop_file = sys.argv[3]
        pop1_name = sys.argv[4]
        pop2_name = sys.argv[5]
        out_prefix = sys.argv[6]
        
        pop_map = load_population_map(pop_file)
        samples, variants = parse_vcf(vcf_file)
        
        pop1_samples = [s for s, p in pop_map.items() if p == pop1_name]
        pop2_samples = [s for s, p in pop_map.items() if p == pop2_name]
        
        results = calculate_fst(variants, samples, pop1_samples, pop2_samples)
        
        with open(f"{out_prefix}.fst", 'w') as f:
            f.write("CHROM\tPOS\tFST\n")
            for chrom, pos, fst in results:
                f.write(f"{chrom}\t{pos}\t{fst:.6f}\n")
        print(f"FST written to {out_prefix}.fst")
    
    elif command == "--ihs":
        vcf_file = sys.argv[2]
        out_prefix = sys.argv[3]
        
        samples, variants = parse_vcf(vcf_file)
        results = calculate_ihs(variants, samples)
        
        with open(f"{out_prefix}.ihs", 'w') as f:
            f.write("CHR\tPOSITION\tSNP\tDAF\tUnstd_iHS\tnorm_iHS\n")
            for chrom, pos, snp, daf, unstd, norm in results:
                f.write(f"{chrom}\t{pos}\t{snp}\t{daf:.4f}\t{unstd:.4f}\t{norm:.4f}\n")
        print(f"iHS written to {out_prefix}.ihs")

if __name__ == "__main__":
    main()
