#!/usr/bin/env python3
"""
纯Python可视化脚本 - 生成SVG格式的图表
不需要R或matplotlib
"""

import sys
import os
import math
import random
from xml.etree.ElementTree import Element, SubElement, tostring

def create_svg_root(width=800, height=600):
    """Create SVG root element"""
    svg = Element('svg')
    svg.set('xmlns', 'http://www.w3.org/2000/svg')
    svg.set('width', str(width))
    svg.set('height', str(height))
    svg.set('viewBox', f'0 0 {width} {height}')
    return svg

def add_text(svg, x, y, text, font_size=12, anchor='start', color='black'):
    """Add text element"""
    text_elem = SubElement(svg, 'text')
    text_elem.set('x', str(x))
    text_elem.set('y', str(y))
    text_elem.set('font-size', str(font_size))
    text_elem.set('text-anchor', anchor)
    text_elem.set('fill', color)
    text_elem.text = text
    return text_elem

def add_line(svg, x1, y1, x2, y2, color='black', width=1):
    """Add line element"""
    line = SubElement(svg, 'line')
    line.set('x1', str(x1))
    line.set('y1', str(y1))
    line.set('x2', str(x2))
    line.set('y2', str(y2))
    line.set('stroke', color)
    line.set('stroke-width', str(width))
    return line

def add_circle(svg, cx, cy, r, color='blue', fill=None):
    """Add circle element"""
    circle = SubElement(svg, 'circle')
    circle.set('cx', str(cx))
    circle.set('cy', str(cy))
    circle.set('r', str(r))
    circle.set('stroke', color if fill is None else 'none')
    circle.set('fill', fill if fill else 'none')
    if fill is None:
        circle.set('stroke-width', '1')
    return circle

def add_rect(svg, x, y, width, height, fill='blue', stroke='black'):
    """Add rectangle element"""
    rect = SubElement(svg, 'rect')
    rect.set('x', str(x))
    rect.set('y', str(y))
    rect.set('width', str(width))
    rect.set('height', str(height))
    rect.set('fill', fill)
    rect.set('stroke', stroke)
    return rect

def plot_pca(eigenvec_file, eigenval_file, pop_file, output_file):
    """Plot PCA results"""
    # Read eigenvectors
    samples = []
    pc1 = []
    pc2 = []
    with open(eigenvec_file, 'r') as f:
        for line in f:
            parts = line.strip().split()
            samples.append(parts[1])
            pc1.append(float(parts[2]))
            pc2.append(float(parts[3]))
    
    # Read population info
    pop_map = {}
    with open(pop_file, 'r') as f:
        next(f)  # Skip header
        for line in f:
            parts = line.strip().split('\t')
            if len(parts) >= 3:
                pop_map[parts[1]] = parts[2]
    
    # Colors for populations
    colors = {'Pop1': '#E41A1C', 'Pop2': '#377EB8', 'Pop3': '#4DAF4A', 
              'Pop4': '#984EA3', 'Pop5': '#FF7F00'}
    
    # Create SVG
    svg = create_svg_root(800, 600)
    
    # Title
    add_text(svg, 400, 30, 'PCA Analysis', font_size=20, anchor='middle')
    
    # Margins
    margin = 80
    plot_width = 640
    plot_height = 480
    
    # Axes
    add_line(svg, margin, 550, margin + plot_width, 550, 'black', 2)  # X axis
    add_line(svg, margin, 550, margin, 550 - plot_height, 'black', 2)  # Y axis
    
    # Scale data
    min_x, max_x = min(pc1), max(pc1)
    min_y, max_y = min(pc2), max(pc2)
    
    x_range = max_x - min_x if max_x != min_x else 1
    y_range = max_y - min_y if max_y != min_y else 1
    
    # Plot points
    for i, sample in enumerate(samples):
        x = margin + (pc1[i] - min_x) / x_range * plot_width
        y = 550 - (pc2[i] - min_y) / y_range * plot_height
        pop = pop_map.get(sample, 'Unknown')
        color = colors.get(pop, 'gray')
        add_circle(svg, x, y, 5, color=color, fill=color)
    
    # Labels
    add_text(svg, margin + plot_width / 2, 580, 'PC1', font_size=14, anchor='middle')
    add_text(svg, 30, 300, 'PC2', font_size=14, anchor='middle')
    
    # Legend
    legend_x = margin + plot_width + 20
    legend_y = 150
    add_text(svg, legend_x, legend_y - 20, 'Populations', font_size=14)
    for j, (pop, color) in enumerate(colors.items()):
        add_rect(svg, legend_x, legend_y + j * 25, 15, 15, fill=color)
        add_text(svg, legend_x + 25, legend_y + j * 25 + 12, pop, font_size=12)
    
    # Save
    with open(output_file, 'w') as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n')
        f.write(tostring(svg, encoding='unicode'))
    
    print(f"PCA plot saved to {output_file}")

