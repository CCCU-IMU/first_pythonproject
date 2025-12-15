## ===============================================
## 多片段 → 多个汇总点（斜线连向各自簇中心）的完整脚本
## ===============================================

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(scales)
})

## ========= 1) 读入数据（修改为你的真实路径） =========
## 需要的列：Chr, Start, End, Ancestry, Frequency
dt <- fread("E:/桌面/武汉数据/乌珠穆沁白牛/10-24祖先比例/result/05.loter/loter_segment.txt")

## 基本检查
req_cols <- c("Chr","Start","End","Ancestry","Frequency")
miss <- setdiff(req_cols, names(dt))
if (length(miss)) stop("缺少必要列：", paste(miss, collapse = ", "))

## ========= 2) 基础派生列 =========
## 提取染色体数字，例如 "chr1" -> 1
dt[, chr_num := as.integer(gsub("^chr", "", Chr))]
if (any(is.na(dt$chr_num))) {
  stop("chr_num 中存在 NA，请检查 Chr 是否形如 'chr1', 'chr2', ...")
}

## 片段中点与长度
dt[, mid_pos := (Start + End) / 2]
dt[, seg_len := pmax(End - Start, 0)]

## 每条染色体的“高度”
chr_len <- dt[, .(chr_len = max(End, na.rm = TRUE)), by = .(Chr, chr_num)]

## 染色体“底图”参数（越小越窄）
w_chr <- 0.5
bg <- chr_len[, .(
  chr_num = chr_num,
  xmin = chr_num - w_chr/2,
  xmax = chr_num + w_chr/2,
  ymin = 0,
  ymax = chr_len
)]

## ========= 3) 多点汇总：1D gap 聚类 =========
## 思路：在同一 Chr × Ancestry 内，先按 Start 排序；
## 若当前片段与上一个片段的间隔 > gap_bp（如 5 Mb），则新开一个簇，否则归入同一簇。
## 这个规则能把相近的片段“汇成一个点”，距离远的则分成多个点。
gap_bp <- 5e6   # ← 你可以改：比如 2e6（更细）、1e7（更粗）

setorder(dt, chr_num, Ancestry, Start)
dt[, lag_end := shift(End, type = "lag"), by = .(Chr, chr_num, Ancestry)]
dt[, new_cluster := fifelse(is.na(lag_end) | (Start - lag_end) > gap_bp, 1L, 0L)]
dt[, cluster_id := 1L + cumsum(new_cluster) - new_cluster, by = .(Chr, chr_num, Ancestry)]
dt[, c("lag_end","new_cluster") := NULL]

## 现在：同一 Chr × Ancestry × cluster_id 就是一簇

## ========= 4) 计算每个簇的代表点（长度加权中点） =========
point_dt <- dt[
  , .(y_point = if (sum(seg_len, na.rm = TRUE) > 0)
    weighted.mean(mid_pos, w = seg_len, na.rm = TRUE)
    else
      mean(mid_pos, na.rm = TRUE)),
  by = .(Chr, chr_num, Ancestry, cluster_id)
]

## 合并回片段数据，方便画“来源斜线”
dt_seg <- merge(dt, point_dt, by = c("Chr","chr_num","Ancestry","cluster_id"), all.x = TRUE)

## ========= 5) 显示样式：祖先的形状/颜色、右侧点的横向错位 =========
## 设定 Ancestry 顺序（按数据实际可调整/删除）
ancestry_levels <- sort(unique(dt$Ancestry))
dt[, Ancestry := factor(Ancestry, levels = ancestry_levels)]
point_dt[, Ancestry := factor(Ancestry, levels = ancestry_levels)]
dt_seg[, Ancestry := factor(Ancestry, levels = ancestry_levels)]

## 已知两类的映射；若类别更多，下面会自动扩展
base_shape_map <- c("Mo-OD" = 17, "Charolais" = 19)
base_color_map <- c("Mo-OD" = "#6A51A3", "Charolais" = "#007C73")

