#!/usr/bin/env python3
# Generates bundled demo databases (text + image) for CirclesGo demo mode.
# Two datasets: Comic Market 998 and 999, in Japanese.
# The reference schema is derived from the app's read paths (column names are
# read verbatim via getColumnIndexOrThrow), so these DBs load without changes.

import colorsys
import io
import os
import sqlite3
import random
from PIL import Image, ImageDraw, ImageFont

OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "app", "src", "main", "assets", "demo")
os.makedirs(OUT_DIR, exist_ok=True)

# ---- Fonts -----------------------------------------------------------------
FONT_CANDIDATES = [
    "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
    "/System/Library/Fonts/Hiragino Sans GB.ttc",
]
def load_font(size):
    for path in FONT_CANDIDATES:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                pass
    return ImageFont.load_default()

# ---- Scale -----------------------------------------------------------------
# Every space is drawn on the map; circles fill all spaces (a/b on each day),
# so all circles are laid out on the map like a real catalog.
# Each block (one letter) is a two-column island; islands are separated by
# aisles, mimicking how booths are clustered at the real Comic Market.
ROWS_PER_ISLAND = 13
ISLANDS_PER_ROW = 8
ISLAND_ROWS = 2
COLS = 2
CIRC_PER_SPACE_DAY = 2
GENRE_ZONE = 2           # adjacent blocks sharing a genre, so the overlay covers areas
CUT_W, CUT_H = 120, 170
CUT_POOL = 400

# ---- Geometry (all HD, even numbers so /2 is exact) ------------------------
MARGIN = 40
TITLE_H = 56
SQ = 40          # space square (squares within an island are contiguous)
AISLE_X = 28     # gap between islands horizontally
AISLE_Y = 44     # gap between island rows vertically
LABEL_H = 26     # label strip above each island

# ---- Demo content ----------------------------------------------------------
STUDENTS = [
    "シロコ", "ホシノ", "アズサ", "ヒフミ", "ハナコ", "ヒナ", "イオリ", "アコ",
    "ノノミ", "マリー", "ノア", "モモイ", "ミドリ", "コハル", "シュン", "チヒロ",
    "サオリ", "ユウカ", "アスナ", "ミカ", "ヒマリ", "カリン", "ハルナ", "セリカ",
    "アヤネ", "アカリ", "スモモ", "カヨコ", "ムツキ", "ハスミ", "コトリ", "アル",
    "カズサ", "ケイ", "ネル", "トキ", "ハルカ", "イズナ", "ミチル", "ツバキ",
]

HALLS = [("E123", "東123"), ("E456", "東456"), ("W12", "西12")]

GENRES = [
    "アクション", "アクションRPG", "RPG", "シューティング", "シミュレーション",
    "アドベンチャー", "ノベル", "ビジュアルノベル", "パズル", "格闘",
    "対戦格闘", "リズム", "音楽", "レース", "スポーツ",
    "ストラテジー", "ローグライク", "サンドボックス", "ホラー", "FPS",
    "MMORPG", "カードゲーム", "ボードゲーム", "恋愛",
]

GENRE_COLORS = [
    tuple(int(c * 255) for c in colorsys.hsv_to_rgb(i / len(GENRES), 0.55, 0.95))
    for i in range(len(GENRES))
]

BLOCK_LABELS = list(
    "あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん"
    "アイウエオカキクケコサシスセソタチツテトナニヌネノ"
)

BOOK_TEMPLATES = [
    "%s設定資料集", "%sアンソロジー", "%s画集", "%sショートストーリー集",
    "%sリプレイ集", "%s攻略本",
]

# ---- Image helpers ---------------------------------------------------------
def _lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))

def gradient_cut(rng):
    w, h = CUT_W, CUT_H
    c1 = tuple(rng.randint(40, 220) for _ in range(3))
    c2 = tuple(rng.randint(40, 220) for _ in range(3))
    base = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(base)
    for y in range(h):
        d.line([(0, y), (w, y)], fill=_lerp(c1, c2, y / (h - 1)))
    # top-left info box, like a real circle cut
    box, inset = int(w * 0.3), int(w * 0.07)
    d.rectangle([inset, inset, inset + box, inset + box],
                fill=(250, 250, 250), outline=(0, 0, 0), width=2)
    # cut template frame
    d.rectangle([1, 1, w - 2, h - 2], outline=(255, 255, 255), width=2)
    d.rectangle([1, 1, w - 2, h - 2], outline=(0, 0, 0), width=1)
    buf = io.BytesIO()
    base.save(buf, format="PNG", optimize=True)
    return buf.getvalue()

