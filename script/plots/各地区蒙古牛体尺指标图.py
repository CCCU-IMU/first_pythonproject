import pandas as pd
import numpy as np
import os

# 读数据（注意 header=1）
df = pd.read_excel(r"E:\桌面\武汉数据\苏尼特牛\苏尼特蒙古牛测定表209头.xlsx", header=2)

# ★ 只保留母牛
df = df[df["性别"] == "母"]

# 如果只想要“成年母牛（例如4岁以上）”，可以改成：
# df = df[(df["性别"] == "母") & (df["年龄"] >= 4)]

# 列名
h_col = "体高"      # cm
l_col = "体斜长"    # cm
g_col = "胸围"      # cm
w_col_name = "体重"  # kg

# 转数值
for c in [h_col, l_col, g_col] + ([w_col_name] if w_col_name in df.columns else []):
    df[c] = pd.to_numeric(df[c], errors="coerce")

# 行级估算体重：体重 = 体斜长 × 胸围 × 胸围 / 10800
est_weight = (df[l_col] * df[g_col] * df[g_col]) / 10800.0

# 合成体重：有实测用实测，缺失就用估算
if w_col_name in df.columns:
    weight_series = df[w_col_name].where(~df[w_col_name].isna(), est_weight)
else:
    weight_series = est_weight

# 汇总（这一份文件只有苏尼特左旗，所以地区写死即可）
row = {
    '地区': '苏尼特左旗',
    '年龄': '4岁以上',   # 如果你上面用了年龄过滤，就可以写成这个说明
    '体高/cm': df[h_col].mean(skipna=True),
    '体长/cm': df[l_col].mean(skipna=True),
    '胸围/cm': df[g_col].mean(skipna=True),
    '体重/kg': weight_series.mean(skipna=True)
}

out = pd.DataFrame([row]).round(2)
print(out)

out_dir = r"D:\Python\script\pythonProject\data\result"
os.makedirs(out_dir, exist_ok=True)
out.to_excel(os.path.join(out_dir, "苏尼特左旗_成年母牛体尺均值.xlsx"), index=False)
