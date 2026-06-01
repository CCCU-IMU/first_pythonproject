# Script Catalog

This catalog turns the local knowledge base into a maintainable open-source index. Existing scripts keep their original Chinese names so lab members can match them with local analysis notes.

## Population Structure And Ancestry

| Script | Purpose | Typical input |
| --- | --- | --- |
| `script/R/PCA分析.R` | Plot PLINK PCA eigenvectors with group labels | `pca.eigenvec`, `pca.eigenval`, breed/group table |
| `script/R/PCA分析（csv）.R` | Plot PCA from CSV matrices | PCA coordinate CSV |
| `script/R/structure绘图脚本（默认排序）.R` | Draw ADMIXTURE/Structure Q matrices | `.Q` files |
| `script/R/structure绘图脚本（指定群体排序）.R` | Draw grouped and ordered Q matrices | `.Q` plus group order |
| `script/R/祖先比例.R` | Plot ancestry proportions | LOTER/ancestry segments |
| `script/R/祖先比例折线图.R` | Plot ancestry proportion trends | Regional or genomic ancestry summary |

## Selection And Population Genetics

| Script | Purpose | Typical input |
| --- | --- | --- |
| `script/R/FST折线图.R` | FST line plot | windowed/per-site FST |
| `script/R/Tajima‘s D折线图.R` | Tajima's D line plot | windowed Tajima's D |
| `script/R/IHS单独.R` | iHS visualization | normalized iHS |
| `script/R/IHS2的SNP比例图.R` | iHS candidate SNP proportion plot | interval table and iHS files |
| `script/R/LD衰减.R` | LD decay plot | LD statistics from PLINK/PopLDdecay |
| `script/R/曼哈顿图（PI）.R` | Pi Manhattan/box plots | windowed pi |
| `script/R/曼哈顿图（CLR&PI）.R` | CLR and pi combined Manhattan plot | CLR and pi tables |
| `script/R/箱线图-核苷酸多样性.R` | Nucleotide diversity box plot | pi tables |
| `script/R/计算对应区间选择分数.R` | Candidate interval score calculation | candidate region and DEG tables |
| `script/R/EHH最强位点.R` | EHH top locus visualization | haplotype/EHH results |

## Enrichment And Candidate Gene Figures

| Script | Purpose | Typical input |
| --- | --- | --- |
| `script/R/富集分析（GO）.R` | GO enrichment bubble/bar plot | GO enrichment table |
| `script/R/富集分析（KEGG）.R` | KEGG enrichment plot | KEGG enrichment table |
| `script/R/富集分析（LOTER）.R` | LOTER candidate enrichment plot | candidate gene enrichment table |
| `script/R/桑基图(GO).R` | GO Sankey plot | GO classification/enrichment table |
| `script/R/桑基图（KEGG）.R` | KEGG Sankey plot | KEGG classification/enrichment table |
| `script/R/GO圈图.R` | GO chord/circle plot | GO enrichment plus logFC table |
| `script/R/韦恩图.R` | Multi-method candidate gene overlap | gene sets |
| `script/R/韦恩图（CLR&PI）.R` | CLR and pi overlap plot | candidate region sets |

## Genomic Regions, ROH, Haplotype, And Maps

| Script | Purpose | Typical input |
| --- | --- | --- |
| `script/R/ROH和FROH结果可视化.R` | ROH/FROH summary figures | PLINK `--homozyg` outputs |
| `script/R/进化树构建.R` | Phylogenetic tree plotting | distance matrix or Newick |
| `script/R/单倍型热图.R` | Haplotype heatmap | VCF or haplotype matrix |
| `script/R/基因相对位置.R` | Gene relative position tracks | gene/region annotation |
| `script/R/make_tracks_stack.R` | Track stacking helper | genomic intervals |
| `script/R/世界地图.R` | Geographic map plot | sample location table |

## Maintained Python Helpers

| Command | Purpose |
| --- | --- |
| `python -m livestock_genomics_toolkit vcf-stats` | Generate small VCF pi, Tajima's D, and optional FST tables |
| `python -m livestock_genomics_toolkit plot-pca` | Render PLINK PCA output to SVG |
| `python -m livestock_genomics_toolkit plot-line` | Render any numeric TSV x/y table to SVG |

## Known Cleanup Tasks

- Remove or replace empty legacy scripts such as `script/R/轮回杂交.R` before a release tag.
- Replace hard-coded local paths with command line arguments.
- Add one synthetic fixture per major workflow.
- Prefer SVG/PNG example outputs generated from public demo data.
