# =========================
# CLR Manhattan + Top1% threshold + label ONE peak gene per chr (skip LOC if possible)
# WITH broken y-axis (ggbreak)
# - No red highlight for top1%
# - Avoid duplicate labels in broken axis: use geom_text + fixed label y (no ggrepel)
# Output: TIFF 600 dpi, Arial
# =========================

pkgs <- c("data.table", "dplyr", "ggplot2", "showtext", "sysfonts", "ggbreak")
to_install <- pkgs[!pkgs %in% rownames(installed.packages())]
if (length(to_install) > 0) install.packages(to_install)

library(data.table)
library(dplyr)
library(ggplot2)
library(showtext)
library(sysfonts)
library(ggbreak)
library(grid)

# ---------- 1) Paths (EDIT THESE) ----------
CLR_FILE  <- "data/raw/乌珠穆沁白牛/文章图汇总/测试/内群/UW.CLR.xls"
GENE_FILE <- "data/raw/乌珠穆沁白牛/文章图汇总/测试/内群/UW.CLR.merge_gene.xls"

OUT_DIR   <- "data/raw/乌珠穆沁白牛/文章图汇总/测试/内群/"
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)
OUT_TIFF  <- file.path(OUT_DIR, "UW_CLR_manhattan_brokenY_top1pct_peakGene_skipLOC.tiff")

# ---------- 2) Font: Arial ----------
font_family <- "Arial"
try(sysfonts::font_add(family = "Arial", regular = "Arial"), silent = TRUE)
showtext_auto(TRUE)
showtext_opts(dpi = 600)

# ---------- 3) Read data ----------
clr0 <- fread(CLR_FILE, sep = "\t", header = TRUE, data.table = FALSE, check.names = FALSE)

genes <- fread(GENE_FILE, sep = "\t", header = FALSE, data.table = FALSE)
colnames(genes) <- c("Chr", "GeneStart", "GeneEnd", "Gene")

# ---------- 4) Rename & clean ----------
clr <- clr0 %>%
  rename(
    Chr = `Chr ID`,
    Position = Position,
    Likelihood = Likelihood,
    StartPos = StartPos,
    EndPos = EndPos
  ) %>%
  mutate(
    Chr = gsub("^chr", "", as.character(Chr), ignore.case = TRUE),
    Position = as.numeric(Position),
    StartPos = as.numeric(StartPos),
    EndPos = as.numeric(EndPos),
    Likelihood = as.numeric(Likelihood)
  )

genes <- genes %>%
  mutate(
    Chr = gsub("^chr", "", as.character(Chr), ignore.case = TRUE),
    GeneStart = as.numeric(GeneStart),
    GeneEnd   = as.numeric(GeneEnd)
  )

# ---------- 5) Chromosome order ----------
chr_num <- sort(unique(suppressWarnings(as.integer(clr$Chr))))
chr_num <- chr_num[!is.na(chr_num)]
chr_chr <- unique(clr$Chr[is.na(suppressWarnings(as.integer(clr$Chr)))])
chr_levels <- c(as.character(chr_num), chr_chr)

clr$Chr   <- factor(clr$Chr, levels = chr_levels)
genes$Chr <- factor(genes$Chr, levels = chr_levels)

# ---------- 6) Cumulative coordinate ----------
chr_len <- clr %>%
  group_by(Chr) %>%
  summarise(chr_max = max(EndPos, na.rm = TRUE), .groups = "drop") %>%
  arrange(Chr) %>%
  mutate(chr_start = lag(cumsum(chr_max), default = 0))

clr <- clr %>%
  left_join(chr_len, by = "Chr") %>%
  mutate(BP_cum = Position + chr_start)

axis_df <- chr_len %>% mutate(center = chr_start + chr_max / 2)

# ---------- 6.5) FIXED x-axis limits for alignment with PI ----------
x_min <- min(chr_len$chr_start, na.rm = TRUE)
x_max <- max(chr_len$chr_start + chr_len$chr_max, na.rm = TRUE)

# ---------- 7) Top 1% threshold (used for peak selection) ----------
thr  <- as.numeric(quantile(clr$Likelihood, 0.99, na.rm = TRUE))
top1 <- clr %>% filter(Likelihood >= thr)

# 每条染色体：top1% 中取最高峰（用于标注）
peaks <- top1 %>%
  group_by(Chr) %>%
  slice_max(order_by = Likelihood, n = 1, with_ties = FALSE) %>%
  ungroup()

