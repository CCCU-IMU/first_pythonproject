# ============================================================
# Batch iHS track plot (per gene) from 分析区间.xlsx  —— 每个基因只读自己的 plot 文件
# - xlsx: ±0.5 Mb 区间 -> analysis window; ±0.1 Mb 区间 -> shading band
# - FOR EACH GENE:
#     1) auto find iHS_plot_dir/<GENE>.plot.txt   (strict first, then fuzzy)
#     2) read that ONE file only (avoid mixing sources)
#     3) detect window_step from that file
# - genome-wide baseline from *.norm (same logic as your single-gene script)
# - export PDF + PNG + TIFF (LZW, 600 dpi)
# ============================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(ggplot2)
  library(grid)
  library(readxl)
})

# ============================================================
# 1) 固定路径
# ============================================================
norm_dir <- "E:/桌面/武汉数据/乌珠穆沁白牛/单倍型分析1224/result/01.iHS/chr_iHS/"
norm_pattern <- "\\.norm$"

ihs_plot_dir <- "E:/桌面/武汉数据/乌珠穆沁白牛/单倍型分析1224/result/01.iHS/iHS_plot/"
plot_pattern <- "\\.plot\\.txt$"

out_dir <- "E:/桌面/武汉数据/乌珠穆沁白牛/文章图汇总/测试"
interval_xlsx <- file.path(out_dir, "分析区间.xlsx")

ihs_thr <- 2
window_size <- 50000
window_step_default <- 20000

baseline_q <- 0.95
min_nsnp_for_baseline <- 20

fig_w <- 8.2
fig_h <- 1.5
use_percent <- TRUE

batch_folder_name <- "iHS_batch_from_分析区间"

# ============================================================
# 2) Devices availability
# ============================================================
has_pkg <- function(pkg) requireNamespace(pkg, quietly = TRUE)
use_cairo <- has_pkg("Cairo")
use_ragg  <- has_pkg("ragg")

# ============================================================
# 3) Colors
# ============================================================
COL_MAIN  <- "#DA2224"
COL_BAND  <- "#E9ECFB"
COL_COCOA <- "#4B5563"
COL_BASE  <- "#6B7280"

# ============================================================
# 4) Helpers
# ============================================================
get_chr_from_fname <- function(f) {
  bn <- basename(f)
  m <- regmatches(bn, regexpr("chr[0-9XYM]+", bn, ignore.case = TRUE))
  if (length(m) == 0 || nchar(m) == 0) return(NA_character_)
  m <- tolower(m)
  if (!startsWith(m, "chr")) m <- paste0("chr", m)
  m
}

read_norm_one <- function(f) {
  chr <- get_chr_from_fname(f)
  if (is.na(chr)) stop("Cannot parse chr from filename: ", basename(f))
  
  df <- read_tsv(f, col_names = FALSE, show_col_types = FALSE, progress = FALSE)
  if (ncol(df) < 7) stop("Unexpected norm format (need >=7 columns): ", basename(f))
  
  df %>%
    dplyr::transmute(
      CHR = chr,
      POS = as.numeric(X2),
      iHS_norm = as.numeric(X7)
    ) %>%
    dplyr::filter(!is.na(POS), !is.na(iHS_norm))
}

mb_breaks <- function(lim_bp) pretty(lim_bp / 1e6, n = 6) * 1e6

parse_bp_range <- function(x) {
  x <- as.character(x)
  x <- gsub(",", "", x)
  x <- gsub("\\s+", "", x)
  parts <- unlist(strsplit(x, "[–—-]", perl = TRUE))
  if (length(parts) < 2) return(c(NA_real_, NA_real_))
  v1 <- suppressWarnings(as.numeric(parts[1]))
  v2 <- suppressWarnings(as.numeric(parts[2]))
  c(v1, v2)
}

safe_name <- function(x) {
  x <- as.character(x)
  gsub("[^A-Za-z0-9_\\-]+", "_", x)
}

pick_plot_file <- function(gene, plot_dir) {
  gene <- as.character(gene)
  all_files <- list.files(plot_dir, pattern = "\\.plot\\.txt$", full.names = TRUE)
  if (length(all_files) == 0) return(NA_character_)
  bn <- basename(all_files)
  
  idx1 <- which(tolower(bn) == tolower(paste0(gene, ".plot.txt")))
  if (length(idx1) >= 1) return(all_files[idx1[1]])
  
  esc_gene <- gsub("([\\.^$|()\\[\\]{}*+?\\\\-])", "\\\\\\1", gene)
  idx2 <- grep(paste0("^", esc_gene, ".*\\.plot\\.txt$"), bn, ignore.case = TRUE)
  if (length(idx2) >= 1) return(all_files[idx2[1]])
  
  idx3 <- grep(gene, bn, ignore.case = TRUE)
  if (length(idx3) >= 1) return(all_files[idx3[1]])
  
  NA_character_
}

