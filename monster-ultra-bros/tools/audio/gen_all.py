"""Regenerates all audio: python3 tools/audio/gen_all.py"""
import music, sfx

if __name__ == "__main__":
    sfx.build()
    music.build()
    print("audio generated")
