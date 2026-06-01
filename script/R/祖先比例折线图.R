# ============================================================
# Batch Local ancestry proportion track plot from 分析区间.xlsx
# - Reads intervals per gene (±0.5Mb analysis window; ±0.1Mb band)
# - Auto match ancestry file per gene in loter_dir (*.ancestry.txt)
# - Legend inside top-right
# - Export: PDF + PNG + TIFF (LZW, 600dpi)
# ============================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(ggplot2)
  library(grid)
  library(readxl)
  library(scales)  # for scales::alpha
})

# ============================================================
# 1) PATH CONFIG
# ============================================================
out_dir <- "data/raw/乌珠穆沁白牛/文章图汇总/测试"
interval_xlsx <- file.path(out_dir, "分析区间.xlsx")

loter_dir <- "data/raw/乌珠穆沁白牛/单倍型分析1224/result/02.loter/"
ancestry_pattern <- "\\.ancestry\\.txt$"

fig_w <- 8.2
fig_h <- 1.5

# 这里即使你改 FALSE，也会统一按 0-100 输出（满足你最新要求）
use_percent <- TRUE

batch_folder_name <- "Ancestry_batch_from_分析区间"

# ============================================================
# 2) Devices availability
# ============================================================
has_pkg <- function(pkg) requireNamespace(pkg, quietly = TRUE)
use_cairo <- has_pkg("Cairo")
use_ragg  <- has_pkg("ragg")

# ============================================================
# 3) Colors
# ============================================================
COL_LINE1 <- "#e29e39"
COL_LINE2 <- "#4e97ba"

COL_BAND   <- "#E9ECFB"
COL_COCOA  <- "#4B5563"

EXTRA_COLS <- c(
  "#DA2222", "#4F97BA", "#714C9A", "#E57030",
  "#80B973", "#5171BF", "#A372B0", "#5EA9A0"
)

# ============================================================
# 4) Helpers
# ============================================================
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

mb_breaks <- function(lim_bp) pretty(lim_bp / 1e6, n = 6) * 1e6

pick_ancestry_file <- function(gene, all_files) {
  gene <- as.character(gene)
  bn <- basename(all_files)
  
  idx1 <- which(tolower(bn) == tolower(paste0(gene, ".ancestry.txt")))
  if (length(idx1) >= 1) return(all_files[idx1[1]])
  
  idx2 <- grep(
    paste0("^", gsub("([\\.^$|()\\[\\]{}*+?\\\\-])", "\\\\\\1", gene), ".*\\.ancestry\\.txt$"),
    bn, ignore.case = TRUE
  )
  if (length(idx2) >= 1) return(all_files[idx2[1]])
  
  idx3 <- grep(gene, bn, ignore.case = TRUE)
  if (length(idx3) >= 1) return(all_files[idx3[1]])
  
  NA_character_
}

