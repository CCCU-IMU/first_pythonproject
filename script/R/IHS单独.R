# iHS track plot (columns) + genome-wide baseline from *.norm
# - Same framework: box border, no grid, Arial, band shading
# - Y axis: 0–100% range, ticks shown only 0–80%
# - Bars color: #5BCB3A
# - Baseline: genome-wide q95 of window proportion(|iHS|>2), with Nsnp filter
# - Export: PDF + PNG + TIFF (LZW, 600 dpi)
# ============================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(ggplot2)
  library(grid)
})

# ============================================================
# 1) CONFIG BLOCK (以后只改这里)
# ============================================================

# ---- A) .norm 文件所在目录（每条染色体一个 .norm）----
norm_dir <- "E:/桌面/武汉数据/乌珠穆沁白牛/单倍型分析1224/result/01.iHS/chr_iHS/"
norm_pattern <- "\\.norm$"   # 匹配 .norm 结尾

# ---- B) 候选区窗口文件（chr/start/value/Nsnp）----
use_window_file <- TRUE
ihs_window_file <- "E:/桌面/武汉数据/乌珠穆沁白牛/单倍型分析1224/result/01.iHS/iHS_plot/GDF11.plot.txt"

# ---- C) 输出目录 ----
out_dir <- "E:/桌面/武汉数据/乌珠穆沁白牛/文章图汇总/测试"

# ---- D) 区间与阴影（bp）----
chrom_to_plot <- "chr5"
x_min <- 57005355
x_max <- 58012998
band_start <- 57405355
band_end   <- 57612998

# ---- E) iHS 阈值 ----
ihs_thr <- 2

window_size <- 50000   # 50kb window
window_step <- 20000   # 20kb step

# ---- F) 基准线设置（推荐 q=0.95 更像文献；觉得太低可改 0.99）----
baseline_q <- 0.95
min_nsnp_for_baseline <- 20  # 过滤掉SNP太少窗口，避免分位数离谱

# ---- G) 输出文件名前缀 ----
out_prefix <- "GDF11_iHS_hist"

# ---- H) 图形尺寸（英寸）----
fig_w <- 8.2
fig_h <- 1.5

# ---- I) 是否显示为百分比（建议 TRUE）----
use_percent <- TRUE

# ============================================================
# 2) Devices availability
# ============================================================
has_pkg <- function(pkg) requireNamespace(pkg, quietly = TRUE)
use_cairo <- has_pkg("Cairo")
use_ragg  <- has_pkg("ragg")

# ============================================================
# 3) Colors
# ============================================================
COL_MAIN  <- "#bf3826"   # bars
COL_BAND  <- "#FFF1D6"   # shading
COL_COCOA <- "#4B5563"   # border/axis
COL_BASE  <- "#6B7280"   # baseline line

# ============================================================
# 4) Helpers
# ============================================================

# 从文件名提取 chr：ihs_chr1.ihs.out.100bins.norm -> chr1
get_chr_from_fname <- function(f) {
  bn <- basename(f)
  m <- regmatches(bn, regexpr("chr[0-9XYM]+", bn, ignore.case = TRUE))
  if (length(m) == 0 || nchar(m) == 0) return(NA_character_)
  m <- tolower(m)
  if (!startsWith(m, "chr")) m <- paste0("chr", m)
  m
}

# 读取单个 .norm（无表头）
# 你的格式：X2=POS, X7=iHS_norm（标准化后均值~0 sd~1）
read_norm_one <- function(f) {
  chr <- get_chr_from_fname(f)
  if (is.na(chr)) stop("Cannot parse chr from filename: ", basename(f))
  
  df <- read_tsv(f, col_names = FALSE, show_col_types = FALSE, progress = FALSE)
  if (ncol(df) < 7) stop("Unexpected norm format (need >=7 columns): ", basename(f))
  
  df %>%
    transmute(
      CHR = chr,
      POS = as.numeric(X2),
      iHS_norm = as.numeric(X7)
    ) %>%
    filter(!is.na(POS), !is.na(iHS_norm))
}

