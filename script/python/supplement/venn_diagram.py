#!/usr/bin/env python3
"""
韦恩图分析 - 4-set Venn
基于模拟选择信号分析结果创建韦恩图
"""

import os
import random
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib_venn import venn4, venn4_circles
import matplotlib.patches as mpatches

out_dir = "/mnt/e/桌面/脚本/autovalidation_supplement/venn_diagram"

log_file = os.path.join(out_dir, "venn_diagram.log")
log = []

def log_msg(msg):
    print(msg)
    log.append(msg)

log_msg(f"分析开始时间: {pd.Timestamp.now()}")

# 创建模拟候选基因列表
random.seed(42)
np.random.seed(42)

all_genes = [f"Gene{i}" for i in range(1, 2001)]

# 模拟4种不同方法检测到的基因集
sets = {
    'FST': set(random.sample(all_genes, 800)),
    'PiRatio': set(random.sample(all_genes, 650)),
    'XP-CLR': set(random.sample(all_genes, 720)),
    'XP-EHH': set(random.sample(all_genes, 580))
}

log_msg("模拟基因集大小:")
for name, gene_set in sets.items():
    log_msg(f"  {name}: {len(gene_set)}")

# 保存基因集大小
overlap_summary = pd.DataFrame({
    'Method': list(sets.keys()),
    'Count': [len(s) for s in sets.values()]
})
overlap_summary.to_csv(os.path.join(out_dir, 'set_sizes.tsv'), sep='\t', index=False)

# 计算交集
def get_subset_name(subset):
    """将二进制tuple转换为可读名称"""
    names = ['FST', 'PiRatio', 'XP-CLR', 'XP-EHH']
    included = [names[i] for i, v in enumerate(subset) if v]
    return ' ∩ '.join(included) if included else 'None'

# 颜色设置
colors = {
    'FST': '#DA2222',
    'PiRatio': '#80B973',
    'XP-CLR': '#4F97BA',
    'XP-EHH': '#714C9A'
}

# 生成韦恩图
fig, ax = plt.subplots(figsize=(12, 10))

# 使用matplotlib-venn绘制4集合韦恩图
v = venn4(
    subsets=(
        len(sets['FST'] - sets['PiRatio'] - sets['XP-CLR'] - sets['XP-EHH']),  # FST only
        len(sets['PiRatio'] - sets['FST'] - sets['XP-CLR'] - sets['XP-EHH']),  # PiRatio only
        len(sets['FST'] & sets['PiRatio'] - sets['XP-CLR'] - sets['XP-EHH']),  # FST ∩ PiRatio
        len(sets['XP-CLR'] - sets['FST'] - sets['PiRatio'] - sets['XP-EHH']),  # XP-CLR only
        len(sets['FST'] & sets['XP-CLR'] - sets['PiRatio'] - sets['XP-EHH']),  # FST ∩ XP-CLR
        len(sets['PiRatio'] & sets['XP-CLR'] - sets['FST'] - sets['XP-EHH']),  # PiRatio ∩ XP-CLR
        len(sets['FST'] & sets['PiRatio'] & sets['XP-CLR'] - sets['XP-EHH']),  # FST ∩ PiRatio ∩ XP-CLR
        len(sets['XP-EHH'] - sets['FST'] - sets['PiRatio'] - sets['XP-CLR']),  # XP-EHH only
        len(sets['FST'] & sets['XP-EHH'] - sets['PiRatio'] - sets['XP-CLR']),  # FST ∩ XP-EHH
        len(sets['PiRatio'] & sets['XP-EHH'] - sets['FST'] - sets['XP-CLR']),  # PiRatio ∩ XP-EHH
        len(sets['FST'] & sets['PiRatio'] & sets['XP-EHH'] - sets['XP-CLR']),  # FST ∩ PiRatio ∩ XP-EHH
        len(sets['XP-CLR'] & sets['XP-EHH'] - sets['FST'] - sets['PiRatio']),  # XP-CLR ∩ XP-EHH
        len(sets['FST'] & sets['XP-CLR'] & sets['XP-EHH'] - sets['PiRatio']),  # FST ∩ XP-CLR ∩ XP-EHH
        len(sets['PiRatio'] & sets['XP-CLR'] & sets['XP-EHH'] - sets['FST']),  # PiRatio ∩ XP-CLR ∩ XP-EHH
        len(sets['FST'] & sets['PiRatio'] & sets['XP-CLR'] & sets['XP-EHH']),  # All four
    ),
    set_labels=('FST', 'PiRatio', 'XP-CLR', 'XP-EHH'),
    ax=ax
)

# 设置颜色
for i, label in enumerate(['FST', 'PiRatio', 'XP-CLR', 'XP-EHH']):
    if v.subset_labels:
        for text in v.subset_labels:
            if text:
                text.set_fontsize(10)

ax.set_title('Candidate Genes Detected by Different Methods', fontsize=16, fontweight='bold')

plt.tight_layout()
plt.savefig(os.path.join(out_dir, 'venn4_methods.png'), dpi=300, bbox_inches='tight')
plt.savefig(os.path.join(out_dir, 'venn4_methods.pdf'), bbox_inches='tight')
plt.close()
log_msg(f"韦恩图已保存: {os.path.join(out_dir, 'venn4_methods.png')}")

# 计算并保存交集详情
from itertools import combinations

intersection_results = {}
methods = list(sets.keys())

# 两两交集
for combo in combinations(methods, 2):
    key = f"{combo[0]}_{combo[1]}"
    intersection_results[key] = sets[combo[0]] & sets[combo[1]]

# 三个方法交集
for combo in combinations(methods, 3):
    key = f"{combo[0]}_{combo[1]}_{combo[2]}"
    intersection_results[key] = sets[combo[0]] & sets[combo[1]] & sets[combo[2]]

# 四个方法交集
intersection_results['all_four'] = set.intersection(*sets.values())

log_msg("交集统计:")
for name, genes in intersection_results.items():
    log_msg(f"  {name}: {len(genes)}")
    # 保存交集基因列表
    if len(genes) > 0:
        df = pd.DataFrame({'Gene': sorted(list(genes))})
        df.to_csv(os.path.join(out_dir, f'genes_{name}.tsv'), sep='\t', index=False)

# 保存日志
with open(log_file, 'w') as f:
    f.write('\n'.join(log))

log_msg(f"分析完成时间: {pd.Timestamp.now()}")
print(f"\n韦恩图分析完成!")
print(f"输出文件: {os.path.join(out_dir, 'venn4_methods.png')}")