## 自动补全额外祖先类别的形状/颜色
extra_lv <- setdiff(ancestry_levels, names(base_shape_map))
if (length(extra_lv)) {
  spare_shapes <- setdiff(c(15,16,17,18,19,7,8,0,1,2), unname(base_shape_map))
  base_shape_map <- c(base_shape_map, setNames(head(spare_shapes, length(extra_lv)), extra_lv))
}
extra_lv_col <- setdiff(ancestry_levels, names(base_color_map))
if (length(extra_lv_col)) {
  spare_cols <- c("#1f77b4","#ff7f0e","#2ca02c","#d62728",
                  "#9467bd","#8c564b","#e377c2","#7f7f7f",
                  "#bcbd22","#17becf")
  base_color_map <- c(base_color_map, setNames(head(spare_cols, length(extra_lv_col)), extra_lv_col))
}

## 给不同祖先一个稳定的小横向偏移，减少右侧点重叠
off_tbl <- data.table(
  Ancestry = ancestry_levels,
  x_off = seq(-0.035, 0.035, length.out = length(ancestry_levels))
)
point_dt <- merge(point_dt, off_tbl, by = "Ancestry", all.x = TRUE)
dt_seg   <- merge(dt_seg,   off_tbl, by = "Ancestry", all.x = TRUE)

## 右侧点的基准 x（越大越靠右，线更拉开）
x_point_base <- 0.60

## ========= 6) 作图 =========
p <- ggplot() +
  ## (1) 染色体背景
  geom_rect(
    data = bg,
    aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
    fill   = "white",
    colour = "grey60",
    linewidth = 0.3
  ) +
  
  ## (2) 染色体内部片段（频率填色）
  geom_rect(
    data = dt_seg,
    aes(xmin = chr_num - w_chr/2, xmax = chr_num + w_chr/2,
        ymin = Start,             ymax = End,
        fill = Frequency),
    colour = NA
  ) +
  
  ## (3) 来源斜线：每个片段 → 其簇代表点
  geom_segment(
    data = dt_seg,
    aes(x    = chr_num + w_chr/2,                   # 染色体右缘
        xend = chr_num + x_point_base + x_off,      # 右侧簇点
        y    = mid_pos,                             # 片段中点
        yend = y_point,                             # 簇代表点
        colour = Ancestry),
    linewidth = 0.18,
    alpha = 0.28
  ) +
  
  ## (4) 右侧簇代表点（每簇 1 个；== 每 Chr×Ancestry×cluster_id 1 个）
  ##     先画白底点做 halo，再画彩色点压住线
  geom_point(
    data = point_dt,
    aes(x = chr_num + x_point_base + x_off, y = y_point),
    size = 4.0,
    colour = "white",
    stroke = 0
  ) +
  geom_point(
    data = point_dt,
    aes(x = chr_num + x_point_base + x_off,
        y = y_point,
        shape  = Ancestry,
        colour = Ancestry),
    size = 3.2,
    stroke = 0.6
  ) +
  
  ## (5) 频率渐变（按需调整范围）
  scale_fill_gradientn(
    colours = c("#007C73", "#6A51A3"),
    limits  = c(0.6, 1.0),
    oob     = squish,
    name    = "Frequency"
  ) +
  
  ## (6) 祖先图例
  scale_shape_manual(values = base_shape_map, name = NULL) +
  scale_colour_manual(values = base_color_map, name = NULL) +
  
  ## (7) x 轴（右边留出点/线空间）
  scale_x_continuous(
    breaks = chr_len$chr_num,
    labels = chr_len$chr_num,
    limits = c(
      min(chr_len$chr_num, na.rm = TRUE) - 0.5,
      max(chr_len$chr_num, na.rm = TRUE) + 1.0
    ),
    expand = c(0, 0)
  ) +
  
  labs(
    x = "Bos taurus autosome",
    y = "Genomic position (bp)"
  ) +
  
  theme_bw() +
  theme(
    panel.grid       = element_blank(),
    axis.text.x      = element_text(size = 8),
    axis.text.y      = element_text(size = 8),
    legend.position  = c(0.84, 0.90),
    legend.direction = "vertical",
    legend.background = element_blank()
  )

print(p)

## 可选：保存
## ggsave("loter_chr_multi_summary_points.pdf", p, width = 9, height = 5.5)
