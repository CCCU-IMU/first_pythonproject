##############################################################################
# GO 弦图（基因<->通路）circlize稳定版
# - 通路：rainbow_wh_rd 渐变式离散配色（整体翻转：rev）
# - 连线：按通路上色
# - 基因：红色渐变表示 |XP-EHH| 强度（浅=弱，深=强），带数值图例
# - 图上：只显示基因名，不显示通路名
# - 底部：通路图例（小方块，多排）
# - 字体：showtext 强制 Arial（解决 Windows 字体系列警告）
##############################################################################

suppressPackageStartupMessages({
  library(data.table)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(cols4all)
  library(circlize)
  library(ComplexHeatmap)
  library(grid)
  library(showtext)   # ✅ 方案2：强制字体渲染
})

# =========================
# 0) 路径与参数（按需修改）
# =========================
go_dir <- "data/raw/乌珠穆沁白牛/12.9重跑102样本结果/result/02.Sweep/05.Conjoint_Analysis/enrich/UW_vs_Angus.UW/GO"
go_class_file <- file.path(go_dir, "UW_vs_Angus.UW.go_classplot.xls")
go_rich_file  <- file.path(go_dir, "UW_vs_Angus.UW.go_rich.xls")

deg_file <- "data/raw/乌珠穆沁白牛/文章图汇总/测试/毛色/DEG_with_logFC.csv"

out_dir <- file.path("data/raw/乌珠穆沁白牛/文章图汇总/测试/毛色/", "GOChord_circlize_out")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

out_prefix  <- "UW_vs_Mo-OD"
go_category <- "Biological Process"  # 或 "Molecular Function" / "Cellular Component"
topN        <- 12
dpi         <- 600

# ✅ 字体：Arial（showtext 强制）
font_family <- "Arial"
arial_ttf   <- "C:/Windows/Fonts/arial.ttf"  # Windows 默认路径
if (!file.exists(arial_ttf)) {
  stop("找不到 Arial 字体文件：", arial_ttf, "\n请检查路径或换成你电脑 Arial 的真实路径。")
}

# 图上只显示基因名，不显示通路名
show_term_labels <- FALSE
show_gene_labels <- TRUE

# 每个通路最多保留多少个基因（按 |score| 最大）避免太挤；不想限制就设为 NULL
max_genes_per_term <- 20

# 字体与位置（越大越向外）
cex_gene <- 0.55
gene_label_pos <- 0.03

# |score| 截断（让颜色不要被极端值挤压）
clip_quantile <- 0.95

# 底部通路图例：几排（2或3）
path_legend_nrow <- 4

# 画布（像素）——底部留空间放图例
jpg_w <- 5200
jpg_h <- 5200
# =========================


# =========================
# 1) 工具函数
# =========================
get_pal <- function(name, n) {
  pal <- cols4all::c4a(name, n)
  if (is.function(pal)) pal <- pal(n)
  if (!is.atomic(pal)) pal <- unlist(pal)
  pal <- as.character(pal)
  pal <- unname(pal)
  pal[1:n]
}

shorten_term <- function(x, max_chars = 52) {
  x <- str_replace_all(as.character(x), "\\s+", " ")
  x <- str_trim(x)
  ifelse(nchar(x) > max_chars, paste0(substr(x, 1, max_chars - 1), "…"), x)
}

# 你的“Hit ratio”风格红色渐变：浅 -> 深（用于 |XP-EHH| 强度）
gene_red_pal <- c("#FBBBA0", "#FB8969", "#F6583D", "#D82622", "#A1030F")


# =========================
# 2) 读入 GO 并筛 topN
# =========================
go_class <- read.delim(go_class_file, check.names = FALSE)
go_rich  <- read.delim(go_rich_file,  check.names = FALSE)

go_all <- go_rich %>%
  left_join(go_class %>% select(Go_ID, GO_Term), by = c("ID" = "Go_ID"))

go_use <- go_all %>%
  filter(GO_Term == go_category) %>%
  arrange(pvalue) %>%
  slice(1:min(topN, n()))

if (nrow(go_use) == 0) stop("go_use为空：请检查 go_category 是否正确。")
term_levels <- go_use$Description


# =========================
# 3) 读入基因分数（文件列名是 logFC，但这里当作 XP-EHH/选择信号分数）
# =========================
deg <- fread(deg_file)
if (!all(c("ID","logFC") %in% colnames(deg))) stop("DEG_with_logFC.csv 必须包含列：ID, logFC")
deg$logFC <- as.numeric(deg$logFC)


