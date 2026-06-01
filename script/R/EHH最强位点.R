# ============================================================
# Fig5c-style EHH plots using rehh::data2haplohh (auto-detect args)
# Window: "±0.1 Mb 区间" from 分析区间.xlsx
# Core SNPs: user-provided (chr_pos)
# Outputs: PDF + JPG(600dpi) + TIFF(600dpi)
# ============================================================

options(stringsAsFactors = FALSE)

# -------------------- USER SETTINGS --------------------
input_dir <- "E:/桌面/武汉数据/乌珠穆沁白牛/文章图汇总/测试/temp/02.EHH/"
interval_xlsx <- file.path(input_dir, "分析区间.xlsx")

vcf_chr_dir <- input_dir   # chr*.vcf.gz 的目录（按需修改）
out_dir <- file.path(input_dir, "out_EHH_Fig5c_pm0p1Mb")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

maf_min <- 0.20
keep_biallelic_snps_only <- TRUE

w_in <- 4.4
h_in <- 2.9
dpi <- 600

COL_ANC <- "#2B6CB0"
COL_DER <- "#7A3DB8"

# 关键：如果你的VCF没有祖先等位基因信息(AA) 或你不想极化，就保持 FALSE
polarize_vcf <- FALSE

# 若 polarize_vcf=FALSE，会自动强制 label_as_AD=FALSE（避免把 major/minor 误写成 A/D）
label_as_AD <- TRUE

core_tbl <- data.frame(
  gene = c("ASIP","EDN3","GDF11","PLAG1","PMEL","SMG6","TRIM59"),
  chr  = c("chr13","chr13","chr5","chr14","chr5","chr19","chr1"),
  core_pos = c(63559879, 57104104, 57408786, 23241926, 57401689, 23107200, 107051336),
  stringsAsFactors = FALSE
)

# -------------------- PACKAGES --------------------
need_pkgs <- c("readxl","data.table","VariantAnnotation","GenomicRanges","IRanges",
               "Rsamtools","rehh","ggplot2","showtext","sysfonts")
for (p in need_pkgs) if (!requireNamespace(p, quietly = TRUE)) install.packages(p, dependencies = TRUE)

suppressPackageStartupMessages({
  library(readxl)
  library(data.table)
  library(VariantAnnotation)
  library(GenomicRanges)
  library(IRanges)
  library(Rsamtools)
  library(rehh)
  library(ggplot2)
  library(showtext)
  library(sysfonts)
})

# -------------------- FONT: Arial --------------------
ok_font <- TRUE
tryCatch({
  sysfonts::font_add(family = "arial", regular = "Arial")
}, error = function(e) ok_font <<- FALSE)
if (!ok_font && file.exists("C:/Windows/Fonts/arial.ttf")) {
  sysfonts::font_add(family = "arial", regular = "C:/Windows/Fonts/arial.ttf")
  ok_font <- TRUE
}
showtext::showtext_auto(TRUE)
FONT <- if (ok_font) "arial" else "sans"

# -------------------- HELPERS --------------------
stop_if_not <- function(cond, msg) if (!isTRUE(cond)) stop(msg, call. = FALSE)

normalize_chr <- function(x) gsub("^CHR", "chr", as.character(x), ignore.case = TRUE)

parse_interval <- function(x) {
  x0 <- gsub(",", "", as.character(x))
  x0 <- gsub(" ", "", x0)
  stop_if_not(length(x0) == 1 && nchar(x0) > 0, paste0("区间为空/缺失：", x))
  parts <- strsplit(x0, "[-–—]")[[1]]
  parts <- parts[nzchar(parts)]
  stop_if_not(length(parts) >= 2, paste0("无法解析区间：", x))
  st <- suppressWarnings(as.numeric(parts[1]))
  ed <- suppressWarnings(as.numeric(parts[2]))
  stop_if_not(!is.na(st) && !is.na(ed), paste0("区间不是数字：", x))
  if (st > ed) { tmp <- st; st <- ed; ed <- tmp }
  list(start = st, end = ed)
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
  int_col  <- pick_col(c("±0\\.1", "0\\.1Mb", "0\\.1", "0p1", "0_1"))
  stop_if_not(!is.na(gene_col) && !is.na(chr_col) && !is.na(int_col),
              paste0("分析区间.xlsx 找不到必要列。\n列名：", paste(nms, collapse=", "),
                     "\n请确认存在“±0.1Mb 区间”那一列。"))
  setnames(dt, gene_col, "gene")
  setnames(dt, chr_col, "chr")
  setnames(dt, int_col, "interval_0p1Mb")
  dt[]
}

