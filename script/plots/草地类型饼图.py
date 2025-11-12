import os
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.font_manager import FontProperties

# ===================== 字体设置 =====================
plt.rcParams['font.family'] = 'Times New Roman'   # 数字/英文
plt.rcParams['axes.unicode_minus'] = False
ch_font = FontProperties(family='SimSun')         # 中文宋体（必要时用绝对路径）

# ===================== 数据 =====================
types = [
    '温性荒漠草原',
    '温性草原',
    '温性草甸草原',
    '温性草原化荒漠',
    '低湿地草甸',
    '温性山地草甸'
]
areas = [30323.33, 92688.40, 26597.07, 4071.93, 31243.13, 3903.14]
total_area = sum(areas)
percentages = [a / total_area * 100 for a in areas]

# ===================== 配色（Paul Tol 风格，SCI 常用） =====================
# 参考 Tol (vibrant/bright) 色板；见 CRAN khroma 文档
colors = [
    '#3969AC',  # 蓝
    '#11A579',  # 绿
    '#E73F74',  # 洋红
    '#F2B701',  # 金黄
    '#80BA5A',  # 浅绿
    '#7F3C8D'   # 紫
]

# ===================== 绘图 =====================
fig, ax = plt.subplots(figsize=(8, 8))

# 扇区加白色描边，视觉更干净
wedges, _ = ax.pie(
    areas,
    labels=None,
    colors=colors,
    startangle=90,
    counterclock=False,
    radius=1.0,
    wedgeprops=dict(linewidth=1, edgecolor='white')
)

ax.set_title('锡林郭勒盟草地资源比例图', fontproperties=ch_font, fontsize=20)
ax.axis('equal')  # 圆形

# ===================== 手动画“支出”百分比（两段式折线） =====================
# 思路：在圆周 r=1.0 取扇区中心角，起点=圆周点；折线先径向一点，再水平拉出；文本放在末端
for wedge, pct in zip(wedges, percentages):
    theta = np.deg2rad(0.5 * (wedge.theta1 + wedge.theta2))
    r = 1.0
    # 圆周上的起点（精确在饼图边缘）
    x0, y0 = r * np.cos(theta), r * np.sin(theta)

    # 折线终点（圆外），适度外扩
    r_text = 1.28  # 文本半径
    xt, yt = r_text * np.cos(theta), r_text * np.sin(theta)

    # 根据左右半区设置水平偏移与对齐
    if np.cos(theta) >= 0:
        ha = 'left'
        xt += 0.02
    else:
        ha = 'right'
        xt -= 0.02

    # 使用 angle3 形成“径向+水平”两段式领引线
    ax.annotate(
        f"{pct:.1f}%",
        xy=(x0, y0),            # 线的起点：圆周边缘
        xytext=(xt, yt),        # 文本位置：圆外
        ha=ha, va='center',
        fontsize=14, fontweight='bold', fontfamily='Times New Roman',
        arrowprops=dict(
            arrowstyle='-',
            color='black',
            lw=1.0,
            shrinkA=0, shrinkB=0,
            connectionstyle='angle3,angleA=0,angleB=90'  # 两段式折线
        )
    )

# ===================== 图例（仅类型名，中文宋体） =====================
ax.legend(
    wedges,
    types,
    title='草地类型',
    loc='center left',
    bbox_to_anchor=(1.05, 0.5),
    fontsize=12,
    prop=ch_font,
    title_fontproperties=ch_font
)

plt.tight_layout()

# ===================== 保存 =====================
output_dir = r"E:\桌面\武汉数据\苏尼特牛"
os.makedirs(output_dir, exist_ok=True)
output_path = os.path.join(output_dir, "锡林郭勒盟草地资源比例图.png")
plt.savefig(output_path, dpi=600, bbox_inches='tight')
plt.close()
print(f"已生成：{output_path}")
