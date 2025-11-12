# ==========================
# ADMIXTURE plotting with x-axis as group names
# Uses: snp.x.Q files (x = any numeric) and structure_Q_group.txt
# structure_Q_group.txt must contain two columns: Sample and Group, tab-delimited
# ==========================

library(tidyverse)
library(RColorBrewer)
library(ggsci)

# --------- User config ----------
base_path <- "E:/桌面/武汉数据/乌珠穆沁白牛/分析结果/admixture"
setwd(base_path)

q_pattern <- "snp\\.[0-9]+\\.Q"
out_prefix <- "admixture_grouped"

# --------- 读取样本信息 ----------
if (!file.exists("structure_Q_group.txt")) stop("找不到 structure_Q_group.txt。请放在 base_path 下。")
sample_info <- read.table("structure_Q_group.txt", header = FALSE, stringsAsFactors = FALSE)
colnames(sample_info) <- c("Sample", "Group")
sample_info <- sample_info %>% filter(Sample != "")
n_samples <- nrow(sample_info)
if (n_samples == 0) stop("structure_Q_group.txt 为空或只含空行，请检查。")
original_names <- sample_info$Sample
cat("已读取", n_samples, "个样本及其群体信息\n")

# --------- 读取 Q 文件 ----------
q_files <- list.files(pattern = q_pattern)
if (length(q_files) == 0) stop("未找到任何 snp.[数字].Q 文件，请确认文件名和路径。")
q_files <- q_files[order(as.numeric(str_extract(q_files, "(?<=snp\\.)[0-9]+")))]
cat("找到 Q 文件：\n"); print(q_files)

# --------- 读取并转长格式 ----------
all_long <- list()
for (f in q_files) {
  m <- read.table(f, header = FALSE, stringsAsFactors = FALSE)
  if (nrow(m) != n_samples) stop(paste0("行数不匹配：文件 ", f))
  
  k <- ncol(m)
  colnames(m) <- paste0("Cluster", seq_len(k))
  m$Sample <- original_names
  m$Group  <- sample_info$Group
  
  long_df <- m %>%
    pivot_longer(cols = starts_with("Cluster"), names_to = "Cluster", values_to = "Proportion") %>%
    mutate(K_value = k,
           K_label = paste0("K=", k))
  
  all_long[[f]] <- long_df
}

plot_data <- bind_rows(all_long)

# --------- 设置因子 ----------
plot_data <- plot_data %>%
  mutate(Sample = factor(Sample, levels = original_names),
         K_label = factor(K_label, levels = unique(plot_data$K_label[order(plot_data$K_value)])),
         Cluster = factor(Cluster),
         Group = factor(Group, levels = unique(sample_info$Group)))

# --------- 颜色 ----------
max_clusters <- plot_data %>% group_by(K_label) %>% summarise(n = n_distinct(Cluster)) %>% pull(n) %>% max()
cluster_colors <- if (max_clusters <= 10) {
  pal_npg("nrc", alpha = 0.9)(max_clusters)
} else {
  c(pal_npg("nrc", alpha = 0.9)(10), brewer.pal(min(max_clusters - 10, 8), "Set2"))
}

# --------- 群体分隔线位置 ----------
group_breaks <- sample_info %>%
  mutate(pos = 1:n_samples) %>%
  group_by(Group) %>%
  summarise(max_pos = max(pos)) %>%
  pull(max_pos)
group_breaks <- group_breaks[-length(group_breaks)] + 0.5

# --------- 绘图 ----------
p <- ggplot(plot_data, aes(x = Sample, y = Proportion, fill = Cluster)) +
  geom_bar(stat = "identity", width = 1, color = NA) +
  facet_grid(K_label ~ ., scales = "free_y", switch = "y") +
  scale_fill_manual(values = cluster_colors) +
  scale_x_discrete(labels = sample_info$Group, expand = c(0,0)) +  # <- 显示群体名
  scale_y_continuous(expand = c(0,0)) +
  theme_minimal(base_family = "Arial") +
  theme(
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    panel.grid = element_blank(),
    strip.text.y = element_text(size = 9, face = "bold", angle = 0, hjust = 0),
    strip.background = element_blank(),
    panel.spacing = unit(4, "mm"),
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1, size = 6, color = "black"),
    axis.ticks = element_blank(),
    axis.title = element_blank(),
    legend.position = "none",
    plot.margin = unit(c(5,5,12,5), "mm")
  ) +
  coord_cartesian(ylim = c(-0.02, 1.02), clip = "off") +
  geom_vline(xintercept = group_breaks, color = "grey50", linetype = "dashed", size = 0.3)

# --------- 保存图片 ----------
k_count <- length(unique(plot_data$K_label))
fig_w_mm <- 180
fig_h_mm <- 20 * k_count + 10

dir.create("color", showWarnings = FALSE)
png_file <- file.path("color", paste0(out_prefix, ".png"))
pdf_file <- file.path("color", paste0(out_prefix, ".pdf"))

ggsave(png_file, p, width = fig_w_mm, height = fig_h_mm, units = "mm", dpi = 600)
ggsave(pdf_file, p, width = fig_w_mm, height = fig_h_mm, units = "mm", device = cairo_pdf)

cat("完成：\n PNG ->", png_file, "\n PDF ->", pdf_file, "\n")
print(p)
