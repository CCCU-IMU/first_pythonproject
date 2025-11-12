# 加载必要的 R 包
library(ape)       # 构建进化树
library(ggtree)    # 绘制进化树
library(ggplot2)   # 绘图

# 设置工作目录
setwd("E:/桌面/武汉数据/进化分析/Tree/")

# 读取距离矩阵和样本 ID
dist_mat <- as.matrix(read.table("distance_matrix.dist", header = FALSE))
sample_ids <- read.table("distance_matrix.dist.id", header = FALSE)$V1
rownames(dist_mat) <- sample_ids
colnames(dist_mat) <- sample_ids

# 构建邻接树
dist_obj <- as.dist(dist_mat)
nj_tree <- nj(dist_obj)

# 将构建的树保存为 Newick 格式的 .nwk 文件
write.tree(nj_tree, file = "NJ_tree.nwk")

# 读取分组信息
group_info <- read.table("breed_info.txt", header = FALSE, sep = "\t", stringsAsFactors = FALSE)
colnames(group_info) <- c("SampleID", "Group")

# 创建分组列表
group_list <- split(group_info$SampleID, group_info$Group)

# 将分组映射到树上
tree_grouped <- groupOTU(nj_tree, group_list)

# 手动指定颜色
group_colors <- c(
  "Bos_indicus" = "#eb493d",
  "Angus"       = "#fcb216",
  "Charolais"   = "#609a5b",
  "Hanwoo"      = "#2397b7",
  "Mo-OD"       = "#c6caf9",
  "Mo-SN"       = "#f0639f",
  "Simmental"   = "#cbc46e",
  "UW"          = "#97d4c5",
  "Yanbian"     = "#6e91cb"
)

# 绘图（无根形式），移除样本标签和叶节点点标记
p <- ggtree(tree_grouped, layout = "unrooted", aes(color = group), size = 0.5) +
  scale_color_manual(values = group_colors) +
  theme(
    legend.position = "right",
    legend.title = element_text(size = 12),
    legend.text = element_text(size = 10),
    plot.title = element_text(hjust = 0.5, face = "bold", size = 16)
  ) +
  ggtitle("Tree of Cattle Populations")

# 保存高分辨率图片
ggsave("NJ_tree_grouped.jpg", plot = p, width = 10, height = 10, dpi = 600)