# =========================
# 4) links：gene <-> term，并合并分数
# =========================
links2 <- go_use %>%
  transmute(term = Description, geneID = geneID) %>%
  separate_rows(geneID, sep = "/") %>%
  mutate(gene = gsub("^gene-", "", geneID)) %>%
  distinct(gene, term) %>%
  left_join(deg %>% transmute(gene = ID, score = logFC), by = "gene") %>%
  filter(!is.na(score))

if (nrow(links2) == 0) stop("links2为空：go_rich中的gene在 DEG_with_logFC.csv 中没有匹配上。")

if (!is.null(max_genes_per_term)) {
  links2 <- links2 %>%
    group_by(term) %>%
    arrange(desc(abs(score)), .by_group = TRUE) %>%
    slice(1:min(max_genes_per_term, n())) %>%
    ungroup()
}

gene_df <- links2 %>% distinct(gene, score) %>% arrange(desc(abs(score)))
genes <- gene_df$gene

links2$gene <- factor(links2$gene, levels = genes)
links2$term <- factor(links2$term, levels = term_levels)


# =========================
# 5) 矩阵：genes x terms
# =========================
mat <- as.matrix(table(links2$gene, links2$term))
mat[mat > 0] <- 1


# =========================
# 6) 通路颜色：rainbow_wh_rd（整体翻转）
# =========================
term_cols <- rev(get_pal("rainbow_wh_rd", length(term_levels)))  # ✅ 翻转
names(term_cols) <- term_levels

# 通路图例短名（避免太长）
term_legend_labels <- shorten_term(term_levels, max_chars = 60)
names(term_legend_labels) <- term_levels
# ---- 手工简写字典：用来覆盖某些特别长/有公认缩写的通路名 ----
manual_short <- c(
  "protein kinase C-activating G protein-coupled receptor signaling pathway" =
    "PKC-activating GPCR signaling","transmembrane receptor protein tyrosine kinase signaling pathway" = "RTK signaling"
)

# 覆盖对应通路的显示名（只影响底部图例，不影响连线/颜色匹配）
term_legend_labels[names(manual_short)] <- manual_short


# =========================
# 7) 基因颜色：按 |score| 强度映射红色渐变
# =========================
gene_score <- gene_df$score
names(gene_score) <- gene_df$gene

abs_lim <- as.numeric(quantile(abs(gene_score), probs = clip_quantile, na.rm = TRUE))
if (!is.finite(abs_lim) || abs_lim == 0) abs_lim <- max(abs(gene_score), na.rm = TRUE)
if (!is.finite(abs_lim) || abs_lim == 0) abs_lim <- 1

gene_strength <- pmax(pmin(abs(gene_score), abs_lim), 0)

col_fun <- circlize::colorRamp2(
  seq(0, abs_lim, length.out = length(gene_red_pal)),
  gene_red_pal
)

gene_cols <- as.character(col_fun(gene_strength))
names(gene_cols) <- names(gene_strength)

# 扇区颜色顺序：基因在左、通路在右
grid_cols <- c(gene_cols, term_cols)


# =========================
# 8) 连线颜色：按通路上色
# =========================
link_col_mat <- matrix(NA_character_, nrow = nrow(mat), ncol = ncol(mat), dimnames = dimnames(mat))
for (j in seq_len(ncol(mat))) {
  tn <- colnames(mat)[j]
  link_col_mat[, j] <- term_cols[tn]
}
link_col_mat[mat == 0] <- NA


# =========================
# 9) 绘图 + 图例（左上强度图例 + 底部通路图例）
# =========================
out_jpg <- file.path(out_dir, paste0(out_prefix, "_GOChord_revPathColor_onlyGeneLabel_pathLegend_",
                                     gsub(" ", "_", go_category),
                                     "_Top", nrow(go_use), "_", dpi, "dpi.jpg"))

sector_order <- c(genes, term_levels)
gap_after <- c(rep(1, length(genes)-1), 12, rep(1, length(term_levels)-1), 12)

# ✅ showtext 强制加载 Arial 并启用
# ✅ showtext 强制加载 Arial（包含 regular/italic/bold/bolditalic）
arial_ttf    <- "C:/Windows/Fonts/arial.ttf"
arial_i_ttf  <- "C:/Windows/Fonts/ariali.ttf"
arial_b_ttf  <- "C:/Windows/Fonts/arialbd.ttf"
arial_bi_ttf <- "C:/Windows/Fonts/arialbi.ttf"

