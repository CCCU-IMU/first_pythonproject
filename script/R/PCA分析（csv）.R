# ===== 必要库 =====
library(ggplot2)
library(dplyr)
library(ggrepel)
library(rlang)

# ===== 路径（用 / 更稳妥）=====
in_file <- "E:/桌面/武汉数据/乌珠穆沁白牛/12.9重跑102样本结果/result/01.Population_Structure/02.pca/PCA.matrix.csv"
out_dir <- "E:/桌面/武汉数据/乌珠穆沁白牛/12.9重跑102样本结果"
if (!file.exists(in_file)) stop("找不到输入文件：", in_file)
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ===== 读取 PCA.matrix.csv（自动判定分隔符）=====
first_line <- readLines(in_file, n = 1, warn = FALSE)
sep_guess  <- if (grepl("\t", first_line)) "\t" else ","
pca_df <- read.table(in_file, header = TRUE, sep = sep_guess,
                     stringsAsFactors = FALSE, check.names = FALSE)

# 标准化样本 ID 列名
if (!("Sample" %in% names(pca_df))) {
  if ("IID" %in% names(pca_df)) {
    pca_df$Sample <- pca_df$IID
  } else if ("FID" %in% names(pca_df)) {
    pca_df$Sample <- pca_df$FID
  } else {
    stop("PCA.matrix.csv 需要包含 Sample 或 IID/FID 列之一。")
  }
}

# ===== 解析 PC 列与解释率（列名形如 PC1 或 PC1(8.61%)）=====
pc_cols_raw <- grep("^PC[0-9]+", names(pca_df), value = TRUE)
if (length(pc_cols_raw) < 2) stop("未检测到至少两个 PC 列（PC1、PC2...）。")

pc_basename <- sub("\\(.*\\)$", "", pc_cols_raw)  # 去括号 -> PC1
pc_percent  <- ifelse(grepl("\\(", pc_cols_raw),
                      sub(".*\\(([^)]+)\\).*", "\\1", pc_cols_raw), NA_character_)
colnames(pca_df)[match(pc_cols_raw, names(pca_df))] <- pc_basename
var_explained <- setNames(pc_percent, pc_basename)  # 命名向量：PC -> "8.61%" 或 NA

# ===== Group 列处理（若无则回退 breed_info.txt）=====
if (!("Group" %in% names(pca_df))) {
  bi_file <- file.path(dirname(in_file), "breed_info.txt")
  if (!file.exists(bi_file)) stop("PCA.matrix.csv 无 Group 列，且未找到：", bi_file)
  group_info <- read.table(bi_file, header = FALSE,
                           col.names = c("IID", "Group"), stringsAsFactors = FALSE)
  pca_df <- dplyr::left_join(pca_df, group_info, by = c("Sample" = "IID"))
  if (any(is.na(pca_df$Group))) warning("有样本未匹配到 Group。")
}

# ===== 群体配色（瘤牛 & UW 固定；其余按指定方案）=====
group_colors <- c(
  "Bos_indicus" = "#E64B35E5",  # 瘤牛
  "UW"          = "#4DBBD5E5",  # UW
  "Angus"       = "#00A087E5",
  "Charolais"   = "#3C5488E5",
  "Hanwoo"      = "#F39B7FE5",
  "Mo-OD"       = "#8491B4E5",
  "Mo-SN"       = "#91D1C2E5",
  "Simmental"   = "#DC0000E5",
  "Yanbian"     = "#7E6148E5",
  "Other"       = "#B09C85E5"   # 备用：未知群体映射到此
)
unknown_groups <- setdiff(unique(pca_df$Group), names(group_colors))
if (length(unknown_groups) > 0) {
  message("未知群体将使用 'Other' 颜色：", paste(unknown_groups, collapse = ", "))
  pca_df$Group[pca_df$Group %in% unknown_groups] <- "Other"
}

