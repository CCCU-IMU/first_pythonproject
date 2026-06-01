## =========================
## 4-set Venn (JPG, 600 dpi) - Arial via showtext
## =========================

if (!requireNamespace("VennDiagram", quietly = TRUE)) install.packages("VennDiagram")
if (!requireNamespace("grid", quietly = TRUE)) install.packages("grid")
if (!requireNamespace("showtext", quietly = TRUE)) install.packages("showtext")
if (!requireNamespace("sysfonts", quietly = TRUE)) install.packages("sysfonts")

library(VennDiagram)
library(grid)
library(showtext)
library(sysfonts)

# ===== Arial 设置（Windows）=====
font_family <- "Arial"
arial_ttf <- "C:/Windows/Fonts/arial.ttf"
if (!file.exists(arial_ttf)) {
  stop("找不到 Arial 字体文件：", arial_ttf, "\n请把 arial_ttf 改成你电脑 Arial 的真实路径。")
}
font_add(font_family, regular = arial_ttf)
showtext_auto(TRUE)
showtext_opts(dpi = 600)

# 输入文件（按需改路径）
infile <- "E:/桌面/武汉数据/乌珠穆沁白牛/文章图汇总/测试/生长/candidate_region.gene.stat.xls"
df <- read.delim(infile, header = TRUE, sep = "\t",
                 stringsAsFactors = FALSE, check.names = FALSE)

# 识别 gene 列（优先常见列名，否则默认第一列）
gene_candidates <- c("gene", "Gene", "gene_id", "GeneID", "id", "ID")
gene_col <- intersect(gene_candidates, names(df))
gene_col <- if (length(gene_col) > 0) gene_col[1] else names(df)[1]

# ===== 自动识别列名（兼容 "Gene ID", "XP-EHH", "XP-CLR" 等写法）=====
# ===== 直接按当前文件表头映射（最稳妥）=====
names(df) <- trimws(names(df))  # 去掉列名两端可能的不可见空格

gene_col  <- "Gene ID"
fst_col   <- "FST"
pi_col    <- "PiRatio"
xpehh_col <- "XP-EHH"
xpclr_col <- "XP-CLR"

need_cols <- c(gene_col, fst_col, pi_col, xpehh_col, xpclr_col)
miss <- setdiff(need_cols, names(df))
if (length(miss) > 0) {
  stop("缺少必要列：", paste(miss, collapse = ", "),
       "\n当前表头为：", paste(names(df), collapse = ", "))
}



# 生成集合
get_set <- function(flag_col) {
  x <- df[[gene_col]][df[[flag_col]] == 1]
  unique(x[!is.na(x) & x != ""])
}

sets <- list(
  FST      = get_set(fst_col),
  PiRatio  = get_set(pi_col),
  `XP-CLR` = get_set(xpclr_col),
  `XP-EHH` = get_set(xpehh_col)
)


# 颜色（按你指定顺序）
fill_cols <- c(
  "#DA2222", # FST
  "#80B973", # piRatio
  "#4F97BA", # XPCLR
  "#714C9A"  # XPEHH
)

# 输出路径
out_dir <- "E:/桌面/武汉数据/乌珠穆沁白牛/文章图汇总/测试/生长"
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)
out_jpg <- file.path(out_dir, "venn4_methods.jpg")

# ===== 保存 JPG：600 dpi =====
jpeg(filename = out_jpg, width = 7, height = 5.5, units = "in",
     res = 600, quality = 100, bg = "white")
par(family = font_family)

grid.newpage()
vp <- venn.diagram(
  x = sets,
  filename = NULL,
  fill = fill_cols,
  alpha = 0.65,
  lwd = 0,
  cex = 1.2,
  fontfamily = font_family,       # ✅ 圈内数字 Arial
  cat.cex = 1.2,
  cat.fontfamily = font_family,   # ✅ 分类标签 Arial
  cat.col = "black"
)
grid.draw(vp)

dev.off()

# 关闭 showtext（避免影响后续绘图）
showtext_auto(FALSE)

message("Saved: ", out_jpg)
print(sapply(sets, length))
