# ==========================
# KEGG 桑基 + 富集气泡组合图
# Top12 + 完全对齐 + Arial + 输出 JPG/TIFF 600dpi + 刻度向内
# ==========================

library(tidyverse)
library(ggsankey)
library(ggplot2)
library(cols4all)
library(cowplot)
library(grid)      # unit()
library(stringr)   # str_wrap()

# --------- 0) 参数区：你常用只改这里 ----------
setwd("data/raw/乌珠穆沁白牛/12.9重跑102样本结果/result/02.Sweep/05.Conjoint_Analysis/enrich/UW_vs_Mo-OD.UW/KEGG")
# 注意：请确保工作路径正确
out_dir <- "data/raw/乌珠穆沁白牛/文章图汇总/测试/生长"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

kegg_category <- "Metabolism"   # <<< 按需要改
topN <- 12

# 输出尺寸（画布放大）
W <- 40
H <- 18
U <- "cm"

# 右侧气泡图占比（越小越“不会放大”）
rel_w_left  <- 1.2
rel_w_right <- 0.35

# 字体
base_family <- "Arial"

# 通路名换行（避免长通路名挤在一起；不想换行可把 width 调大，比如 100）
path_wrap_width <- 100

# --------- 1) 全局字体设置 ----------
theme_set(theme_bw(base_family = base_family))

# --------- 2) 读入 KEGG 结果 ----------
# 请确保文件在当前路径下
kegg_class <- read.delim("UW_vs_Mo-OD.UW.ko_classplot.xls", check.names = FALSE)
kegg_rich  <- read.delim("UW_vs_Mo-OD.UW.kegg_rich.xls",   check.names = FALSE)

# 合并 Pathway 大类
kegg_all <- kegg_rich %>%
  left_join(
    kegg_class %>% dplyr::select(Ko_ID, Pathway),
    by = c("ID" = "Ko_ID")
  )

# Top12
kegg_use <- kegg_all %>%
  filter(Pathway == kegg_category) %>%
  arrange(pvalue) %>%
  slice_head(n = topN) %>%
  mutate(
    # 通路名自动换行，减少拥挤
    Description = str_wrap(Description, width = path_wrap_width)
  )

# --------- 3) 桑基数据：gene -> pathway ----------
sankeydt <- kegg_use %>%
  dplyr::select(pathNames = Description, geneID) %>%
  separate_rows(geneID, sep = "/") %>%
  mutate(
    metamolites = gsub("^gene-", "", geneID)  # 若没有 gene- 前缀，可改成 metamolites = geneID
  ) %>%
  distinct(metamolites, pathNames)

df <- sankeydt %>% make_long(metamolites, pathNames)

# 固定节点顺序（levels 影响上下顺序）
path_order <- kegg_use$Description
gene_order <- sankeydt %>%
  distinct(metamolites) %>%
  arrange(metamolites) %>%
  pull(metamolites)

df$node      <- factor(df$node,      levels = c(rev(gene_order), rev(path_order)))
df$next_node <- factor(df$next_node, levels = levels(df$node))

# [新增步骤] 设置字体样式列：如果是基因列(metamolites)，则为 italic，否则为 plain
# make_long 生成的 x 列对应原来的列名
df$text_face <- ifelse(df$x == "metamolites", "italic", "plain") # <<< 修改处：定义字体样式

# 颜色
mycol <- c4a("rainbow_wh_rd", length(levels(df$node)))

# --------- 4) 先画桑基（初版），用于提取通路节点 y_center ----------
p_sankey0 <- ggplot(
  df,
  aes(
    x = x, next_x = next_x,
    node = node, next_node = next_node,
    fill = node, label = node
  )
) +
  geom_sankey(
    flow.alpha = 0.7,
    flow.fill  = "#F3F5FF",
    flow.color = "#E9ECFB",
    node.fill  = mycol,
    smooth     = 8,
    width      = 0.08
  ) +
  geom_sankey_text(
    aes(fontface = text_face), # <<< 修改处：应用上面定义的字体样式
    size     = 3.2,
    family   = base_family,
    color    = "black",
    hjust    = 1,
    position = position_nudge(x = -0.05)
  ) +
  coord_cartesian(clip = "off") +
  theme_void(base_family = base_family) +
  theme(
    legend.position = "none",
    plot.margin     = unit(c(6, 6, 6, 80), "pt") # 左侧留更大空白给基因名
  )

