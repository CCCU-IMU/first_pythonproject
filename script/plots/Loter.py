# -*- coding: utf-8 -*-
"""
方案C：像论文原图风格（圆角染色体柱 + 分段着色 + 自动排版），但完全不抄坐标。
在 PyCharm 里直接运行：改 CONFIG 区域的路径即可。
"""

from __future__ import annotations

import re
import math
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Tuple, Optional

import pandas as pd

# =========================
# 0) CONFIG：你只需要改这里
# =========================

TXT_PATH = r"E:\桌面\武汉数据\乌珠穆沁白牛\文章图汇总\测试\loter_segment.txt"   # TODO: 改成你的 loter_segment.txt 路径
OUT_DIR = r"E:桌面\武汉数据\乌珠穆沁白牛\文章图汇总\测试"                 # TODO: 改成你的输出文件夹
BASENAME = "loter"              # 输出文件名（不含后缀）

# --- 高清输出控制（推荐用“物理宽度 + dpi”） ---
DPI = 600
FIG_WIDTH_CM = 18.0        # 论文常用：16~18cm（双栏图或单栏宽）
# 如果你想按像素宽度，直接设定 PX_WIDTH 并把 FIG_WIDTH_CM 设为 None
PX_WIDTH: Optional[int] = None

# --- 图形样式（像论文图的关键：留白 + 圆角 + 细边线） ---
CANVAS_PADDING = 60        # 画布边距（px）
CHR_BAR_WIDTH = 26         # 染色体柱宽（px）
CHR_GAP = 48               # 染色体间距（px）
CORNER_RADIUS = 13         # 圆角半径（px），通常设为柱宽/2 更像胶囊
STROKE_WIDTH = 1.0         # 柱边线宽
SHOW_CHR_LABEL = True
LABEL_FONT_SIZE = 14
TITLE = ""                 # 你想加标题就写字符串，不要就留空

# ancestry 颜色：你可以按自己的类别改（不存在的类别会自动分配稳定颜色）
USER_COLOR_MAP: Dict[str, str] = {
    # "Mo-OD": "#d62728",
    # "Mo-AN": "#1f77b4",
}

# 可选：输出 jpg
EXPORT_JPG = True
JPG_QUALITY = 95  # 1-95


# =========================
# 1) 读取与规范化数据
# =========================

def _normalize_chr_name(s: str) -> str:
    s = str(s).strip()
    # 统一 chr 前缀
    if not s.lower().startswith("chr"):
        s = "chr" + s
    return s

def _smart_int(x) -> int:
    # 允许 1,234,567 这种格式
    if pd.isna(x):
        return 0
    s = str(x).strip().replace(",", "")
    return int(float(s))

def read_loter_segments(txt_path: Path) -> pd.DataFrame:
    """
    尽量兼容常见 loter_segment.txt：
    - 分隔符可以是 tab 或空格（多个空格）
    - 列名可能是 Chr/chr/chrom, Start/End, ancestry/Anc/Source 等
    """
    raw = txt_path.read_text(encoding="utf-8", errors="ignore").strip().splitlines()
    if not raw:
        raise ValueError("输入文件为空。")

    # 用 pandas 自动推断分隔符：优先 tab，否则用多个空格
    # 先尝试 tab
    try:
        df = pd.read_csv(txt_path, sep="\t", engine="python")
        if df.shape[1] < 3:
            raise ValueError
    except Exception:
        df = pd.read_csv(txt_path, sep=r"\s+", engine="python")

    # 规范列名
    cols = {c: re.sub(r"\s+", "", str(c)).lower() for c in df.columns}
    df = df.rename(columns={c: cols[c] for c in df.columns})

    # 寻找关键列
    def pick(*cands: str) -> Optional[str]:
        for c in cands:
            if c in df.columns:
                return c
        return None

    chr_col = pick("chr", "chrom", "chromosome")
    start_col = pick("start", "begin", "from")
    end_col = pick("end", "stop", "to")
    anc_col = pick("ancestry", "anc", "source", "pop", "label")

    if not (chr_col and start_col and end_col and anc_col):
        raise ValueError(
            f"无法识别列名。需要类似 chr/start/end/ancestry。\n"
            f"当前列：{list(df.columns)}"
        )

    out = pd.DataFrame({
        "chr": df[chr_col].map(_normalize_chr_name),
        "start": df[start_col].map(_smart_int),
        "end": df[end_col].map(_smart_int),
        "ancestry": df[anc_col].astype(str).str.strip(),
    })

    # 清理
    out = out[out["end"] > out["start"]].copy()
    out.sort_values(["chr", "start", "end"], inplace=True)
    out.reset_index(drop=True, inplace=True)
    if out.empty:
        raise ValueError("清洗后没有有效 segment（end <= start 的行被剔除了）。")
    return out

