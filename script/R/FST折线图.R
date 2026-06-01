# ============================================================
# Fst overlay track plot template (Candy palette + Arial)
# - Legend inside (top-right)
# - No grid lines
# - Box border around panel
# - Thin lines
# - Band shading (required)
# - Export: PDF + PNG + TIFF (LZW, 600dpi)
# ============================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(ggplot2)
  library(grid)
  library(scales)  # for alpha
})

# ============================================================
# 1) CONFIG BLOCK  (以后只改这里)
# ============================================================
input_dir <- "E:/桌面/武汉数据/乌珠穆沁白牛/单倍型分析1224/result/03.Fst/plot_Fst"
out_dir   <- "E:/桌面/武汉数据/乌珠穆沁白牛/文章图汇总/测试"

file_uw <- file.path(input_dir, "UW_vs_Mo-OD.PLAG1.Fst.txt")
file_ch <- file.path(input_dir, "Charolais_vs_Mo-OD.PLAG1.Fst.txt")

label_uw <- "UW vs Mo-OD"
label_ch <- "Charolais vs Mo-OD"

chrom_to_plot <- "chr14"
x_min <- 22823709
x_max <- 23875679

band_start <- 23223709
band_end   <- 23475679

ycol <- "WEIGHTED_FST"   # 或 "MEAN_FST"
out_prefix <- "PLAG1_Fst"

fig_w <- 8.2
fig_h <- 1.5

use_smooth <- FALSE
smooth_span <- 0.18

# ============================================================
# 2) Devices availability
# ============================================================
has_pkg <- function(pkg) requireNamespace(pkg, quietly = TRUE)
use_cairo <- has_pkg("Cairo")
use_ragg  <- has_pkg("ragg")

# ============================================================
# 3) Candy palette
# ============================================================
COL_ORANGE <- "#a373b1"
COL_GREEN  <- "#80b974"
COL_BAND   <- "#E9ECFB"
COL_COCOA  <- "#4B5563"

COL_LEMON  <- "#FF4FA3"
COL_BERRY  <- "#FF8A00"
COL_SKY    <- "#5BCB3A"
COL_GRAPE  <- "#2CB7FF"

PAL_GROUP <- c(COL_ORANGE, COL_GREEN)
names(PAL_GROUP) <- c(label_ch, label_uw)

# ============================================================
# 4) Helpers
# ============================================================
# ---- unified axis + wrapped title helpers ----
wrap_y_title <- function(x, width = 18) {
  paste(strwrap(as.character(x), width = width), collapse = "\n")
}

# 由于这里把 Fst*100 画在 0-100 上：80 对应 0.8
label_only_0_0p8_on_0_100 <- function(x) {
  ifelse(x == 0, "0.0", ifelse(x == 80, "0.8", ""))
}

# ============================================================
# 5) Read data
# ============================================================
read_fst <- function(path, group_name) {
  df <- read_tsv(path, show_col_types = FALSE, progress = FALSE)
  need <- c("CHROM", "BIN_START", "BIN_END", ycol)
  miss <- setdiff(need, colnames(df))
  if (length(miss) > 0) {
    stop(paste0("Missing columns in ", basename(path), ": ", paste(miss, collapse = ", ")))
  }
  
  df %>%
    mutate(
      BIN_START = as.numeric(BIN_START),
      BIN_END   = as.numeric(BIN_END),
      MID       = (BIN_START + BIN_END) / 2,
      Fst       = as.numeric(.data[[ycol]]),
      group     = group_name
    ) %>%
    filter(!is.na(MID), !is.na(Fst)) %>%
    arrange(CHROM, MID)
}

uw <- read_fst(file_uw, label_uw)
ch <- read_fst(file_ch, label_ch)

dat <- bind_rows(ch, uw) %>%
  filter(CHROM == chrom_to_plot, MID >= x_min, MID <= x_max)

if (nrow(dat) == 0) stop("No rows after filtering. Check chrom name and x-range.")

# 统一映射到 0-100（0.8 -> 80）
dat <- dat %>% mutate(Fst_pct = Fst * 100)

mb_breaks <- function(lim_bp) pretty(lim_bp / 1e6, n = 6) * 1e6

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

# ============================================================
# 7) Plot (y=0-100 + 只显示0.0/0.8)
# ============================================================
p <- ggplot(dat, aes(x = MID, y = Fst_pct, color = group)) +
  annotate("rect",
           xmin = band_start, xmax = band_end,
           ymin = -Inf, ymax = Inf,
           fill = COL_BAND, alpha = 0.55) +
  geom_line(linewidth = 0.42, lineend = "round") +
  { if (use_smooth)
    geom_smooth(se = FALSE, method = "loess", span = smooth_span, linewidth = 0.55)
  } +
  coord_cartesian(xlim = c(x_min, x_max), ylim = c(0, 100)) +
  scale_y_continuous(
    breaks = c(0, 20, 40, 60, 80, 100),
    labels = label_only_0_0p8_on_0_100,
    expand = expansion(mult = c(0.03, 0.02))
  ) +
  scale_x_continuous(
    breaks = mb_breaks(c(x_min, x_max)),
    labels = function(x) sprintf("%.2f", x/1e6)
  ) +
  scale_color_manual(values = PAL_GROUP) +
  guides(color = guide_legend(reverse = TRUE)) +
  labs(x = NULL, y = wrap_y_title("Fst", width = 18)) +
  theme_clean_arial

# ============================================================
# 8) Save (PDF + PNG + TIFF)
# ============================================================
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

pdf_path  <- file.path(out_dir, paste0(out_prefix, ".pdf"))
png_path  <- file.path(out_dir, paste0(out_prefix, ".png"))
tiff_path <- file.path(out_dir, paste0(out_prefix, ".tiff"))
saveRDS(p, sub("\\.pdf$", ".rds", pdf_path))

if (use_cairo) {
  Cairo::CairoPDF(file = pdf_path, width = fig_w, height = fig_h, family = "Arial")
  print(p)
  dev.off()
} else {
  ggsave(pdf_path, plot = p, width = fig_w, height = fig_h, device = "pdf")
}

if (use_ragg) {
  ggsave(png_path, plot = p, width = fig_w, height = fig_h, dpi = 600, device = ragg::agg_png)
} else {
  ggsave(png_path, plot = p, width = fig_w, height = fig_h, dpi = 600)
}

if (use_ragg) {
  ggsave(tiff_path, plot = p, width = fig_w, height = fig_h,
         dpi = 600, device = ragg::agg_tiff, compression = "lzw")
} else {
  ggsave(tiff_path, plot = p, width = fig_w, height = fig_h,
         dpi = 600, device = "tiff", compression = "lzw")
}

message("Done! Saved:\n  ", pdf_path, "\n  ", png_path, "\n  ", tiff_path)

palette_all <- c(
  orange = COL_ORANGE, green = COL_GREEN, band = COL_BAND,
  lemon = COL_LEMON, berry = COL_BERRY, sky = COL_SKY, grape = COL_GRAPE,
  cocoa = COL_COCOA
)
print(palette_all)
