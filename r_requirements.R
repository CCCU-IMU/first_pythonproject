#!/usr/bin/env Rscript

# Optional R dependencies used by scripts under script/R/.
# Run with: Rscript r_requirements.R

cran_packages <- c(
  "ape",
  "cols4all",
  "cowplot",
  "data.table",
  "dplyr",
  "ggbreak",
  "ggforce",
  "ggplot2",
  "ggrepel",
  "ggsci",
  "RColorBrewer",
  "rlang",
  "scales",
  "showtext",
  "stringr",
  "sysfonts",
  "tidyverse",
  "VennDiagram"
)

missing_cran <- cran_packages[!vapply(cran_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_cran) > 0) {
  install.packages(missing_cran, dependencies = TRUE)
}

if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}

bioc_packages <- c("biomaRt", "ComplexHeatmap", "ggtree")
missing_bioc <- bioc_packages[!vapply(bioc_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_bioc) > 0) {
  BiocManager::install(missing_bioc, ask = FALSE, update = FALSE)
}

if (!requireNamespace("ggsankey", quietly = TRUE)) {
  if (!requireNamespace("remotes", quietly = TRUE)) {
    install.packages("remotes")
  }
  remotes::install_github("davidsjoberg/ggsankey")
}
