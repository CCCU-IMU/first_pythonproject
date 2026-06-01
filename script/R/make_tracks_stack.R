# ============================================================
# make_tracks_stack.R
# Stack multiple ggplot track panels with perfectly aligned
# panel widths, then export as PDF/PNG/TIFF.
#
# Usage (in R):
#   source('make_tracks_stack.R')
#   make_tracks_stack(gene='ASIP', rds_dir='path/to/rds', out_dir='path/to/out')
#   make_tracks_stack(gene='PMEL', rds_dir='path/to/rds', out_dir='path/to/out')
# ============================================================

suppressPackageStartupMessages({
  library(ggplot2)
  library(cowplot)
  library(tools)
})

.pick_one <- function(files, label) {
  if (length(files) == 0) stop('No match for: ', label)
  if (length(files) > 1) {
    message('Multiple matches for ', label, ' -> using first:\n  ', files[1],
            '\nOther matches:\n  ', paste(files[-1], collapse='\n  '))
  }
  files[1]
}

.strip_x <- function(p) {
  p + theme(
    # Keep tick marks (so inward ticks remain), but hide labels/title
    axis.text.x  = element_blank(),
    axis.title.x = element_blank()
  )
}

.fix_margin <- function(p, top=4, right=6, bottom=3, left=6) {
  p + theme(plot.margin = margin(top, right, bottom, left))
}

#' Build an aligned stacked track figure for one gene.
#'
#' @param gene Character. e.g. 'ASIP' or 'PMEL'
#' @param rds_dir Directory that contains the exported *.rds files.
#' @param out_dir Output directory.
#' @param prefix Output file prefix (default gene).
#' @param keep_all_x Logical. If FALSE, only the bottom track keeps the x-axis.
#' @param fig_w Numeric. Width in inches.
#' @param track_h Numeric. Base height per track in inches.
#' @return The combined ggplot object (invisibly).
make_tracks_stack <- function(
    gene,
    rds_dir,
    out_dir = rds_dir,
    prefix = gene,
    keep_all_x = FALSE,
    fig_w = 8.2,
    track_h = 1.5
) {
  stopifnot(dir.exists(rds_dir))
  if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)
  
  # ---- locate files ----
  f_ihs <- .pick_one(list.files(rds_dir, pattern = paste0('^', gene, '_chr.*_iHS\\.rds$'),
                                full.names = TRUE), paste0(gene, ' iHS'))
  f_anc <- .pick_one(list.files(rds_dir, pattern = paste0('^', gene, '_chr.*_Ancestry\\.rds$'),
                                full.names = TRUE), paste0(gene, ' Ancestry'))
  f_taj <- .pick_one(list.files(rds_dir, pattern = paste0('^', gene, '_chr.*_TajimasD\\.rds$'),
                                full.names = TRUE), paste0(gene, " Tajima's D"))
  f_fst <- .pick_one(list.files(rds_dir, pattern = paste0('^', gene, '_Fst\\.rds$'),
                                full.names = TRUE), paste0(gene, ' FST'))
  f_gene <- .pick_one(list.files(rds_dir, pattern = paste0('^GeneTrack_.*_', gene, '_.*\\.rds$'),
                                 full.names = TRUE), paste0(gene, ' GeneTrack'))
  
  # ---- read plots ----
  p_ihs  <- readRDS(f_ihs)
  p_anc  <- readRDS(f_anc)
  p_fst  <- readRDS(f_fst)
  p_taj  <- readRDS(f_taj)
  p_gene <- readRDS(f_gene)
  
  # ---- optional: only bottom keeps x axis ----
  if (!keep_all_x) {
    p_ihs <- .strip_x(p_ihs)
    p_anc <- .strip_x(p_anc)
    p_fst <- .strip_x(p_fst)
    p_taj <- .strip_x(p_taj)
    # keep p_gene x
  }
  
  # ---- fix margins so align is stable ----
  plots <- list(
    .fix_margin(p_ihs),
    .fix_margin(p_anc),
    .fix_margin(p_fst),
    .fix_margin(p_taj),
    .fix_margin(p_gene)
  )
  
  # ---- force identical panel widths ----
  aligned <- align_plots(plotlist = plots, align = 'v', axis = 'lr')
  
  # relative heights (tweak if you want a thinner gene track)
  rel_h <- c(1, 1, 1, 1, 0.73)
  fig_h <- track_h * sum(rel_h)
  
  final <- plot_grid(plotlist = aligned, ncol = 1, rel_heights = rel_h)
  
  # ---- export ----
  out_pdf  <- file.path(out_dir, paste0(prefix, '_tracks_aligned.pdf'))
  out_png  <- file.path(out_dir, paste0(prefix, '_tracks_aligned.png'))
  out_tiff <- file.path(out_dir, paste0(prefix, '_tracks_aligned.tiff'))
  
  # Use cairo if available; otherwise fall back.
  try({
    ggsave(out_pdf, final, width = fig_w, height = fig_h, device = cairo_pdf)
  }, silent = TRUE)
  if (!file.exists(out_pdf)) {
    ggsave(out_pdf, final, width = fig_w, height = fig_h, device = 'pdf')
  }
  
  ggsave(out_png,  final, width = fig_w, height = fig_h, dpi = 600)
  ggsave(out_tiff, final, width = fig_w, height = fig_h, dpi = 600,
         device = 'tiff', compression = 'lzw')
  
  message('Saved:\n  ', out_pdf, '\n  ', out_png, '\n  ', out_tiff)
  invisible(final)
}