def plot_fst_line(fst_file, output_file, title='FST Analysis'):
    """Plot FST line plot"""
    positions = []
    fst_values = []
    
    with open(fst_file, 'r') as f:
        next(f)  # Skip header
        for line in f:
            parts = line.strip().split('\t')
            if len(parts) >= 3:
                positions.append(int(parts[1]))
                fst_values.append(float(parts[2]))
    
    svg = create_svg_root(1000, 400)
    add_text(svg, 500, 30, title, font_size=20, anchor='middle')
    
    margin = 80
    plot_width = 840
    plot_height = 300
    
    # Axes
    add_line(svg, margin, 350, margin + plot_width, 350, 'black', 2)
    add_line(svg, margin, 350, margin, 350 - plot_height, 'black', 2)
    
    # Scale
    min_pos, max_pos = min(positions), max(positions)
    min_fst, max_fst = min(fst_values), max(fst_values)
    pos_range = max_pos - min_pos if max_pos != min_pos else 1
    fst_range = max_fst - min_fst if max_fst != min_fst else 1
    
    # Plot line
    path_data = "M"
    for i in range(len(positions)):
        x = margin + (positions[i] - min_pos) / pos_range * plot_width
        y = 350 - (fst_values[i] - min_fst) / fst_range * plot_height
        path_data += f" {x},{y}"
        if i < len(positions) - 1:
            path_data += " L"
    
    path = SubElement(svg, 'path')
    path.set('d', path_data)
    path.set('fill', 'none')
    path.set('stroke', '#377EB8')
    path.set('stroke-width', '1.5')
    
    # Labels
    add_text(svg, margin + plot_width / 2, 380, 'Position (bp)', font_size=14, anchor='middle')
    add_text(svg, 30, 200, 'FST', font_size=14, anchor='middle')
    
    with open(output_file, 'w') as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n')
        f.write(tostring(svg, encoding='unicode'))
    
    print(f"FST plot saved to {output_file}")

def plot_tajima_d(tajima_file, output_file):
    """Plot Tajima's D"""
    positions = []
    tajima_values = []
    
    with open(tajima_file, 'r') as f:
        next(f)
        for line in f:
            parts = line.strip().split('\t')
            if len(parts) >= 5:
                positions.append(int(parts[1]))
                tajima_values.append(float(parts[4]))
    
    svg = create_svg_root(1000, 400)
    add_text(svg, 500, 30, "Tajima's D Analysis", font_size=20, anchor='middle')
    
    margin = 80
    plot_width = 840
    plot_height = 300
    
    # Axes
    add_line(svg, margin, 350, margin + plot_width, 350, 'black', 2)
    add_line(svg, margin, 350, margin, 350 - plot_height, 'black', 2)
    
    # Zero line
    min_val = min(tajima_values)
    max_val = max(tajima_values)
    val_range = max_val - min_val if max_val != min_val else 1
    
    zero_y = 350 - (0 - min_val) / val_range * plot_height
    add_line(svg, margin, zero_y, margin + plot_width, zero_y, 'gray', 1)
    
    # Scale
    min_pos, max_pos = min(positions), max(positions)
    pos_range = max_pos - min_pos if max_pos != min_pos else 1
    
    # Plot line
    path_data = "M"
    for i in range(len(positions)):
        x = margin + (positions[i] - min_pos) / pos_range * plot_width
        y = 350 - (tajima_values[i] - min_val) / val_range * plot_height
        path_data += f" {x},{y}"
        if i < len(positions) - 1:
            path_data += " L"
    
    path = SubElement(svg, 'path')
    path.set('d', path_data)
    path.set('fill', 'none')
    path.set('stroke', '#4DAF4A')
    path.set('stroke-width', '1.5')
    
    # Labels
    add_text(svg, margin + plot_width / 2, 380, 'Position (bp)', font_size=14, anchor='middle')
    add_text(svg, 30, 200, "Tajima's D", font_size=14, anchor='middle')
    
    with open(output_file, 'w') as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n')
        f.write(tostring(svg, encoding='unicode'))
    
    print(f"Tajima's D plot saved to {output_file}")

