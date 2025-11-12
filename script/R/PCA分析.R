# 加载必要的库
library(ggplot2)
library(dplyr)
library(ggrepel)
library(rlang)  # 用于 tidy evaluation

# 读取 PCA 结果
pca <- read.table("pca.eigenvec", header = FALSE)
colnames(pca) <- c("FID", "IID", paste0("PC", 1:(ncol(pca) - 2)))

# 读取特征值
eigenval <- scan("pca.eigenval")
total_var <- sum(eigenval)

# 读取群体信息
# breed_info.txt 文件格式：两列，没有表头，第一列为 IID，第二列为 Group
group_info <- read.table("breed_info.txt", header = FALSE, col.names = c("IID", "Group"))
pca_merged <- merge(pca, group_info, by = "IID")

# 自定义颜色（瘤牛固定为红色，其它按需要分配颜色）
custom_colors <- c(
  "Bos_indicus" = "#eb493d",
  "Angus" = "#fcb216",
  "Charolais" = "#609a5b",
  "Hanwoo" = "#2397b7",
  "Mo-OD" = "#c6caf9",
  "Mo-SN" = "#f0639f",
  "Simmental" = "#cbc46e",
  "UW" = "#97d4c5",
  "Yanbian" = "#6e91cb"
)

# 定义一个绘图函数，生成指定两个主成分的图，并保存为高分辨率图片
plot_pca <- function(x_pc, y_pc, file_name) {
  # 根据 PC 编号计算解释率百分比
  x_index <- as.numeric(gsub("PC", "", x_pc))
  y_index <- as.numeric(gsub("PC", "", y_pc))
  x_var <- round(eigenval[x_index] / total_var * 100, 2)
  y_var <- round(eigenval[y_index] / total_var * 100, 2)
  
  # 计算每个群体的中心点，便于后续放置群体标签
  centroids <- pca_merged %>%
    group_by(Group) %>%
    summarize(x = mean(.data[[x_pc]]), y = mean(.data[[y_pc]]), .groups = "drop")
  
  p <- ggplot(pca_merged, aes(x = !!sym(x_pc), y = !!sym(y_pc), color = Group)) +
    geom_point(size = 2.2, alpha = 0.9) +
    geom_text_repel(
      data = centroids,
      mapping = aes(x = x, y = y, label = Group),
      size = 3.2,
      family = "Arial",
      fontface = "plain",
      segment.size = 0.2,
      box.padding = 0.3,
      point.padding = 0.3,
      max.overlaps = 10,
      color = "black"
    ) +
    scale_color_manual(values = custom_colors) +
    theme_minimal(base_size = 12) +
    theme(
      legend.title = element_text(size = 11),
      legend.text = element_text(size = 10),
      plot.title = element_text(hjust = 0.5, face = "bold", size = 14)
    ) +
    labs(
      title = paste("PCA of Cattle Populations (", x_pc, " vs ", y_pc, ")", sep = ""),
      x = paste0(x_pc, " (", x_var, "%)"),
      y = paste0(y_pc, " (", y_var, "%)"),
      color = "Breed"
    )
  
  ggsave(filename = file_name, plot = p, width = 6, height = 6, dpi = 600)
}

# 分别生成三个图
plot_pca("PC1", "PC2", "PCA_PC1_PC2_highres.jpg")
plot_pca("PC1", "PC3", "PCA_PC1_PC3_highres.jpg")
plot_pca("PC2", "PC3", "PCA_PC2_PC3_highres.jpg")