# ---------- 8) For each peak: pick ONE gene, skip LOCxxxx if possible ----------
pick_peak_gene <- function(pk_chr, pk_pos, pk_start, pk_end, pk_bpcum, pk_score) {
  ov <- genes %>%
    filter(Chr == pk_chr,
           GeneStart <= pk_end,
           GeneEnd   >= pk_start) %>%
    mutate(Gene = trimws(as.character(Gene))) %>%
    filter(!is.na(Gene), Gene != "")
  
  if (nrow(ov) == 0) return(NULL)
  
  ov <- ov %>%
    mutate(
      Gene_clean = sub("^gene[-_ ]*", "", Gene, ignore.case = TRUE),
      dist = pmin(abs(GeneStart - pk_pos), abs(GeneEnd - pk_pos)),
      is_loc = grepl("^LOC\\d+", Gene_clean, ignore.case = TRUE)
    )
  
  if (all(ov$is_loc)) return(NULL)
  
  ov2 <- ov %>% filter(!is_loc)
  if (nrow(ov2) == 0) return(NULL)
  
  ov2 %>%
    arrange(dist) %>%
    slice(1) %>%
    transmute(Chr = pk_chr, PeakBPcum = pk_bpcum, PeakScore = pk_score, Gene = Gene_clean)
}

label_list <- lapply(seq_len(nrow(peaks)), function(i) {
  pk <- peaks[i, ]
  pick_peak_gene(pk$Chr, pk$Position, pk$StartPos, pk$EndPos, pk$BP_cum, pk$Likelihood)
})

label_df <- bind_rows(label_list) %>%
  distinct(Chr, PeakBPcum, PeakScore, Gene) %>%
  rename(Label = Gene)

label_df <- label_df %>% filter(!grepl("^LOC\\d+", Label, ignore.case = TRUE))
label_df <- label_df %>% filter(PeakScore > 400)

# ---------- 9) Broken y-axis settings ----------
break_low   <- 3000
break_high  <- 7000
break_scale <- 0.35

# ---------- 10) Make label y fixed & keep lower labels BELOW break_low to avoid duplication ----------
y_range <- range(clr$Likelihood, na.rm = TRUE)
y_nudge <- 0.01 * diff(y_range)

label_df <- label_df %>%
  mutate(
    LabelY = PeakScore + y_nudge,
    LabelY = ifelse(PeakScore <= break_low, pmin(LabelY, break_low * 0.98), LabelY)
  )

cap_y <- 8200
label_df <- label_df %>% mutate(LabelY = pmin(LabelY, cap_y))

label_df <- label_df %>%
  mutate(LabelY = ifelse(Chr == "2", LabelY + 0.02 * diff(y_range), LabelY))

# ---------- 11) Chromosome palette (multi-color like your reference) ----------
base_cols <- c(
  "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd",
  "#17becf", "#e377c2", "#bcbd22", "#8c564b", "#7f7f7f",
  "#4e79a7", "#f28e2b", "#59a14f", "#e15759", "#b07aa1"
)
chr_cols <- rep(base_cols, length.out = length(levels(clr$Chr)))
names(chr_cols) <- levels(clr$Chr)

# ---------- 12) Plot ----------
p_clr <- ggplot(clr, aes(x = BP_cum, y = Likelihood, color = Chr)) +
  geom_point(size = 0.35, alpha = 0.85) +
  geom_point(
    data = label_df,
    aes(x = PeakBPcum, y = PeakScore),
    inherit.aes = FALSE,
    shape = 21, fill = "red", color = "black",
    size = 1.6, stroke = 0.25
  ) +
  geom_hline(yintercept = thr, linetype = "dashed", linewidth = 0.4, color = "grey35") +
  geom_text(
    data = label_df,
    aes(x = PeakBPcum, y = LabelY, label = Label),
    inherit.aes = FALSE,
    family = font_family,
    fontface = "italic",     # ✅ Gene italic
    size = 3.2,
    angle = 0,
    hjust = 0,
    vjust = 0.5
  ) +
  scale_color_manual(values = chr_cols, guide = "none") +
  scale_x_continuous(
    breaks = axis_df$center,
    labels = axis_df$Chr,
    limits = c(x_min, x_max),     # ✅ added for alignment
    expand = c(0.01, 0.01)
  ) +
  labs(x = "Chromosome", y = "CLR") +
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
  scale_y_continuous(
    breaks = c(0, 1000, 2000, 3000, 7000, 7500, 8000),
    expand = expansion(mult = c(0.02, 0.12))
  ) +
  ggbreak::scale_y_break(
    c(break_low, break_high),
    scales = break_scale
  )

# ---------- 12.5) Save shared axis for PI ----------
shared_axis <- list(
  chr_levels = chr_levels,
  chr_len    = chr_len,
  axis_df    = axis_df,
  chr_cols   = chr_cols,
  x_min      = x_min,
  x_max      = x_max
)
saveRDS(shared_axis, file.path(OUT_DIR, "shared_axis.rds"))

print(p_clr)

# ---------- 13) Save TIFF + JPG (600 dpi) ----------
OUT_JPG <- file.path(OUT_DIR, "UW_CLR_manhattan_brokenY_top1pct_peakGene_skipLOC.jpg")

# TIFF
tiff(filename = OUT_TIFF, width = 12, height = 6, units = "in",
     res = 600, compression = "lzw")
print(p_clr)   # ✅ FIX: was print(p)
dev.off()

# JPG
jpeg(filename = OUT_JPG, width = 12, height = 6, units = "in",
     res = 600, quality = 100)
print(p_clr)
dev.off()

message("Saved TIFF: ", OUT_TIFF)
message("Saved JPG : ", OUT_JPG)