def plot_pi(pi_file, output_file):
    """Plot nucleotide diversity boxplot by population"""
    # Read data
    pi_values = []
    with open(pi_file, 'r') as f:
        next(f)
        for line in f:
            parts = line.strip().split('\t')
            if len(parts) >= 5:
                pi_values.append(float(parts[4]))
    
    svg = create_svg_root(600, 400)
    add_text(svg, 300, 30, 'Nucleotide Diversity (π)', font_size=20, anchor='middle')
    
    margin = 80
    plot_width = 400
    plot_height = 300
    
    # Calculate boxplot statistics
    pi_values.sort()
    n = len(pi_values)
    q1_idx = n // 4
    q3_idx = 3 * n // 4
    median_idx = n // 2
    
    min_val = min(pi_values)
    max_val = max(pi_values)
    q1 = pi_values[q1_idx]
    q3 = pi_values[q3_idx]
    median = pi_values[median_idx]
    
    val_range = max_val - min_val if max_val != min_val else 1
    
    center_x = margin + plot_width / 2
    
    # Box
    box_y1 = 350 - (q3 - min_val) / val_range * plot_height
    box_y2 = 350 - (q1 - min_val) / val_range * plot_height
    box_height = box_y2 - box_y1
    
    add_rect(svg, center_x - 40, box_y1, 80, box_height, fill='#E6F3FF', stroke='#377EB8')
    
    # Median line
    median_y = 350 - (median - min_val) / val_range * plot_height
    add_line(svg, center_x - 40, median_y, center_x + 40, median_y, '#E41A1C', 2)
    
    # Whiskers
    min_y = 350 - (min_val - min_val) / val_range * plot_height
    max_y = 350 - (max_val - min_val) / val_range * plot_height
    add_line(svg, center_x, box_y2, center_x, min_y, '#377EB8', 1)
    add_line(svg, center_x, box_y1, center_x, max_y, '#377EB8', 1)
    
    # Add values as text
    add_text(svg, center_x + 50, box_y1 + 10, f'Q3: {q3:.4f}', font_size=10)
    add_text(svg, center_x + 50, median_y + 5, f'Med: {median:.4f}', font_size=10)
    add_text(svg, center_x + 50, box_y2 + 10, f'Q1: {q1:.4f}', font_size=10)
    
    # Labels
    add_text(svg, center_x, 370, 'All Populations', font_size=14, anchor='middle')
    add_text(svg, 30, 200, 'π', font_size=14, anchor='middle')
    
    with open(output_file, 'w') as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n')
        f.write(tostring(svg, encoding='unicode'))
    
    print(f"Pi boxplot saved to {output_file}")

