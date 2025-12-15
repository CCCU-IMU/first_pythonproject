## =========================
## Fig2-like plot:  A) ROH bins stacked bar  +  B) FROH violin
## Run directly in R / RStudio
## Font: Arial (via showtext)
## BIG FONT version
## =========================

## 1) packages
pkgs <- c("tidyverse", "cowplot", "readr", "sysfonts", "showtext")
to_install <- pkgs[!pkgs %in% rownames(installed.packages())]
if (length(to_install) > 0) install.packages(to_install)
invisible(lapply(pkgs, library, character.only = TRUE))

## 2) load Arial from Windows fonts (showtext)
arial_regular <- "C:/Windows/Fonts/arial.ttf"
arial_bold    <- "C:/Windows/Fonts/arialbd.ttf"
arial_italic  <- "C:/Windows/Fonts/ariali.ttf"
arial_bi      <- "C:/Windows/Fonts/arialbi.ttf"

if (!file.exists(arial_regular)) {
  stop("找不到 Arial 字体文件：", arial_regular, "\n请确认 Windows 是否安装 Arial。")
}

sysfonts::font_add(
  family = "Arial",
  regular = arial_regular,
  bold = if (file.exists(arial_bold)) arial_bold else arial_regular,
  italic = if (file.exists(arial_italic)) arial_italic else arial_regular,
  bolditalic = if (file.exists(arial_bi)) arial_bi else arial_regular
)
showtext::showtext_auto(enable = TRUE)

## 3) paths
in_dir  <- "E:/桌面/武汉数据/乌珠穆沁白牛/10-13-ROH/result"
out_dir <- "E:/桌面/武汉数据/乌珠穆沁白牛/文章图汇总"
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

roh_hom_path <- file.path(in_dir, "table.plink.hom.txt")
froh_path    <- file.path(in_dir, "FROH.txt")
out_prefix   <- file.path(out_dir, "Fig2_ROH_FROH_like_BIGFONT")

## 4) options
WHICH_SET <- 2
exclude_iid <- c(paste0("Charolais-", 1:7), paste0("Charolais", 1:7))

## 5) palettes
breed_pal <- c(
  "Bos_indicus" = "#E64B35E5",
  "UW"          = "#4DBBD5E5",
  "Angus"       = "#00A087E5",
  "Charolais"   = "#3C5488E5",
  "Hanwoo"      = "#F39B7FE5",
  "Mo-OD"       = "#8491B4E5",
  "Mo-SN"       = "#91D1C2E5",
  "Simmental"   = "#DC0000E5"
)

roh_bins <- c("0.5-1 Mb", "1-2 Mb", "2-4 Mb", ">4 Mb")
bin_cols <- c(
  "0.5-1 Mb" = "#4DBBD5E5",  # UW
  "1-2 Mb"   = "#8491B4E5",  # Mo-OD
  "2-4 Mb"   = "#F39B7FE5",  # Hanwoo
  ">4 Mb"    = "#E64B35E5"   # Bos_indicus
)

## 6) font sizes (你想更大就把 16 改 18/20)
BASE_SIZE   <- 16
AXIS_TEXT   <- 13
AXIS_TITLE  <- 15
LEG_TEXT    <- 12
LEG_TITLE   <- 13
PANEL_LAB   <- 18

## 7) helpers
read_auto <- function(path) {
  tryCatch(
    readr::read_tsv(path, show_col_types = FALSE, progress = FALSE, comment = "#"),
    error = function(e) readr::read_table2(path, show_col_types = FALSE, progress = FALSE, comment = "#")
  )
}

theme_paper <- function() {
  theme_classic(base_size = BASE_SIZE, base_family = "Arial") +
    theme(
      panel.border = element_rect(fill = NA, colour = "black", linewidth = 0.6),
      axis.text  = element_text(size = AXIS_TEXT, colour = "black"),
      axis.title = element_text(size = AXIS_TITLE),
      axis.ticks.length = unit(0.18, "cm"),
      plot.margin = margin(10, 12, 10, 12),
      legend.text  = element_text(size = LEG_TEXT),
      legend.title = element_text(size = LEG_TITLE),
      legend.key.size = unit(0.50, "cm"),
      legend.spacing.y = unit(0.2, "cm")
    )
}