ensure_tabix_index <- function(vcfgz) {
  tbi <- paste0(vcfgz, ".tbi")
  csi <- paste0(vcfgz, ".csi")
  if (!file.exists(tbi) && !file.exists(csi)) {
    message("Index not found, creating tabix index: ", basename(vcfgz))
    Rsamtools::indexTabix(vcfgz, format = "vcf")
  }
}

is_biallelic_snv_vec <- function(ref, alt) {
  nchar(ref) == 1 & nchar(alt) == 1 & !grepl(",", alt, fixed = TRUE)
}

calc_maf_from_GT <- function(gt_mat) {
  parse_one <- function(x) {
    if (is.na(x) || x %in% c(".", "./.", ".|.")) return(c(NA_integer_, NA_integer_))
    if (grepl("/", x)) return(c(NA_integer_, NA_integer_))
    sp <- strsplit(x, "\\|")[[1]]
    if (length(sp) != 2) return(c(NA_integer_, NA_integer_))
    c(suppressWarnings(as.integer(sp[1])), suppressWarnings(as.integer(sp[2])))
  }
  nvar <- nrow(gt_mat)
  maf <- rep(NA_real_, nvar)
  for (i in seq_len(nvar)) {
    ab <- do.call(rbind, lapply(gt_mat[i, ], parse_one))
    alleles <- as.vector(ab)
    alleles <- alleles[!is.na(alleles)]
    if (length(alleles) == 0) next
    p_alt <- mean(alleles == 1)
    maf[i] <- min(p_alt, 1 - p_alt)
  }
  maf
}

make_region_vcfgz <- function(chr_vcfgz, chr, start, end, out_prefix) {
  ensure_tabix_index(chr_vcfgz)
  tbx <- Rsamtools::TabixFile(chr_vcfgz)
  param <- VariantAnnotation::ScanVcfParam(which = GRanges(chr, IRanges(start, end)))
  v <- VariantAnnotation::readVcf(tbx, genome = NA_character_, param = param)
  stop_if_not(nrow(v) > 0, paste0("区间内无变异：", chr, ":", start, "-", end))
  
  gt <- geno(v)$GT
  stop_if_not(!any(grepl("/", gt), na.rm = TRUE), "发现未相位GT（含'/'），请用 phased VCF（0|1）。")
  
  if (keep_biallelic_snps_only) {
    ref <- as.character(ref(v))
    alt_list <- alt(v)
    alt_chr <- vapply(alt_list, function(a) paste(as.character(a), collapse=","), character(1))
    keep <- is_biallelic_snv_vec(ref, alt_chr)
    v <- v[keep]
    stop_if_not(nrow(v) > 0, "过滤后无可用二等位 SNP。")
  }
  
  maf <- calc_maf_from_GT(geno(v)$GT)
  v <- v[!is.na(maf) & maf >= maf_min]
  stop_if_not(nrow(v) > 0, paste0("MAF>=", maf_min, " 后无位点。可把 maf_min 改小。"))
  
  tmp_vcf <- paste0(out_prefix, ".vcf")
  tmp_vcfgz <- paste0(out_prefix, ".vcf.gz")
  writeVcf(v, tmp_vcf)
  Rsamtools::bgzip(tmp_vcf, dest = tmp_vcfgz, overwrite = TRUE)
  Rsamtools::indexTabix(tmp_vcfgz, format = "vcf")
  unlink(tmp_vcf)
  tmp_vcfgz
}

get_core_label <- function(region_vcfgz, chr, core_pos) {
  ensure_tabix_index(region_vcfgz)
  v <- readVcf(Rsamtools::TabixFile(region_vcfgz), genome = NA_character_)
  pos <- start(rowRanges(v))
  j <- which.min(abs(pos - core_pos))
  used_pos <- pos[j]
  id <- names(rowRanges(v))[j]
  if (is.null(id) || is.na(id) || id == "." || id == "") id <- paste0(chr, ":", used_pos)
  list(label = id, used_pos = used_pos)
}

