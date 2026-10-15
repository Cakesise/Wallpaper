"""Build a compact labeled overview of all generated wallpaper looks."""

from pathlib import Path

import cv2
import numpy as np


LOOKS = [
    "01", "02", "03", "04", "05", "06", "07", "08", "09",
    "classic-20", "classic-24",
    "recline-01", "recline-02", "recline-03", "recline-04",
    "recline-05", "recline-06", "recline-07",
    "sit-01", "sit-02", "sit-04", "sit-05", "sit-06", "sit-07",
    "sit-12", "sit-13", "sit-14", "sit-16",
]


def main() -> None:
    repo = Path(__file__).resolve().parent.parent
    output = repo.parents[1] / "outputs" / "Roland-28\u5957\u6700\u7ec8\u603b\u89c8.jpg"
    tile_width, image_height, label_height = 640, 360, 28
    rows = []
    for start in range(0, len(LOOKS), 3):
        tiles = []
        for look_id in LOOKS[start:start + 3]:
            image = cv2.imread(str(repo / "assets" / "images" / f"look-{look_id}.jpg"))
            image = cv2.resize(image, (tile_width, image_height), interpolation=cv2.INTER_AREA)
            tile = np.zeros((image_height + label_height, tile_width, 3), dtype=np.uint8)
            tile[:image_height] = image
            cv2.putText(tile, look_id, (8, image_height + 20), cv2.FONT_HERSHEY_SIMPLEX,
                        0.5, (210, 210, 210), 1, cv2.LINE_AA)
            tiles.append(tile)
        while len(tiles) < 3:
            tiles.append(np.zeros_like(tiles[0]))
        rows.append(np.hstack(tiles))
    sheet = np.vstack(rows)
    output.parent.mkdir(parents=True, exist_ok=True)
    encoded, buffer = cv2.imencode(".jpg", sheet, [cv2.IMWRITE_JPEG_QUALITY, 90])
    if not encoded:
        raise RuntimeError("Could not encode contact sheet")
    buffer.tofile(str(output))
    print(output)


if __name__ == "__main__":
    main()
