import os
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.font_manager import FontProperties

# ===================== 1. 字体设置 =====================
# 全局默认字体：Times New Roman（英文和数字）
plt.rcParams['font.family'] = 'Times New Roman'
plt.rcParams['axes.unicode_minus'] = False  # 解决负号显示问题

# 中文宋体（SimSun）
# 如果报错，可以改为绝对路径：FontProperties(fname=r"C:\Windows\Fonts\simsun.ttc")
ch_font = FontProperties(family='SimSun')

# ===================== 2. 数据 =====================
types = [
    '温性荒漠草原',
    '温性草原',
    '温性草甸草原',
    '温性草原化荒漠',
    '低湿地草甸',
    '温性山地草甸'
]

areas = [
    30323.33,
    92688.40,
    26597.07,
    4071.93,
    31243.13,
    3903.14
]

total_area = sum(areas)
percentages = [a / total_area * 100 for a in areas]

# ===================== 3. SCI 风格配色 =====================
# 参考常见 SCI 图配色（高对比度、偏冷静）
colors = [
    '#4C72B0',  # 蓝
    '#55A868',  # 绿
    '#C44E52',  # 红
    '#8172B2',  # 紫
    '#CCB974',  # 黄棕
    '#64B5CD'   # 青蓝
]

# ===================== 4. 绘图 =====================
fig, ax = plt.subplots(figsize=(8, 8))

# 仅画扇区，不让 pie 自己画百分比文字
wedges, _ = ax.pie(
    areas,
    labels=None,
    colors=colors,
    startangle=90,
    counterclock=False,
    radius=1.0
)

ax.set_title('锡林郭勒盟草地资源比例图',
             fontproperties=ch_font,
             fontsize=20)

ax.axis('equal')  # 保证为正圆

# ===================== 5. 手动画“支出来”的百分比 + 线条 =====================
# 思路：根据每个扇区的中心角，算出起点和终点坐标，用 annotate 拉一根小线，再在末端写百分比

for wedge, pct in zip(wedges, percentages):
    # 扇区角度中心（度 -> 弧度）
    theta = 0.5 * (wedge.theta1 + wedge.theta2)
    theta_rad = np.deg2rad(theta)

    # 扇区外沿上的一个点（线的起点）
    x = np.cos(theta_rad)
    y = np.sin(theta_rad)
    r = 1.0

    # 线条起点和终点
    # 起点稍微在扇区外沿里一点，终点在圆外
    start_x = r * 0.9 * x
    start_y = r * 0.9 * y
    end_x = r * 1.2 * x
    end_y = r * 1.2 * y

    # 文本位置再比线条终点稍微外一点
    text_x = r * 1.32 * x
    text_y = r * 1.32 * y

    # 根据左右位置调整对齐方式
    if x >= 0:
        ha = 'left'
    else:
        ha = 'right'

    # 百分比文本（Times New Roman）
    ax.annotate(
        f"{pct:.1f}%",
        xy=(start_x, start_y),
        xytext=(text_x, text_y),
        ha=ha,
        va='center',
        fontsize=12,
        fontfamily='Times New Roman',
        arrowprops=dict(
            arrowstyle='-',
            color='black',
            lw=0.8,
            shrinkA=0,
            shrinkB=0,
        )
    )

# ===================== 6. 图例（中文宋体，只标类型） =====================
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

# ===================== 7. 保存到指定路径 =====================
output_dir = r"E:\桌面\武汉数据\苏尼特牛"
os.makedirs(output_dir, exist_ok=True)

output_path = os.path.join(output_dir, "锡林郭勒盟草地资源比例图.png")

plt.savefig(output_path, dpi=600, bbox_inches='tight')
plt.close()

print(f"已生成：{output_path}")