# ---- unified axis + wrapped title helpers ----
wrap_y_title <- function(x, width = 18) {
  paste(strwrap(as.character(x), width = width), collapse = "\n")
}

label_only_0_80_percent <- function(x) {
  ifelse(x %in% c(0, 80), paste0(x, "%"), "")
}

# ============================================================
# 5) Read regions from Excel
# ============================================================
if (!file.exists(interval_xlsx)) stop("找不到 Excel：", interval_xlsx)

dfi <- readxl::read_excel(interval_xlsx)
need_cols <- c("基因名（GENE）", "染色体", "±0.5 Mb 区间", "±0.1 Mb 区间")
miss <- setdiff(need_cols, names(dfi))
if (length(miss) > 0) stop("Excel 缺列：", paste(miss, collapse = ", "))

regions <- dfi %>%
  dplyr::transmute(
    gene = as.character(`基因名（GENE）`),
    chrom = as.character(`染色体`),
    rng_0p5 = as.character(`±0.5 Mb 区间`),
    rng_0p1 = as.character(`±0.1 Mb 区间`)
  ) %>%
  dplyr::rowwise() %>%
  dplyr::mutate(
    x_min0 = parse_bp_range(rng_0p5)[1],
    x_max0 = parse_bp_range(rng_0p5)[2],
    band_start0 = parse_bp_range(rng_0p1)[1],
    band_end0   = parse_bp_range(rng_0p1)[2]
  ) %>%
  dplyr::ungroup() %>%
  dplyr::filter(!is.na(gene), !is.na(chrom), !is.na(x_min0), !is.na(x_max0)) %>%
  dplyr::mutate(
    x_min = pmin(x_min0, x_max0, na.rm = TRUE),
    x_max = pmax(x_min0, x_max0, na.rm = TRUE),
    band_start = pmin(band_start0, band_end0, na.rm = TRUE),
    band_end   = pmax(band_start0, band_end0, na.rm = TRUE)
  ) %>%
  dplyr::select(gene, chrom, x_min, x_max, band_start, band_end)

message("Excel regions loaded: ", nrow(regions))

# ============================================================
# 6) baseline helpers
# ============================================================
summarise_sliding_windows <- function(pos, score, window_size, window_step, thr = 2) {
  o <- order(pos)
  pos <- pos[o]
  flag <- abs(score[o]) > thr
  
  max_pos <- max(pos, na.rm = TRUE)
  starts <- seq(1, max_pos - window_size + 1, by = window_step)
  ends <- starts + window_size - 1L
  
  right <- findInterval(ends, pos)
  left  <- findInterval(starts - 1L, pos) + 1L
  
  nsnp <- right - left + 1L
  nsnp[nsnp < 0] <- 0L
  
  cs <- cumsum(flag)
  get_cs <- function(i) ifelse(i > 0, cs[i], 0)
  extreme <- ifelse(nsnp == 0, 0, get_cs(right) - get_cs(left - 1L))
  
  prop <- ifelse(nsnp == 0, NA_real_, extreme / nsnp)
  data.frame(WIN_START = starts, Nsnp = nsnp, prop = prop)
}

norm_files <- list.files(norm_dir, pattern = norm_pattern, full.names = TRUE)
if (length(norm_files) == 0) stop("No *.norm files found in norm_dir: ", norm_dir)
message("Reading norm files: ", length(norm_files))
norm_list <- lapply(norm_files, read_norm_one)

compute_baseline_y <- function(window_step) {
  norm_win <- dplyr::bind_rows(lapply(norm_list, function(df) {
    df <- df %>% dplyr::filter(!is.na(POS), !is.na(iHS_norm))
    if (nrow(df) == 0) return(NULL)
    chr <- unique(df$CHR)[1]
    w <- summarise_sliding_windows(df$POS, df$iHS_norm,
                                   window_size = window_size,
                                   window_step = window_step,
                                   thr = ihs_thr)
    w$CHR <- chr
    w
  })) %>%
    dplyr::filter(!is.na(prop)) %>%
    dplyr::filter(Nsnp >= min_nsnp_for_baseline)
  
  if (nrow(norm_win) == 0) return(NA_real_)
  as.numeric(stats::quantile(norm_win$prop, probs = baseline_q, na.rm = TRUE)) * 100
}