def png_bytes(img):
    buf = io.BytesIO()
    img.save(buf, format="PNG", optimize=True)
    return buf.getvalue()

# ---- Layout computation ----------------------------------------------------
def build_layouts():
    hall_geo = {}
    layout_rows = []
    block_id = 0
    island_w = COLS * SQ
    island_h = ROWS_PER_ISLAND * SQ
    for map_id, (filename, disp) in enumerate(HALLS, start=1):
        blocks = []
        for ir in range(ISLAND_ROWS):
            for ic in range(ISLANDS_PER_ROW):
                block_id += 1
                label = BLOCK_LABELS[(block_id - 1) % len(BLOCK_LABELS)]
                student_idx = (block_id - 1) % len(STUDENTS)
                ix = MARGIN + ic * (island_w + AISLE_X)
                iy = MARGIN + TITLE_H + ir * (LABEL_H + island_h + AISLE_Y) + LABEL_H
                spaces = []
                for col in range(COLS):
                    for row in range(ROWS_PER_ISLAND):
                        space_no = col * ROWS_PER_ISLAND + row + 1
                        x = ix + col * SQ
                        y = iy + row * SQ
                        spaces.append((space_no, x, y))
                        layout_rows.append(dict(blockId=block_id, spaceNo=space_no,
                                                xpos2=x, ypos2=y, mapId=map_id, hallId=map_id))
                blocks.append(dict(id=block_id, label=label, student=student_idx, ic=ic, ir=ir,
                                   label_x=ix, label_y=iy - LABEL_H, spaces=spaces))
        w2 = MARGIN + ISLANDS_PER_ROW * island_w + (ISLANDS_PER_ROW - 1) * AISLE_X + MARGIN
        h2 = MARGIN + TITLE_H + ISLAND_ROWS * (LABEL_H + island_h) + (ISLAND_ROWS - 1) * AISLE_Y + MARGIN
        hall_geo[filename] = dict(w2=w2, h2=h2, disp=disp, blocks=blocks)
    return hall_geo, layout_rows

NUM_FONT = load_font(19)

def draw_space_number(d, space_no, x, y, fill, stroke_fill):
    txt = str(space_no)
    bbox = d.textbbox((0, 0), txt, font=NUM_FONT, stroke_width=1)
    tx = x + (SQ - (bbox[2] - bbox[0])) / 2 - bbox[0]
    ty = y + (SQ - (bbox[3] - bbox[1])) / 2 - bbox[1]
    d.text((tx, ty), txt, font=NUM_FONT, fill=fill, stroke_width=1, stroke_fill=stroke_fill)

def draw_base_map(geo):
    w2, h2, blocks = geo["w2"], geo["h2"], geo["blocks"]
    img = Image.new("RGB", (w2, h2), (255, 255, 255))
    d = ImageDraw.Draw(img)
    title_font = load_font(30)
    label_font = load_font(18)
    d.rectangle([0, 0, w2 - 1, h2 - 1], outline=(0, 0, 0), width=2)
    d.text((MARGIN, 16), geo["disp"], fill=(0, 0, 0), font=title_font)
    for b in blocks:
        d.text((b["label_x"], b["label_y"]), b["label"], fill=(0, 0, 0), font=label_font)
        for (space_no, x, y) in b["spaces"]:
            d.rectangle([x, y, x + SQ, y + SQ], fill=(255, 255, 255), outline=(0, 0, 0), width=1)
            draw_space_number(d, space_no, x, y, (0, 0, 0), (0, 0, 0))
    return img

