# =========================
# Pi Manhattan (windowed PI) aligned to CLR using shared_axis.rds
# y = -log10(PI)
# label ONE peak gene per chr (search downward, skip LOC)
# keep only labels with y > 4
# style match CLR: chr multi-color, Arial, ticks, etc.
# Output: TIFF + JPG, 600 dpi
# =========================

pkgs <- c("data.table", "dplyr", "ggplot2", "showtext", "sysfonts", "grid")
to_install <- pkgs[!pkgs %in% rownames(installed.packages())]
if (length(to_install) > 0) install.packages(to_install)

library(data.table)
library(dplyr)
library(ggplot2)
library(showtext)
library(sysfonts)
library(grid)

# ---------- 1) Paths ----------
PI_FILE    <- "E:/桌面/武汉数据/乌珠穆沁白牛/文章图汇总/测试/内群/UW.windowed.pi.xls"
GENE_FILE  <- "E:/桌面/武汉数据/乌珠穆沁白牛/文章图汇总/测试/内群/UW.pi.merge_gene.xls"
OUT_DIR    <- "E:/桌面/武汉数据/乌珠穆沁白牛/文章图汇总/测试/内群/"
SHARED_RDS <- file.path(OUT_DIR, "shared_axis.rds")

dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)
OUT_TIFF <- file.path(OUT_DIR, "UW_PI_manhattan_aligned_CLRstyle_peakGene_yGT4.tiff")
OUT_JPG  <- file.path(OUT_DIR, "UW_PI_manhattan_aligned_CLRstyle_peakGene_yGT4.jpg")

# ---------- 2) Font: Arial ----------
font_family <- "Arial"
try(sysfonts::font_add(family = "Arial", regular = "Arial"), silent = TRUE)
showtext_auto(TRUE)
showtext_opts(dpi = 600)

# ---------- 3) Load shared x-axis system from CLR ----------
shared <- readRDS(SHARED_RDS)
chr_levels <- shared$chr_levels
chr_len    <- shared$chr_len
axis_df    <- shared$axis_df
chr_cols   <- shared$chr_cols

if (is.null(chr_cols)) {
  stop("shared_axis.rds 里没有 chr_cols，请先运行 CLR 脚本生成 shared_axis.rds")
}

# --- shared x limits for perfect alignment ---
x_min <- shared$x_min
x_max <- shared$x_max
# 如果旧版 shared_axis.rds 没存 x_min/x_max，就用下面两行兜底
if (is.null(x_min) || is.null(x_max)) {
  x_min <- min(chr_len$chr_start, na.rm = TRUE)
  x_max <- max(chr_len$chr_start + chr_len$chr_max, na.rm = TRUE)
}

# ---------- 4) Read PI windowed data ----------
pi0 <- fread(PI_FILE, sep = "\t", header = TRUE, data.table = FALSE)

pi_df <- pi0 %>%
  rename(
    Chr   = CHROM,
    Start = BIN_START,
    End   = BIN_END,
    PI    = PI
  ) %>%
  mutate(
    Chr   = gsub("^chr", "", as.character(Chr), ignore.case = TRUE),
    Start = as.numeric(Start),
    End   = as.numeric(End),
    PI    = as.numeric(PI),
    Position = (Start + End) / 2,
    neglog10PI = -log10(PI)
  )

pi_df$Chr <- factor(pi_df$Chr, levels = chr_levels)

# cumulative coordinate (aligned to CLR)
pi_df <- pi_df %>%
  left_join(chr_len, by = "Chr") %>%
  mutate(BP_cum = Position + chr_start)

# ---------- 5) Threshold line on -log10(PI) ----------
thr <- as.numeric(quantile(pi_df$neglog10PI, 0.99, na.rm = TRUE))

# ---------- 6) Read genes (4 columns, no header) ----------
genes <- fread(GENE_FILE, sep = "\t", header = FALSE, data.table = FALSE)
colnames(genes) <- c("Chr", "GeneStart", "GeneEnd", "Gene")

genes <- genes %>%
  mutate(
    Chr = gsub("^chr", "", as.character(Chr), ignore.case = TRUE),
    GeneStart = as.numeric(GeneStart),
    GeneEnd   = as.numeric(GeneEnd),
    Gene      = trimws(as.character(Gene))
  )
genes$Chr <- factor(genes$Chr, levels = chr_levels)

# ---------- 7) Pick ONE gene for a given window ----------
pick_peak_gene <- function(pk_chr, pk_pos, pk_start, pk_end, pk_bpcum, pk_score) {
  pk_chr <- as.character(pk_chr)
  
  ov <- genes %>%
    filter(as.character(Chr) == pk_chr,
           GeneStart <= pk_end,
           GeneEnd   >= pk_start) %>%
    mutate(
      Gene_clean = sub("^gene[-_ ]*", "", Gene, ignore.case = TRUE),
      is_loc = grepl("^LOC\\d+", Gene_clean, ignore.case = TRUE),
      dist = pmin(abs(GeneStart - pk_pos), abs(GeneEnd - pk_pos))
    ) %>%
    filter(!is.na(Gene_clean), Gene_clean != "")
  
  if (nrow(ov) == 0) return(NULL)
  if (all(ov$is_loc)) return(NULL)
  
  ov2 <- ov %>% filter(!is_loc)
  if (nrow(ov2) == 0) return(NULL)
  
  ov2 %>%
    arrange(dist) %>%
    slice(1) %>%
    transmute(
      Chr = pk_chr,
      PeakBPcum = pk_bpcum,
      PeakScore = pk_score,
      Label = Gene_clean
    )
}

