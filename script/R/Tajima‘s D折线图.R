# ============================================================
# Batch Tajima's D track plot from 分析区间.xlsx (Arial + same framework)
# - Read per-gene: chrom/x-range from ±0.5Mb, band from ±0.1Mb
# - Auto match 3 group files per gene in tajima_dir:
#     UW.<GENE>.tajimasD.txt
#     Charolais.<GENE>.tajimasD.txt
#     Mo-OD.<GENE>.tajimasD.txt
# - Legend order (top->bottom): UW, Charolais, Mo-OD
# - Colors:
#     UW        = "#bf3826"
#     Charolais = "#2A9D8F"
#     Mo-OD     = "#80B973"
# - Export: PDF + PNG + TIFF (LZW, 600dpi)
# ============================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(ggplot2)
  library(grid)
  library(readxl)
  library(scales) # alpha
})

# ============================================================
# 1) PATH CONFIG (不用再手动改区间)
# ============================================================
out_dir <- "E:/桌面/武汉数据/乌珠穆沁白牛/文章图汇总/测试"
interval_xlsx <- file.path(out_dir, "分析区间.xlsx")

tajima_dir <- "E:/桌面/武汉数据/乌珠穆沁白牛/单倍型分析1224/result/04.tajimasD/plot_tajimas.D/"

# 输出子文件夹
batch_folder_name <- "TajimasD_batch_from_分析区间"

# 图形尺寸（英寸；与你框架一致）
fig_w <- 8.2
fig_h <- 1.5

# 可选：轻微平滑（保持你原逻辑）
use_smooth <- FALSE
smooth_span <- 0.18

# ============================================================
# 2) Devices availability
# ============================================================
has_pkg <- function(pkg) requireNamespace(pkg, quietly = TRUE)
use_cairo <- has_pkg("Cairo")
use_ragg  <- has_pkg("ragg")

# ============================================================
# 3) Palette + Legend order (按你指定)
# ============================================================
COL_UW   <- "#DA2224"
COL_CHA  <- "#4e97ba"
COL_MOOD <- "#e29e39"

COL_BAND  <- "#E9ECFB"
COL_COCOA <- "#4B5563"

legend_levels <- c("UW", "Charolais", "Mo-OD")

