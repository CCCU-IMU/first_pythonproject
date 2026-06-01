#!/usr/bin/env python3
"""
ROH和FROH可视化
"""

import sys
from xml.etree.ElementTree import Element, SubElement, tostring

def create_svg_root(width=1000, height=600):
    svg = Element('svg')
    svg.set('xmlns', 'http://www.w3.org/2000/svg')
    svg.set('width', str(width))
    svg.set('height', str(height))
    svg.set('viewBox', f'0 0 {width} {height}')
    return svg

def add_text(svg, x, y, text, font_size=12, anchor='start', color='black'):
    text_elem = SubElement(svg, 'text')
    text_elem.set('x', str(x))
    text_elem.set('y', str(y))
    text_elem.set('font-size', str(font_size))
    text_elem.set('text-anchor', anchor)
    text_elem.set('fill', color)
    text_elem.text = text
    return text_elem

def add_line(svg, x1, y1, x2, y2, color='black', width=1):
    line = SubElement(svg, 'line')
    line.set('x1', str(x1))
    line.set('y1', str(y1))
    line.set('x2', str(x2))
    line.set('y2', str(y2))
    line.set('stroke', color)
    line.set('stroke-width', str(width))
    return line

def add_rect(svg, x, y, width, height, fill='blue', stroke='black'):
    rect = SubElement(svg, 'rect')
    rect.set('x', str(x))
    rect.set('y', str(y))
    rect.set('width', str(width))
    rect.set('height', str(height))
    rect.set('fill', fill)
    rect.set('stroke', stroke)
    return rect

def read_roh_summary(hom_indiv_file):
    """Read ROH summary per individual"""
    individuals = []
    with open(hom_indiv_file, 'r') as f:
        next(f)  # Skip header
        for line in f:
            parts = line.strip().split()
            if len(parts) >= 6:
                individuals.append({
                    'fid': parts[0],
                    'iid': parts[1],
                    'nseg': int(parts[2]),  # Number of ROH segments
                    'length': float(parts[3]),  # Total length
                    'kb': float(parts[4]),  # Total length in KB
                    'nsnp': int(parts[5])  # Number of SNPs
                })
    return individuals

def plot_roh_distribution(individuals, output_file):
    """Plot ROH distribution across individuals"""
    svg = create_svg_root(1000, 600)
    add_text(svg, 500, 30, 'ROH Distribution Across Individuals', font_size=20, anchor='middle')
    
    margin_x = 100
    margin_y = 80
    plot_width = 800
    plot_height = 450
    
    # Calculate FROH (fraction of genome in ROH)
    genome_size = 1000000  # Approximate for this simulation
    froh_values = [ind['kb'] * 1000 / genome_size for ind in individuals]
    
    # Sort by FROH
    sorted_indices = sorted(range(len(froh_values)), key=lambda i: froh_values[i])
    
    # Plot bars
    bar_width = plot_width / len(individuals) * 0.8
    gap = plot_width / len(individuals) * 0.2
    
    max_froh = max(froh_values) if froh_values else 1
    max_froh = max_froh if max_froh > 0 else 1
    
    colors = ['#377EB8' if froh < 0.1 else '#E41A1C' for froh in froh_values]
    
    for i, idx in enumerate(sorted_indices):
        x = margin_x + i * (bar_width + gap)
        bar_height = (froh_values[idx] / max_froh) * plot_height if max_froh > 0 else 0
        y = margin_y + plot_height - bar_height
        add_rect(svg, x, y, bar_width, bar_height, fill=colors[idx], stroke='none')
    
    # Axes
    add_line(svg, margin_x, margin_y + plot_height, margin_x + plot_width, margin_y + plot_height, 'black', 2)
    add_line(svg, margin_x, margin_y, margin_x, margin_y + plot_height, 'black', 2)
    
    # Labels
    add_text(svg, margin_x + plot_width / 2, margin_y + plot_height + 50, 'Individuals (sorted by FROH)', font_size=14, anchor='middle')
    add_text(svg, 30, margin_y + plot_height / 2, 'FROH', font_size=14, anchor='middle')
    
    # Legend
    legend_x = margin_x + plot_width + 20
    add_rect(svg, legend_x, 150, 15, 15, fill='#377EB8')
    add_text(svg, legend_x + 25, 162, 'FROH < 0.1', font_size=12)
    add_rect(svg, legend_x, 175, 15, 15, fill='#E41A1C')
    add_text(svg, legend_x + 25, 187, 'FROH ≥ 0.1', font_size=12)
    
    with open(output_file, 'w') as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n')
        f.write(tostring(svg, encoding='unicode'))
    
    print(f"ROH distribution plot saved to {output_file}")

def plot_roh_summary_stats(individuals, output_file):
    """Plot ROH summary statistics"""
    svg = create_svg_root(800, 400)
    add_text(svg, 400, 30, 'ROH Summary Statistics', font_size=20, anchor='middle')
    
    margin = 80
    plot_width = 600
    plot_height = 300
    
    # Calculate statistics
    n_roh = [ind['nseg'] for ind in individuals]
    total_length = [ind['kb'] for ind in individuals]
    
    stats = [
        ('Mean ROH Segments', sum(n_roh) / len(n_roh)),
        ('Mean Total Length (Kb)', sum(total_length) / len(total_length)),
        ('Max ROH Segments', max(n_roh)),
        ('Max Total Length (Kb)', max(total_length))
    ]
    
    # Plot bars
    bar_height = plot_height / len(stats) * 0.7
    gap = plot_height / len(stats) * 0.3
    max_val = max(s[1] for s in stats)
    max_val = max_val if max_val > 0 else 1
    
    colors = ['#E41A1C', '#377EB8', '#4DAF4A', '#984EA3']
    
    for i, (label, value) in enumerate(stats):
        y = margin + i * (bar_height + gap)
        bar_width = (value / max_val) * plot_width
        add_rect(svg, margin, y, bar_width, bar_height, fill=colors[i], stroke='black')
        add_text(svg, margin - 10, y + bar_height / 2 + 5, label, font_size=12, anchor='end')
        add_text(svg, margin + bar_width + 10, y + bar_height / 2 + 5, f'{value:.2f}', font_size=12)
    
    with open(output_file, 'w') as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n')
        f.write(tostring(svg, encoding='unicode'))
    
    print(f"ROH summary plot saved to {output_file}")

def main():
    if len(sys.argv) < 3:
        print("Usage: python3 plot_roh.py <hom_indiv_file> <output_prefix>")
        sys.exit(1)
    
    hom_indiv_file = sys.argv[1]
    output_prefix = sys.argv[2]
    
    individuals = read_roh_summary(hom_indiv_file)
    print(f"Loaded {len(individuals)} individuals")
    
    plot_roh_distribution(individuals, f"{output_prefix}_distribution.svg")
    plot_roh_summary_stats(individuals, f"{output_prefix}_summary.svg")

if __name__ == "__main__":
    main()