# ---------- robust call data2haplohh ----------
call_data2haplohh_vcf <- function(vcfgz_region, chr, polarize_vcf = FALSE) {
  fml <- names(formals(rehh::data2haplohh))
  
  if ("vcf_file" %in% fml) {
    # rehh 新版常见
    return(rehh::data2haplohh(
      vcf_file = vcfgz_region,
      chr.name = chr,
      polarize_vcf = polarize_vcf,
      verbose = FALSE
    ))
  }
  
  if ("hap_file" %in% fml) {
    # 某些版本用 hap_file 接收 vcf
    if ("polarize_vcf" %in% fml) {
      return(rehh::data2haplohh(
        hap_file = vcfgz_region,
        chr.name = chr,
        polarize_vcf = polarize_vcf,
        verbose = FALSE
      ))
    } else {
      # 老版本可能没有 polarize_vcf 参数
      return(rehh::data2haplohh(
        hap_file = vcfgz_region,
        chr.name = chr,
        verbose = FALSE
      ))
    }
  }
  
  stop("你的 rehh::data2haplohh 不支持直接读 VCF。\n",
       "请把 VCF 转为 .haps/.map 再读（我也可以给你对应脚本）。\n",
       "当前 data2haplohh 参数为：", paste(fml, collapse = ", "))
}

# ---------- robust positions accessor ----------
get_hh_positions <- function(hh) {
  # 优先用 accessor
  p <- tryCatch(rehh::positions(hh), error = function(e) NULL)
  if (!is.null(p)) return(p)
  # 退回 slot（一些旧版可能有）
  sn <- tryCatch(methods::slotNames(hh), error = function(e) character(0))
  if ("positions" %in% sn) return(hh@positions)
  stop("无法获取 haplohh positions：rehh 版本/对象结构不兼容。")
}

extract_ehh_df <- function(ehh_obj) {
  df <- as.data.frame(ehh_obj$ehh)
  pos_col <- grep("POS", names(df), ignore.case = TRUE, value = TRUE)
  if (length(pos_col) == 0) pos_col <- names(df)[1]
  pos_col <- pos_col[1]
  ycols <- setdiff(names(df), pos_col)
  ycols <- ycols[1:2]
  stop_if_not(length(ycols) == 2, "calc_ehh 输出解析失败（未得到两条曲线）。")
  data.frame(pos = df[[pos_col]], ehh0 = df[[ycols[1]]], ehh1 = df[[ycols[2]]])
}

plot_and_save <- function(dd, chr, core_pos_used, core_label, win_start, win_end, out_prefix,
                          label_as_AD = TRUE, col0 = "#2B6CB0", col1 = "#7A3DB8") {
  dd$Mb <- dd$pos / 1e6
  coreMb <- core_pos_used / 1e6
  
  lab0 <- if (label_as_AD) "Ancestral" else "Allele0"
  lab1 <- if (label_as_AD) "Derived"   else "Allele1"
  
  d_long <- rbind(
    data.frame(Mb = dd$Mb, EHH = dd$ehh0, type = lab0),
    data.frame(Mb = dd$Mb, EHH = dd$ehh1, type = lab1)
  )
  
  p <- ggplot(d_long, aes(x = Mb, y = EHH, color = type)) +
    geom_line(linewidth = 0.9) +
    geom_vline(xintercept = coreMb, linetype = "dashed", linewidth = 0.6, color = "black") +
    coord_cartesian(ylim = c(0, 1), xlim = c(win_start/1e6, win_end/1e6)) +
    labs(
      x = "Position (Mb)",
      y = "Extended haplotype homozygosity",
      title = paste0(core_label, " (", chr, ": ", format(core_pos_used, big.mark=","), ")")
    ) +
    # 修复：用真实标签名做 mapping
    scale_color_manual(values = setNames(c(col0, col1), c(lab0, lab1))) +
    theme_classic(base_family = FONT, base_size = 14) +
    theme(
      plot.title = element_text(size = 11, face = "plain"),
      legend.title = element_blank(),
      legend.position = c(0.14, 0.87),
      legend.background = element_blank(),
      legend.key = element_blank()
    )
  
  grDevices::cairo_pdf(paste0(out_prefix, ".pdf"), width = w_in, height = h_in, bg = "white")
  print(p); grDevices::dev.off()
  
  grDevices::jpeg(paste0(out_prefix, "_600dpi.jpg"), width = w_in, height = h_in, units = "in",
                  res = dpi, quality = 95, bg = "white")
  print(p); grDevices::dev.off()
  
  grDevices::tiff(paste0(out_prefix, "_600dpi.tiff"), width = w_in, height = h_in, units = "in",
                  res = dpi, compression = "lzw", bg = "white")
  print(p); grDevices::dev.off()
}

