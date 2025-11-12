# -------------------------------------
# 依赖包
# -------------------------------------
# install.packages(c("sf", "ggplot2", "rnaturalearth", "rnaturalearthdata"))
library(sf)
library(ggplot2)
library(rnaturalearth)
library(rnaturalearthdata)

# -------------------------------------
# 1. 世界地图数据
# -------------------------------------
world <- ne_countries(scale = "medium", returnclass = "sf")

# -------------------------------------
# 2. 提取中国数据
# -------------------------------------
china <- world[world$name == "China", ]  # 中国

# -------------------------------------
# 3. 绘制缩略图（中国灰色，其他浅灰）
# -------------------------------------
inset_map <- ggplot() +
  geom_sf(data = world, fill = "grey90", color = "grey70", size = 0.2) +  # 其他国家浅灰
  geom_sf(data = china, fill = "grey60", color = "grey50", size = 0.3) +   # 中国深灰
  theme_void() +
  theme(
    legend.position = "none",
    plot.background = element_rect(color = "black", fill = NA, size = 1),  # 外框
    panel.border = element_rect(color = "black", fill = NA, size = 1)
  )

# -------------------------------------
# 4. 保存缩略图
# -------------------------------------
ggsave("World_inset_map_china_grey.png", inset_map, width = 6, height = 3.5, dpi = 400)
