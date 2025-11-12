import geopandas as gpd
import matplotlib.pyplot as plt

# 替换成你本地的路径
shapefile_path = r"E:\桌面\武汉数据\乌珠穆沁白牛\白牛文章图片\地图\ne_110m_admin_0_countries\ne_110m_admin_0_countries.shp"

# 读取 shapefile
world = gpd.read_file(shapefile_path)

# 示例采样点
from shapely.geometry import Point
import pandas as pd

data = {
    'Site': ['UW', 'Hanwoo'],
    'Longitude': [109.4, 138.1],
    'Latitude': [40.9, 36.2]
}
df = pd.DataFrame(data)
gdf_points = gpd.GeoDataFrame(df, geometry=gpd.points_from_xy(df.Longitude, df.Latitude), crs='EPSG:4326')

# 绘图
fig, ax = plt.subplots(figsize=(10, 6))
world.plot(ax=ax, color='whitesmoke', edgecolor='gray')
gdf_points.plot(ax=ax, color='red', markersize=30)

# 添加标签
for x, y, label in zip(df.Longitude, df.Latitude, df.Site):
    ax.text(x + 0.5, y + 0.5, label, fontsize=15)

ax.set_xlim(40, 150)
ax.set_ylim(15,  55)
ax.set_title("Sampling Sites in East Asia")
plt.axis('off')
plt.tight_layout()
plt.show()