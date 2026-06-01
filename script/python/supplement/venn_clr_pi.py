#!/usr/bin/env python3
"""
韦恩图（CLR&PI）分析 - Two-ellipse Venn
CLR vs θπ 双集合韦恩图
"""

import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.patches import Ellipse
import matplotlib.patches as mpatches

out_dir = "/mnt/e/桌面/脚本/autovalidation_supplement/venn_clr_pi"

log_file = os.path.join(out_dir, "venn_clr_pi.log")
log = []

def log_msg(msg):
    print(msg)
    log.append(msg)

log_msg(f"分析开始时间: {pd.Timestamp.now()}")

# 模拟计数数据
np.random.seed(42)
n_clr_only = 583
n_overlap = 57
n_pi_only = 90

counts = pd.DataFrame({
    'Category': ['CLR only', 'Overlap', 'PI only'],
    'Count': [n_clr_only, n_overlap, n_pi_only]
})
counts.to_csv(os.path.join(out_dir, 'venn_counts.tsv'), sep='\t', index=False)

log_msg("韦恩图计数:")
log_msg(f"  CLR only: {n_clr_only}")
log_msg(f"  Overlap: {n_overlap}")
log_msg(f"  PI only: {n_pi_only}")

# 颜色设置
col_pi = "#7FB7D6"   # theta pi - light blue
col_clr = "#bb9cc5"  # CLR - light purple

# 创建图形
fig, ax = plt.subplots(figsize=(12, 6))

# 绘制两个椭圆
ellipse1 = Ellipse(xy=(0, 0), width=9.4, height=6.6, angle=0, 
                   facecolor=col_clr, alpha=0.85, edgecolor='none')
ellipse2 = Ellipse(xy=(3.6, 0), width=9.4, height=6.6, angle=0, 
                   facecolor=col_pi, alpha=0.85, edgecolor='none')

ax.add_patch(ellipse1)
ax.add_patch(ellipse2)

# 添加标签
ax.text(-4.8, 3.2, 'CLR', fontsize=20, ha='center', va='center', fontweight='bold')
ax.text(8.0, 3.2, r'$\theta \pi$', fontsize=20, ha='center', va='center', fontweight='bold')

# 添加计数
ax.text(-2.6, 0, str(n_clr_only), fontsize=16, ha='center', va='center', 
        fontweight='bold', color='white')
ax.text(1.8, 0, str(n_overlap), fontsize=16, ha='center', va='center', 
        fontweight='bold', color='black')
ax.text(6.2, 0, str(n_pi_only), fontsize=16, ha='center', va='center', 
        fontweight='bold', color='white')

# 设置坐标轴
ax.set_xlim(-5.5, 8.5)
ax.set_ylim(-3.8, 3.8)
ax.set_aspect('equal')
ax.axis('off')

# 添加标题
ax.set_title('Candidate Regions: CLR vs θπ', fontsize=18, fontweight='bold', pad=20)

plt.tight_layout()
plt.savefig(os.path.join(out_dir, 'venn_CLR_theta_pi.png'), dpi=300, bbox_inches='tight', facecolor='white')
plt.savefig(os.path.join(out_dir, 'venn_CLR_theta_pi.pdf'), bbox_inches='tight', facecolor='white')
plt.close()
log_msg("PNG韦恩图已保存")

# 创建带统计表的版本
fig, (ax_venn, ax_table) = plt.subplots(2, 1, figsize=(12, 8), 
                                         gridspec_kw={'height_ratios': [3, 1]})

# 绘制韦恩图
ellipse1 = Ellipse(xy=(0, 0), width=9.4, height=6.6, angle=0, 
                   facecolor=col_clr, alpha=0.85, edgecolor='none')
ellipse2 = Ellipse(xy=(3.6, 0), width=9.4, height=6.6, angle=0, 
                   facecolor=col_pi, alpha=0.85, edgecolor='none')
ax_venn.add_patch(ellipse1)
ax_venn.add_patch(ellipse2)

ax_venn.text(-4.8, 3.2, 'CLR', fontsize=20, ha='center', va='center', fontweight='bold')
ax_venn.text(8.0, 3.2, r'$\theta \pi$', fontsize=20, ha='center', va='center', fontweight='bold')
ax_venn.text(-2.6, 0, str(n_clr_only), fontsize=16, ha='center', va='center', 
             fontweight='bold', color='white')
ax_venn.text(1.8, 0, str(n_overlap), fontsize=16, ha='center', va='center', 
             fontweight='bold', color='black')
ax_venn.text(6.2, 0, str(n_pi_only), fontsize=16, ha='center', va='center', 
             fontweight='bold', color='white')

ax_venn.set_xlim(-5.5, 8.5)
ax_venn.set_ylim(-3.8, 3.8)
ax_venn.set_aspect('equal')
ax_venn.axis('off')
ax_venn.set_title('Candidate Regions: CLR vs θπ', fontsize=18, fontweight='bold', pad=20)

# 添加统计表
ax_table.axis('off')
table_data = [
    ['Category', 'Count'],
    ['CLR only', str(n_clr_only)],
    ['Overlap', str(n_overlap)],
    ['θπ only', str(n_pi_only)],
    ['Total', str(n_clr_only + n_overlap + n_pi_only)]
]

table = ax_table.table(cellText=table_data, loc='center', cellLoc='center',
                        colWidths=[0.3, 0.2])
table.auto_set_font_size(False)
table.set_fontsize(12)
table.scale(1, 2)

# 设置表头样式
for i in range(2):
    table[(0, i)].set_facecolor('#4CAF50')
    table[(0, i)].set_text_props(weight='bold', color='white')

plt.tight_layout()
plt.savefig(os.path.join(out_dir, 'venn_CLR_theta_pi_with_stats.png'), dpi=300, 
            bbox_inches='tight', facecolor='white')
plt.close()
log_msg("带统计的韦恩图已保存")

# 保存日志
with open(log_file, 'w') as f:
    f.write('\n'.join(log))

log_msg(f"分析完成时间: {pd.Timestamp.now()}")
print(f"\nCLR&PI韦恩图分析完成!")
print(f"输出文件: {os.path.join(out_dir, 'venn_CLR_theta_pi.png')}")
