# ============================================================
# Fig5b-style haplotype heatmap
# - ONLY heatmap; fixed group order; TRUE Arial via showtext
# - NO dendrogram: cluster_rows = FALSE
# - Font: larger Arial
# - Output: PDF + JPG + TIFF, all 600 dpi (raster); PDF also saved as vector (cairo)
# ============================================================

options(stringsAsFactors = FALSE)

# -------------------- USER SETTINGS --------------------
input_dir <- "E:/桌面/武汉数据/乌珠穆沁白牛/文章图汇总/测试/temp/01.haplotype"
interval_xlsx <- file.path(input_dir, "分析区间.xlsx")

genes_to_plot <- c("PMEL","ASIP","EDN3","PLAG1","GDF11","TRIM59","SMG6")
# genes_to_plot <- NULL

maf_min <- 0.20
keep_biallelic_snps_only <- TRUE
max_snps <- NA
row_gap_mm <- 2.5

group_order <- c("Angus","Simmental","Charolais","UW","Mo-OD","Mo-SN","Hanwoo","Bos_indicus")

# Prairie palette (your current choice)
COL_BLUE  <- "#F7F8D5"
COL_SAND  <- "#BF3826"
COL_NA    <- "#FFFFFF"
BG_WHITE  <- "white"

# ---- FONT SIZE (make bigger) ----
# Fig5b-like label size: you can tune these two
row_title_fontsize <- 16   # group labels on the left (bigger than before)
legend_fontsize <- 14      # legend (we hide labels, but keep consistent)

out_dir <- file.path(input_dir, "out_haplotype_heatmap_fig5b")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ---- OUTPUT SIZE / DPI ----
# For raster outputs (JPG/TIFF), dpi is enforced.
# For PDF, dpi doesn't really apply (vector). We'll still keep size consistent.
pdf_width_in <- 10
pdf_height_in <- 6
dpi <- 600

# Raster pixel dimensions derived from inches * dpi
jpg_width_px  <- as.integer(pdf_width_in * dpi)
jpg_height_px <- as.integer(pdf_height_in * dpi)
tif_width_px  <- jpg_width_px
tif_height_px <- jpg_height_px

# -------------------- PACKAGES --------------------
need_pkgs <- c("data.table","readxl","ComplexHeatmap","circlize","grid","showtext","sysfonts")
for (p in need_pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, dependencies = TRUE)
}
suppressPackageStartupMessages({
  library(data.table)
  library(readxl)
  library(ComplexHeatmap)
  library(circlize)
  library(grid)
  library(showtext)
  library(sysfonts)
})

has_VA <- requireNamespace("VariantAnnotation", quietly = TRUE)
has_vcfR <- requireNamespace("vcfR", quietly = TRUE)

# -------------------- FONT SETUP (Arial via showtext) --------------------
font_family <- "arial"
ok_font <- TRUE
tryCatch({
  # If system can resolve "Arial" by name
  sysfonts::font_add(family = "arial", regular = "Arial")
}, error = function(e) {
  ok_font <<- FALSE
})

# If the above fails on some setups, try loading Arial from Windows font file directly
if (!ok_font) {
  arial_path <- "C:/Windows/Fonts/arial.ttf"
  if (file.exists(arial_path)) {
    sysfonts::font_add(family = "arial", regular = arial_path)
    ok_font <- TRUE
  }
}

# Fallback
if (!ok_font) {
  message("Warning: Arial not found; fallback to sans.")
  font_family <- "sans"
}

showtext::showtext_auto(enable = TRUE)

# -------------------- HELPERS --------------------
stop_if_not <- function(cond, msg) if (!cond) stop(msg, call. = FALSE)

infer_group <- function(sample_id) {
  prefix <- sub("[0-9].*$", "", sample_id)
  prefix <- sub("-+$", "", prefix)
  
  if (grepl("^mo-od$", prefix, ignore.case = TRUE)) return("Mo-OD")
  if (grepl("^mo-sn$", prefix, ignore.case = TRUE)) return("Mo-SN")
  if (grepl("^uw$", prefix, ignore.case = TRUE)) return("UW")
  
  if (grepl("angus", prefix, ignore.case = TRUE)) return("Angus")
  if (grepl("simmental", prefix, ignore.case = TRUE)) return("Simmental")
  if (grepl("charolais", prefix, ignore.case = TRUE)) return("Charolais")
  if (grepl("hanwoo", prefix, ignore.case = TRUE)) return("Hanwoo")
  if (grepl("indicus|bos_indicus|zebu", prefix, ignore.case = TRUE)) return("Bos_indicus")
  
  toupper(prefix)
}

