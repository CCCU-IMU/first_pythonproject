#!/usr/bin/env python3
"""
计算对应区间选择分数
整合iHS、FST、Tajima's D等选择信号
"""

import sys

def read_ihs(ihs_file):
    """Read iHS results"""
    results = []
    with open(ihs_file, 'r') as f:
        next(f)  # Skip header
        for line in f:
            parts = line.strip().split('\t')
            if len(parts) >= 6:
                results.append({
                    'chrom': parts[0],
                    'pos': int(parts[1]),
                    'snp': parts[2],
                    'daf': float(parts[3]),
                    'unstd_ihs': float(parts[4]),
                    'norm_ihs': float(parts[5])
                })
    return results

def read_fst(fst_file):
    """Read FST results"""
    results = []
    with open(fst_file, 'r') as f:
        next(f)  # Skip header
        for line in f:
            parts = line.strip().split('\t')
            if len(parts) >= 3:
                results.append({
                    'chrom': parts[0],
                    'pos': int(parts[1]),
                    'fst': float(parts[2])
                })
    return results

def read_tajima(tajima_file):
    """Read Tajima's D results"""
    results = []
    with open(tajima_file, 'r') as f:
        next(f)  # Skip header
        for line in f:
            parts = line.strip().split('\t')
            if len(parts) >= 5:
                results.append({
                    'chrom': parts[0],
                    'start': int(parts[1]),
                    'end': int(parts[2]),
                    'n_snps': int(parts[3]),
                    'tajima_d': float(parts[4])
                })
    return results

def calculate_selection_score(ihs_data, fst_data, tajima_data, window_size=10000):
    """
    Calculate composite selection score for genomic windows
    """
    # Create windows
    windows = {}
    
    # Process iHS
    for ihs in ihs_data:
        window = (ihs['chrom'], (ihs['pos'] // window_size) * window_size)
        if window not in windows:
            windows[window] = {'ihs': [], 'fst': [], 'tajima_d': []}
        windows[window]['ihs'].append(abs(ihs['norm_ihs']))
    
    # Process FST
    for fst in fst_data:
        window = (fst['chrom'], (fst['pos'] // window_size) * window_size)
        if window not in windows:
            windows[window] = {'ihs': [], 'fst': [], 'tajima_d': []}
        windows[window]['fst'].append(fst['fst'])
    
    # Process Tajima's D
    for tajima in tajima_data:
        window = (tajima['chrom'], tajima['start'])
        if window not in windows:
            windows[window] = {'ihs': [], 'fst': [], 'tajima_d': []}
        windows[window]['tajima_d'].append(abs(tajima['tajima_d']))
    
    # Calculate composite scores
    results = []
    for (chrom, start), data in sorted(windows.items()):
        # Average scores
        avg_ihs = sum(data['ihs']) / len(data['ihs']) if data['ihs'] else 0
        avg_fst = sum(data['fst']) / len(data['fst']) if data['fst'] else 0
        avg_tajima = sum(data['tajima_d']) / len(data['tajima_d']) if data['tajima_d'] else 0
        
        # Count significant signals
        sig_ihs = sum(1 for x in data['ihs'] if x > 2)
        sig_fst = sum(1 for x in data['fst'] if x > 0.1)
        sig_tajima = sum(1 for x in data['tajima_d'] if x > 2)
        
        # Composite score (weighted sum)
        composite = avg_ihs * 0.4 + avg_fst * 10 + avg_tajima * 0.3
        
        results.append({
            'chrom': chrom,
            'start': start,
            'end': start + window_size,
            'n_sites': len(data['ihs']),
            'avg_ihs': avg_ihs,
            'avg_fst': avg_fst,
            'avg_tajima_d': avg_tajima,
            'sig_ihs': sig_ihs,
            'sig_fst': sig_fst,
            'sig_tajima': sig_tajima,
            'composite_score': composite
        })
    
    return results

def main():
    if len(sys.argv) < 5:
        print("Usage: python3 calculate_selection_score.py <ihs_file> <fst_file> <tajima_file> <output_file>")
        sys.exit(1)
    
    ihs_file = sys.argv[1]
    fst_file = sys.argv[2]
    tajima_file = sys.argv[3]
    output_file = sys.argv[4]
    
    print("Reading selection signals...")
    ihs_data = read_ihs(ihs_file)
    fst_data = read_fst(fst_file)
    tajima_data = read_tajima(tajima_file)
    
    print(f"iHS sites: {len(ihs_data)}")
    print(f"FST sites: {len(fst_data)}")
    print(f"Tajima's D windows: {len(tajima_data)}")
    
    print("Calculating composite selection scores...")
    results = calculate_selection_score(ihs_data, fst_data, tajima_data)
    
    print(f"Writing results to {output_file}")
    with open(output_file, 'w') as f:
        f.write('CHROM\tSTART\tEND\tN_SITES\tAVG_IHS\tAVG_FST\tAVG_TAJIMA_D\tSIG_IHS\tSIG_FST\tSIG_TAJIMA\tCOMPOSITE_SCORE\n')
        for r in results:
            f.write(f"{r['chrom']}\t{r['start']}\t{r['end']}\t{r['n_sites']}\t"
                   f"{r['avg_ihs']:.6f}\t{r['avg_fst']:.6f}\t{r['avg_tajima_d']:.6f}\t"
                   f"{r['sig_ihs']}\t{r['sig_fst']}\t{r['sig_tajima']}\t{r['composite_score']:.6f}\n")
    
    print(f"Calculated scores for {len(results)} windows")
    print("Done!")

if __name__ == "__main__":
    main()