# -------------------- POLARIZATION CONSISTENCY --------------------
if (!isTRUE(polarize_vcf) && isTRUE(label_as_AD)) {
  message("NOTE: polarize_vcf=FALSE -> EHH will be computed as major/minor, not ancestral/derived.\n",
          "      Automatically setting label_as_AD=FALSE for correct legend.")
  label_as_AD <- FALSE
}
polarized_calc <- isTRUE(polarize_vcf)

# -------------------- LOAD INTERVAL TABLE --------------------
stop_if_not(file.exists(interval_xlsx), paste0("找不到区间表：", interval_xlsx))
iv <- as.data.table(readxl::read_excel(interval_xlsx, sheet = 1))
iv <- standardize_interval_table(iv)
iv[, chr := normalize_chr(chr)]

miss <- setdiff(core_tbl$gene, iv$gene)
stop_if_not(length(miss) == 0, paste0("分析区间表缺少这些基因：", paste(miss, collapse = ", ")))

# -------------------- MAIN LOOP --------------------
for (i in seq_len(nrow(core_tbl))) {
  
  gene_id  <- core_tbl$gene[i]
  chr      <- core_tbl$chr[i]
  core_pos <- core_tbl$core_pos[i]
  
  row <- iv[gene == gene_id]
  stop_if_not(nrow(row) == 1, paste0("分析区间表里 gene=", gene_id, " 不唯一或不存在。"))
  
  se <- parse_interval(row$interval_0p1Mb[1])
  win_start <- se$start
  win_end   <- se$end
  
  stop_if_not(core_pos >= win_start && core_pos <= win_end,
              paste0(gene_id, " core_pos=", core_pos, " 不在表格区间内：",
                     chr, ":", win_start, "-", win_end))
  
  chr_vcf <- file.path(vcf_chr_dir, paste0(chr, ".vcf.gz"))
  stop_if_not(file.exists(chr_vcf), paste0("找不到VCF：", chr_vcf))
  
  message(sprintf("\n[%s] %s core=%d, window=%d-%d (±0.1Mb from table)",
                  gene_id, chr, core_pos, win_start, win_end))
  
  tmp_prefix <- file.path(out_dir, paste0(gene_id, "_", chr, "_", win_start, "_", win_end))
  region_vcfgz <- make_region_vcfgz(chr_vcf, chr, win_start, win_end, paste0(tmp_prefix, "_region"))
  
  lab <- get_core_label(region_vcfgz, chr, core_pos)
  core_label <- lab$label
  core_pos_used <- lab$used_pos
  
  hh <- call_data2haplohh_vcf(region_vcfgz, chr, polarize_vcf = polarize_vcf)
  
  # -------- FIX: no hh@markers; use positions accessor + integer mrk index --------
  posv <- get_hh_positions(hh)
  j <- which.min(abs(posv - core_pos_used))
  core_pos_used <- posv[j]
  
  ehh <- rehh::calc_ehh(hh, mrk = j, polarized = polarized_calc)
  dd <- extract_ehh_df(ehh)
  
  out_prefix <- file.path(out_dir, paste0(gene_id, "_Fig5c_EHH_pm0p1Mb_", chr, "_", core_pos))
  plot_and_save(dd, chr, core_pos_used, core_label, win_start, win_end, out_prefix,
                label_as_AD = label_as_AD, col0 = COL_ANC, col1 = COL_DER)
  
  message(sprintf("[%s] saved: %s(.pdf/.jpg/.tiff)", gene_id, out_prefix))
}

message("\nAll done! Output folder:\n", out_dir)