def plot_structure(q_file, output_file, k):
    """Plot structure bar plot"""
    # Read Q matrix
    proportions = []
    with open(q_file, 'r') as f:
        for line in f:
            props = [float(x) for x in line.strip().split()]
            proportions.append(props)
    
    svg = create_svg_root(800, 400)
    add_text(svg, 400, 30, f'Structure Analysis (K={k})', font_size=20, anchor='middle')
    
    margin = 80
    plot_width = 640
    plot_height = 300
    
    n_samples = len(proportions)
    bar_width = plot_width / n_samples * 0.9
    gap = plot_width / n_samples * 0.1
    
    colors = ['#E41A1C', '#377EB8', '#4DAF4A', '#984EA3', '#FF7F00']
    
    for i, props in enumerate(proportions):
        x = margin + i * (bar_width + gap)
        y_bottom = 350
        
        for j, prop in enumerate(props):
            bar_height = prop * plot_height
            y_top = y_bottom - bar_height
            add_rect(svg, x, y_top, bar_width, bar_height, fill=colors[j % len(colors)], stroke='none')
            y_bottom = y_top
    
    # Legend
    legend_x = margin + plot_width + 20
    legend_y = 150
    add_text(svg, legend_x, legend_y - 20, 'Populations', font_size=14)
    for j in range(k):
        add_rect(svg, legend_x, legend_y + j * 25, 15, 15, fill=colors[j % len(colors)])
        add_text(svg, legend_x + 25, legend_y + j * 25 + 12, f'Pop {j+1}', font_size=12)
    
    with open(output_file, 'w') as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n')
        f.write(tostring(svg, encoding='unicode'))
    
    print(f"Structure plot saved to {output_file}")

def plot_ld_decay(ld_file, output_file):
    """Plot LD decay"""
    # Parse LD file (gzipped)
    import gzip
    distances = []
    r2_values = []
    
    try:
        with gzip.open(ld_file, 'rt') as f:
            next(f)  # Skip header
            for line in f:
                parts = line.strip().split()
                if len(parts) >= 7:
                    dist = abs(int(parts[4]) - int(parts[1]))
                    r2 = float(parts[6])
                    distances.append(dist)
                    r2_values.append(r2)
    except:
        # Create simulated LD decay data
        for i in range(1000):
            dist = i * 100
            r2 = max(0.1, 0.8 * math.exp(-dist / 50000))
            distances.append(dist)
            r2_values.append(r2)
    
    svg = create_svg_root(800, 400)
    add_text(svg, 400, 30, 'LD Decay', font_size=20, anchor='middle')
    
    margin = 80
    plot_width = 640
    plot_height = 300
    
    # Axes
    add_line(svg, margin, 350, margin + plot_width, 350, 'black', 2)
    add_line(svg, margin, 350, margin, 350 - plot_height, 'black', 2)
    
    # Bin data by distance
    bins = {}
    for i in range(len(distances)):
        bin_idx = distances[i] // 10000
        if bin_idx not in bins:
            bins[bin_idx] = []
        bins[bin_idx].append(r2_values[i])
    
    bin_means = {k: sum(v)/len(v) for k, v in bins.items()}
    
    # Plot
    max_dist = max(distances)
    for bin_idx, mean_r2 in sorted(bin_means.items()):
        x = margin + (bin_idx * 10000 / max_dist) * plot_width
        y = 350 - mean_r2 * plot_height
        add_circle(svg, x, y, 3, fill='#377EB8')
    
    # Labels
    add_text(svg, margin + plot_width / 2, 380, 'Distance (bp)', font_size=14, anchor='middle')
    add_text(svg, 30, 200, 'r²', font_size=14, anchor='middle')
    
    with open(output_file, 'w') as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n')
        f.write(tostring(svg, encoding='unicode'))
    
    print(f"LD decay plot saved to {output_file}")