# Mb axis breaks
mb_breaks <- function(lim_bp) pretty(lim_bp / 1e6, n = 6) * 1e6

# ============================================================
# 5) Read window file (for plotting) + detect window_step
# ============================================================
if (use_window_file) {
  dfw <- read_tsv(ihs_window_file, show_col_types = FALSE, progress = FALSE)
  need <- c("chr", "start", "value", "Nsnp")
  miss <- setdiff(need, names(dfw))
  if (length(miss) > 0) stop("Missing columns in ihs_window_file: ", paste(miss, collapse = ", "))
  
  # 自动识别窗口步长（用全文件的start差值中位数）
  s_all <- sort(unique(as.numeric(dfw$start)))
  window_step <- as.numeric(median(diff(s_all), na.rm = TRUE))
  if (!is.finite(window_step) || window_step <= 0) window_step <- 20000
  message("Detected window_step from plot file: ", window_step, " bp")
  
  dat <- dfw %>%
    mutate(
      chr = as.character(chr),
      start = as.numeric(start),
      value = as.numeric(value),
      Nsnp = as.numeric(Nsnp),
      y = if (use_percent) value * 100 else value
    ) %>%
    filter(chr == chrom_to_plot, start >= x_min, start <= x_max) %>%
    arrange(start)
  
  if (nrow(dat) == 0) stop("No rows after filtering window file. Check chrom/range.")
} else {
  # 如果你没有窗口文件，也可以从 .norm 里算候选区窗口；但这里先要求 window_step 手动设置
  window_step <- 20000
}

# ============================================================
# 6) Compute genome-wide baseline from all .norm files (same window_step)
# ============================================================
# ---- sliding-window summarise: 50k window + 20k step ----
summarise_sliding_windows <- function(pos, score, window_size, window_step, thr = 2) {
  o <- order(pos)
  pos <- pos[o]
  flag <- abs(score[o]) > thr
  
  # 以 1 为起点的滑窗（与你常见流程一致）
  max_pos <- max(pos, na.rm = TRUE)
  starts <- seq(1, max_pos - window_size + 1, by = window_step)
  ends <- starts + window_size - 1L
  
  # 用 findInterval 快速得到每个窗的左右索引
  right <- findInterval(ends, pos)                 # <= end 的最后一个索引
  left  <- findInterval(starts - 1L, pos) + 1L     # >= start 的第一个索引
  
  nsnp <- right - left + 1L
  nsnp[nsnp < 0] <- 0L
  
  cs <- cumsum(flag)
  get_cs <- function(i) ifelse(i > 0, cs[i], 0)
  extreme <- ifelse(nsnp == 0, 0, get_cs(right) - get_cs(left - 1L))
  
  prop <- ifelse(nsnp == 0, NA_real_, extreme / nsnp)
  
  data.frame(
    WIN_START = starts,
    Nsnp = nsnp,
    prop = prop
  )
}

# ---- read all norm ----
norm_files <- list.files(norm_dir, pattern = norm_pattern, full.names = TRUE)
if (length(norm_files) == 0) stop("No *.norm files found in norm_dir: ", norm_dir)
message("Reading norm files: ", length(norm_files))

norm_list <- lapply(norm_files, read_norm_one)

# ---- per chr sliding windows ----
norm_win <- bind_rows(lapply(norm_list, function(df) {
  df <- df %>% filter(!is.na(POS), !is.na(iHS_norm))
  if (nrow(df) == 0) return(NULL)
  chr <- unique(df$CHR)[1]
  w <- summarise_sliding_windows(df$POS, df$iHS_norm,
                                 window_size = window_size,
                                 window_step = window_step,
                                 thr = ihs_thr)
  w$CHR <- chr
  w
})) %>%
  filter(!is.na(prop)) %>%
  filter(Nsnp >= min_nsnp_for_baseline)

