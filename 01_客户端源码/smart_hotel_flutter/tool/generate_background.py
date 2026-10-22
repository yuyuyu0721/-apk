#!/usr/bin/env python3
"""从 UI 素材包原图生成 App 背景图（首页暖色 / 登录冷色）

用法（需要 Pillow）：
    python tool/generate_background.py

输入：../materials/鸿蒙智慧客房应用-UI素材包/4.配图/img_raw.png（2400×2400）
输出：assets/images/bg_hotel.jpg（首页，暖色）
      assets/images/bg_login.jpg（登录页，冷色调）

参数含义：
    radius     高斯模糊半径（越大越糊；视频背景能看出窗与床头轮廓，约 10）
    bright     亮度倍率（首页 0.78 → 平均亮度 ~113）
    gains      逐通道增益（登录页用压红提蓝，得到蓝灰冷调）
"""
import os
import sys

try:
    from PIL import Image, ImageEnhance, ImageFilter
except ImportError:
    sys.exit("需要 Pillow：pip install pillow")

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
PROJECT = os.path.dirname(HERE)
RAW = os.path.join(
    PROJECT, "..", "materials", "鸿蒙智慧客房应用-UI素材包", "4.配图", "img_raw.png"
)
RAW = os.path.normpath(RAW)
OUT_DIR = os.path.join(PROJECT, "assets", "images")

TARGET_W, TARGET_H = 1080, 2336  # 440×952 的竖版


def base(radius: float = 10.0) -> Image.Image:
    src = Image.open(RAW).convert("RGB")
    w, h = src.size
    scale = max(TARGET_W / w, TARGET_H / h)
    nw, nh = int(w * scale + 0.5), int(h * scale + 0.5)
    im = src.resize((nw, nh), Image.LANCZOS)
    im = im.crop(
        ((nw - TARGET_W) // 2, (nh - TARGET_H) // 2,
         (nw - TARGET_W) // 2 + TARGET_W, (nh - TARGET_H) // 2 + TARGET_H)
    )
    return im.filter(ImageFilter.GaussianBlur(radius=radius))


def grade(im: Image.Image, bright: float, gains, color: float,
          contrast: float) -> Image.Image:
    a = np.asarray(im).astype(float)
    a[:, :, 0] *= gains[0]
    a[:, :, 1] *= gains[1]
    a[:, :, 2] *= gains[2]
    out = Image.fromarray(np.clip(a, 0, 255).astype("uint8"))
    out = ImageEnhance.Brightness(out).enhance(bright)
    out = ImageEnhance.Color(out).enhance(color)
    return ImageEnhance.Contrast(out).enhance(contrast)


def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)

    home = grade(base(10.0), 0.78, (1.0, 1.0, 1.0), 0.94, 0.97)
    home.save(os.path.join(OUT_DIR, "bg_hotel.jpg"),
              quality=90, optimize=True, progressive=True)

    # 登录页：压红、提蓝 → 视频登录页那种蓝灰冷调
    login = grade(base(10.0), 1.0, (0.674, 0.776, 0.833), 1.0, 1.0)
    login.save(os.path.join(OUT_DIR, "bg_login.jpg"),
               quality=90, optimize=True, progressive=True)
    print("已生成 bg_hotel.jpg / bg_login.jpg")


if __name__ == "__main__":
    main()
