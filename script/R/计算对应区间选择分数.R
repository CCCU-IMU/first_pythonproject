library(data.table)
library(stringr)

# 1) 读入：基因区间（你上传的）
genes <- fread("data/raw/乌珠穆沁白牛/文章图汇总/测试/毛色/candidate_region.merge_gene.xls")   # CHROM START END GENE
setnames(genes, c("CHROM","START","END","GENE"))

# 2) 读入：XP-EHH（你本地的那个制表符文件）
  xpe <- fread("data/raw/乌珠穆沁白牛/文章图汇总/测试/毛色/UW_vs_Angus.xpehh.xls")  # CHROM BIN_START BIN_END xpehh

# 3) 清洗 xpehh（你示例里有 -0.28563s 这种尾巴，要去掉非数字字符）
xpe[, xpehh := as.numeric(gsub("[^0-9eE+\\-\\.]", "", xpehh))]

# 4) 为 foverlaps 准备 key（区间列必须是整数/数值）
setkey(genes, CHROM, START, END)
setkey(xpe,   CHROM, BIN_START, BIN_END)

# 5) 做重叠：把落在基因区间内的 xpehh 关联到该基因
ol <- foverlaps(xpe, genes,
                by.x = c("CHROM","BIN_START","BIN_END"),
                by.y = c("CHROM","START","END"),
                type = "any", nomatch = 0L)

# 6) 按基因汇总一个“基因选择分数”
# 常用几种：均值(mean)、最大绝对值(max_abs)、绝对值最大的那个点(保留方向, signed_max)
gene_score <- ol[, .(
  n_hit     = .N,
  mean_xpe  = mean(xpehh, na.rm = TRUE),
  max_abs   = max(abs(xpehh), na.rm = TRUE),
  signed_max = xpehh[which.max(abs(xpehh))]   # 最强信号点，并保留正负方向
), by = GENE]

# 7) 生成 GOplot 需要的两列：ID + logFC（这里用 signed_max 做“伪logFC”最直观）
gene_score[, ID := gsub("^gene-", "", GENE)]
gene_score[, logFC := as.numeric(scale(signed_max))]  # 标准化一下，颜色更均匀
out <- gene_score[, .(ID, logFC)]

fwrite(out, "data/raw/乌珠穆沁白牛/文章图汇总/测试/毛色/DEG_with_logFC.csv")   # 你之前GOplot脚本里 deg_file 指向它即可