make_palette_for_ancestry <- function(levels_vec) {
  lev <- unique(as.character(levels_vec))
  lev <- lev[!is.na(lev)]
  if (length(lev) == 0) return(setNames(character(0), character(0)))
  
  if (length(lev) == 2) {
    return(setNames(c(COL_LINE1, COL_LINE2), lev))
  }
  
  cols <- c(COL_LINE1, COL_LINE2, EXTRA_COLS)
  if (length(cols) < length(lev)) cols <- rep(cols, length.out = length(lev))
  setNames(cols[seq_along(lev)], lev)
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
  transmute(
    gene = as.character(`基因名（GENE）`),
    chrom = as.character(`染色体`),
    rng_0p5 = as.character(`±0.5 Mb 区间`),
    rng_0p1 = as.character(`±0.1 Mb 区间`)
  ) %>%
  rowwise() %>%
  mutate(
    x_min = parse_bp_range(rng_0p5)[1],
    x_max = parse_bp_range(rng_0p5)[2],
    band_start = parse_bp_range(rng_0p1)[1],
    band_end   = parse_bp_range(rng_0p1)[2]
  ) %>%
  ungroup() %>%
  filter(!is.na(gene), !is.na(chrom), !is.na(x_min), !is.na(x_max)) %>%
  rowwise() %>%
  mutate(
    x1 = min(x_min, x_max, na.rm = TRUE),
    x2 = max(x_min, x_max, na.rm = TRUE),
    b1 = min(band_start, band_end, na.rm = TRUE),
    b2 = max(band_start, band_end, na.rm = TRUE)
  ) %>%
  ungroup() %>%
  transmute(gene, chrom, x_min = x1, x_max = x2, band_start = b1, band_end = b2)

message("Excel regions loaded: ", nrow(regions))

# ============================================================
# 6) Collect all ancestry files once
# ============================================================
all_ancestry_files <- list.files(loter_dir, pattern = ancestry_pattern, full.names = TRUE)
if (length(all_ancestry_files) == 0) stop("在 loter_dir 下找不到 *.ancestry.txt：", loter_dir)

# ============================================================
# 7) Theme
# ============================================================
theme_clean_arial <- theme_classic(base_size = 10, base_family = "Arial") +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.border = element_rect(colour = COL_COCOA, fill = NA, linewidth = 0.8),
    axis.line = element_blank(),
    
    axis.ticks = element_line(linewidth = 0.6, colour = COL_COCOA),
    axis.ticks.length = unit(-2.2, "pt"),
    
    axis.text = element_text(colour = COL_COCOA, size = 9),
    axis.text.y = element_text(vjust = 0.2),
    
    axis.title = element_text(colour = COL_COCOA, size = 10),
    axis.title.y = element_text(lineheight = 0.95, margin = margin(r = 6)),
    
    legend.position = c(0.98, 0.98),
    legend.justification = c(1, 1),
    legend.direction = "vertical",
    legend.title = element_blank(),
    legend.text  = element_text(size = 9),
    legend.key.width  = unit(12, "pt"),
    legend.key.height = unit(6, "pt"),
    legend.background = element_rect(fill = scales::alpha("white", 0.45), colour = NA),
    
    plot.margin = margin(4, 6, 3, 10)
  )

y_label <- wrap_y_title("proportion of ancestry (%)", width = 18)

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
  
  f <- pick_ancestry_file(gene_i, all_ancestry_files)
  if (is.na(f) || !file.exists(f)) {
    warning("Skip (no ancestry file matched): gene=", gene_i)
    next
  }
  
  df <- read_tsv(f, show_col_types = FALSE, progress = FALSE)
  need <- c("chr", "start", "value", "ancestry")
  miss2 <- setdiff(need, colnames(df))
  if (length(miss2) > 0) {
    warning("Skip (missing columns in file): ", basename(f), " missing=", paste(miss2, collapse = ", "))
    next
  }
  
  dat <- df %>%
    mutate(
      chr = as.character(chr),
      start = as.numeric(start),
      value = as.numeric(value),
      y = value * 100,  # 统一到 0-100
      ancestry = as.character(ancestry)
    ) %>%
    filter(chr == chrom_to_plot, start >= x_min, start <= x_max) %>%
    arrange(chr, start)
  
  if (nrow(dat) == 0) {
    warning("Skip (no rows after filtering): gene=", gene_i, " file=", basename(f))
    next
  }
  
  pal <- make_palette_for_ancestry(dat$ancestry)
  
  p <- ggplot(dat, aes(x = start, y = y, color = ancestry)) +
    annotate("rect",
             xmin = band_start, xmax = band_end,
             ymin = -Inf, ymax = Inf,
             fill = COL_BAND, alpha = 0.55) +
    geom_line(linewidth = 0.42, lineend = "round") +
    coord_cartesian(xlim = c(x_min, x_max), ylim = c(0, 100)) +
    scale_y_continuous(
      breaks = c(0, 20, 40, 60, 80, 100),
      labels = label_only_0_80_percent,
      expand = expansion(mult = c(0.03, 0.02))
    ) +
    scale_x_continuous(
      breaks = mb_breaks(c(x_min, x_max)),
      labels = function(x) format(x, scientific = FALSE)
    ) +
    scale_color_manual(values = pal) +
    labs(x = NULL, y = y_label) +
    theme_clean_arial
  
  prefix <- paste0(safe_name(gene_i), "_", chrom_to_plot, "_", x_min, "_", x_max, "_Ancestry")
  
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
    ggsave(tiff_path, plot = p, width = fig_w, height = fig_h,
           dpi = 600, device = ragg::agg_tiff, compression = "lzw")
  } else {
    ggsave(png_path, plot = p, width = fig_w, height = fig_h, dpi = 600)
    ggsave(tiff_path, plot = p, width = fig_w, height = fig_h,
           dpi = 600, device = "tiff", compression = "lzw")
  }
  
  message("Saved: ", gene_i, " -> ", prefix)
}

message("Done! Batch outputs in: ", batch_out_dir)