# ============================================================
# 7) Theme (统一向内刻度 + 左边距加大 + y标题可换行)
# ============================================================
theme_clean_arial <- theme_classic(base_size = 10, base_family = "Arial") +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(colour = COL_COCOA, fill = NA, linewidth = 0.8),
    axis.line = element_blank(),
    
    axis.ticks = element_line(linewidth = 0.6, colour = COL_COCOA),
    axis.ticks.length = unit(-2.2, "pt"),  # 向内
    
    axis.text = element_text(colour = COL_COCOA, size = 9),
    axis.text.y = element_text(vjust = 0.2),
    
    axis.title = element_text(colour = COL_COCOA, size = 10),
    axis.title.y = element_text(lineheight = 0.95, margin = margin(r = 6)),
    
    plot.margin = margin(4, 6, 3, 10),
    legend.position = "none"
  )

y_label_raw <- paste0("Proportion of SNPs with |iHS| > ", ihs_thr, " (%)")
y_label <- wrap_y_title(y_label_raw, width = 18)

# ============================================================
# 8) Batch plot + save
# ============================================================
batch_out_dir <- file.path(out_dir, batch_folder_name)
if (!dir.exists(batch_out_dir)) dir.create(batch_out_dir, recursive = TRUE)

for (i in seq_len(nrow(regions))) {
  gene_i <- regions$gene[i]
  chrom_to_plot <- regions$chrom[i]
  x_min <- regions$x_min[i]
  x_max <- regions$x_max[i]
  band_start <- regions$band_start[i]
  band_end   <- regions$band_end[i]
  
  plot_file <- pick_plot_file(gene_i, ihs_plot_dir)
  if (is.na(plot_file) || !file.exists(plot_file)) {
    warning("Skip (no plot file matched): gene=", gene_i)
    next
  }
  
  dfw <- read_tsv(plot_file, show_col_types = FALSE, progress = FALSE)
  need <- c("chr", "start", "value", "Nsnp")
  miss2 <- setdiff(need, names(dfw))
  if (length(miss2) > 0) {
    warning("Skip (missing columns): ", basename(plot_file), " missing=", paste(miss2, collapse = ", "))
    next
  }
  
  s_all <- sort(unique(as.numeric(dfw$start)))
  window_step <- as.numeric(median(diff(s_all), na.rm = TRUE))
  if (!is.finite(window_step) || window_step <= 0) window_step <- window_step_default
  
  baseline_y <- compute_baseline_y(window_step)
  if (!is.finite(baseline_y)) {
    warning("Skip (baseline NA): gene=", gene_i)
    next
  }
  
  dat <- dfw %>%
    dplyr::mutate(
      chr = as.character(chr),
      start = as.numeric(start),
      value = as.numeric(value),
      Nsnp = as.numeric(Nsnp),
      y = value * 100  # 统一为 0-100
    ) %>%
    dplyr::filter(chr == chrom_to_plot, start >= x_min, start <= x_max) %>%
    dplyr::arrange(start)
  
  if (nrow(dat) == 0) {
    warning("Skip (no rows after filtering plot file): gene=", gene_i, " file=", basename(plot_file))
    next
  }
  
  w_col <- window_step
  
  p <- ggplot(dat, aes(x = start, y = y)) +
    annotate("rect",
             xmin = band_start, xmax = band_end,
             ymin = -Inf, ymax = Inf,
             fill = COL_BAND, alpha = 0.55) +
    geom_col(width = w_col * 0.95, fill = COL_MAIN, alpha = 0.95) +
    geom_hline(yintercept = baseline_y, linetype = "dashed", linewidth = 0.6, colour = COL_BASE) +
    coord_cartesian(xlim = c(x_min, x_max), ylim = c(0, 100)) +
    scale_y_continuous(
      breaks = c(0, 20, 40, 60, 80, 100),
      labels = label_only_0_80_percent,
      expand = expansion(mult = c(0.03, 0.02)) # 让 0% 不贴边框
    ) +
    scale_x_continuous(
      breaks = mb_breaks(c(x_min, x_max)),
      labels = function(x) sprintf("%.2f", x / 1e6)
    ) +
    labs(x = NULL, y = y_label) +
    theme_clean_arial
  
  prefix <- paste0(safe_name(gene_i), "_", chrom_to_plot, "_", x_min, "_", x_max, "_iHS")
  
  pdf_path  <- file.path(batch_out_dir, paste0(prefix, ".pdf"))
  png_path  <- file.path(batch_out_dir, paste0(prefix, ".png"))
  tiff_path <- file.path(batch_out_dir, paste0(prefix, ".tiff"))
  saveRDS(p, sub("\\.pdf$", ".rds", pdf_path))
  
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
  
  message("Saved: ", gene_i, " -> ", prefix, " | plot=", basename(plot_file), " | step=", window_step)
}

message("Done! Batch outputs in: ", batch_out_dir)