if (nrow(norm_win) == 0) stop("No windows left after Nsnp filter. Lower min_nsnp_for_baseline.")

bg_mean <- mean(norm_win$prop, na.rm = TRUE)
q95     <- as.numeric(quantile(norm_win$prop, probs = 0.95, na.rm = TRUE))
q99     <- as.numeric(quantile(norm_win$prop, probs = 0.99, na.rm = TRUE))

baseline_prop <- as.numeric(quantile(norm_win$prop, probs = baseline_q, na.rm = TRUE))
baseline_y <- baseline_prop * 100

message(sprintf(
  "Baseline windows (50k/20k, Nsnp>=%d): mean=%.2f%%, q95=%.2f%%, q99=%.2f%%; using q=%.3f -> %.2f%%",
  min_nsnp_for_baseline, bg_mean*100, q95*100, q99*100, baseline_q, baseline_y
))


# ============================================================
# 7) Theme (same framework)
# ============================================================
theme_clean_arial <- theme_classic(base_size = 10, base_family = "Arial") +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(colour = COL_COCOA, fill = NA, linewidth = 0.8),
    axis.line = element_blank(),
    axis.ticks = element_line(linewidth = 0.6, colour = COL_COCOA),
    axis.ticks.length = unit(2.2, "pt"),
    axis.text = element_text(colour = COL_COCOA, size = 9),
    axis.title = element_text(colour = COL_COCOA, size = 10),
    plot.margin = margin(4, 6, 3, 6),
    legend.position = "none"
  )

# ============================================================
# 8) Plot
# ============================================================
y_label <- paste0("Proportion of SNPs with |iHS| > ", ihs_thr, " (%)")

# 柱宽：按窗口步长
w <- window_step

p <- ggplot(dat, aes(x = start, y = y)) +
  annotate("rect",
           xmin = band_start, xmax = band_end,
           ymin = -Inf, ymax = Inf,
           fill = COL_BAND, alpha = 0.55) +
  geom_col(width = w * 0.95, fill = COL_MAIN, alpha = 0.95) +
  geom_hline(yintercept = baseline_y, linetype = "dashed", linewidth = 0.6, colour = COL_BASE) +
  coord_cartesian(xlim = c(x_min, x_max), ylim = c(0, 100)) +
  scale_y_continuous(
    breaks = c(0, 20, 40, 60, 80),
    labels = function(x) ifelse(x %in% c(0, 80), paste0(x, "%"), ""),
    expand = expansion(mult = c(0, 0.02))
  ) +
  scale_x_continuous(
    breaks = mb_breaks(c(x_min, x_max)),
    labels = function(x) sprintf("%.2f", x / 1e6)
  ) +
  labs(x = NULL, y = y_label) +
  theme_clean_arial

# ============================================================
# 9) Save (PDF + PNG + TIFF)
# ============================================================
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

pdf_path  <- file.path(out_dir, paste0(out_prefix, ".pdf"))
png_path  <- file.path(out_dir, paste0(out_prefix, ".png"))
tiff_path <- file.path(out_dir, paste0(out_prefix, ".tiff"))

if (use_cairo) {
  Cairo::CairoPDF(file = pdf_path, width = fig_w, height = fig_h, family = "Arial")
  print(p); dev.off()
} else {
  ggsave(pdf_path, plot = p, width = fig_w, height = fig_h, device = "pdf")
}

if (use_ragg) {
  ggsave(png_path, plot = p, width = fig_w, height = fig_h, dpi = 600, device = ragg::agg_png)
  ggsave(tiff_path, plot = p, width = fig_w, height = fig_h, dpi = 600,
         device = ragg::agg_tiff, compression = "lzw")
} else {
  ggsave(png_path, plot = p, width = fig_w, height = fig_h, dpi = 600)
  ggsave(tiff_path, plot = p, width = fig_w, height = fig_h, dpi = 600,
         device = "tiff", compression = "lzw")
}

message("Done! Saved:\n  ", pdf_path, "\n  ", png_path, "\n  ", tiff_path)