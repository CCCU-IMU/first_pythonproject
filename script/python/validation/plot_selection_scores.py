#!/usr/bin/env python3
"""
绘制选择分数图
"""

import sys
from xml.etree.ElementTree import Element, SubElement, tostring

def create_svg_root(width=1000, height=400):
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

def add_circle(svg, cx, cy, r, fill='blue'):
    circle = SubElement(svg, 'circle')
    circle.set('cx', str(cx))
    circle.set('cy', str(cy))
    circle.set('r', str(r))
    circle.set('fill', fill)
    return circle

def plot_selection_scores(score_file, output_file):
    """Plot composite selection scores"""
    positions = []
    scores = []
    
    with open(score_file, 'r') as f:
        next(f)
        for line in f:
            parts = line.strip().split('\t')
            if len(parts) >= 11:
                positions.append(int(parts[1]))
                scores.append(float(parts[10]))  # COMPOSITE_SCORE
    
    svg = create_svg_root(1000, 400)
    add_text(svg, 500, 30, 'Composite Selection Score', font_size=20, anchor='middle')
    
    margin = 80
    plot_width = 840
    plot_height = 300
    
    # Axes
    add_line(svg, margin, 350, margin + plot_width, 350, 'black', 2)
    add_line(svg, margin, 350, margin, 350 - plot_height, 'black', 2)
    
    # Scale
    min_pos, max_pos = min(positions), max(positions)
    pos_range = max_pos - min_pos if max_pos != min_pos else 1
    max_score = max(scores)
    
    # Threshold line (top 5%)
    sorted_scores = sorted(scores, reverse=True)
    threshold_idx = len(scores) // 20
    threshold = sorted_scores[threshold_idx] if threshold_idx < len(scores) else max_score * 0.8
    
    th_y = 350 - threshold / max_score * plot_height
    add_line(svg, margin, th_y, margin + plot_width, th_y, 'red', 1)
    
    # Plot points
    for i in range(len(positions)):
        x = margin + (positions[i] - min_pos) / pos_range * plot_width
        y = 350 - (scores[i] / max_score) * plot_height
        color = '#E41A1C' if scores[i] > threshold else '#377EB8'
        add_circle(svg, x, y, 4, fill=color)
    
    # Labels
    add_text(svg, margin + plot_width / 2, 380, 'Position (bp)', font_size=14, anchor='middle')
    add_text(svg, 30, 200, 'Selection Score', font_size=14, anchor='middle')
    
    # Legend
    legend_x = margin + plot_width + 20
    add_circle(svg, legend_x, 150, 4, fill='#E41A1C')
    add_text(svg, legend_x + 15, 154, 'Significant', font_size=12)
    add_circle(svg, legend_x, 175, 4, fill='#377EB8')
    add_text(svg, legend_x + 15, 179, 'Non-significant', font_size=12)
    
    with open(output_file, 'w') as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n')
        f.write(tostring(svg, encoding='unicode'))
    
    print(f"Selection score plot saved to {output_file}")

def main():
    if len(sys.argv) < 3:
        print("Usage: python3 plot_selection_scores.py <score_file> <output_file>")
        sys.exit(1)
    
    score_file = sys.argv[1]
    output_file = sys.argv[2]
    
    plot_selection_scores(score_file, output_file)

if __name__ == "__main__":
    main()
