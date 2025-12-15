# ==========================
# ADMIXTURE plotting with strict sample & group order
# ==========================

library(tidyverse)
library(RColorBrewer)
library(ggsci)

# --------- User config ----------
base_path <- "E:/桌面/武汉数据/乌珠穆沁白牛/12.9重跑102样本结果/result/01.Population_Structure/03.structure/01.Q_group"
setwd(base_path)

q_pattern <- "snp\\.[0-9]+\\.Q"               # 匹配 Q 文件
sample_txt <- "structure_Q_group.txt"         # 原始 Sample+Group 文件
out_dir <- "sorted_Q"
out_prefix <- "admixture_ordered_onlyK1-4"

# 自定义群体顺序
custom_group_order <- c("Angus","Simmental","Charolais","UW","Mo-OD","Mo-SN","Hanwoo","Bos_indicus")
dir.create(out_dir, showWarnings = FALSE)

# --------- 读取原始样本信息 ----------
if(!file.exists(sample_txt)) stop("找不到 structure_Q_group.txt")
sample_info <- read.table(sample_txt, header = FALSE, stringsAsFactors = FALSE)
colnames(sample_info) <- c("Sample", "Group")
sample_info <- sample_info %>% filter(Sample != "")

# --------- 读取 Q 文件 ----------
q_files <- list.files(pattern = q_pattern)
if(length(q_files)==0) stop("未找到 Q 文件")
q_files <- q_files[order(as.numeric(str_extract(q_files, "(?<=snp\\.)[0-9]+")))]

# --------- 按群体顺序排序样本（群体内部保持 Q 文件顺序） ----------
all_order <- c()
for(g in custom_group_order){
  tmp <- sample_info %>% filter(Group==g)
  all_order <- c(all_order, tmp$Sample)
}
sample_order <- all_order
n_samples <- length(sample_order)

# --------- 读取 Q 文件并重排 ----------
all_long <- list()
for(f in q_files){
  q <- read.table(f, header = FALSE, stringsAsFactors = FALSE)
  if(nrow(q)!=nrow(sample_info)) stop(paste0("行数不匹配: ", f))
  
  k <- ncol(q)
  
  # 按 sample_order 重排 Q 文件
  q <- q[match(sample_order, sample_info$Sample), , drop=FALSE]
  
  # 添加 Sample 和 Group
  q <- cbind(
    q,
    Sample = sample_info$Sample[match(sample_order, sample_info$Sample)],
    Group  = sample_info$Group[match(sample_order, sample_info$Sample)]
  )
  
  colnames(q)[1:k] <- paste0("Cluster", 1:k)
  
  # 转长格式
  long_df <- q %>%
    pivot_longer(
      cols = starts_with("Cluster"),
      names_to = "Cluster",
      values_to = "Proportion"
    ) %>%
    mutate(
      K_value = k,
      K_label = paste0("K=", k)
    )
  
  all_long[[f]] <- long_df
  
  # 保存排序后的 Q 文件（只保存前 k 列概率）
  out_file <- file.path(out_dir, paste0(tools::file_path_sans_ext(f), ".sorted.Q"))
  write.table(q[,1:k], out_file, row.names = FALSE, col.names = FALSE, quote = FALSE, sep = "\t")
  cat("排序完成:", f, "->", out_file, "\n")
}

# --------- 合并所有 K ----------
plot_data <- bind_rows(all_long)

# ===== 只保留 K=2 和 K=4 =====
keep_K <- c(2, 4)
plot_data <- plot_data %>%
  filter(K_value %in% keep_K) %>%
  mutate(
    K_label = factor(paste0("K=", K_value), levels = paste0("K=", keep_K))
  )

# --------- 设置因子顺序 ----------
plot_data <- plot_data %>%
  mutate(
    Sample  = factor(Sample, levels = sample_order),
    Group   = factor(Group,  levels = custom_group_order),
    Cluster = factor(Cluster),
    K_label = factor(K_label, levels = unique(plot_data$K_label[order(plot_data$K_value)]))
  )

# --------- 颜色（仅交换红与绿，其余不变） ----------
max_clusters <- plot_data %>%
  group_by(K_label) %>%
  summarise(n = n_distinct(Cluster), .groups = "drop") %>%
  pull(n) %>%
  max()

# 原始调色板：<=10 用 NPG，>10 再拼接 Set2
cluster_colors <- if (max_clusters <= 10) {
  pal_npg("nrc", alpha = 0.9)(max_clusters)
} else {
  c(
    pal_npg("nrc", alpha = 0.9)(10),
    brewer.pal(min(max_clusters - 10, 8), "Set2")
  )
}

