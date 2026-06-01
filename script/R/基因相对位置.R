# ============================================================
# Gene track (RECT blocks) from interval Excel
# - ONLY genes overlapping the shaded band (±0.1Mb)
# - Keep only top N genes (Strategy A): protein_coding + max overlap with band
# - Labels: gene symbols only (no ENSBTAXXXX)
# - 标签固定在方块x轴中点；初始在上方/下方；只在垂直方向避让；不画引导线
# - Same framework: Arial + box border + no grid + cream band
# - Export: PDF + PNG + TIFF (LZW, 600 dpi)
# ============================================================

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(ggplot2)
  library(grid)
})

# 如未安装：install.packages("ggrepel")
suppressPackageStartupMessages(library(ggrepel))

# ============================================================
# 1) CONFIG BLOCK (以后只改这里)
# ============================================================
excel_path <- "data/raw/乌珠穆沁白牛/基因筛选/分析区间.xlsx"
out_dir    <- "data/raw/乌珠穆沁白牛/文章图汇总/测试"

genes_to_plot <- NULL
use_mirror <- "asia"

# ---- Strategy A controls ----
max_genes <- 5                    # 建议 3-5
keep_biotype <- "protein_coding"  # 只保留蛋白编码；不想过滤就设 NULL

# Colors & style
COL_GENE  <- "#e67030"
COL_BAND  <- "#E9ECFB"
COL_COCOA <- "#4B5563"

fig_w <- 8.2
fig_h <- 1.17

prefix <- "GeneTrack_bandOnly_topN_repelY_noLine"

block_h <- 0.12
lane_gap <- 0.22

# ---- label placement (核心) ----
label_gap <- 1.3   # 标签离方块外边缘的距离（0.12~0.25 推荐）
y_pad_extra <- 0.22  # ylim 上下额外留白（不够可调大）

# ---- ggrepel controls ----
repel_force      <- 3.0
repel_force_pull <- 0.3
repel_box_pad    <- 0.25
repel_max_iter   <- 3000
repel_max_time   <- 1.5

# ============================================================
# 2) Optional devices
# ============================================================
has_pkg <- function(pkg) requireNamespace(pkg, quietly = TRUE)
use_cairo <- has_pkg("Cairo")
use_ragg  <- has_pkg("ragg")

# ============================================================
# 3) Helpers
# ============================================================
parse_range <- function(x) {
  x <- as.character(x)
  x <- gsub(",", "", x)
  x <- gsub("\\s+", "", x)
  x <- gsub("[–—−]", "-", x)
  parts <- strsplit(x, "-", fixed = TRUE)[[1]]
  if (length(parts) < 2) stop("Cannot parse range: ", x)
  c(as.numeric(parts[1]), as.numeric(parts[2]))
}

norm_chr <- function(chr) {
  chr <- tolower(as.character(chr))
  chr <- gsub("^chr", "", chr)
  chr <- gsub("^bta", "", chr)
  chr <- toupper(chr)
  if (chr %in% c("M", "MT")) chr <- "MT"
  chr
}

assign_lanes <- function(df) {
  if (nrow(df) == 0) return(df %>% dplyr::mutate(lane = integer(0)))
  df <- df %>% dplyr::arrange(start_position, end_position)
  lane_end <- numeric(0)
  lane_id <- integer(nrow(df))
  for (i in seq_len(nrow(df))) {
    s <- df$start_position[i]
    e <- df$end_position[i]
    k <- which(lane_end < s)
    if (length(k) == 0) {
      lane_end <- c(lane_end, e)
      lane_id[i] <- length(lane_end)
    } else {
      j <- k[which.min(lane_end[k])]
      lane_end[j] <- e
      lane_id[i] <- j
    }
  }
  df %>% dplyr::mutate(lane = lane_id)
}

mb_breaks <- function(lim_bp) pretty(lim_bp / 1e6, n = 6) * 1e6
overlap_band <- function(s, e, b1, b2) !(e < b1 | s > b2)