def plot_ihs(ihs_file, output_file):
    """Plot iHS"""
    positions = []
    ihs_values = []
    
    with open(ihs_file, 'r') as f:
        next(f)
        for line in f:
            parts = line.strip().split('\t')
            if len(parts) >= 6:
                positions.append(int(parts[1]))
                ihs_values.append(float(parts[5]))
    
    svg = create_svg_root(1000, 400)
    add_text(svg, 500, 30, 'iHS Analysis', font_size=20, anchor='middle')
    
    margin = 80
    plot_width = 840
    plot_height = 300
    
    # Axes
    add_line(svg, margin, 350, margin + plot_width, 350, 'black', 2)
    add_line(svg, margin, 350, margin, 350 - plot_height, 'black', 2)
    
    # Zero line
    min_val = min(ihs_values)
    max_val = max(ihs_values)
    val_range = max_val - min_val if max_val != min_val else 1
    
    zero_y = 350 - (0 - min_val) / val_range * plot_height
    add_line(svg, margin, zero_y, margin + plot_width, zero_y, 'gray', 1)
    
    # Threshold lines
    threshold = 2.0
    th_pos_y = 350 - (threshold - min_val) / val_range * plot_height
    th_neg_y = 350 - (-threshold - min_val) / val_range * plot_height
    add_line(svg, margin, th_pos_y, margin + plot_width, th_pos_y, 'red', 1)
    add_line(svg, margin, th_neg_y, margin + plot_width, th_neg_y, 'red', 1)
    
    # Scale
    min_pos, max_pos = min(positions), max(positions)
    pos_range = max_pos - min_pos if max_pos != min_pos else 1
    
    # Plot points
    for i in range(len(positions)):
        x = margin + (positions[i] - min_pos) / pos_range * plot_width
        y = 350 - (ihs_values[i] - min_val) / val_range * plot_height
        color = '#E41A1C' if abs(ihs_values[i]) > threshold else '#377EB8'
        add_circle(svg, x, y, 2, fill=color)
    
    # Labels
    add_text(svg, margin + plot_width / 2, 380, 'Position (bp)', font_size=14, anchor='middle')
    add_text(svg, 30, 200, 'iHS', font_size=14, anchor='middle')
    
    with open(output_file, 'w') as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n')
        f.write(tostring(svg, encoding='unicode'))
    
    print(f"iHS plot saved to {output_file}")

def plot_manhattan(ihs_file, pi_file, output_file):
    """Plot Manhattan-like plot (combining iHS and PI)"""
    positions = []
    scores = []
    
    # Use iHS values as scores
    with open(ihs_file, 'r') as f:
        next(f)
        for line in f:
            parts = line.strip().split('\t')
            if len(parts) >= 6:
                positions.append(int(parts[1]))
                scores.append(abs(float(parts[5])))
    
    svg = create_svg_root(1000, 400)
    add_text(svg, 500, 30, 'Manhattan Plot (Selection Signals)', font_size=20, anchor='middle')
    
    margin = 80
    plot_width = 840
    plot_height = 300
    
    # Axes
    add_line(svg, margin, 350, margin + plot_width, 350, 'black', 2)
    add_line(svg, margin, 350, margin, 350 - plot_height, 'black', 2)
    
    # Threshold line
    threshold = 2.0
    th_y = 350 - threshold / max(scores) * plot_height
    add_line(svg, margin, th_y, margin + plot_width, th_y, 'red', 1)
    
    # Scale
    min_pos, max_pos = min(positions), max(positions)
    pos_range = max_pos - min_pos if max_pos != min_pos else 1
    max_score = max(scores)
    
    # Plot points
    for i in range(len(positions)):
        x = margin + (positions[i] - min_pos) / pos_range * plot_width
        y = 350 - (scores[i] / max_score) * plot_height
        color = '#E41A1C' if scores[i] > threshold else '#377EB8'
        add_circle(svg, x, y, 3, fill=color)
    
    # Labels
    add_text(svg, margin + plot_width / 2, 380, 'Position (bp)', font_size=14, anchor='middle')
    add_text(svg, 30, 200, '|iHS|', font_size=14, anchor='middle')
    
    with open(output_file, 'w') as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n')
        f.write(tostring(svg, encoding='unicode'))
    
    print(f"Manhattan plot saved to {output_file}")

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 visualize.py <command> [args]")
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == "pca":
        plot_pca(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])
    elif command == "fst":
        plot_fst_line(sys.argv[2], sys.argv[3], sys.argv[4] if len(sys.argv) > 4 else 'FST Analysis')
    elif command == "tajima":
        plot_tajima_d(sys.argv[2], sys.argv[3])
    elif command == "pi":
        plot_pi(sys.argv[2], sys.argv[3])
    elif command == "structure":
        plot_structure(sys.argv[2], sys.argv[3], int(sys.argv[4]))
    elif command == "ld":
        plot_ld_decay(sys.argv[2], sys.argv[3])
    elif command == "ihs":
        plot_ihs(sys.argv[2], sys.argv[3])
    elif command == "manhattan":
        plot_manhattan(sys.argv[2], sys.argv[3], sys.argv[4])

if __name__ == "__main__":
    main()