PAL_GROUP <- c(
  "UW"        = COL_UW,
  "Charolais" = COL_CHA,
  "Mo-OD"     = COL_MOOD
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

# 在目录里优先找严格文件名；找不到就模糊匹配
pick_file <- function(dir, fname_strict, gene, group) {
  f1 <- file.path(dir, fname_strict)
  if (file.exists(f1)) return(f1)
  
  # 模糊：包含 group 和 gene 且以 .tajimasD.txt 结尾
  allf <- list.files(dir, pattern = "\\.tajimasD\\.txt$", full.names = TRUE)
  if (length(allf) == 0) return(NA_character_)
  bn <- basename(allf)
  
  idx <- which(grepl(group, bn, ignore.case = TRUE) & grepl(gene, bn, ignore.case = TRUE))
  if (length(idx) >= 1) return(allf[idx[1]])
  
  NA_character_
}

read_tajima <- function(path, label_override) {
  df <- read_tsv(path, show_col_types = FALSE, progress = FALSE)
  need <- c("CHROM", "BIN_START", "BIN_END", "TajimaD")
  miss <- setdiff(need, colnames(df))
  if (length(miss) > 0) {
    stop(paste0("Missing columns in ", basename(path), ": ", paste(miss, collapse = ", ")))
  }
  
  df %>%
    mutate(
      BIN_START = as.numeric(BIN_START),
      BIN_END   = as.numeric(BIN_END),
      MID       = (BIN_START + BIN_END) / 2,
      TajimaD   = as.numeric(TajimaD),
      group_use = label_override
    ) %>%
    filter(!is.na(MID), !is.na(TajimaD)) %>%
    arrange(CHROM, MID)
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
# 6) Theme (match your Fst style)
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
    
    legend.position = c(0.98, 0.98),
    legend.justification = c(1, 1),
    legend.direction = "vertical",
    legend.title = element_blank(),
    legend.text  = element_text(size = 9),
    legend.key.width  = unit(12, "pt"),
    legend.key.height = unit(6, "pt"),
    legend.background = element_rect(fill = scales::alpha("white", 0.45), colour = NA),
    
    plot.margin = margin(4, 6, 3, 6)
  )

# ============================================================
# 7) Batch plot + save
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
  
  f_uw  <- pick_file(tajima_dir, paste0("UW.", gene_i, ".tajimasD.txt"), gene_i, "UW")
  f_cha <- pick_file(tajima_dir, paste0("Charolais.", gene_i, ".tajimasD.txt"), gene_i, "Charolais")
  f_mo  <- pick_file(tajima_dir, paste0("Mo-OD.", gene_i, ".tajimasD.txt"), gene_i, "Mo-OD")
  
  if (any(is.na(c(f_uw, f_cha, f_mo)))) {
    warning("Skip (missing tajimasD files): gene=", gene_i,
            " | UW=", basename(f_uw),
            " | Charolais=", basename(f_cha),
            " | Mo-OD=", basename(f_mo))
    next
  }
  
  d1 <- read_tajima(f_uw,  "UW")
  d2 <- read_tajima(f_cha, "Charolais")
  d3 <- read_tajima(f_mo,  "Mo-OD")
  
  dat <- bind_rows(d1, d2, d3) %>%
    filter(CHROM == chrom_to_plot, MID >= x_min, MID <= x_max) %>%
    mutate(group_use = factor(group_use, levels = legend_levels))
  
  if (nrow(dat) == 0) {
    warning("Skip (no rows after filtering): gene=", gene_i)
    next
  }
  
  # y-range padding（保持你原逻辑）
  yr <- range(dat$TajimaD, na.rm = TRUE)
  pad <- 0.06 * diff(yr)
  y_min <- yr[1] - pad
  y_max <- yr[2] + pad
  if (!is.finite(pad) || pad == 0) { # 防止全一样导致 diff=0
    y_min <- yr[1] - 0.1
    y_max <- yr[2] + 0.1
  }
  
  p <- ggplot(dat, aes(x = MID, y = TajimaD, color = group_use)) +
    annotate("rect",
             xmin = band_start, xmax = band_end,
             ymin = -Inf, ymax = Inf,
             fill = COL_BAND, alpha = 0.55) +
    geom_line(linewidth = 0.42, lineend = "round") +
    { if (use_smooth)
      geom_smooth(se = FALSE, method = "loess", span = smooth_span, linewidth = 0.55)
    } +
    coord_cartesian(xlim = c(x_min, x_max), ylim = c(y_min, y_max)) +
    scale_x_continuous(
      breaks = mb_breaks(c(x_min, x_max)),
      labels = function(x) sprintf("%.2f", x/1e6)
    ) +
    scale_color_manual(values = PAL_GROUP, breaks = legend_levels) +
    guides(color = guide_legend(reverse = FALSE)) +  # top->bottom 按 levels 顺序
    labs(x = NULL, y = "Tajima's D") +
    theme_clean_arial
  
  out_prefix <- paste0(safe_name(gene_i), "_", chrom_to_plot, "_", x_min, "_", x_max, "_TajimasD")
  
  pdf_path  <- file.path(batch_out_dir, paste0(out_prefix, ".pdf"))
  png_path  <- file.path(batch_out_dir, paste0(out_prefix, ".png"))
  tiff_path <- file.path(batch_out_dir, paste0(out_prefix, ".tiff"))
  saveRDS(p, sub("\\.pdf$", ".rds", pdf_path))
  
  # PDF
  if (use_cairo) {
    Cairo::CairoPDF(file = pdf_path, width = fig_w, height = fig_h, family = "Arial")
    print(p); dev.off()
  } else {
    ggsave(pdf_path, plot = p, width = fig_w, height = fig_h, device = "pdf")
  }
  
  # PNG
  if (use_ragg) {
    ggsave(png_path, plot = p, width = fig_w, height = fig_h, dpi = 600, device = ragg::agg_png)
  } else {
    ggsave(png_path, plot = p, width = fig_w, height = fig_h, dpi = 600)
  }
  
  # TIFF (LZW)
  if (use_ragg) {
    ggsave(tiff_path, plot = p, width = fig_w, height = fig_h,
           dpi = 600, device = ragg::agg_tiff, compression = "lzw")
  } else {
    ggsave(tiff_path, plot = p, width = fig_w, height = fig_h,
           dpi = 600, device = "tiff", compression = "lzw")
  }
  
  message("Saved: ", gene_i, " -> ", out_prefix)
}

message("Done! Batch outputs in: ", batch_out_dir)