def natural_chr_key(chr_name: str) -> Tuple[int, str]:
    """
    chr1..chr29 排前面，chrX/chrY/chrM 后面
    """
    s = chr_name.lower().replace("chromosome", "chr")
    m = re.match(r"chr(\d+)$", s)
    if m:
        return (0, f"{int(m.group(1)):04d}")
    if s in ("chrx",):
        return (1, "x")
    if s in ("chry",):
        return (1, "y")
    if s in ("chrm", "chrmt", "chrmito"):
        return (2, "m")
    return (3, s)


# =========================
# 2) 颜色分配（稳定、好看）
# =========================

def _stable_color(name: str) -> str:
    """
    给未知 ancestry 一个稳定颜色（不依赖 matplotlib）
    """
    # 取 hash 产生 H 值，固定饱和度和亮度，避免太浅太黑
    h = (abs(hash(name)) % 360)
    s = 65
    l = 45
    return f"hsl({h}, {s}%, {l}%)"

def build_color_map(labels: List[str]) -> Dict[str, str]:
    cmap = dict(USER_COLOR_MAP)
    for lb in labels:
        if lb not in cmap:
            cmap[lb] = _stable_color(lb)
    return cmap


# =========================
# 3) SVG 生成（像论文图）
# =========================

@dataclass
class Layout:
    width: int
    height: int
    chr_x: Dict[str, int]
    chr_len: Dict[str, int]
    top: int
    bottom: int

def compute_layout(df: pd.DataFrame) -> Layout:
    chrs = sorted(df["chr"].unique().tolist(), key=natural_chr_key)
    chr_len = {c: int(df.loc[df["chr"] == c, "end"].max()) for c in chrs}

    # 画布宽
    content_w = len(chrs) * CHR_BAR_WIDTH + (len(chrs) - 1) * CHR_GAP
    width = CANVAS_PADDING * 2 + content_w

    # 画布高：留出标题 + 标签空间
    top = CANVAS_PADDING + (40 if TITLE else 0)
    bottom = CANVAS_PADDING + (40 if SHOW_CHR_LABEL else 0)
    # “像论文图”：柱子尽量高，但留白足
    height = top + 900 + bottom  # 900 是逻辑柱高，可按需要改

    # 每条染色体的 x（居中对齐）
    chr_x = {}
    x = CANVAS_PADDING
    for c in chrs:
        chr_x[c] = x
        x += CHR_BAR_WIDTH + CHR_GAP

    return Layout(width=width, height=height, chr_x=chr_x, chr_len=chr_len, top=top, bottom=bottom)

def svg_header(w: int, h: int) -> List[str]:
    return [
        '<?xml version="1.0" encoding="UTF-8"?>',
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">',
        '<defs>',
        '  <style type="text/css"><![CDATA[',
        '    .chrLabel { font-family: "Times New Roman", Arial, sans-serif; }',
        '    .title { font-family: "Times New Roman", Arial, sans-serif; font-weight: 600; }',
        '  ]]></style>',
        '</defs>',
        '<rect x="0" y="0" width="100%" height="100%" fill="white"/>'
    ]