parse_interval <- function(x) {
  x0 <- gsub(",", "", as.character(x))
  x0 <- gsub(" ", "", x0)
  parts <- strsplit(x0, "[-–—]")[[1]]
  parts <- parts[nzchar(parts)]
  stop_if_not(length(parts) >= 2, paste0("无法解析区间：", x))
  st <- suppressWarnings(as.numeric(parts[1]))
  ed <- suppressWarnings(as.numeric(parts[2]))
  stop_if_not(!is.na(st) && !is.na(ed), paste0("区间不是数字：", x))
  if (st > ed) { tmp <- st; st <- ed; ed <- tmp }
  list(start = st, end = ed)
}

thin_snps <- function(pos_vec, max_snps) {
  if (is.na(max_snps) || length(pos_vec) <= max_snps) return(seq_along(pos_vec))
  idx <- unique(round(seq(1, length(pos_vec), length.out = max_snps)))
  idx[idx >= 1 & idx <= length(pos_vec)]
}

gt_to_haps <- function(gt_mat) {
  has_unphased <- any(grepl("/", gt_mat), na.rm = TRUE)
  stop_if_not(!has_unphased, "发现未相位GT（含 '/'）。请用 phased VCF（0|1）。")
  
  split_one <- function(x) {
    if (is.na(x) || x %in% c(".", "./.", ".|.")) return(c(NA_integer_, NA_integer_))
    parts <- strsplit(x, "\\|")[[1]]
    if (length(parts) != 2) return(c(NA_integer_, NA_integer_))
    a <- suppressWarnings(as.integer(parts[1]))
    b <- suppressWarnings(as.integer(parts[2]))
    c(a, b)
  }
  
  nvar <- nrow(gt_mat); ns <- ncol(gt_mat)
  h1 <- matrix(NA_integer_, nrow = nvar, ncol = ns, dimnames = dimnames(gt_mat))
  h2 <- matrix(NA_integer_, nrow = nvar, ncol = ns, dimnames = dimnames(gt_mat))
  
  for (i in seq_len(nvar)) {
    for (j in seq_len(ns)) {
      ab <- split_one(gt_mat[i, j])
      h1[i, j] <- ab[1]
      h2[i, j] <- ab[2]
    }
  }
  list(h1 = h1, h2 = h2)
}

build_minor_matrix <- function(h1, h2) {
  hap <- cbind(h1, h2)
  alt_freq <- apply(hap, 1, function(x) {
    x <- x[!is.na(x)]
    if (length(x) == 0) return(NA_real_)
    mean(x == 1)
  })
  maf <- pmin(alt_freq, 1 - alt_freq)
  
  minor_is_alt <- alt_freq <= 0.5
  minor_mat <- hap
  for (i in seq_len(nrow(hap))) {
    if (is.na(minor_is_alt[i])) next
    if (!minor_is_alt[i]) {
      minor_mat[i, ] <- ifelse(is.na(hap[i, ]), NA_integer_, 1L - hap[i, ])
    }
  }
  list(minor_mat = minor_mat, maf = maf)
}

is_biallelic_snv_vec <- function(ref, alt) {
  nchar(ref) == 1 & nchar(alt) == 1 & !grepl(",", alt, fixed = TRUE)
}

normalize_chr <- function(chr_vec) {
  chr_vec <- as.character(chr_vec)
  gsub("^CHR", "chr", chr_vec, ignore.case = TRUE)
}

read_vcf_any <- function(vcf_gz) {
  idx_tbi <- paste0(vcf_gz, ".tbi")
  idx_csi <- paste0(vcf_gz, ".csi")
  
  if (has_VA && (file.exists(idx_tbi) || file.exists(idx_csi))) {
    suppressPackageStartupMessages(library(VariantAnnotation))
    vcf <- VariantAnnotation::readVcf(vcf_gz)
    gt <- VariantAnnotation::geno(vcf)$GT
    rr <- VariantAnnotation::rowRanges(vcf)
    ref <- as.character(VariantAnnotation::ref(vcf))
    alt_list <- VariantAnnotation::alt(vcf)
    alt_chr <- vapply(alt_list, function(a) paste(as.character(a), collapse=","), character(1))
    list(
      gt = gt,
      chr = as.character(GenomeInfoDb::seqnames(rr)),
      pos = GenomicRanges::start(rr),
      ref = ref,
      alt = alt_chr,
      samples = colnames(gt)
    )
  } else {
    stop_if_not(has_vcfR,
                paste0("建议为VCF建立索引(.tbi/.csi)以更快读取。\n",
                       "解决：tabix -p vcf GENE.vcf.gz 或 bcftools index -t GENE.vcf.gz\n",
                       "或者安装 vcfR：install.packages('vcfR')\n",
                       "VCF：", vcf_gz)
    )
    suppressPackageStartupMessages(library(vcfR))
    v <- vcfR::read.vcfR(vcf_gz, verbose = FALSE)
    gt <- vcfR::extract.gt(v, element = "GT")
    fix <- v@fix
    list(
      gt = gt,
      chr = fix[, "CHROM"],
      pos = suppressWarnings(as.numeric(fix[, "POS"])),
      ref = fix[, "REF"],
      alt = fix[, "ALT"],
      samples = colnames(gt)
    )
  }
}