# ---------- 8) For each chr, search downward until find non-LOC label ----------
SEARCH_TOPN <- 300

pick_chr_label <- function(chr_value) {
  df_chr <- pi_df %>%
    filter(as.character(Chr) == as.character(chr_value)) %>%
    filter(!is.na(neglog10PI)) %>%
    arrange(desc(neglog10PI)) %>%
    slice_head(n = SEARCH_TOPN)
  
  if (nrow(df_chr) == 0) return(NULL)
  
  for (i in seq_len(nrow(df_chr))) {
    pk <- df_chr[i, ]
    lab <- pick_peak_gene(
      pk_chr   = pk$Chr,
      pk_pos   = pk$Position,
      pk_start = pk$Start,
      pk_end   = pk$End,
      pk_bpcum = pk$BP_cum,
      pk_score = pk$neglog10PI
    )
    if (!is.null(lab) && nrow(lab) > 0) return(lab)
  }
  NULL
}

label_list <- lapply(chr_levels, pick_chr_label)
label_df <- bind_rows(label_list)

if (is.null(label_df) || nrow(label_df) == 0) {
  label_df <- data.frame(
    Chr = character(),
    PeakBPcum = numeric(),
    PeakScore = numeric(),
    Label = character(),
    stringsAsFactors = FALSE
  )
}

# ---------- 9) keep only labels with y > 4 ----------
if (nrow(label_df) > 0) {
  label_df <- label_df %>% filter(!is.na(PeakScore), PeakScore > 4)
}

# label y (match CLR nudge)
if (nrow(label_df) > 0) {
  # y nudge: match CLR but slightly higher
  y_range <- range(pi_df$neglog10PI, na.rm = TRUE)
  y_nudge <- 0.015 * diff(y_range)  # ✅ 比 CLR 的0.01略大，使标签更靠上
  
  # x nudge: fixed right shift like CLR-style manual placement
  x_range <- range(pi_df$BP_cum, na.rm = TRUE)
  x_nudge <- 0.004 * diff(x_range)  # ✅ 往右偏移量（可调）
  
  label_df <- label_df %>%
    mutate(
      LabelY = PeakScore + y_nudge,
      LabelX = PeakBPcum + x_nudge
    )
}


# ---------- 10) Plot (match CLR style) ----------
p_pi <- ggplot(pi_df, aes(x = BP_cum, y = neglog10PI, color = Chr)) +
  geom_point(size = 0.35, alpha = 0.85) +
  geom_hline(yintercept = thr, linetype = "dashed", linewidth = 0.4, color = "grey35") +
  { if (nrow(label_df) > 0)
    geom_point(
      data = label_df,
      aes(x = PeakBPcum, y = PeakScore),
      inherit.aes = FALSE,
      shape = 21, fill = "red", color = "black",
      size = 1.6, stroke = 0.25
    )
  } +
  { if (nrow(label_df) > 0)
    geom_text(
      data = label_df,
      aes(x = LabelX, y = LabelY, label = Label),
      inherit.aes = FALSE,
      family = font_family,
      fontface = "italic",
      size = 3.2,
      angle = 0,
      hjust = 0,
      vjust = 0.5
    )
  } +
  scale_color_manual(values = chr_cols, guide = "none") +
  scale_x_continuous(
    breaks = axis_df$center,
    labels = axis_df$Chr,
    limits = c(x_min, x_max),
    expand = c(0.01, 0.01)
  ) +
  labs(x = "Chromosome",
       y = expression(-log[10] * "(" * italic(theta*pi) * ")"))+
  theme_bw(base_family = font_family) +
  theme(
    text = element_text(family = font_family),
    panel.grid = element_blank(),
    axis.ticks.length = unit(-0.22, "cm"),
    axis.text.x.top  = element_blank(),
    axis.ticks.x.top = element_blank(),
    axis.title = element_text(size = 12),
    axis.text.x = element_text(size = 9, colour = "black"),
    axis.text.y = element_text(size = 10, colour = "black"),
    axis.ticks  = element_line(colour = "black"),
    axis.text.y.right  = element_blank(),
    axis.ticks.y.right = element_blank(),
    axis.line.y.right  = element_blank(),
    plot.margin = margin(5, 10, 5, 5)
  ) +
  scale_y_continuous(expand = expansion(mult = c(0.02, 0.12)))

print(p_pi)

# ---------- 11) Save ----------
tiff(filename = OUT_TIFF, width = 12, height = 6, units = "in",
     res = 600, compression = "lzw")
print(p_pi)   # ✅ FIX: was print(p)
dev.off()

jpeg(filename = OUT_JPG, width = 12, height = 6, units = "in",
     res = 600, quality = 100)
print(p_pi)
dev.off()

message("Saved TIFF: ", OUT_TIFF)
message("Saved JPG : ", OUT_JPG)
message("Threshold (99% quantile of -log10(PI)) = ", format(thr, digits = 16))
message("Labeled peaks: ", nrow(label_df))
message("Per chr search windows (topN): ", SEARCH_TOPN)