# 命名，确保跨 K 一致：Cluster1..N 对应固定颜色
cluster_colors_named <- setNames(cluster_colors, paste0("Cluster", seq_len(length(cluster_colors))))

# 找到 NPG 的红(#E64B35*)与绿(#00A087*)并交换（匹配可能带透明度后缀）
hex_up <- toupper(cluster_colors_named)
idx_red   <- which(hex_up %in% c("#E64B35E5", "#E64B35FF", "#E64B35"))
idx_green <- which(hex_up %in% c("#00A087E5", "#00A087FF", "#00A087"))

if (length(idx_red) >= 1 && length(idx_green) >= 1) {
  ir <- idx_red[1]
  ig <- idx_green[1]
  tmp <- cluster_colors_named[ir]
  cluster_colors_named[ir] <- cluster_colors_named[ig]
  cluster_colors_named[ig] <- tmp
} else {
  message("未检测到 NPG 红/绿（可能因 >10 色主要来自 Set2）。")
}

# 让 Cluster 的 level 固定为 Cluster1..max_clusters，确保取色稳定
plot_data <- plot_data %>%
  mutate(Cluster = factor(Cluster, levels = paste0("Cluster", 1:max_clusters)))

# --------- 群体分隔线位置（基于 sample_order 重新计算，避免 UW-Mo-OD 缺线） ----------
sample_df <- tibble(
  Sample = sample_order,
  Group  = sample_info$Group[match(sample_order, sample_info$Sample)]
) %>%
  filter(!is.na(Group)) %>%           # 有 NA 说明 sample_info 中没对上，去掉
  mutate(
    Group = factor(Group, levels = custom_group_order),
    pos   = row_number()
  )

group_breaks <- sample_df %>%
  group_by(Group) %>%
  summarise(max_pos = max(pos), .groups = "drop") %>%
  arrange(Group) %>%                  # 按 custom_group_order 的 factor 顺序
  pull(max_pos)

if (length(group_breaks) > 1) {
  group_breaks <- group_breaks[-length(group_breaks)] + 0.5
} else {
  group_breaks <- numeric(0)
}

# --------- 绘图 ----------
p <- ggplot(plot_data, aes(x = Sample, y = Proportion, fill = Cluster)) +
  geom_bar(stat="identity", width=1, color=NA) +
  facet_grid(K_label ~ ., scales = "free_y", switch = "y") +
  scale_fill_manual(values = cluster_colors_named) +
  scale_x_discrete(
    labels = plot_data$Group[!duplicated(plot_data$Sample)],
    expand = c(0,0)
  ) +
  scale_y_continuous(expand = c(0,0)) +
  theme_minimal(base_family="Arial") +
  theme(
    plot.background   = element_rect(fill="white", color=NA),
    panel.background  = element_rect(fill="white", color=NA),
    panel.grid        = element_blank(),
    strip.text.y      = element_text(size=9, face="bold", angle=0, hjust=0),
    strip.background  = element_blank(),
    panel.spacing     = unit(4, "mm"),
    axis.text.x       = element_text(angle=90, vjust=0.5, hjust=1, size=6, color="black"),
    axis.ticks        = element_blank(),
    axis.title        = element_blank(),
    legend.position   = "none",
    plot.margin       = unit(c(5,5,12,5), "mm")
  ) +
  coord_cartesian(ylim = c(-0.02, 1.02), clip = "off") +
  geom_vline(
    xintercept = group_breaks,
    color      = "grey50",
    linetype   = "dashed",
    size       = 0.3
  )

# --------- 保存图片（只含 K=1 和 K=4） ----------
k_count  <- nlevels(plot_data$K_label)  # =2
row_h_mm <- 30                          # 每行高度
fig_w_mm <- 180                         # 图宽
fig_h_mm <- row_h_mm * k_count + 10     # 总高度

dir.create("color", showWarnings = FALSE)
png_file <- file.path("color", paste0(out_prefix, "_K1-K4.png"))
pdf_file <- file.path("color", paste0(out_prefix, "_K1-K4.pdf"))

ggsave(png_file, p, width = fig_w_mm, height = fig_h_mm, units = "mm", dpi = 600)
ggsave(pdf_file, p, width = fig_w_mm, height = fig_h_mm, units = "mm", device = cairo_pdf)

cat("完成：\n PNG ->", png_file, "\n PDF ->", pdf_file, "\n")
print(p)
