# ==============================================================================
# 1. 加载必要的包
# ==============================================================================
library(ggplot2)
library(data.table)
library(dplyr)
library(stringr)
library(showtext)

# ==============================================================================
# 2. 环境与参数设置
# ==============================================================================
# 请修改为你的实际路径
work_dir <- "data/raw/乌珠穆沁白牛/文章图汇总/测试/遗传多样性"
setwd(work_dir)

# 字体设置
font_add("Arial", "arial.ttf")
showtext_auto()
showtext_opts(dpi = 600)

# --- 核心参数 ---
max_dist_kb <- 300    # X轴最大显示距离 (kb)
y_max_limit <- 0.8    # Y轴最大显示数值

# --- 群体顺序（固定）---
breed_order <- c("Angus", "Simmental", "Charolais", "UW", "Mo-OD", "Mo-SN", "Hanwoo", "Indicine")

# --- 自定义配色（按群体命名绑定，确保颜色/图例顺序稳定）---
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
file_list <- list.files(path = work_dir, pattern = "\\.stat\\.gz$", full.names = FALSE)
if (length(file_list) == 0) stop("未找到 .stat.gz 文件")

plot_data_list <- list()
cat("正在处理数据 (0-300kb)...\n")

for (file in file_list) {
  raw_name <- str_remove(file, "\\.stat\\.gz$")
  breed_name <- ifelse(raw_name == "Bos_indicus", "Indicine", raw_name)
  
  # 只保留指定的8个群体
  if (!(breed_name %in% breed_order)) next
  
  df <- fread(file, header = TRUE)
  colnames(df)[1:2] <- c("Dist", "Mean_r2")
  
  # --- 分段处理 (保留垂直尾巴) ---
  
  # 1) 头部 (Head): 0 - 1kb，保留原始数据
  df_head <- df %>%
    filter(Dist <= 1000) %>%
    mutate(
      Dist_kb = Dist / 1000,
      Breed = breed_name
    ) %>%
    select(Dist_kb, Mean_r2, Breed)
  
  # 2) 身体 (Body): > 1kb，进行 500bp 平滑
  df_body <- df %>%
    filter(Dist > 1000 & Dist <= max_dist_kb * 1000) %>%
    mutate(
      Dist_Bin = floor(Dist / 500) * 500 + 250,
      Breed = breed_name
    ) %>%
    group_by(Breed, Dist_Bin) %>%
    summarise(Mean_r2 = mean(Mean_r2, na.rm = TRUE), .groups = "drop") %>%
    mutate(Dist_kb = Dist_Bin / 1000) %>%
    select(Dist_kb, Mean_r2, Breed)
  
  plot_data_list[[breed_name]] <- bind_rows(df_head, df_body)
}

final_data <- bind_rows(plot_data_list)

# 固定因子顺序（决定绘图顺序 + 图例顺序）
final_data$Breed <- factor(final_data$Breed, levels = breed_order)

# ==============================================================================
# 4. 绘图
# ==============================================================================
p <- ggplot(final_data, aes(x = Dist_kb, y = Mean_r2, color = Breed)) +
  geom_line(linewidth = 1.0, alpha = 0.85, lineend = "round") +
  scale_color_manual(values = custom_colors, breaks = breed_order, drop = FALSE) +
  labs(x = "Distance (kb)", y = expression(LD ~ (r^2))) +
  
  # --- X轴设置 ---
  scale_x_continuous(
    limits = c(0, max_dist_kb),
    breaks = seq(0, max_dist_kb, 50),
    expand = expansion(mult = c(0.04, 0.02))
  ) +
  
  # --- Y轴设置 ---
  scale_y_continuous(
    limits = c(0, y_max_limit),
    breaks = seq(0, y_max_limit, 0.1),
    expand = expansion(mult = c(0.04, 0.02))
  ) +
  
  # --- 主题设置 ---
  theme_classic(base_size = 14) +
  theme(
    text = element_text(family = "Arial"),
    
    # 刻度线向内：0.18 cm（负值表示向内）
    axis.ticks = element_line(linewidth = 0.8, color = "black"),
    axis.ticks.length = unit(-0.18, "cm"),
    
    # 坐标轴文字
    axis.text.x = element_text(margin = margin(t = 8), color = "black", size = 12),
    axis.text.y = element_text(margin = margin(r = 8), color = "black", size = 12),
    axis.title  = element_text(size = 14, color = "black"),
    
    # 图例
    legend.title = element_blank(),
    legend.position = c(0.85, 0.85),
    legend.background = element_rect(fill = "transparent"),
    legend.key = element_rect(fill = "transparent"),
    legend.text = element_text(size = 12),
    legend.key.width = unit(1.0, "cm"),
    
    # 边距
    plot.margin = margin(20, 20, 20, 20),
    
    # 取消默认axis线（用 annotate 自己画）
    axis.line = element_blank()
  ) +
  
  # --- 分离坐标轴绘制 ---
  annotate("segment", x = 0, xend = max_dist_kb, y = -Inf, yend = -Inf,
           linewidth = 0.8, color = "black") +
  annotate("segment", x = -Inf, xend = -Inf, y = 0, yend = y_max_limit,
           linewidth = 0.8, color = "black")

# ==============================================================================
# 5. 输出
# ==============================================================================
ggsave("LD_decay_300kb.jpg", plot = p, width = 8, height = 6, dpi = 600)
ggsave("LD_decay_300kb.tiff", plot = p, width = 8, height = 6, dpi = 600, compression = "lzw")

cat("绘图完成！范围已扩展至 300kb。\n")
