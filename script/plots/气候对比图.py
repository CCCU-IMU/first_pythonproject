import os
import numpy as np
import matplotlib.pyplot as plt
import rasterio

# ==============================
# 1. Paths & Parameters
# ==============================

# TODO: change to your climate data folder
climate_base_dir = r"E:\桌面\武汉数据\乌珠穆沁白牛\白牛文章\气候数据"

tmin_dir = os.path.join(climate_base_dir, "tmin")
tmax_dir = os.path.join(climate_base_dir, "tmax")
prec_dir = os.path.join(climate_base_dir, "prec")

year = 2024
months = np.arange(1, 13)

# TODO: update coordinates (lon, lat)
coords = {
    "West Ujimqin": (117.60, 44.58),   # 西乌珠穆沁旗（示例：巴彦胡硕附近，可按你的研究点改）
    "Charolais":    (4.28,  46.43),    # 夏洛莱地区（示例：Charolles 附近，可按你的研究点改）
}

# output directory
out_dir = r"D:\Python\script\pythonProject\data\result"
os.makedirs(out_dir, exist_ok=True)

# ==============================
# 2. Font & Style
# ==============================
plt.rcParams["font.family"] = "Times New Roman"
plt.rcParams["axes.unicode_minus"] = False

plt.rcParams["font.size"] = 12
plt.rcParams["axes.titlesize"] = 18
plt.rcParams["axes.labelsize"] = 16
plt.rcParams["xtick.labelsize"] = 12
plt.rcParams["ytick.labelsize"] = 12
plt.rcParams["legend.fontsize"] = 14

# Color palette similar to your sample
COL_WU = "#D08C60"     # West Ujimqin (warm brown)
COL_CH = "#0A8F4E"     # Charolais (green)

# ==============================
# 3. Helpers
# ==============================
def extract_monthly_data(folder, year, coords_dict):
    """
    Read 12 monthly raster values for each site (lon/lat).
    File name example:
    wc2.1_cruts4.09_10m_tmin_2024-01.tif
    """
    monthly_values = {name: [] for name in coords_dict.keys()}
    var_name = os.path.basename(folder)  # tmin / tmax / prec

    for m in range(1, 13):
        month_str = f"{m:02d}"
        tif_name = f"wc2.1_cruts4.09_10m_{var_name}_{year}-{month_str}.tif"
        file_path = os.path.join(folder, tif_name)

        if not os.path.exists(file_path):
            raise FileNotFoundError(f"Missing file: {file_path}")

        with rasterio.open(file_path) as src:
            band = src.read(1)
            for name, (lon, lat) in coords_dict.items():
                row, col = src.index(lon, lat)
                val = band[row, col]
                monthly_values[name].append(float(val))

    return monthly_values

def maybe_scale_temperature(arr):
    """
    Some datasets store temperature as °C*10.
    If values look too large (e.g. 150, -230), scale by /10.
    """
    arr = np.array(arr, dtype=float)
    if np.nanmax(np.abs(arr)) > 100:
        arr = arr / 10.0
    return arr

# ==============================
# 4. Load data
# ==============================
tmin_data = extract_monthly_data(tmin_dir, year, coords)
tmax_data = extract_monthly_data(tmax_dir, year, coords)
prec_data = extract_monthly_data(prec_dir, year, coords)

wu_tmin = maybe_scale_temperature(tmin_data["West Ujimqin"])
wu_tmax = maybe_scale_temperature(tmax_data["West Ujimqin"])
wu_prec = np.array(prec_data["West Ujimqin"], dtype=float)

ch_tmin = maybe_scale_temperature(tmin_data["Charolais"])
ch_tmax = maybe_scale_temperature(tmax_data["Charolais"])
ch_prec = np.array(prec_data["Charolais"], dtype=float)

# ==============================
# 5. Figure A: Monthly Precipitation Comparison
# ==============================
fig, ax = plt.subplots(figsize=(10, 6))

bar_w = 0.38
ax.bar(months - bar_w/2, wu_prec, width=bar_w, color=COL_WU, label="West Ujimqin")
ax.bar(months + bar_w/2, ch_prec, width=bar_w, color=COL_CH, label="Charolais")

ax.set_xlabel("Month")
ax.set_ylabel("Precipitation (mm)")
ax.set_title(f"{year} Monthly Precipitation Comparison")
ax.set_xticks([1, 3, 6, 9, 12])

ax.legend(loc="upper right", frameon=True)
ax.grid(False)
fig.tight_layout()

prec_fig_path = os.path.join(out_dir, f"Precipitation_Comparison_{year}.png")
fig.savefig(prec_fig_path, dpi=600)
plt.close(fig)
print(f"Saved: {prec_fig_path}")

# ==============================
# 6. Figure B: Monthly Tmin/Tmax Comparison
# ==============================
fig, ax = plt.subplots(figsize=(10, 6))

# West Ujimqin
ax.plot(months, wu_tmin, marker="o", linestyle="--", linewidth=3, color=COL_WU, alpha=0.35, label="West Ujimqin Tmin")
ax.plot(months, wu_tmax, marker="o", linestyle="-",  linewidth=3, color=COL_WU, alpha=1.00, label="West Ujimqin Tmax")

# Charolais
ax.plot(months, ch_tmin, marker="o", linestyle="--", linewidth=3, color=COL_CH, alpha=0.35, label="Charolais Tmin")
ax.plot(months, ch_tmax, marker="o", linestyle="-",  linewidth=3, color=COL_CH, alpha=1.00, label="Charolais Tmax")

ax.set_xlabel("Month")
ax.set_ylabel("Temperature (°C)")
ax.set_title(f"{year} Monthly Tmin/Tmax Comparison")
ax.set_xticks([1, 3, 6, 9, 12])

ax.legend(loc="lower center", frameon=True, ncol=2)
ax.grid(False)
fig.tight_layout()

temp_fig_path = os.path.join(out_dir, f"Temperature_Comparison_{year}.png")
fig.savefig(temp_fig_path, dpi=600)
plt.close(fig)
print(f"Saved: {temp_fig_path}")

# ==============================
# 7. Print tables (for checking)
# ==============================
print(f"\n=== {year} Monthly Temperature (°C): West Ujimqin vs Charolais ===")
print("{:<6} {:<14} {:<14} {:<14} {:<14}".format("Month", "WU Tmin", "WU Tmax", "CH Tmin", "CH Tmax"))
for i in range(12):
    print("{:<6} {:<14.1f} {:<14.1f} {:<14.1f} {:<14.1f}".format(
        i+1, wu_tmin[i], wu_tmax[i], ch_tmin[i], ch_tmax[i]
    ))

print(f"\n=== {year} Monthly Precipitation (mm): West Ujimqin vs Charolais ===")
print("{:<6} {:<14} {:<14}".format("Month", "WU Prec", "CH Prec"))
for i in range(12):
    print("{:<6} {:<14.1f} {:<14.1f}".format(i+1, wu_prec[i], ch_prec[i]))
