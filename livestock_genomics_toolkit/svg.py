"""Dependency-free SVG plotting helpers used by the command line tools."""

from __future__ import annotations

import csv
from pathlib import Path
from xml.etree.ElementTree import Element, SubElement, tostring


PALETTE = [
    "#1b9e77",
    "#d95f02",
    "#7570b3",
    "#e7298a",
    "#66a61e",
    "#e6ab02",
    "#a6761d",
    "#1f78b4",
]


def _svg(width: int, height: int) -> Element:
    root = Element("svg")
    root.set("xmlns", "http://www.w3.org/2000/svg")
    root.set("width", str(width))
    root.set("height", str(height))
    root.set("viewBox", f"0 0 {width} {height}")
    return root


def _text(root: Element, x: float, y: float, label: str, size: int = 12, anchor: str = "start") -> None:
    item = SubElement(root, "text")
    item.set("x", f"{x:.2f}")
    item.set("y", f"{y:.2f}")
    item.set("font-family", "Arial, Helvetica, sans-serif")
    item.set("font-size", str(size))
    item.set("text-anchor", anchor)
    item.text = label


def _line(root: Element, x1: float, y1: float, x2: float, y2: float, stroke: str = "#333", width: float = 1) -> None:
    item = SubElement(root, "line")
    item.set("x1", f"{x1:.2f}")
    item.set("y1", f"{y1:.2f}")
    item.set("x2", f"{x2:.2f}")
    item.set("y2", f"{y2:.2f}")
    item.set("stroke", stroke)
    item.set("stroke-width", str(width))


def _circle(root: Element, cx: float, cy: float, radius: float, fill: str) -> None:
    item = SubElement(root, "circle")
    item.set("cx", f"{cx:.2f}")
    item.set("cy", f"{cy:.2f}")
    item.set("r", f"{radius:.2f}")
    item.set("fill", fill)
    item.set("opacity", "0.88")


def _scale(value: float, lower: float, upper: float, start: float, end: float) -> float:
    if upper == lower:
        return (start + end) / 2
    return start + (value - lower) / (upper - lower) * (end - start)


def _write(root: Element, output: str | Path) -> None:
    Path(output).write_text(
        '<?xml version="1.0" encoding="UTF-8"?>\n' + tostring(root, encoding="unicode"),
        encoding="utf-8",
    )


def plot_line(
    rows: list[dict[str, str]],
    x_column: str,
    y_column: str,
    output: str | Path,
    title: str,
    x_label: str | None = None,
    y_label: str | None = None,
) -> None:
    points = [(float(row[x_column]), float(row[y_column])) for row in rows if row.get(x_column) and row.get(y_column)]
    if not points:
        raise ValueError("No numeric points found for the requested columns")

    width, height = 960, 480
    left, right, top, bottom = 90, 30, 60, 70
    plot_width = width - left - right
    plot_height = height - top - bottom
    xs = [point[0] for point in points]
    ys = [point[1] for point in points]

    root = _svg(width, height)
    _text(root, width / 2, 32, title, 20, "middle")
    _line(root, left, height - bottom, width - right, height - bottom, "#111", 1.4)
    _line(root, left, height - bottom, left, top, "#111", 1.4)

    path_parts = []
    for index, (x_value, y_value) in enumerate(points):
        x = _scale(x_value, min(xs), max(xs), left, left + plot_width)
        y = _scale(y_value, min(ys), max(ys), height - bottom, top)
        path_parts.append(("M" if index == 0 else "L") + f" {x:.2f} {y:.2f}")
    path = SubElement(root, "path")
    path.set("d", " ".join(path_parts))
    path.set("fill", "none")
    path.set("stroke", "#1f78b4")
    path.set("stroke-width", "2")

    _text(root, left + plot_width / 2, height - 24, x_label or x_column, 13, "middle")
    _text(root, 18, top + plot_height / 2, y_label or y_column, 13, "middle")
    _write(root, output)


def plot_pca(eigenvec_path: str | Path, population_path: str | Path, output: str | Path) -> None:
    eigen_rows = []
    for line in Path(eigenvec_path).read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        fields = line.split()
        if len(fields) < 4:
            continue
        eigen_rows.append({"sample": fields[1], "pc1": float(fields[2]), "pc2": float(fields[3])})

    population = _load_population(population_path)
    if not eigen_rows:
        raise ValueError("No PCA rows found")

    groups = sorted({population.get(row["sample"], "Unknown") for row in eigen_rows})
    color_by_group = {group: PALETTE[index % len(PALETTE)] for index, group in enumerate(groups)}
    xs = [row["pc1"] for row in eigen_rows]
    ys = [row["pc2"] for row in eigen_rows]

    width, height = 760, 560
    left, right, top, bottom = 85, 150, 60, 70
    plot_width = width - left - right
    plot_height = height - top - bottom
    root = _svg(width, height)
    _text(root, width / 2, 32, "PCA scatter plot", 20, "middle")
    _line(root, left, height - bottom, width - right, height - bottom, "#111", 1.4)
    _line(root, left, height - bottom, left, top, "#111", 1.4)

    for row in eigen_rows:
        group = population.get(row["sample"], "Unknown")
        x = _scale(row["pc1"], min(xs), max(xs), left, left + plot_width)
        y = _scale(row["pc2"], min(ys), max(ys), height - bottom, top)
        _circle(root, x, y, 4.5, color_by_group[group])

    _text(root, left + plot_width / 2, height - 24, "PC1", 13, "middle")
    _text(root, 18, top + plot_height / 2, "PC2", 13, "middle")

    legend_x = width - right + 24
    legend_y = top + 20
    _text(root, legend_x, legend_y - 12, "Group", 13)
    for index, group in enumerate(groups):
        y = legend_y + index * 24
        _circle(root, legend_x + 6, y - 4, 5, color_by_group[group])
        _text(root, legend_x + 18, y, group, 12)

    _write(root, output)


def read_tsv(path: str | Path) -> list[dict[str, str]]:
    with Path(path).open("r", encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle, delimiter="\t"))


def _load_population(path: str | Path) -> dict[str, str]:
    rows = read_tsv(path)
    if rows:
        sample_key = _pick_key(rows[0], ["IID", "sample", "sample_id", "id"])
        group_key = _pick_key(rows[0], ["Group", "population", "pop", "breed"])
        if sample_key and group_key:
            return {row[sample_key]: row[group_key] for row in rows if row.get(sample_key)}

    mapping: dict[str, str] = {}
    for line in Path(path).read_text(encoding="utf-8").splitlines():
        fields = line.split()
        if len(fields) >= 3:
            mapping[fields[1]] = fields[2]
        elif len(fields) == 2:
            mapping[fields[0]] = fields[1]
    return mapping


def _pick_key(row: dict[str, str], names: list[str]) -> str | None:
    lower_to_actual = {key.lower(): key for key in row}
    for name in names:
        if name.lower() in lower_to_actual:
            return lower_to_actual[name.lower()]
    return None