# ===== 紧凑杂志风绘图函数（正方形 85 mm + 图例在框外右侧；单列但行距加大）=====
plot_pca <- function(x_pc, y_pc, file_name,
                     canvas_mm = 85,       # 正方形绘图区边长（PCA图大小）
                     legend_right_mm = 25, # 右侧图例留白
                     dpi = 300,            # BMC 建议 ~300 dpi
                     size_pt = 1.8, stroke = 0.45,
                     base_sz = 9, axis_title_sz = 9.5,
                     axis_text_sz = 8, legend_text_sz = 8,
                     breaks_n = 4) {
  
  stopifnot(x_pc %in% names(pca_df), y_pc %in% names(pca_df))
  
  x_lab <- paste0(x_pc, if (!is.na(var_explained[x_pc])) paste0(" (", var_explained[x_pc], ")"))
  y_lab <- paste0(y_pc, if (!is.na(var_explained[y_pc])) paste0(" (", var_explained[y_pc], ")"))
  
  # 轴范围：留白 10%，避免贴边
  xr <- range(pca_df[[x_pc]], na.rm = TRUE); x_pad <- diff(xr) * 0.10
  yr <- range(pca_df[[y_pc]], na.rm = TRUE); y_pad <- diff(yr) * 0.10
  x_lim <- c(min(xr[1], 0) - x_pad, max(xr[2], 0) + x_pad)
  y_lim <- c(min(yr[1], 0) - y_pad, max(yr[2], 0) + y_pad)
  
  p <- ggplot(pca_df, aes(x = !!sym(x_pc), y = !!sym(y_pc))) +
    # 彩色填充 + 白色描边的圆点
    geom_point(aes(fill = Group), shape = 21, size = size_pt,
               color = "white", stroke = stroke, alpha = 0.95) +
    # 中心虚线参考
    geom_hline(yintercept = 0, linetype = "dashed", linewidth = 0.25, color = "grey65") +
    geom_vline(xintercept = 0, linetype = "dashed", linewidth = 0.25, color = "grey65") +
    # 刻度更少
    scale_x_continuous(breaks = scales::pretty_breaks(n = breaks_n)) +
    scale_y_continuous(breaks = scales::pretty_breaks(n = breaks_n)) +
    # 手动配色 + 单列图例（行距/键高/标签留白加大）
    scale_fill_manual(
      values = group_colors,
      guide = guide_legend(
        # 单列：不写 ncol
        override.aes = list(shape = 21, size = 2.4, color = "white", stroke = stroke),
        keyheight = unit(8, "pt"),   # ← 每个图例键高度（行距主要控制器）
        keywidth  = unit(12, "pt")
      )
    ) +
    # 正方形 & 等比例坐标
    coord_fixed(ratio = 1, xlim = x_lim, ylim = y_lim, expand = FALSE) +
    # 简洁主题与更小字号
    theme_classic(base_size = base_sz, base_family = "Arial") +
    theme(
      axis.title  = element_text(size = axis_title_sz),
      axis.text   = element_text(size = axis_text_sz),
      axis.ticks.length = unit(2, "pt"),
      axis.line   = element_line(linewidth = 0.4),
      panel.border= element_rect(fill = NA, color = "black", linewidth = 0.4),
      
      # —— 图例在框外右侧，单列但更“松” —— 
      legend.position      = "right",
      legend.justification = c(0, 1),
      legend.title         = element_blank(),
      legend.text          = element_text(size = legend_text_sz,
                                          margin = margin(t = 2, b = 2)), # 标签上下留白
      legend.background    = element_blank(),
      legend.key.height    = unit(8,  "pt"),  # 与上面的 keyheight 呼应
      legend.key.width     = unit(12, "pt"),
      legend.spacing.y     = unit(6,  "pt"),  # 行间距（可调大到 8–10 pt）
      legend.spacing.x     = unit(6,  "pt"),
      
      plot.title = element_text(hjust = 0, face = "bold", size = base_sz + 1)
    ) +
    labs(title = NULL, x = x_lab, y = y_lab)
  
  # —— 保存：绘图区为正方形 85mm；总宽 = 85mm + 右侧图例留白 ——
  width_mm  <- canvas_mm + legend_right_mm
  height_mm <- canvas_mm
  
  # PNG（300dpi）
  ggsave(file.path(out_dir, sub("\\.jpg$", "_85mm.png", file_name)),
         plot = p, width = width_mm, height = height_mm,
         units = "mm", dpi = dpi)
  
  # PDF（矢量，嵌入字体/抗锯齿更好）
  ggsave(file.path(out_dir, sub("\\.jpg$", "_85mm.pdf", file_name)),
         plot = p, width = width_mm, height = height_mm,
         units = "mm", device = cairo_pdf)
}

# ===== 出图 =====
plot_pca("PC1", "PC2", "PCA_PC1_PC2_sq.jpg")
plot_pca("PC1", "PC3", "PCA_PC1_PC3_sq.jpg")
plot_pca("PC2", "PC3", "PCA_PC2_PC3_sq.jpg")
