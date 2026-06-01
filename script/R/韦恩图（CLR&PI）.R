# =========================
# Two-ellipse Venn (CLR vs θπ)
# Output: TIFF, 600 dpi, Arial
# Save to: E:/桌面/武汉数据/乌珠穆沁白牛/文章图汇总/测试
# =========================

# Packages
pkgs <- c("ggplot2", "ggforce", "showtext", "sysfonts")
to_install <- pkgs[!pkgs %in% rownames(installed.packages())]
if (length(to_install) > 0) install.packages(to_install)

library(ggplot2)
library(ggforce)
library(showtext)
library(sysfonts)

# ---- Font: Arial ----
font_family <- "Arial"
try({
  sysfonts::font_add(family = "Arial", regular = "Arial")
}, silent = TRUE)
showtext_auto(enable = TRUE)
showtext_opts(dpi = 600)  # ensure text renders crisply at 600 dpi

# ---- Colors (as requested) ----
col_pi  <- "#7FB7D6"  # theta pi
col_clr <- "#bb9cc5"  # CLR

# ---- Counts (edit if needed) ----
n_clr_only <- 5833
n_overlap  <- 575
n_pi_only  <- 906

# ---- Ellipse geometry (edit to tune overlap) ----
ellipses <- data.frame(
  set = c("CLR", "PI"),
  x0  = c(0.0, 3.6),
  y0  = c(0.0, 0.0),
  a   = c(4.7, 4.7),   # 两个一样
  b   = c(3.3, 3.3)    # 两个一样
)

# ---- Build plot ----
p <- ggplot() +
  ggforce::geom_ellipse(
    data = subset(ellipses, set == "CLR"),
    aes(x0 = x0, y0 = y0, a = a, b = b, angle = 0),
    fill = col_clr, alpha = 0.85, color = NA
  ) +
  ggforce::geom_ellipse(
    data = subset(ellipses, set == "PI"),
    aes(x0 = x0, y0 = y0, a = a, b = b, angle = 0),
    fill = col_pi, alpha = 0.85, color = NA
  ) +
  annotate("text", x = -4.8, y = 3.2, label = "CLR",
           family = font_family, size = 10) +
  annotate("text", x = 8.0, y = 3.2, label = expression(theta*pi),
           family = font_family, size = 10) +
  annotate("text", x = -2.6, y = 0.0, label = n_clr_only,
           family = font_family, size = 8) +
  annotate("text", x = 1.8, y = 0.0, label = n_overlap,
           family = font_family, size = 8) +
  annotate("text", x = 6.2, y = 0.0, label = n_pi_only,
           family = font_family, size = 8) +
  coord_fixed(xlim = c(-5.5, 8.5), ylim = c(-3.8, 3.8), expand = FALSE) +
  theme_void(base_family = font_family) +
  theme(
    plot.background  = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  )

# ---- Save path (your folder) ----
out_dir <- "E:/桌面/武汉数据/乌珠穆沁白牛/文章图汇总/测试"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

out_file <- file.path(out_dir, "venn_CLR_theta_pi.tiff")

# ---- Export TIFF: 600 dpi ----
tiff(filename = out_file, width = 12, height = 6, units = "in",
     res = 600, compression = "lzw")
print(p)
dev.off()

message("Saved to: ", out_file)