# --------- 5) 从桑基图构建结果里拿到节点真实位置 ----------
pb <- ggplot_build(p_sankey0)

node_layer_id <- which(sapply(pb$data, function(d) all(c("xmin","xmax","ymin","ymax") %in% names(d))))[1]
node_layer <- pb$data[[node_layer_id]]

# 原始 y 范围
y_rng <- range(c(node_layer$ymin, node_layer$ymax), na.rm = TRUE)

# 给 y 增加 padding（不破坏对齐，但视觉更松）
y_pad <- diff(y_rng) * 0.03
y_rng2 <- c(y_rng[1] - y_pad, y_rng[2] + y_pad)

# 提取通路节点位置（第二列 x_center≈2）
path_pos <- node_layer %>%
  mutate(
    x_center = (xmin + xmax) / 2,
    y_center = (ymin + ymax) / 2,
    node_chr = as.character(node)
  ) %>%
  filter(
    abs(x_center - 2) < 1e-3,
    node_chr %in% path_order
  ) %>%
  transmute(pathNames = node_chr, y = y_center)

# 固定桑基 y 轴（用加 padding 的 y_rng2）
p_sankey <- p_sankey0 +
  scale_y_continuous(limits = y_rng2, expand = c(0, 0))

# --------- 6) 气泡图数据（y 用通路 y_center，保证严格对齐） ----------
kegg_bubble <- kegg_use %>%
  separate(GeneRatio, into = c("hit", "all"), sep = "/", remove = FALSE, convert = TRUE) %>%
  mutate(
    Hit.Ratio = hit / all,
    pathNames = Description,
    Pvalue    = pvalue,
    count     = Count
  ) %>%
  left_join(path_pos, by = "pathNames") %>%
  filter(!is.na(y))

x_max <- max(-log10(kegg_bubble$Pvalue)) * 1.05

p_bubble <- ggplot(kegg_bubble) +
  geom_point(
    aes(
      x     = -log10(Pvalue),
      y     = y,
      size  = count,
      color = Hit.Ratio
    )
  ) +
  scale_size_continuous(range = c(2, 8)) +
  scale_x_continuous(limits = c(0, x_max), breaks = scales::pretty_breaks(n = 3)) +
  scale_y_continuous(limits = y_rng2, breaks = NULL, expand = c(0, 0)) +
  scale_colour_distiller(palette = "Reds", direction = 1) +
  labs(
    # <<< 修改处：改为大写P、斜体，并用减号连接 value
    x = expression(-log[10](italic(P)-value)), 
    y = NULL,
    size  = "Gene count",
    color = "Hit ratio"
  ) +
  theme_bw(base_family = base_family) +
  theme(
    axis.title    = element_text(size = 13, family = base_family),
    axis.text     = element_text(size = 11, family = base_family),
    axis.text.y   = element_blank(),
    axis.ticks.y  = element_blank(),
    legend.title  = element_text(size = 13, family = base_family),
    legend.text   = element_text(size = 11, family = base_family),
    
    # 刻度向内
    axis.ticks.length = unit(-0.15, "cm"),
    axis.text.x = element_text(margin = margin(t = 6)),
    
    plot.margin = unit(c(6, 6, 6, 6), "pt")
  )

# --------- 7) 拼图：放大画布，但让右侧占比小（右图不会视觉变大） ----------
aligned <- align_plots(p_sankey, p_bubble, align = "h", axis = "tb")

final_plot <- plot_grid(
  aligned[[1]], aligned[[2]],
  nrow = 1,
  rel_widths = c(rel_w_left, rel_w_right)
)

final_plot

# --------- 8) 输出：JPG / TIFF（600dpi） ----------
prefix <- paste0(
  "UW_vs_Mo-OD_KEGG_sankey_bubble_",
  gsub(" ", "_", kegg_category),
  "_Top12_Arial"
)

ggsave(
  filename = file.path(out_dir, paste0(prefix, ".jpg")),
  plot     = final_plot,
  width    = W,
  height   = H,
  units    = U,
  dpi      = 600
)

ggsave(
  filename    = file.path(out_dir, paste0(prefix, ".tiff")),
  plot        = final_plot,
  width       = W,
  height      = H,
  units       = U,
  dpi         = 600,
  compression = "lzw"
)