# ============================================================
# 4) Read Excel
# ============================================================
tbl_raw <- readxl::read_xlsx(excel_path)

tbl <- tbl_raw %>%
  dplyr::mutate(
    gene = `基因名（GENE）`,
    chr_raw = `染色体`,
    range_full = `±0.5 Mb 区间`,
    range_band = `±0.1 Mb 区间`
  ) %>%
  dplyr::select(gene, chr_raw, range_full, range_band)

if (!is.null(genes_to_plot)) {
  tbl <- tbl %>% dplyr::filter(gene %in% genes_to_plot)
}
if (nrow(tbl) == 0) stop("No rows to plot. Check genes_to_plot or Excel content.")

# ============================================================
# 5) Setup biomaRt
# ============================================================
if (!has_pkg("biomaRt")) {
  stop(
    "Package 'biomaRt' not installed.\n",
    "Install with:\n",
    "  if (!requireNamespace('BiocManager', quietly=TRUE)) install.packages('BiocManager')\n",
    "  BiocManager::install('biomaRt')\n"
  )
}
suppressPackageStartupMessages(library(biomaRt))

mart <- biomaRt::useEnsembl(
  biomart = "genes",
  dataset = "btaurus_gene_ensembl",
  mirror  = use_mirror
)

fetch_genes <- function(chr, start_bp, end_bp) {
  chr2 <- norm_chr(chr)
  biomaRt::getBM(
    attributes = c(
      "external_gene_name",
      "ensembl_gene_id",
      "chromosome_name",
      "start_position",
      "end_position",
      "strand",
      "gene_biotype"
    ),
    filters = c("chromosome_name", "start", "end"),
    values  = list(chr2, start_bp, end_bp),
    mart    = mart
  ) %>%
    tibble::as_tibble() %>%
    dplyr::filter(!is.na(start_position), !is.na(end_position)) %>%
    dplyr::mutate(
      strand = ifelse(strand == 1, 1L, -1L),
      gene_symbol = dplyr::na_if(trimws(external_gene_name), "")
    )
}

# ============================================================
# 6) Theme
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
    axis.title = element_text(colour = COL_COCOA, size = 10),
    axis.ticks.y = element_blank(),
    plot.margin = margin(4, 6, 3, 6),
    legend.position = "none"
  )

# ============================================================
# 7) Plot per row
# ============================================================
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

# 让 ggrepel 结果可重复

