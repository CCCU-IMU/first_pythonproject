# ==============================================================================
# 1. 加载必要的包
# ==============================================================================
library(ggplot2)
library(data.table)
library(dplyr)
library(stringr)
library(showtext)
library(scales)

# ==============================================================================
# 2. 环境与参数设置 (严格对齐 LD 脚本)
# ==============================================================================
work_dir <- "E:/桌面/武汉数据/乌珠穆沁白牛/文章图汇总/测试/遗传多样性"
setwd(work_dir)

# --- 字体设置 ---
font_add("Arial", "arial.ttf")
showtext_auto()
showtext_opts(dpi = 600)
my_font <- "Arial"

# --- 群体顺序（固定）---
breed_order <- c("Angus", "Simmental", "Charolais", "UW", "Mo-OD", "Mo-SN", "Hanwoo", "Indicine")

# --- 配色：只使用你指定的 8 个颜色，并按群体命名绑定 ---
custom_colors <- c(
  "Angus"     = "#E64B35",
  "Simmental" = "#4DBBD5",
  "Charolais" = "#00A087",
  "UW"        = "#3C5488",
  "Mo-OD"     = "#F39B7F",
  "Mo-SN"     = "#8491B4",
  "Hanwoo"    = "#91D1C2",
  "Indicine"  = "#DC0000"
)

# ==============================================================================
# 3. 数据读取与处理
# ==============================================================================
file_list <- list.files(path = work_dir, pattern = "\\.windowed\\.pi\\.xls$", full.names = FALSE)
if (length(file_list) == 0) stop("未找到 .windowed.pi.xls 文件")

plot_data_list <- list()
cat("正在读取数据...\n")

for (file in file_list) {
  raw_name <- str_remove(file, "\\.windowed\\.pi\\.xls.*")
  breed_name <- ifelse(raw_name == "Bos_indicus", "Indicine", raw_name)
  
  # 只保留指定的8个群体
  if (!(breed_name %in% breed_order)) next
  
  df <- fread(file, header = TRUE)
  if (!("PI" %in% colnames(df))) next
  
  df_clean <- df %>%
    transmute(
      PI = as.numeric(PI),
      Breed = breed_name
    ) %>%
    filter(!is.na(PI))
  
  plot_data_list[[breed_name]] <- df_clean
}

final_data <- bind_rows(plot_data_list)
final_data$Breed <- factor(final_data$Breed, levels = breed_order)

cat("绘图准备就绪...\n")

# ==============================================================================
# 4. 绘图 (样式参数严格对齐 LD 脚本)
# ==============================================================================
p <- ggplot(final_data, aes(x = Breed, y = PI, fill = Breed)) +
  
  # --- Error Bar (T型横线) ---
  stat_boxplot(
    geom = "errorbar",
    width = 0.25,
    linewidth = 0.55,
    color = "black"
  ) +
  
  # --- 箱线图主体 ---
  geom_boxplot(
    width = 0.6,
    linewidth = 0.55,
    outlier.shape = NA,
    colour = "black"
  ) +
  
  # --- 中位数标签 ---
  stat_summary(
    fun = median,
    geom = "text",
    aes(label = sprintf("%.4f", after_stat(y))),
    vjust = -0.8,
    size = 3.8,
    family = my_font,
    colour = "black"
  ) +
  
  # --- 配色（锁定顺序）---
  scale_fill_manual(values = custom_colors, breaks = breed_order, drop = FALSE) +
  
  # --- Y轴设置 ---
  scale_y_continuous(
    breaks = seq(0, 0.009, 0.003),
    expand = expansion(mult = c(0.06, 0.04))
  ) +
  coord_cartesian(ylim = c(0, 0.01)) +
  
  labs(x = NULL, y = "Nucleotide diversity") +
  
  # --- 主题设置（与 LD 一致）---
  theme_bw(base_size = 14) +
  theme(
    text = element_text(family = my_font),
    
    # 刻度线：向内 0.18 cm
    axis.ticks = element_line(linewidth = 0.8, color = "black"),
    axis.ticks.length = unit(-0.18, "cm"),
    
    # ✅ X轴标签倾斜（45°，与ROH/FROH一致的论文风）
    axis.text.x = element_text(
      angle = 45, hjust = 1, vjust = 1,
      margin = margin(t = 8),
      color = "black", size = 12
    ),
    axis.text.y = element_text(margin = margin(r = 8), color = "black", size = 12),
    
    axis.title.y = element_text(size = 14, margin = margin(r = 15), color = "black"),
    
    panel.border = element_rect(colour = "black", fill = NA, linewidth = 0.8),
    panel.grid = element_blank(),
    legend.position = "none",
    plot.margin = margin(20, 20, 20, 20)
  )

# ==============================================================================
# 5. 输出
# ==============================================================================
print(p)

ggsave("Nucleotide_Diversity_Unified.jpg", plot = p, width = 8, height = 6, dpi = 600)
ggsave("Nucleotide_Diversity_Unified.pdf", plot = p, width = 8, height = 6)

cat("绘图完成！\n已添加 X 轴标签 45° 倾斜，并保持刻度线内向 0.18cm。\n")