def generate_svg(df: pd.DataFrame, out_svg: Path) -> Tuple[Path, Dict[str, str]]:
    layout = compute_layout(df)
    chrs = sorted(df["chr"].unique().tolist(), key=natural_chr_key)

    labels = sorted(df["ancestry"].unique().tolist())
    color_map = build_color_map(labels)

    bar_top = layout.top
    bar_bottom = layout.height - layout.bottom
    bar_h = bar_bottom - bar_top

    svg: List[str] = []
    svg += svg_header(layout.width, layout.height)

    # 标题
    if TITLE:
        svg.append(f'<text x="{layout.width//2}" y="{CANVAS_PADDING+24}" text-anchor="middle" class="title" font-size="18">{TITLE}</text>')

    # 先画每条染色体“胶囊底座”（灰边白底），再画彩色分段（clip 到胶囊形状里）
    for c in chrs:
        x = layout.chr_x[c]
        y = bar_top
        h = bar_h
        r = min(CORNER_RADIUS, CHR_BAR_WIDTH // 2)

        # clipPath：保证彩色分段不会跑出圆角
        clip_id = f"clip_{c}"
        svg.append('<defs>')
        svg.append(f'  <clipPath id="{clip_id}">')
        svg.append(f'    <rect x="{x}" y="{y}" width="{CHR_BAR_WIDTH}" height="{h}" rx="{r}" ry="{r}"/>')
        svg.append('  </clipPath>')
        svg.append('</defs>')

        # 胶囊底座（边框）
        svg.append(
            f'<rect x="{x}" y="{y}" width="{CHR_BAR_WIDTH}" height="{h}" '
            f'rx="{r}" ry="{r}" fill="white" stroke="black" stroke-width="{STROKE_WIDTH}"/>'
        )

        # 彩色分段（按 bp -> y 映射）
        chr_df = df[df["chr"] == c]
        L = layout.chr_len[c]

        # 防止除零
        if L <= 0:
            continue

        svg.append(f'<g clip-path="url(#{clip_id})">')
        for _, row in chr_df.iterrows():
            s = int(row["start"])
            e = int(row["end"])
            anc = str(row["ancestry"])

            y1 = bar_top + (s / L) * bar_h
            y2 = bar_top + (e / L) * bar_h
            seg_h = max(0.6, y2 - y1)  # 太短的段也给个最小可见高度

            svg.append(
                f'<rect x="{x}" y="{y1:.3f}" width="{CHR_BAR_WIDTH}" height="{seg_h:.3f}" '
                f'fill="{color_map.get(anc, _stable_color(anc))}" stroke="none"/>'
            )
        svg.append('</g>')

        # chr label
        if SHOW_CHR_LABEL:
            svg.append(
                f'<text x="{x + CHR_BAR_WIDTH/2}" y="{bar_bottom + 26}" text-anchor="middle" '
                f'class="chrLabel" font-size="{LABEL_FONT_SIZE}">{c}</text>'
            )

    # 简单 legend（右上角）
    # 如果类别特别多，你也可以把这段注释掉
    legend_x = layout.width - CANVAS_PADDING + 10
    legend_y = layout.top
    svg.append(f'<g transform="translate({legend_x}, {legend_y})">')
    svg.append(f'<text x="0" y="-10" font-size="14" class="chrLabel">Ancestry</text>')
    yy = 10
    for anc in labels:
        svg.append(f'<rect x="0" y="{yy}" width="14" height="14" fill="{color_map[anc]}" stroke="black" stroke-width="0.4"/>')
        svg.append(f'<text x="20" y="{yy+12}" font-size="12" class="chrLabel">{anc}</text>')
        yy += 20
    svg.append('</g>')

    svg.append("</svg>")
    out_svg.parent.mkdir(parents=True, exist_ok=True)
    out_svg.write_text("\n".join(svg), encoding="utf-8")
    return out_svg, color_map


# =========================
# 4) 高清导出（600 dpi PNG / JPG）
# =========================

def cm_to_px(cm: float, dpi: int) -> int:
    return int(round((cm / 2.54) * dpi))

def export_raster(svg_path: Path, out_png: Optional[Path], out_jpg: Optional[Path]) -> None:
    try:
        import cairosvg  # type: ignore
    except Exception as e:
        raise SystemExit("需要安装 cairosvg 才能导出 PNG/JPG：pip install cairosvg") from e

    # 决定输出像素宽度
    if PX_WIDTH is not None:
        out_width_px = int(PX_WIDTH)
    else:
        out_width_px = cm_to_px(FIG_WIDTH_CM, DPI)

    if out_png:
        cairosvg.svg2png(
            url=str(svg_path),
            write_to=str(out_png),
            output_width=out_width_px
        )
        print(f"[OK] PNG 已输出：{out_png} （宽度约 {out_width_px}px，对应 {DPI}dpi）")

    if out_jpg:
        # 先用 cairosvg 生成临时 png，再用 pillow 转 jpg（可控质量）
        tmp_png = svg_path.with_suffix(".tmp_for_jpg.png")
        cairosvg.svg2png(
            url=str(svg_path),
            write_to=str(tmp_png),
            output_width=out_width_px
        )
        try:
            from PIL import Image
        except Exception as e:
            raise SystemExit("需要安装 pillow 才能导出 JPG：pip install pillow") from e

        img = Image.open(tmp_png).convert("RGB")
        img.save(out_jpg, "JPEG", quality=int(JPG_QUALITY), optimize=True)
        tmp_png.unlink(missing_ok=True)
        print(f"[OK] JPG 已输出：{out_jpg} （quality={JPG_QUALITY}，宽度约 {out_width_px}px）")


# =========================
# 5) main
# =========================

def main() -> None:
    txt = Path(TXT_PATH)
    out_dir = Path(OUT_DIR)
    out_dir.mkdir(parents=True, exist_ok=True)

    out_svg = out_dir / f"{BASENAME}.svg"
    out_png = out_dir / f"{BASENAME}_{DPI}dpi.png"
    out_jpg = out_dir / f"{BASENAME}_{DPI}dpi.jpg" if EXPORT_JPG else None

    df = read_loter_segments(txt)
    print(f"[INFO] 读取到 {len(df)} 条 segments，染色体数：{df['chr'].nunique()}，ancestry 类别数：{df['ancestry'].nunique()}")

    svg_path, cmap = generate_svg(df, out_svg)
    print(f"[OK] SVG 已输出：{svg_path}")

    export_raster(svg_path, out_png, out_jpg)

    # 打印颜色表，方便你在论文里保持一致
    print("\n[INFO] Ancestry -> Color:")
    for k, v in sorted(cmap.items()):
        print(f"  {k}: {v}")

if __name__ == "__main__":
    main()