def draw_genre_map(geo, day, genre_by):
    w2, h2, blocks = geo["w2"], geo["h2"], geo["blocks"]
    img = Image.new("RGBA", (w2, h2), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    island_w = COLS * SQ
    island_h = ROWS_PER_ISLAND * SQ
    pitch_x = island_w + AISLE_X
    pitch_y = LABEL_H + island_h + AISLE_Y
    content_top = MARGIN + TITLE_H
    last_ic = ISLANDS_PER_ROW - 1
    last_ir = ISLAND_ROWS - 1
    # Fill each block's whole cell (booths + surrounding aisles up to the
    # midpoints / map edges) so genres read as solid areas, not boxed booths.
    for b in blocks:
        ic, ir = b["ic"], b["ir"]
        x_left = 0 if ic == 0 else MARGIN + (ic - 1) * pitch_x + island_w + AISLE_X // 2
        x_right = w2 if ic == last_ic else MARGIN + ic * pitch_x + island_w + AISLE_X // 2
        y_top = content_top if ir == 0 \
            else content_top + (ir - 1) * pitch_y + LABEL_H + island_h + AISLE_Y // 2
        y_bottom = h2 if ir == last_ir \
            else content_top + ir * pitch_y + LABEL_H + island_h + AISLE_Y // 2
        color = GENRE_COLORS[genre_by[(b["id"], day)] - 1] + (51,)  # 20% opacity
        d.rectangle([x_left, y_top, x_right, y_bottom], fill=color)
    return img

# ---- Database creation -----------------------------------------------------
TEXT_SCHEMA = """
CREATE TABLE ComiketInfoWC (comiketNo INTEGER, comiketName TEXT,
  cutSizeW INTEGER, cutSizeH INTEGER, cutOriginX INTEGER, cutOriginY INTEGER,
  cutOffsetX INTEGER, cutOffsetY INTEGER, mapSizeW INTEGER, mapSizeH INTEGER,
  mapOriginX INTEGER, mapOriginY INTEGER, map2SizeW INTEGER, map2SizeH INTEGER,
  map2OriginX INTEGER, map2OriginY INTEGER);
CREATE TABLE ComiketDateWC (comiketNo INTEGER, id INTEGER, year INTEGER, month INTEGER, day INTEGER);
CREATE TABLE ComiketMapWC (comiketNo INTEGER, id INTEGER, name TEXT, filename TEXT,
  allFilename TEXT, w INTEGER, h INTEGER, x INTEGER, y INTEGER,
  w2 INTEGER, h2 INTEGER, x2 INTEGER, y2 INTEGER, rotate INTEGER);
CREATE TABLE ComiketBlockWC (comiketNo INTEGER, id INTEGER, name TEXT, areaId INTEGER);
CREATE TABLE ComiketGenreWC (comiketNo INTEGER, id INTEGER, name TEXT, code INTEGER, day INTEGER);
CREATE TABLE ComiketMappingWC (comiketNo INTEGER, mapId INTEGER, blockId INTEGER);
CREATE TABLE ComiketLayoutWC (comiketNo INTEGER, blockId INTEGER, spaceNo INTEGER,
  xpos INTEGER, ypos INTEGER, xpos2 INTEGER, ypos2 INTEGER, layout INTEGER,
  mapId INTEGER, hallId INTEGER);
CREATE TABLE ComiketCircleWC (comiketNo INTEGER, id INTEGER, pageNo INTEGER, cutIndex INTEGER,
  day INTEGER, blockId INTEGER, spaceNo INTEGER, spaceNoSub INTEGER, genreId INTEGER,
  circleName TEXT, circleKana TEXT, penName TEXT, bookName TEXT, url TEXT, mailAddr TEXT,
  description TEXT, memo TEXT, updateId INTEGER, updateData TEXT, circlems TEXT,
  rss TEXT, updateFlag INTEGER);
CREATE TABLE ComiketCircleExtend (comiketNo INTEGER, id INTEGER, WCId INTEGER,
  twitterURL TEXT, pixivURL TEXT, CirclemsPortalURL TEXT);
"""

IMAGE_SCHEMA = """
CREATE TABLE ComiketCommonImage (name TEXT, image BLOB);
CREATE TABLE ComiketCircleImage (id INTEGER, cutImage BLOB);
"""

DAYS = [(1, 2024, 8, 10), (2, 2024, 8, 11)]

def generate_dataset(event_no, seed):
    rng = random.Random(seed)
    text_path = os.path.join(OUT_DIR, "webcatalog%d.db" % event_no)
    image_path = os.path.join(OUT_DIR, "webcatalog%dImage1.db" % event_no)
    for p in (text_path, image_path):
        if os.path.exists(p):
            os.remove(p)

    hall_geo, layout_rows = build_layouts()
    cut_pool = [gradient_cut(rng) for _ in range(CUT_POOL)]
    # Assign one genre per block, in contiguous zones, so the overlay paints
    # areas rather than individual booths. Zones shift per day.
    genre_by = {}
    for lr in layout_rows:
        block_index = lr["blockId"] - 1
        for day_index, (did, *_rest) in enumerate(DAYS):
            genre_by[(lr["blockId"], did)] = \
                1 + ((block_index // GENRE_ZONE) + day_index * 7) % len(GENRES)

    tdb = sqlite3.connect(text_path)
    tdb.executescript(TEXT_SCHEMA)
    idb = sqlite3.connect(image_path)
    idb.executescript(IMAGE_SCHEMA)

    tdb.execute("INSERT INTO ComiketInfoWC VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
                (event_no, "コミックマーケット%d (デモ)" % event_no,
                 CUT_W, CUT_H, 0, 0, 0, 0, 320, 320, 0, 0, 640, 640, 0, 0))

    for (did, y, m, dd) in DAYS:
        tdb.execute("INSERT INTO ComiketDateWC VALUES (?,?,?,?,?)", (event_no, did, y, m, dd))

    for gid, gname in enumerate(GENRES, start=1):
        tdb.execute("INSERT INTO ComiketGenreWC VALUES (?,?,?,?,?)",
                    (event_no, gid, gname, gid, 0))

    all_blocks = []
    for map_id, (filename, disp) in enumerate(HALLS, start=1):
        geo = hall_geo[filename]
        w2, h2 = geo["w2"], geo["h2"]
        w1, h1 = w2 // 2, h2 // 2
        tdb.execute("INSERT INTO ComiketMapWC VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
                    (event_no, map_id, disp, filename, filename,
                     w1, h1, 0, 0, w2, h2, 0, 0, 0))
        for b in geo["blocks"]:
            tdb.execute("INSERT INTO ComiketMappingWC VALUES (?,?,?)", (event_no, map_id, b["id"]))
            tdb.execute("INSERT INTO ComiketBlockWC VALUES (?,?,?,?)",
                        (event_no, b["id"], b["label"], map_id))
            all_blocks.append((map_id, b))
        base = draw_base_map(geo)
        hd_map = png_bytes(base)
        sd_map = png_bytes(base.resize((w1, h1), Image.LANCZOS))
        for (did, *_rest) in DAYS:
            genre = draw_genre_map(geo, did, genre_by)
            idb.execute("INSERT INTO ComiketCommonImage VALUES (?,?)",
                        ("LWMP%d%s" % (did, filename), hd_map))
            idb.execute("INSERT INTO ComiketCommonImage VALUES (?,?)",
                        ("WMP%d%s" % (did, filename), sd_map))
            idb.execute("INSERT INTO ComiketCommonImage VALUES (?,?)",
                        ("LWGR%d%s" % (did, filename), png_bytes(genre)))
            idb.execute("INSERT INTO ComiketCommonImage VALUES (?,?)",
                        ("WGR%d%s" % (did, filename), png_bytes(genre.resize((w1, h1), Image.LANCZOS))))

    for lr in layout_rows:
        tdb.execute("INSERT INTO ComiketLayoutWC VALUES (?,?,?,?,?,?,?,?,?,?)",
                    (event_no, lr["blockId"], lr["spaceNo"],
                     lr["xpos2"] // 2, lr["ypos2"] // 2, lr["xpos2"], lr["ypos2"],
                     1, lr["mapId"], lr["hallId"]))

    # Fill every space (a/b on each day) so all circles are laid out on the map.
    circle_id = 0
    wc_id = event_no * 100000
    for (map_id, b) in all_blocks:
        student = STUDENTS[b["student"]]
        for (space_no, x, y) in b["spaces"]:
            for (did, *_rest) in DAYS:
                for sub in range(CIRC_PER_SPACE_DAY):
                    circle_id += 1
                    wc_id += 1
                    name = "デモ用サークル%04d" % circle_id
                    kana = "でもようさーくる%04d" % circle_id
                    gid = genre_by[(b["id"], did)]
                    book = rng.choice(BOOK_TEMPLATES) % student
                    desc = "このサークルは、サークル番号%04dです。" % circle_id
                    tdb.execute(
                        "INSERT INTO ComiketCircleWC VALUES "
                        "(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
                        (event_no, circle_id, circle_id, 0, did, b["id"], space_no, sub, gid,
                         name, kana, student, book, "", "", desc,
                         "", 0, "", "", "", 0))
                    tdb.execute("INSERT INTO ComiketCircleExtend VALUES (?,?,?,?,?,?)",
                                (event_no, circle_id, wc_id, "", "", ""))
                    idb.execute("INSERT INTO ComiketCircleImage VALUES (?,?)",
                                (circle_id, rng.choice(cut_pool)))

    tdb.commit(); tdb.close()
    idb.commit(); idb.close()
    tsize = os.path.getsize(text_path)
    isize = os.path.getsize(image_path)
    print("Event %d: %d circles, text=%.0fKB image=%.0fKB" %
          (event_no, circle_id, tsize / 1024, isize / 1024))

if __name__ == "__main__":
    generate_dataset(999, seed=999)
    generate_dataset(998, seed=1998)
    total = sum(os.path.getsize(os.path.join(OUT_DIR, f)) for f in os.listdir(OUT_DIR))
    print("Total demo bundle: %.1f KB" % (total / 1024))
    print("Output dir:", OUT_DIR)
