import os
import numpy as np
import matplotlib.pyplot as plt
import rasterio
from matplotlib.font_manager import FontProperties

# ==============================
# 1. 路径与参数设置
# ==============================

# 气候数据根目录（你改成苏尼特左旗气候数据所在文件夹）
climate_base_dir = r"E:\桌面\武汉数据\乌珠穆沁白牛\白牛文章\气候数据"  # TODO: 修改为你的实际路径

tmin_dir = os.path.join(climate_base_dir, "tmin")
tmax_dir = os.path.join(climate_base_dir, "tmax")
prec_dir = os.path.join(climate_base_dir, "prec")

# 苏尼特左旗坐标（经度, 纬度）
coords = {
    "Sunite Zuoqi": (113.6506, 43.8569)   # 苏尼特左旗
}

year = 2024
months = np.arange(1, 13)

# 输出目录
out_dir = r"D:\Python\script\pythonProject\data\result"
os.makedirs(out_dir, exist_ok=True)

# ==============================
# 2. 字体与配色
# ==============================

# 全局默认字体：Times New Roman（数字、英文字母）
plt.rcParams["font.family"] = "Times New Roman"
plt.rcParams["axes.unicode_minus"] = False  # 解决负号显示问题

# 中文宋体（用于标题、坐标轴标签、图例中文）
# 如果报错，可改为绝对路径：FontProperties(fname=r"C:\Windows\Fonts\simsun.ttc")
ch_font = FontProperties(family="SimSun")

# 你指定的两种配色
COL_TMAX = "#E73F74"   # 最高气温（洋红）
COL_TMIN = "#11A579"   # 最低气温（绿色）
COL_PREC = "#11A579"   # 降水量柱形同用绿色（形状区分：柱 vs 线）

# 统一字号略大一些，适合论文插图
plt.rcParams["font.size"] = 12
plt.rcParams["axes.titlesize"] = 16
plt.rcParams["axes.labelsize"] = 14
plt.rcParams["xtick.labelsize"] = 12
plt.rcParams["ytick.labelsize"] = 12
plt.rcParams["legend.fontsize"] = 12

# ==============================
# 3. 提取月尺度数据的函数
# ==============================

def extract_monthly_data(folder, year, coords_dict):
    """
    从 tmin/tmax/prec 文件夹中，按年份和经纬度提取 12 个月的栅格值。
    文件命名格式示例：
    wc2.1_cruts4.09_10m_tmin_2024-01.tif
    """
    monthly_values = {name: [] for name in coords_dict.keys()}
    var_name = os.path.basename(folder)  # tmin / tmax / prec

    for month in months:
        month_str = f"{month:02d}"
        tif_name = f"wc2.1_cruts4.09_10m_{var_name}_{year}-{month_str}.tif"
        file_path = os.path.join(folder, tif_name)

        if not os.path.exists(file_path):
            raise FileNotFoundError(f"找不到数据文件: {file_path}")

        with rasterio.open(file_path) as src:
            band = src.read(1)
            for name, (lon, lat) in coords_dict.items():
                row, col = src.index(lon, lat)
                val = band[row, col]
                monthly_values[name].append(val)

    return monthly_values

# ==============================
# 4. 读取苏尼特左旗气候数据
# ==============================

tmin_data = extract_monthly_data(tmin_dir, year, coords)
tmax_data = extract_monthly_data(tmax_dir, year, coords)
prec_data = extract_monthly_data(prec_dir, year, coords)

site_name = "Sunite Zuoqi"
tmin = tmin_data[site_name]
tmax = tmax_data[site_name]
prec = prec_data[site_name]

# ==============================
# 5. 图 1：苏尼特左旗月平均最高/最低气温（两色）
# ==============================

fig, ax = plt.subplots(figsize=(8, 5))

ax.plot(
    months, tmin,
    marker='o', linestyle='--',
    color=COL_TMIN,
    linewidth=2.5,
    label="最低气温"
)

ax.plot(
    months, tmax,
    marker='o', linestyle='-',
    color=COL_TMAX,
    linewidth=2.5,
    label="最高气温"
)

ax.set_xticks([1, 3, 6, 9, 12])
ax.set_xlabel("月份", fontproperties=ch_font, fontsize=14)
ax.set_ylabel("气温(℃)", fontproperties=ch_font, fontsize=14)
ax.set_title(f"苏尼特左旗{year}年月平均最高/最低气温", fontproperties=ch_font, fontsize=16)

legend = ax.legend(loc="upper left")
for text in legend.get_texts():
    text.set_fontproperties(ch_font)

ax.grid(False)
fig.tight_layout()

temp_fig_path = os.path.join(out_dir, f"苏尼特左旗_气温_{year}.png")
fig.savefig(temp_fig_path, dpi=600)
plt.close(fig)
print(f"气温图已保存到: {temp_fig_path}")

# ==============================
# 6. 图 2：苏尼特左旗月降水量（同用绿色）
# ==============================

fig, ax = plt.subplots(figsize=(8, 5))

ax.bar(
    months, prec,
    width=0.6,
    color=COL_PREC,
    edgecolor="black",
    label="降水量"
)

ax.set_xticks([1, 3, 6, 9, 12])
ax.set_xlabel("月份", fontproperties=ch_font, fontsize=14)
ax.set_ylabel("降水量(mm)", fontproperties=ch_font, fontsize=14)
ax.set_title(f"苏尼特左旗{year}年月降水量", fontproperties=ch_font, fontsize=16)

legend = ax.legend(loc="upper left")
for text in legend.get_texts():
    text.set_fontproperties(ch_font)

ax.grid(False)
fig.tight_layout()

prec_fig_path = os.path.join(out_dir, f"苏尼特左旗_降水量_{year}.png")
fig.savefig(prec_fig_path, dpi=600)
plt.close(fig)
print(f"降水量图已保存到: {prec_fig_path}")

# ==============================
# 7. 终端打印中文表头，方便核对
# ==============================

print(f"\n=== 苏尼特左旗{year}年月平均最高/最低气温(℃) ===")
print("{:<6} {:<10} {:<10}".format("月份", "最低气温", "最高气温"))
for i in range(12):
    print("{:<6} {:<10.1f} {:<10.1f}".format(i + 1, tmin[i], tmax[i]))

print(f"\n=== 苏尼特左旗{year}年月降水量(mm) ===")
print("{:<6} {:<10}".format("月份", "降水量"))
for i in range(12):
    print("{:<6} {:<10.1f}".format(i + 1, prec[i]))
