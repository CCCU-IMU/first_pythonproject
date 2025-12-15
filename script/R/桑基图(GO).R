# ==========================
# GO 桑基 + 富集气泡组合图（适配 UW_vs_Angus.UW.go_* 文件）
# ==========================

# 1. 加载 R 包 -----------------------------------------------------------
library(tidyverse)
library(ggsankey)
library(ggplot2)
library(cols4all)
library(cowplot)
setwd("E:/桌面/武汉数据/乌珠穆沁白牛/12.9重跑102样本结果/result/02.Sweep/05.Conjoint_Analysis/enrich/UW_vs_Angus.UW/GO")
# 2. 读入你的富集结果 ----------------------------------------------------
## 注意：这两个 .xls 实际是 tab 分隔文本，所以用 read.delim/read.table
go_class <- read.delim("UW_vs_Angus.UW.go_classplot.xls", check.names = FALSE)
go_rich  <- read.delim("UW_vs_Angus.UW.go_rich.xls",     check.names = FALSE)

# 简单检查
head(go_rich)
head(go_class)

# 3. 数据对齐 & 选择 GO 类别 --------------------------------------------
# 把 GO_Term (Biological Process / Molecular Function / Cellular Component)
# 加到富集结果里，方便按类别筛选
go_all <- go_rich %>%
  left_join(
    go_class %>% select(Go_ID, GO_Term),
    by = c("ID" = "Go_ID")
  )

# 在这里选择你想画的 GO 类别：BP / MF / CC
go_category <- "Biological Process"  # <- 改成 "Molecular Function" 或 "Cellular Component" 也行

go_use <- go_all %>%
  filter(GO_Term == go_category)

# 只取前 topN 个通路，避免太挤
topN <- 20
go_use <- go_use %>%
  arrange(pvalue) %>%
  slice(1:topN)

# 4. 构造富集气泡图数据 (kegg2) -----------------------------------------
# 从 GeneRatio 计算 Hit.Ratio
go_bubble <- go_use %>%
  separate(GeneRatio, into = c("hit", "all"), sep = "/", remove = FALSE, convert = TRUE) %>%
  mutate(
    Hit.Ratio = hit / all,
    pathNames = Description,   # 对齐原脚本的列名
    Pvalue    = pvalue,
    count     = Count
  ) %>%
  # 决定在 y 轴上的排列顺序：按 count 从大到小
  arrange(desc(count)) %>%
  mutate(
    ymax  = cumsum(count),
    ymin  = ymax - count,
    label = (ymin + ymax) / 2
  )

# 计算轴范围（自动）
x_max  <- max(-log10(go_bubble$Pvalue)) * 1.05
x_min  <- 0
y_max  <- max(go_bubble$ymax) * 1.05

# 自定义主题
mytheme <- theme(
  axis.title   = element_text(size = 13),
  axis.text    = element_text(size = 11),
  axis.text.y  = element_blank(),  # y 轴标签用桑基图来显示
  axis.ticks.y = element_blank(),
  legend.title = element_text(size = 13),
  legend.text  = element_text(size = 11)
)

# 富集气泡图（适配你的数据）
p3 <- ggplot(go_bubble) +
  geom_point(
    aes(
      x     = -log10(Pvalue),
      y     = label,
      size  = count,
      color = Hit.Ratio
    )
  ) +
  scale_size_continuous(range = c(2, 8)) +
  scale_y_reverse(expand = c(0, 0.1), limits = c(y_max, 0)) +
  scale_x_continuous(limits = c(x_min, x_max)) +
  scale_colour_distiller(palette = "Reds", direction = 1) +
  labs(
    x = expression(-log[10](italic(p)~value)),
    y = NULL,
    size  = "Gene count",
    color = "Hit ratio"
  ) +
  theme_bw() +
  mytheme

p3

# 5. 构造桑基图数据 (sankeydt) -------------------------------------------
# 这里做的是 “基因  ->  GO 通路” 的二层桑基

sankeydt <- go_use %>%
  select(pathNames = Description, geneID) %>%
  # geneID 形如 "gene-A/gene-B/..."，拆开
  separate_rows(geneID, sep = "/") %>%
  mutate(
    metamolites = gsub("^gene-", "", geneID)  # 去掉前缀 "gene-"
  ) %>%
  distinct(metamolites, pathNames)

# 6. 转换为 ggsankey 所需格式 -------------------------------------------
df <- sankeydt %>%
  make_long(metamolites, pathNames)

# 节点顺序：先通路，再基因；通路顺序与气泡图一致（保证上下对齐）
path_order <- go_bubble$pathNames
gene_order <- sankeydt %>%
  distinct(metamolites) %>%
  arrange(metamolites) %>%
  pull(metamolites)

df$node <- factor(
  df$node,
  levels = c(
    rev(path_order),  # 通路节点（倒序）
    rev(gene_order)   # 基因节点（倒序）
  )
)

# 7. 配色（根据节点数自动选颜色） ---------------------------------------
n_nodes <- length(levels(df$node))
# 可换其他 palette，比如 "rainbow_wh", "rainbow_wh_blue" 等
mycol <- c4a("rainbow_wh_rd", n_nodes)

# 8. 桑基图 --------------------------------------------------------------
p4 <- ggplot(
  df,
  aes(
    x         = x,
    next_x    = next_x,
    node      = node,
    next_node = next_node,
    fill      = node,
    label     = node
  )
) +
  geom_sankey(
    flow.alpha = 0.5,
    flow.fill  = "grey80",
    flow.color = "grey90",
    node.fill  = mycol,
    smooth     = 8,
    width      = 0.08
  ) +
  geom_sankey_text(
    size     = 3.2,
    color    = "black",
    hjust    = 1,                         # 右对齐
    position = position_nudge(x = -0.05)  # 整体往左挪到方块左边
  ) +
  coord_cartesian(clip = "off") +         # 允许文字画在面板外面
  theme_void() +
  theme(
    legend.position = "none",
    # 左边多留点空位，避免字被裁掉
    plot.margin     = unit(c(5.5, 30, 5.5, 60), "pt")
  )


# 9. 拼接桑基图 + 气泡图 -------------------------------------------------
# 调整页边距
p5 <- p4 + theme(plot.margin = unit(c(0, 5, 0, 0), units = "cm"))

final_plot <- ggdraw() +
  draw_plot(p5) +
  draw_plot(
    p3,
    scale  = 0.5,
    x      = 0.62,
    y      = -0.21,
    width  = 0.48,
    height = 1.37
  )

final_plot

# 10. 保存图片 -----------------------------------------------------------
ggsave(
  filename = paste0("UW_vs_Angus_GO_sankey_bubble_", gsub(" ", "_", go_category), ".pdf"),
  plot     = final_plot,
  width    = 15,
  height   = 10,
  device   = cairo_pdf
)