## 8) read FROH
froh <- read_auto(froh_path)
froh_col <- if (WHICH_SET == 1) "FROH1" else "FROH2"
stopifnot(all(c("FID", "IID", froh_col) %in% names(froh)))

froh2 <- froh %>%
  transmute(
    FID  = as.character(.data$FID),
    IID  = as.character(.data$IID),
    FROH = as.numeric(.data[[froh_col]])
  ) %>%
  filter(!IID %in% exclude_iid) %>%
  filter(!is.na(FROH))

preferred_order <- names(breed_pal)
breed_in_data <- unique(froh2$FID)
breed_order <- c(preferred_order[preferred_order %in% breed_in_data],
                 setdiff(breed_in_data, preferred_order))

froh2$FID <- factor(froh2$FID, levels = breed_order)
breed_pal_use <- breed_pal[names(breed_pal) %in% levels(froh2$FID)]

## Panel B: FROH violin
pB <- ggplot(froh2, aes(x = FID, y = FROH, fill = FID)) +
  geom_violin(width = 0.88, trim = TRUE, colour = "black", linewidth = 0.35) +
  geom_boxplot(width = 0.14, outlier.size = 0.6, fill = "white",
               colour = "black", linewidth = 0.35) +
  scale_fill_manual(values = breed_pal_use, guide = "none", drop = FALSE) +
  labs(x = NULL, y = expression(F[ROH])) +
  theme_paper() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1))

## 9) ROH from .hom
hom <- read_auto(roh_hom_path)

kb_candidates <- c("KB", "KBLEN", "KB_LEN", "KB_LENGTH", "LENKB", "LENGTH_KB")
kb_col <- kb_candidates[kb_candidates %in% names(hom)][1]
if (is.na(kb_col)) stop("找不到 KB 列。请运行 names(hom) 并把输出发我。")
stopifnot(all(c("FID", "IID") %in% names(hom)))

roh_by_ind <- hom %>%
  transmute(
    FID = as.character(.data$FID),
    IID = as.character(.data$IID),
    KB  = as.numeric(.data[[kb_col]])
  ) %>%
  filter(!IID %in% exclude_iid) %>%
  filter(!is.na(KB) & KB > 0) %>%
  mutate(
    bin = case_when(
      KB >= 500  & KB < 1000 ~ "0.5-1 Mb",
      KB >= 1000 & KB < 2000 ~ "1-2 Mb",
      KB >= 2000 & KB < 4000 ~ "2-4 Mb",
      KB >= 4000             ~ ">4 Mb",
      TRUE                   ~ NA_character_
    )
  ) %>%
  filter(!is.na(bin)) %>%
  count(FID, IID, bin, name = "n_roh")

roh_sum <- roh_by_ind %>%
  group_by(FID, bin) %>%
  summarise(value = mean(n_roh), .groups = "drop") %>%
  mutate(
    FID = factor(FID, levels = breed_order),
    bin = factor(bin, levels = roh_bins)
  ) %>%
  tidyr::complete(FID, bin, fill = list(value = 0))

pA <- ggplot(roh_sum, aes(x = FID, y = value, fill = bin)) +
  geom_col(width = 0.78, colour = "black", linewidth = 0.35) +
  scale_fill_manual(values = bin_cols, name = NULL, drop = FALSE) +
  labs(x = NULL, y = "Number of ROH events") +
  theme_paper() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1),
    legend.position = c(0.88, 0.78)
  )

## 10) combine + save (bigger canvas)
combo <- cowplot::plot_grid(
  cowplot::ggdraw(pA) + cowplot::draw_label("A", x = 0.01, y = 0.99, hjust = 0, vjust = 1,
                                            fontface = "bold", size = PANEL_LAB),
  cowplot::ggdraw(pB) + cowplot::draw_label("B", x = 0.01, y = 0.99, hjust = 0, vjust = 1,
                                            fontface = "bold", size = PANEL_LAB),
  nrow = 1, rel_widths = c(1.05, 1.0)
)

ggsave(paste0(out_prefix, ".pdf"), combo, width = 14, height = 5.5, units = "in",
       device = cairo_pdf)
ggsave(paste0(out_prefix, ".png"), combo, width = 14, height = 5.5, units = "in",
       dpi = 600)

message("✅ 完成！输出到：\n",
        paste0(out_prefix, ".pdf\n"),
        paste0(out_prefix, ".png\n"))
