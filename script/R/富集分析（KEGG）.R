library(ggplot2)
library(dplyr)
library(grid)

# =========================
# 1) 读取 KEGG 文件
# =========================
kegg_rich <- read.delim(
  "E:/桌面/武汉数据/乌珠穆沁白牛/5.22分析结果/新加分析/result/07.UW/03.Conjoint_Analysis/enrich/KEGG/UW.kegg_rich.xls",
  sep = "\t",
  check.names = FALSE
)

ko_class <- read.delim(
  "E:/桌面/武汉数据/乌珠穆沁白牛/5.22分析结果/新加分析/result/07.UW/03.Conjoint_Analysis/enrich/KEGG/UW.ko_classplot.xls",
  sep = "\t",
  check.names = FALSE
)

# =========================
# 2) 合并大类信息 Pathway
# =========================
kegg_rich2 <- kegg_rich %>%
  inner_join(ko_class[, c("Ko_ID", "Pathway")],
             by = c("ID" = "Ko_ID"))

# =========================
# 3) 取前 20 个（按 Count 降序）
# =========================
plot_df <- kegg_rich2 %>%
  arrange(desc(Count)) %>%
  slice(1:20)

# 因子顺序：Count 最大在最上面
plot_df$Description <- factor(plot_df$Description, levels = rev(plot_df$Description))

# =========================
# 4) x轴只显示 3 个整数刻度（自定义 breaks）
# =========================
three_int_breaks <- function(limits) {
  lo <- floor(limits[1])
  hi <- ceiling(limits[2])
  
  # 生成 3 个点并四舍五入为整数
  br <- unique(round(seq(lo, hi, length.out = 3)))
  
  # 范围太小时，可能不足3个，做个兜底
  if (length(br) < 3) {
    br2 <- pretty(c(lo, hi), n = 3)
    br2 <- unique(round(br2))
    br2 <- br2[br2 >= lo & br2 <= hi]
    if (length(br2) >= 3) br <- br2[1:3] else br <- br2
  }
  br
}

# =========================
# 5) 作图（保留你的设置 + 刻度向内 + 字体Arial）
# =========================
p <- ggplot(plot_df, aes(x = Count, y = Description, fill = pvalue)) +
  geom_bar(stat = "identity") +
  labs(
    x = "Gene number",
    y = "KEGG pathway",
    fill = expression(italic(P)*"-value")
  )+
  scale_fill_gradient(
    low  = "#bb9cc5",
    high = "#f4d5db"
  ) +
  # ✅ x轴只要 3 个整数刻度
  scale_x_continuous(
    breaks = c(2, 4, 6, 8)
  )+
  theme_bw(base_family = "Arial") +
  theme(
    # ✅ 全图字体固定 Arial
    text = element_text(family = "Arial"),
    
    panel.grid = element_blank(),
    
    axis.title = element_text(size = 12, family = "Arial"),
    axis.text.x  = element_text(size = 10, colour = "black", family = "Arial",
                                margin = margin(t = 6)),
    axis.text.y  = element_text(size = 8,  colour = "black", family = "Arial",
                                margin = margin(r = 6)),
    axis.ticks   = element_line(colour = "black"),
    
    # ✅ 刻度朝内：负值
    axis.ticks.length = unit(-0.15, "cm"),
    
    legend.position      = c(0.95, 0.02),
    legend.justification = c(1, 0),
    legend.background    = element_rect(colour = "black", fill = "white"),
    legend.title = element_text(size = 9, family = "Arial"),
    legend.text  = element_text(size = 8, family = "Arial"),
    
    plot.margin  = margin(5, 5, 5, 5),
    aspect.ratio = 1.6
  ) +
  guides(
    fill = guide_colorbar(
      title.position = "top",
      barheight = unit(2.0, "cm"),
      barwidth  = unit(0.6, "cm")
    )
  )

print(p)

# =========================
# 6) 保存：TIFF，600 dpi（自动建目录）
# =========================
out_dir <- "E:/桌面/武汉数据/乌珠穆沁白牛/文章图汇总/测试/内群"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

out_file <- file.path(out_dir, "UW_KEGG_top20.tiff")

ggsave(
  filename = out_file,
  plot     = p,
  device   = "tiff",
  dpi      = 600,
  width    = 12, height = 6, units = "in",
  compression = "lzw",
  bg       = "white"
)
