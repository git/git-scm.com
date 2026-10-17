#!/usr/bin/env python3
"""Generate a 1200x630 OG image for git-scm.com (Git).

Pillow-only, byte-reproducible. Clean card matching the Git brand:
cream ground (#fcfcfa site bg), #f14e32 orange accent (Git's --orange),
dark title, section pills + domain chip, subtle branch motif.
"""
import os
from PIL import Image, ImageDraw, ImageFont

W, H = 1200, 630
BG = (252, 252, 250)          # #fcfcfa site main-bg
ORANGE = (241, 78, 50)        # #f14e32 Git --orange
DARK = (78, 68, 60)           # #4e443c font color
WHITE = (255, 255, 255)
GREY = (125, 122, 115)
LIGHT_ORANGE = (252, 225, 218)  # tinted pill background
BLUE = (3, 136, 166)          # #0388a6 link color

FONT_DIR = os.environ.get("FONT_DIR", "/usr/share/fonts/truetype/dejavu")


def font(size, bold=False):
    name = "DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"
    p = os.path.join(FONT_DIR, name)
    if not os.path.exists(p):
        p = os.path.join(FONT_DIR, "LiberationSans-Bold.ttf" if bold else "LiberationSans-Regular.ttf")
    return ImageFont.truetype(p, size)


def rounded(d, box, r, fill):
    d.rounded_rectangle(box, radius=r, fill=fill)


def main():
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)

    # top accent bar (Git orange)
    d.rectangle([0, 0, W, 10], fill=ORANGE)

    f_title = font(84, bold=True)
    f_sub = font(32)
    f_pill = font(30, bold=True)
    f_domain = font(30, bold=True)
    f_foot = font(24)

    # title + subtitle
    d.text((70, 62), "Git", font=f_title, fill=DARK)
    d.text((70, 190), "Free and open source distributed", font=f_sub, fill=GREY)
    d.text((70, 232), "version control system", font=f_sub, fill=GREY)

    # separator
    d.line([70, 310, W - 70, 310], fill=(226, 224, 216), width=2)

    # section pills
    pills = ["Documentation", "Pro Git Book", "Reference", "Downloads", "Community"]
    x = 70
    y = 348
    for p_ in pills:
        w = d.textlength(p_, font=f_pill) + 44
        if x + w > 1130:
            x = 70
            y += 82
        rounded(d, [x, y, x + w, y + 62], 31, ORANGE)
        d.text((x + 22, y + 13), p_, font=f_pill, fill=WHITE)
        x += w + 18

    # footer domain chip
    d.rounded_rectangle([70, H - 92, 410, H - 44], 24, fill=DARK)
    d.text((108, H - 84), "git-scm.com", font=f_domain, fill=WHITE)

    # subtle branch motif top-right
    cx, cy = W - 210, 150
    d.line([cx - 60, cy + 55, cx - 60, cy - 55], fill=ORANGE, width=6)
    d.arc([cx - 60, cy - 55, cx + 22, cy + 22], 90, 270, fill=ORANGE, width=6)
    d.arc([cx - 60, cy - 22, cx + 22, cy + 55], 90, 270, fill=ORANGE, width=6)
    d.ellipse([cx - 68, cy - 63, cx - 52, cy - 47], fill=ORANGE)
    d.ellipse([cx - 68, cy - 30, cx - 52, cy - 14], fill=ORANGE)
    d.ellipse([cx - 68, cy + 47, cx - 52, cy + 63], fill=ORANGE)

    out = "og-image.png"
    img.save(out, "PNG")
    print("wrote", out, img.size)


if __name__ == "__main__":
    main()