for (i in seq_len(nrow(tbl))) {
  gene_name <- tbl$gene[i]
  chr <- tbl$chr_raw[i]
  
  full <- parse_range(tbl$range_full[i])
  band <- parse_range(tbl$range_band[i])
  
  x_min <- full[1]; x_max <- full[2]
  band_start <- band[1]; band_end <- band[2]
  
  g <- fetch_genes(chr, x_min, x_max)
  
  # ---- keep only genes overlapping band ----
  g <- g %>%
    dplyr::filter(overlap_band(start_position, end_position, band_start, band_end)) %>%
    dplyr::mutate(
      overlap_bp = pmax(0, pmin(end_position, band_end) - pmax(start_position, band_start))
    )
  
  # ---- optional: keep only protein_coding ----
  if (!is.null(keep_biotype) && "gene_biotype" %in% names(g)) {
    g <- g %>% dplyr::filter(gene_biotype == keep_biotype)
  }
  
  # ---- remove genes without symbol (avoid ENSBTAXXXX) ----
  g <- g %>% dplyr::filter(!is.na(gene_symbol))
  
  if (nrow(g) == 0) {
    message("No labelled genes left for: ", gene_name, " (", chr, "). Skipped.")
    next
  }
  
  # ---- de-duplicate & keep top N by overlap ----
  g <- g %>%
    dplyr::group_by(gene_symbol) %>%
    dplyr::summarise(
      start_position = min(start_position),
      end_position   = max(end_position),
      strand         = dplyr::first(strand),
      gene_biotype   = dplyr::first(gene_biotype),
      overlap_bp     = max(overlap_bp),
      span_bp        = max(end_position - start_position),
      .groups = "drop"
    ) %>%
    dplyr::arrange(dplyr::desc(overlap_bp), dplyr::desc(span_bp)) %>%
    dplyr::slice_head(n = max_genes)
  
  # forward / reverse + lane
  g_f <- g %>% dplyr::filter(strand == 1) %>% assign_lanes()
  g_r <- g %>% dplyr::filter(strand == -1) %>% assign_lanes()
  
  base_f <-  0.6
  base_r <- -0.6
  
  g_f <- g_f %>% dplyr::mutate(y = base_f + (lane - 1) * lane_gap)
  g_r <- g_r %>% dplyr::mutate(y = base_r - (lane - 1) * lane_gap)
  
  ggdat <- dplyr::bind_rows(g_f, g_r) %>%
    dplyr::mutate(
      mid  = (start_position + end_position) / 2,
      ymin = y - block_h,
      ymax = y + block_h,
      # 初始：标签在方块上方/下方，且x固定在方块中点
      label_y = y + ifelse(strand == 1, +(block_h + label_gap), -(block_h + label_gap))
    )
  
  # ---- y-range：给 ggrepel 在垂直方向避让的空间，并确保 Forward/Reverse 标签始终可见 ----
  # 新：ylim 只看方块（保持方块视觉大小）
  y_lo <- min(ggdat$ymin, na.rm = TRUE) - y_pad_extra
  y_hi <- max(ggdat$ymax, na.rm = TRUE) + y_pad_extra
  
  # 仍然强制显示 Reverse/Forward 轴标签（可选但推荐）
  y_lo <- min(y_lo, base_r - y_pad_extra)
  y_hi <- max(y_hi, base_f + y_pad_extra)
  
  
  p <- ggplot() +
    annotate("rect",
             xmin = band_start, xmax = band_end,
             ymin = -Inf, ymax = Inf,
             fill = COL_BAND, alpha = 0.55) +
    geom_rect(
      data = ggdat,
      aes(xmin = start_position, xmax = end_position, ymin = ymin, ymax = ymax),
      fill = COL_GENE, colour = NA, alpha = 0.95
    ) +
    # 只在垂直方向避让；不加引导线；x固定在方块中点（mid）
    ggrepel::geom_text_repel(
      data = ggdat,
      aes(x = mid, y = label_y, label = gene_symbol),
      family = "Arial", colour = COL_COCOA, size = 3.0,
      direction = "y",
      force = repel_force,
      force_pull = repel_force_pull,
      box.padding = repel_box_pad,
      point.padding = 0,
      max.overlaps = Inf,
      max.iter = repel_max_iter,
      max.time = repel_max_time,
      segment.color = NA     # 关闭引导线
    ) +
    coord_cartesian(xlim = c(x_min, x_max), ylim = c(y_lo, y_hi)) +
    scale_x_continuous(
      breaks = mb_breaks(c(x_min, x_max)),
      labels = function(x) sprintf("%.2f", x / 1e6)
    ) +
    scale_y_continuous(
      breaks = c(base_r, base_f),
      labels = c("Reverse", "Forward")
    ) +
    labs(x = NULL, y = "Gene") +
    theme_clean_arial
  
  base_out <- file.path(
    out_dir,
    paste0(prefix, "_", gene_name, "_", norm_chr(chr), "_top", max_genes, "_",
           sprintf("%.2f-%.2fMb", x_min/1e6, x_max/1e6))
  )
  
  pdf_path  <- paste0(base_out, ".pdf")
  png_path  <- paste0(base_out, ".png")
  tiff_path <- paste0(base_out, ".tiff")
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
  
  message("Saved: ", pdf_path)
}

message("All done.")
