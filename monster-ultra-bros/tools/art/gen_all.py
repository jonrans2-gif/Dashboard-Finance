"""Regenerates every image asset: python3 tools/art/gen_all.py"""
import backgrounds, enemies, font, items, player, tiles, ui

if __name__ == "__main__":
    font.build()  # ui.py renders text with the font
    for m in (player, enemies, tiles, items, backgrounds, ui):
        m.build()
    print("art generated")
