import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, Circle, Wedge

# 只用英文字母，不设置中文字体，避免任何字形警告
plt.rcParams["axes.unicode_minus"] = False


def draw_pie(ax, cx, cy, fractions, colors, radius):
    """在 (cx, cy) 位置画一个半径为 radius 的扇形饼图。"""
    fractions = np.asarray(fractions, dtype=float)
    total = fractions.sum()
    if total <= 0:
        return
    fractions = fractions / total

    start_angle = 90.0
    for frac, color in zip(fractions, colors):
        if frac <= 0:
            continue
        theta2 = start_angle - frac * 360.0
        wedge = Wedge((cx, cy), radius, theta2, start_angle,
                      facecolor=color, edgecolor="none")
        ax.add_patch(wedge)
        start_angle = theta2


# ========= 1. 遗传来源：Af, Am, B, C, D, E, F =========
sources = ["Af", "Am", "B", "C", "D", "E", "F"]
nsrc = len(sources)

# 颜色：Af(黄)、Am(蓝)，后面 B~F 随便给 5 种
col_src = [
    "#FFC000",  # Af  初始母牛 A（黄）
    "#1f77b4",  # Am  初始公牛 A（蓝）
    "#ff7f0e",  # B
    "#2ca02c",  # C
    "#e15759",  # D
    "#59a14f",  # E
    "#8c564b",  # F
]

# ========= 2. 计算各代母牛遗传组成：A0 + F1~F6 =========
eye = np.eye(nsrc)

female_list = []

# A0：初始母牛 Af = 100%
female_list.append(eye[0].copy())

# F1：A0 × Am
female_list.append(0.5 * female_list[0] + 0.5 * eye[1])  # Am

# 后续 5 代：依次与 B, C, D, E, F 公牛交配
# 索引：B=2, C=3, D=4, E=5, F=6
bull_indices = [2, 3, 4, 5, 6]

for k, bull_idx in enumerate(bull_indices, start=1):
    prev_female = female_list[k]
    next_female = 0.5 * prev_female + 0.5 * eye[bull_idx]
    female_list.append(next_female)

# 现在 female_list 包含：A0, F1, F2, F3, F4, F5, F6 7 代


# ========= 3. 布局：斜排一行饼图 + 右侧公牛方块 =========
dx, dy = 2.5, -1.6
x0, y0 = 0.0, 0.0

cx = np.array([x0 + i * dx for i in range(7)])   # A0, F1..F6
cy = np.array([y0 + i * dy for i in range(7)])

# 公牛顺序：A, B, C, D, E, F, A
bull_labels = ["A", "B", "C", "D", "E", "F", "A"]
bull_colors = [
    col_src[1],  # A 公牛用 Am 的蓝色
    col_src[2],
    col_src[3],
    col_src[4],
    col_src[5],
    col_src[6],
    col_src[1],  # 最后回到 A（蓝）
]

bull_x = cx[1:] + 1.8      # F1~F6 对应的 6 个公牛
bull_y = cy[1:] + 0.2
bull_w, bull_h = 1.4, 1.0
lastAx = bull_x[-1] + 2.5  # 最后一个 A 公牛
lastAy = bull_y[-1]

radius = 0.6

# ========= 4. 建立画布：2:1 比例 =========
fig, ax = plt.subplots(figsize=(10, 5))

# 左列饼图：A0 + F1~F6
for i in range(7):
    comp = female_list[i]
    mask = comp > 1e-3
    comp_keep = comp[mask]
    cols = [col_src[j] for j in range(nsrc) if mask[j]]

    draw_pie(ax, cx[i], cy[i], comp_keep, cols, radius)
    ax.add_patch(Circle((cx[i], cy[i]), radius,
                        fill=False, edgecolor="black", lw=0.8))

# 右侧 6 个公牛方块：A,B,C,D,E,F
for k in range(6):
    ax.add_patch(
        Rectangle(
            (bull_x[k], bull_y[k]),
            bull_w,
            bull_h,
            facecolor=bull_colors[k],
            edgecolor="none",
        )
    )
    ax.text(
        bull_x[k] + bull_w / 2,
        bull_y[k] + bull_h / 2,
        bull_labels[k],
        color="white",
        ha="center",
        va="center",
        fontsize=10,
    )

# 最后一个回到 A 的公牛方块
ax.add_patch(
    Rectangle(
        (lastAx, lastAy),
        bull_w,
        bull_h,
        facecolor=bull_colors[-1],
        edgecolor="none",
    )
)
ax.text(
    lastAx + bull_w / 2,
    lastAy + bull_h / 2,
    bull_labels[-1],
    color="white",
    ha="center",
    va="center",
    fontsize=10,
)

# ========= 5. 坐标范围 & 输出 =========
x_lim = (cx[0] - 2.0, lastAx + bull_w + 1.0)
y_lim = (cy[-1] - 2.0, cy[0] + 2.0)
ax.set_xlim(*x_lim)
ax.set_ylim(*y_lim)

ax.set_aspect("equal", adjustable="box")
ax.axis("off")
plt.tight_layout()

# 2:1 比例 + 300 dpi PNG
plt.savefig("rotational_mating_correct.png",
            dpi=300, bbox_inches="tight")

# 如需 PDF 矢量版，可再加一行：
# plt.savefig("rotational_mating_correct.pdf", bbox_inches="tight")

plt.show()
