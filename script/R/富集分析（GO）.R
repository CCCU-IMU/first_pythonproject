library(ggplot2)
library(dplyr)
library(grid)

# =========================
# 1) 读取 GO 富集结果
# =========================
go_rich <- read.delim(
  "E:/桌面/武汉数据/乌珠穆沁白牛/5.22分析结果/新加分析/result/07.UW/03.Conjoint_Analysis/enrich/GO/UW.go_rich.xls",
  sep = "\t",
  check.names = FALSE
)

go_class <- read.delim(
  "E:/桌面/武汉数据/乌珠穆沁白牛/5.22分析结果/新加分析/result/07.UW/03.Conjoint_Analysis/enrich/GO/UW.go_classplot.xls",
  sep = "\t",
  check.names = FALSE
)

# =========================
# 2) 合并 GO 大类信息（GO_Term：BP/MF/CC）
# =========================
go_rich2 <- go_rich %>%
  inner_join(go_class[, c("Go_ID", "GO_Term")],
             by = c("ID" = "Go_ID"))

# =========================
# 3) 取前 20 个（按 Count 降序）
# =========================
plot_df <- go_rich2 %>%
  arrange(desc(Count)) %>%
  slice(1:20)

# 因子顺序：Count 最大在最上面
plot_df$Description <- factor(plot_df$Description, levels = rev(plot_df$Description))

# =========================
# 4) 作图
# =========================
# ---- 让 x 轴只显示 3 个“整数”刻度的函数 ----
three_int_breaks <- function(limits) {
  lo <- floor(limits[1])
  hi <- ceiling(limits[2])
  if (hi - lo < 2) {               # 范围太小避免重复
    br <- unique(c(lo, round(mean(c(lo, hi))), hi))
  } else {
    br <- round(seq(lo, hi, length.out = 3))
  }
  br <- unique(br)
  # 如果因为范围太小导致不足3个，再补一个
  if (length(br) < 3) {
    br <- unique(round(pretty(c(lo, hi), n = 3)))
    br <- br[br >= lo & br <= hi]
  }
  br
}

p <- ggplot(plot_df,
            aes(x = Count, y = Description, fill = pvalue)) +
  geom_bar(stat = "identity") +
  labs(
    x = "Gene number",
    y = "GO term",
    fill = expression(italic(P)*"-value")
  )+
  scale_fill_gradient(
    low  = "#7FB7D6",
    high = "#c4deed"
  ) +
  # ✅ x轴只用3个整数刻度，避免出现7.5这种
  scale_x_continuous(
    breaks = c(2, 4, 6, 8)
  ) +
  theme_bw(base_family = "Arial") +
  theme(
    # ✅ 全图字体固定 Arial
    text = element_text(family = "Arial"),
    
    panel.grid = element_blank(),
    
    axis.title = element_text(size = 12, family = "Arial"),
    axis.text.x = element_text(size = 10, colour = "black", family = "Arial",
                               margin = margin(t = 6)),
    axis.text.y = element_text(size = 8,  colour = "black", family = "Arial",
                               margin = margin(r = 6)),
    
    axis.ticks = element_line(colour = "black"),
    
    # ✅ 刻度线朝内：长度设为负值
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
# 5) 保存（自动建目录 + 600dpi）
# =========================
out_dir <- "E:/桌面/武汉数据/乌珠穆沁白牛/文章图汇总/测试/内群"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

ggsave(
  filename = file.path(out_dir, "UW_GO_top20.tiff"),  # 一定要有扩展名
  plot     = p,
  device   = "tiff",
  dpi      = 600,
  width    = 12, height = 6, units = "in",
  compression = "lzw",
  bg       = "white"
)
