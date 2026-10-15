"""Collect approved H3 videos and derive wallpaper stills and thumbnails."""

from __future__ import annotations

import argparse
import shutil
from pathlib import Path

import cv2

LOOKS = [
    "01", "02", "03", "04", "05", "06", "07", "08", "09",
    "classic-20", "classic-24",
    "sit-01", "sit-02", "sit-04", "sit-05", "sit-06", "sit-07",
    "sit-12", "sit-13", "sit-14", "sit-16",
    "recline-01", "recline-02", "recline-03", "recline-04",
    "recline-05", "recline-06", "recline-07",
]


def newest_video(output: Path, look_id: str) -> Path:
    audio = sorted(output.glob(f"look-{look_id}_*-audio.webm"), key=lambda p: p.stat().st_mtime)
    plain = sorted(output.glob(f"look-{look_id}_*.webm"), key=lambda p: p.stat().st_mtime)
    candidates = audio or plain
    if not candidates:
        raise FileNotFoundError(f"No generated video found for {look_id}")
    return candidates[-1]


def middle_frame(video: Path):
    capture = cv2.VideoCapture(str(video))
    count = int(capture.get(cv2.CAP_PROP_FRAME_COUNT))
    capture.set(cv2.CAP_PROP_POS_FRAMES, max(0, count // 2))
    ok, frame = capture.read()
    capture.release()
    if not ok:
        raise RuntimeError(f"Could not decode {video}")
    return frame


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True, help="ComfyUI final output folder")
    parser.add_argument("--repo", type=Path, required=True)
    args = parser.parse_args()
    image_dir = args.repo / "assets" / "images"
    media_dir = args.repo / "assets" / "media"
    image_dir.mkdir(parents=True, exist_ok=True)
    media_dir.mkdir(parents=True, exist_ok=True)

    for look_id in LOOKS:
        source = newest_video(args.output, look_id)
        target_video = media_dir / f"look-{look_id}.webm"
        shutil.copy2(source, target_video)
        frame = middle_frame(source)
        still = cv2.resize(frame, (3840, 2160), interpolation=cv2.INTER_LANCZOS4)
        thumb = cv2.resize(frame, (480, 270), interpolation=cv2.INTER_AREA)
        cv2.imwrite(str(image_dir / f"look-{look_id}.jpg"), still, [cv2.IMWRITE_JPEG_QUALITY, 92])
        cv2.imwrite(str(image_dir / f"thumb-{look_id}.jpg"), thumb, [cv2.IMWRITE_JPEG_QUALITY, 88])
        print(f"{look_id}: {source.name}")

    preview = image_dir / "look-04.jpg"
    shutil.copy2(preview, args.repo / "preview.jpg")


if __name__ == "__main__":
    main()
