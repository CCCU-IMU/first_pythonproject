import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch
from matplotlib.colors import LinearSegmentedColormap

# -------------------------
# 1. 读数据 + 基本处理
# -------------------------
df = pd.read_csv("E:/桌面/武汉数据/乌珠穆沁白牛/10-24祖先比例/result/05.loter/loter_segment.txt", sep="\t")

# 染色体数字编号：chr1 -> 1
df["chr_num"] = df["Chr"].str.replace("chr", "", regex=False).astype(int)
df["mid_pos"] = (df["Start"] + df["End"]) / 2

# 按染色体和起点排序
df = df.sort_values(["chr_num", "Start"])

# 每条染色体长度（用 End 最大值）
chr_info = (
    df.groupby(["Chr", "chr_num"])["End"]
      .max()
      .reset_index()
      .sort_values("chr_num")
)
chr_nums = chr_info["chr_num"].values
chr_lengths = chr_info["End"].values

# -------------------------
# 2. 作图参数
# -------------------------
# 染色体整体宽度（越小越窄）
chrom_width = 0.35
# 内部 segment 更窄一点
segment_width = 0.28

# 颜色渐变：从 #007C73 到 #6A51A3
cmap = LinearSegmentedColormap.from_list(
    "freq_cmap",
    ["#007C73", "#6A51A3"]
)

# 可以根据自己数据范围调整，这里假设 0.6~1.0
vmin, vmax = 0.6, 1.0
norm = plt.Normalize(vmin=vmin, vmax=vmax)

# 形状：三角 & 圆
marker_map = {
    "Mo-OD": "^",       # 三角
    "Charolais": "o"    # 圆
}
marker_color = {
    "Mo-OD": "#007C73",
    "Charolais": "#6A51A3"
}

# -------------------------
# 3. 开始画图
# -------------------------
plt.rcParams["font.family"] = "Arial"    # 如果报错，可以改成其它字体比如 "DejaVu Sans"

fig, ax = plt.subplots(figsize=(8, 6), dpi=300)

# 3.1 画每条染色体的圆角灰色背景
for _, row in chr_info.iterrows():
    x_center = row["chr_num"]
    height = row["End"]  # 染色体长度
    # FancyBboxPatch：圆角矩形
    rect = FancyBboxPatch(
        (x_center - chrom_width / 2, 0),    # 左下角 (x, y)
        chrom_width,                        # 宽
        height,                             # 高
        boxstyle=f"round,pad=0,rounding_size={chrom_width/2}",
        edgecolor="0.6",
        facecolor="white",
        linewidth=0.4
    )
    ax.add_patch(rect)

# 3.2 画内部的彩色祖先片段（圆角条）
for chr_num, sub in df.groupby("chr_num"):
    for _, seg in sub.iterrows():
        y = seg["Start"]
        h = seg["End"] - seg["Start"]
        color = cmap(norm(seg["Frequency"]))
        inner = FancyBboxPatch(
            (chr_num - segment_width / 2, y),
            segment_width,
            h,
            boxstyle=f"round,pad=0,rounding_size={segment_width/2}",
            edgecolor="none",
            facecolor=color
        )
        ax.add_patch(inner)

# 3.3 画缝隙里的形状点（放大）
# 3.3 画缝隙里的形状点（带连线）

marker_offset = 0.5  # 点在 chr_num 右边 0.5 的缝隙里

for anc, sub in df.groupby("Ancestry"):
    # 先画连线：从染色体右边缘 → 点的位置
    for _, seg in sub.iterrows():
        x_chr_right = seg["chr_num"] + segment_width / 2.0   # 染色体圆角条的右边缘
        x_point     = seg["chr_num"] + marker_offset         # 缝隙中点（点的 x）
        y           = seg["mid_pos"]

        # 画一条水平小线
        ax.plot(
            [x_chr_right, x_point],
            [y, y],
            color="black",    # 也可以改成 marker_color[anc]，每种祖先用自己的颜色
            linewidth=0.3
        )

    # 再画点本身（不描边，只有填充色）
    ax.scatter(
        sub["chr_num"] + marker_offset,     # x：缝隙中
        sub["mid_pos"],                     # y：segment 中点
        marker=marker_map.get(anc, "o"),
        s=60,                               # 再稍微放大一点，原来是 40
        facecolor=marker_color.get(anc, "black"),
        edgecolor="none",                   # ← 不要描边
        label=anc
    )


# 3.4 频率色条（colorbar）
sm = plt.cm.ScalarMappable(cmap=cmap, norm=norm)
sm.set_array([])
cbar = fig.colorbar(sm, ax=ax, fraction=0.03, pad=0.02)
cbar.set_label("Frequency", fontsize=8)
cbar.ax.tick_params(labelsize=7)

# -------------------------
# 4. 轴 & 样式
# -------------------------
ax.set_xlim(chr_nums.min() - 0.5, chr_nums.max() + 1.0)
ax.set_xticks(chr_nums)
ax.set_xticklabels(chr_nums, fontsize=7)
ax.set_xlabel("Bos taurus autosome", fontsize=8)

ax.set_ylabel("Genomic position (bp)", fontsize=8)
ax.tick_params(axis="y", labelsize=7)

# 去掉上、右边框
ax.spines["top"].set_visible(False)
ax.spines["right"].set_visible(False)
# 下、左边框细一点
ax.spines["bottom"].set_linewidth(0.5)
ax.spines["left"].set_linewidth(0.5)

# 图例：Mo-OD 三角，Charolais 圆
handles, labels = ax.get_legend_handles_labels()
# 去重
by_label = dict(zip(labels, handles))
leg = ax.legend(
    by_label.values(),
    by_label.keys(),
    frameon=False,
    fontsize=7,
    loc="upper right"
)

fig.tight_layout()
plt.show()