for (f in c(arial_ttf, arial_i_ttf, arial_b_ttf, arial_bi_ttf)) {
  if (!file.exists(f)) stop("找不到字体文件：", f)
}

font_add(
  family = font_family,
  regular = arial_ttf,
  italic  = arial_i_ttf,
  bold    = arial_b_ttf,
  bolditalic = arial_bi_ttf
)

showtext_auto(TRUE)
showtext_opts(dpi = dpi)


cat("showtext enabled:", showtext:::.pkg.env$.showtext_auto, "\n")
print(sysfonts::font_families())


jpeg(out_jpg, width = jpg_w, height = jpg_h, res = dpi, quality = 100)
par(family = font_family)

circos.clear()
circos.par(
  start.degree = 180,
  gap.after = gap_after,
  track.margin = c(0.01, 0.01),
  canvas.xlim = c(-1.45, 1.45),
  canvas.ylim = c(-1.45, 1.45)
)

chordDiagram(
  x = mat,
  grid.col = grid_cols,
  order = sector_order,
  col = link_col_mat,
  transparency = 0.35,
  annotationTrack = c("grid"),
  preAllocateTracks = 1
)

# 只画基因标签
circos.trackPlotRegion(
  track.index = 1,
  panel.fun = function(x, y) {
    sector_name <- get.cell.meta.data("sector.index")
    xlim <- get.cell.meta.data("xlim")
    ylim <- get.cell.meta.data("ylim")
    
    is_gene <- sector_name %in% genes
    is_term <- sector_name %in% term_levels
    
    if (is_gene && show_gene_labels) {
      
      # 扇区中心角度（0°在右侧，逆时针增加）
      deg_center <- (get.cell.meta.data("cell.start.degree") +
                       get.cell.meta.data("cell.end.degree")) / 2
      
      # 右半边( -90~90 )用左对齐；左半边用右对齐
      # 这样文字会“朝外侧”展开，不再居中飘
      adj_x <- ifelse(deg_center < 90 || deg_center > 270, 0, 1)
      
      circos.text(
        x = mean(xlim),
        y = ylim[1] + (ylim[2]-ylim[1]) * gene_label_pos,
        labels = sector_name,
        facing = "clockwise",
        niceFacing = TRUE,
        adj = c(adj_x, 0.5),
        cex = cex_gene,
        col = gene_cols[sector_name],
        family = font_family,
        font = 3   # ✅ 斜体（italic）
      )
    }
    
    # 通路名不画
    if (is_term && show_term_labels) {
      # intentionally empty
    }
  },
  bg.border = NA
)

title(paste0("GO chord (", go_category, ", Top ", nrow(go_use), ")"),
      family = font_family)

# ---- 左上角：选择信号强度图例（横向、小，带数值）----
mid_val <- abs_lim / 2
lgd_strength <- Legend(
  title = "Signal strength (|XP-EHH|)",
  col_fun = col_fun,
  at = c(0, mid_val, abs_lim),
  labels = c(sprintf("%.1f", 0), sprintf("%.1f", mid_val), sprintf("%.1f", abs_lim)),
  direction = "horizontal",
  legend_width  = unit(25, "mm"),
  legend_height = unit(3, "mm"),
  title_gp  = gpar(fontsize = 10, fontfamily = font_family),
  labels_gp = gpar(fontsize = 9,  fontfamily = font_family)
)
draw(lgd_strength, x = unit(0.04, "npc"), y = unit(0.97, "npc"), just = c("left", "top"))

# ---- 底部：通路图例（小色块，多排）----
lgd_path <- Legend(
  title = paste0("GO terms (Top ", nrow(go_use), ")"),
  labels = unname(term_legend_labels[term_levels]),
  legend_gp = gpar(fill = unname(term_cols[term_levels])),
  nrow = path_legend_nrow,
  grid_width  = unit(3.2, "mm"),
  grid_height = unit(3.2, "mm"),
  labels_gp = gpar(fontsize = 9,  fontfamily = font_family),
  title_gp  = gpar(fontsize = 10, fontfamily = font_family)
)
draw(lgd_path, x = unit(0.50, "npc"), y = unit(0.03, "npc"), just = c("center", "bottom"))

dev.off()
circos.clear()

# ✅ 关闭 showtext（避免影响后续绘图）
showtext_auto(FALSE)

message("✅ 完成：", out_jpg)