standardize_interval_table <- function(dt) {
  nms <- names(dt)
  pick_col <- function(patterns) {
    for (pat in patterns) {
      hit <- grep(pat, nms, ignore.case = TRUE, value = TRUE)
      if (length(hit) >= 1) return(hit[1])
    }
    NA_character_
  }
  gene_col <- pick_col(c("^gene$", "基因", "GENE"))
  chr_col  <- pick_col(c("^chr$", "染色体", "chrom"))
  int_col  <- pick_col(c("±0\\.1", "0\\.1", "0p1", "0_1", "0.1Mb", "区间"))
  
  stop_if_not(!is.na(gene_col) && !is.na(chr_col) && !is.na(int_col),
              paste0("分析区间.xlsx 里找不到必要列。当前列名：", paste(nms, collapse = ", ")))
  
  setnames(dt, gene_col, "gene")
  setnames(dt, chr_col,  "chr")
  setnames(dt, int_col,  "interval_0p1Mb")
  dt[]
}

order_rows_by_group <- function(hap_groups, group_order) {
  g <- as.character(hap_groups)
  extra <- unique(g[!(g %in% group_order)])
  lvl <- c(group_order, extra)
  order(match(g, lvl), seq_along(g))
}

draw_out <- function(ht, out_pdf, out_jpg, out_tif) {
  
  # ---- PDF (vector; dpi not applicable, but keep same size) ----
  grDevices::cairo_pdf(out_pdf, width = pdf_width_in, height = pdf_height_in, bg = BG_WHITE)
  grid::grid.newpage()
  ComplexHeatmap::draw(ht, heatmap_legend_side = "right")
  grDevices::dev.off()
  
  # ---- JPG 600 dpi ----
  grDevices::jpeg(out_jpg, width = jpg_width_px, height = jpg_height_px, res = dpi, quality = 95, bg = BG_WHITE)
  grid::grid.newpage()
  ComplexHeatmap::draw(ht, heatmap_legend_side = "right")
  grDevices::dev.off()
  
  # ---- TIFF 600 dpi ----
  # compression="lzw" is publication-friendly
  grDevices::tiff(out_tif, width = tif_width_px, height = tif_height_px, res = dpi,
                  compression = "lzw", bg = BG_WHITE)
  grid::grid.newpage()
  ComplexHeatmap::draw(ht, heatmap_legend_side = "right")
  grDevices::dev.off()
}

# -------------------- LOAD INTERVALS --------------------
stop_if_not(file.exists(interval_xlsx), paste0("找不到区间表：", interval_xlsx))

iv <- readxl::read_excel(interval_xlsx, sheet = 1)
iv <- as.data.table(iv)
iv <- standardize_interval_table(iv)
iv[, chr := normalize_chr(chr)]

if (is.null(genes_to_plot)) {
  candidates <- unique(iv$gene)
  genes_to_plot <- candidates[file.exists(file.path(input_dir, paste0(candidates, ".vcf.gz")))]
}
stop_if_not(length(genes_to_plot) > 0, "genes_to_plot 为空：请检查区间表 gene 是否与 VCF 文件名一致。")

