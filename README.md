# Livestock Genomics Toolkit

`Livestock Genomics Toolkit` 是一个面向群体遗传学、生信分析教学和科研绘图复用的脚本库。项目把本地知识库中已经验证过的 R/Python 脚本整理为公开仓库，并新增一个可测试的 Python 小工具包，用于轻量级 VCF 统计、PCA/FST/Tajima's D 等结果的 SVG 可视化，以及脚本复现文档。

## 适用场景

- 牛、羊等家畜群体遗传学分析结果的快速整理和绘图。
- PCA、Structure/ADMIXTURE、FST、Tajima's D、iHS、LD decay、ROH/FROH、GO/KEGG 富集、单倍型和进化树等常见图表模板复用。
- 给课题组成员和生信初学者提供可读、可运行、可继续维护的脚本入口。
- 在没有完整服务器软件环境时，用纯 Python 工具进行小规模格式检查和教学演示。

## 仓库结构

```text
livestock_genomics_toolkit/       # 可安装的 Python 辅助包
script/R/                  # 传统 R 绘图和下游分析脚本
script/plots/              # 既有 Python 绘图脚本
script/bash/               # 外部工具调用示例
examples/demo_data/        # 可公开的极小示例数据
tests/                     # 标准库 unittest 测试
docs/                      # 脚本目录和维护计划
```

## 快速开始

```bash
python -m pip install -e .
python -m unittest discover -s tests
python -m livestock_genomics_toolkit vcf-stats \
  --vcf examples/demo_data/demo.vcf \
  --populations examples/demo_data/populations.tsv \
  --outdir demo_out \
  --window-size 10000 \
  --fst PopA PopB
python -m livestock_genomics_toolkit plot-line \
  --table demo_out/fst_PopA_vs_PopB.tsv \
  --x pos \
  --y fst \
  --out demo_out/fst.svg \
  --title "FST demo"
```

核心 Python 包不强制依赖 pandas/matplotlib，便于 CI 和教学演示。`script/plots/` 中的既有绘图脚本通常需要 `pandas`、`numpy`、`matplotlib` 等科学计算库；`script/R/` 中的脚本依赖见 [r_requirements.R](r_requirements.R)。

## 质量边界

本仓库保留两类脚本：

- `livestock_genomics_toolkit/`：经过整理、可测试、适合逐步扩展为稳定接口。
- `script/`：科研工作流中沉淀的可复用脚本模板，优先保留原始逻辑和图形风格，后续逐步参数化。

纯 Python VCF 统计用于小数据教学、结果 sanity check 和 CI 示例，不替代 PLINK、vcftools、bcftools、selscan、ADMIXTURE 等专业工具。

## 维护路线

短期目标是把更多历史脚本改造成“输入参数明确、输出路径明确、示例数据可运行、错误信息清楚”的命令行工具。详细计划见 [docs/maintenance_plan.md](docs/maintenance_plan.md)。

## License

MIT License. See [LICENSE](LICENSE).
