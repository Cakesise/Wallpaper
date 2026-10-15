"""Remove the source character's head while retaining costume, pose and set.

The resulting images are temporary local conditioning inputs. They are not copied
into the public repository or shipped with the wallpaper.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


LOOKS = [
    "01", "02", "03", "04", "05", "06", "07", "08", "09",
    "classic-20", "classic-24",
    "sit-01", "sit-02", "sit-04", "sit-05", "sit-06", "sit-07", "sit-12",
    "sit-13", "sit-14", "sit-16",
    "recline-01", "recline-02", "recline-03", "recline-04",
    "recline-05", "recline-06", "recline-07",
]

RIGHT_SEATED = {"sit-04", "sit-07", "sit-14"}


def head_geometry(look_id: str) -> tuple[float, float, float, float]:
    if look_id.startswith("sit-"):
        cx = 0.82 if look_id in RIGHT_SEATED else 0.53
        return cx, 0.17, 0.145, 0.29
    if look_id.startswith("recline-"):
        return 0.84, 0.20, 0.145, 0.30
    return 0.84, 0.20, 0.145, 0.30


def remove_head(source: Path, destination: Path, look_id: str) -> None:
    image = Image.open(source).convert("RGB")
    width, height = image.size
    cx, cy, rx, ry = head_geometry(look_id)
    box = (
        int((cx - rx) * width),
        int((cy - ry) * height),
        int((cx + rx) * width),
        int((cy + ry) * height),
    )
    mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(mask).ellipse(box, fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(max(18, width // 90)))
    fill = (18, 14, 24) if look_id.startswith(("sit-", "recline-")) else (12, 16, 22)
    replacement = Image.new("RGB", image.size, fill)
    result = Image.composite(replacement, image, mask)
    destination.parent.mkdir(parents=True, exist_ok=True)
    result.save(destination, quality=95, subsampling=0)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    for look_id in LOOKS:
        source = args.source / f"look-{look_id}.jpg"
        destination = args.output / f"reference-look-{look_id}-headless.jpg"
        remove_head(source, destination, look_id)
        print(destination.name)


if __name__ == "__main__":
    main()