# -------------------- MAIN LOOP --------------------
for (gene_id in genes_to_plot) {
  
  row <- iv[gene == gene_id]
  stop_if_not(nrow(row) == 1, paste0("区间表里 gene=", gene_id, " 不唯一或不存在"))
  
  chr_target <- row$chr[1]
  se <- parse_interval(row$interval_0p1Mb[1])
  region_start <- se$start
  region_end <- se$end
  
  vcf_file <- file.path(input_dir, paste0(gene_id, ".vcf.gz"))
  stop_if_not(file.exists(vcf_file), paste0("找不到VCF：", vcf_file))
  
  message("\n[", gene_id, "] Reading: ", vcf_file)
  v <- read_vcf_any(vcf_file)
  
  v_chr <- normalize_chr(v$chr)
  chr_candidates <- if (grepl("^chr", chr_target, ignore.case = TRUE)) {
    unique(c(chr_target, sub("^chr", "", chr_target, ignore.case = TRUE)))
  } else {
    unique(c(chr_target, paste0("chr", chr_target)))
  }
  
  in_region <- (v_chr %in% chr_candidates) & (v$pos >= region_start) & (v$pos <= region_end)
  stop_if_not(any(in_region), paste0(gene_id, ": 在 ", chr_target, ":", region_start, "-", region_end, " 没有变异位点"))
  
  gt <- v$gt[in_region, , drop = FALSE]
  pos <- v$pos[in_region]
  ref <- v$ref[in_region]
  alt <- v$alt[in_region]
  
  if (keep_biallelic_snps_only) {
    keep <- is_biallelic_snv_vec(ref, alt)
    gt <- gt[keep, , drop = FALSE]
    pos <- pos[keep]
  }
  stop_if_not(nrow(gt) > 0, paste0(gene_id, ": 过滤后没有可用的二等位SNP"))
  
  ord <- order(pos)
  gt <- gt[ord, , drop = FALSE]
  pos <- pos[ord]
  
  samples <- colnames(gt)
  groups <- vapply(samples, infer_group, character(1))
  
  # haplotypes -> minor-coded matrix
  haps <- gt_to_haps(gt)
  mm <- build_minor_matrix(haps$h1, haps$h2)
  
  keep_maf <- which(!is.na(mm$maf) & mm$maf >= maf_min)
  stop_if_not(length(keep_maf) > 0, paste0(gene_id, ": MAF>=", maf_min, " 后没有位点"))
  
  minor_mat <- mm$minor_mat[keep_maf, , drop = FALSE]
  pos2 <- pos[keep_maf]
  
  idx_thin <- thin_snps(pos2, max_snps)
  minor_mat <- minor_mat[idx_thin, , drop = FALSE]
  pos2 <- pos2[idx_thin]
  
  # rows=haplotypes, cols=variants
  hap_ids <- c(paste0(samples, "_h1"), paste0(samples, "_h2"))
  hap_groups <- rep(groups, times = 2)
  
  colnames(minor_mat) <- hap_ids
  mat <- t(minor_mat)
  
  # fixed group order + stable order within group
  row_ord <- order_rows_by_group(hap_groups, group_order)
  mat <- mat[row_ord, , drop = FALSE]
  hap_groups <- hap_groups[row_ord]
  
  hap_groups_f <- factor(hap_groups, levels = c(group_order, setdiff(unique(hap_groups), group_order)))
  
  # discrete colors: 0->green, 1->wheat
  col_map <- c("0" = COL_BLUE, "1" = COL_SAND)
  
  ht <- Heatmap(
    mat,
    name = "allele",
    col = col_map,
    na_col = COL_NA,
    show_row_names = FALSE,
    show_column_names = FALSE,
    cluster_columns = FALSE,
    cluster_rows = FALSE,
    row_split = hap_groups_f,
    row_gap = unit(row_gap_mm, "mm"),
    row_title_rot = 0,
    row_title_side = "left",
    row_title_gp = gpar(fontsize = row_title_fontsize, fontfamily = font_family),
    rect_gp = gpar(col = NA),
    border = FALSE,
    heatmap_legend_param = list(
      title = NULL, at = c(0, 1), labels = c("", ""),
      labels_gp = gpar(fontsize = legend_fontsize, fontfamily = font_family)
    )
  )
  
  out_pdf <- file.path(out_dir, paste0(gene_id, "_fixedOrder_noTree_Arial_600dpi.pdf"))
  out_jpg <- file.path(out_dir, paste0(gene_id, "_fixedOrder_noTree_Arial_600dpi.jpg"))
  out_tif <- file.path(out_dir, paste0(gene_id, "_fixedOrder_noTree_Arial_600dpi.tiff"))
  
  draw_out(ht, out_pdf, out_jpg, out_tif)
  
  message("[", gene_id, "] Saved: ", out_pdf, " / ", out_jpg, " / ", out_tif)
}

message("\nAll done. Output folder:\n", out_dir)
