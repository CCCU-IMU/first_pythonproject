#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
recolor_unified.py

根据你给的 chromosome.svg（或同结构的 SVG），把整张图的配色做“统一映射”，
并且保证除了颜色以外，所有几何细节（坐标、线宽、字体、元素数量/顺序等）完全不变。

核心思路：
1) 从 SVG 右上角的渐变色条（由很多很窄的 <rect> 组成）中，恢复原来的连续色带：
   - 通过每个颜色在色条上的位置得到它的相对参数 t∈[0,1]
2) 用同一个 t，把旧颜色映射到新的两端色（new_left -> new_right）之间的渐变。
3) 同时把图例里的两种“类别色”（Charolais 三角、Mo-OD 方块）也换成你指定的两色。

用法示例：
  python recolor_unified.py \
    --in chromosome.svg \
    --out chromosome_unified.svg \
    --new_left "#6A51A3" \
    --new_right "#007C73"

说明：
- 这个脚本是“基于你的 SVG 文件结构”写的：会自动识别渐变色条（同 y/height 的极细 rect 列）。
- 输出 SVG 的所有几何与元素顺序都保持不变，只替换十六进制颜色值。
"""

from __future__ import annotations

import argparse
import re
from collections import defaultdict
from typing import Dict, Tuple


def hex_to_rgb(h: str) -> Tuple[int, int, int]:
    h = h.strip().lstrip("#")
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def rgb_to_hex(rgb: Tuple[int, int, int]) -> str:
    r, g, b = rgb
    return f"#{r:02X}{g:02X}{b:02X}"


def lerp(a: int, b: int, t: float) -> int:
    return int(round(a * (1.0 - t) + b * t))


def build_gradient_mapping_from_colorbar(svg_text: str,
                                         new_left: str,
                                         new_right: str) -> Dict[str, str]:
    """
    从右上角渐变色条（很多很窄的 rect）提取每个旧颜色在色条上的相对位置 t，
    然后把该颜色映射到 new_left -> new_right 的新渐变上。
    返回：old_hex(lower) -> new_hex(#RRGGBB)
    """
    # 这个图里的色条 rect 具有固定的 y 和 height（来自你的 chromosome.svg）
    # y="124.015745" height="14.173228" width 很小且相同。
    rect_re = re.compile(
        r'<rect\s+'
        r'x="(?P<x>[0-9.]+)"\s+'
        r'y="124\.015745"\s+'
        r'width="(?P<w>[0-9.]+)"\s+'
        r'height="14\.173228"\s+'
        r'style="fill:(?P<fill>#[0-9A-Fa-f]{6});stroke:none"\s*/?>'
    )
    rects = [(float(m.group("x")), float(m.group("w")), m.group("fill"))
             for m in rect_re.finditer(svg_text)]
    if not rects:
        raise RuntimeError(
            "没有在 SVG 中找到预期的渐变色条 rect（y=124.015745, height=14.173228）。"
            "如果你的 SVG 结构变了，需要调整 rect_re 正则。"
        )

    xs = [x for x, _, _ in rects]
    ws = [w for _, w, _ in rects]
    x_min = min(xs)
    # 这里所有 rect width 基本一致，取第一个即可
    w0 = ws[0]
    bar_len = (max(xs) + w0) - x_min

    # 统计每个颜色出现的中心 x，取平均中心位置作为该颜色的代表位置
    centers_by_color = defaultdict(list)
    for x, w, fill in rects:
        centers_by_color[fill.lower()].append(x + w / 2.0)

    rgb_left = hex_to_rgb(new_left)
    rgb_right = hex_to_rgb(new_right)

    mapping: Dict[str, str] = {}
    for old_hex, centers in centers_by_color.items():
        c_mean = sum(centers) / len(centers)
        t = (c_mean - (x_min + w0 / 2.0)) / bar_len
        t = max(0.0, min(1.0, t))
        nr = lerp(rgb_left[0], rgb_right[0], t)
        ng = lerp(rgb_left[1], rgb_right[1], t)
        nb = lerp(rgb_left[2], rgb_right[2], t)
        mapping[old_hex] = rgb_to_hex((nr, ng, nb))
    return mapping


def recolor_svg(svg_in: str, new_left: str, new_right: str) -> str:
    """
    统一映射整张 SVG：
    - 渐变色条里的所有颜色（也就是整张图使用的连续色带）整体映射到新渐变
    - 类别色：#ff7f00 -> new_left, #33a02c -> new_right
    """
    mapping = build_gradient_mapping_from_colorbar(svg_in, new_left, new_right)

    # 你的图里另外两种类别色（不在色条里）：Charolais 三角 & Mo-OD 方块
    mapping["#ff7f00"] = new_left.upper()
    mapping["#33a02c"] = new_right.upper()

    hex_re = re.compile(r'#[0-9A-Fa-f]{6}')

    def _rep(m: re.Match) -> str:
        old = m.group(0).lower()
        return mapping.get(old, m.group(0))

    return hex_re.sub(_rep, svg_in)


def main() -> None:
    ap = argparse.ArgumentParser(
        description="对 chromosome.svg 做统一配色映射（保证除颜色外细节完全不变）"
    )
    ap.add_argument("--in", dest="in_path", required=True, help="输入 SVG 路径")
    ap.add_argument("--out", dest="out_path", required=True, help="输出 SVG 路径")
    ap.add_argument("--new_left", default="#6A51A3",
                    help="新渐变低端颜色（同时替换 Charolais 的旧色 #ff7f00）")
    ap.add_argument("--new_right", default="#007C73",
                    help="新渐变高端颜色（同时替换 Mo-OD 的旧色 #33a02c）")
    args = ap.parse_args()

    svg_in = open(args.in_path, "r", encoding="utf-8").read()
    svg_out = recolor_svg(svg_in, args.new_left, args.new_right)
    with open(args.out_path, "w", encoding="utf-8") as f:
        f.write(svg_out)


if __name__ == "__main__":
    main()
