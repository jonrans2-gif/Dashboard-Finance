# MONSTER ULTRA BROS. — WHITE EDITION

Een klassieke 2D-platformgame voor Android, gebouwd met **Godot 4.7.2** (GDScript,
Compatibility-renderer). Je speelt als een levend blikje Monster Energy Ultra White
dat door 12 levels in 4 werelden rent, springt, vijanden plet, geheimen zoekt en
4 eindbazen verslaat.

> Onofficieel fanproject. "Monster Energy" en "Ultra White" zijn merken van hun
> eigenaar. Alle graphics, muziek, geluiden en levels in dit project zijn zelf
> gemaakt (procedureel gegenereerd door de scripts in `tools/`); er zijn geen
> Nintendo- of Monster-assets gebruikt. Het blikje is een eigen interpretatie
> (zilver-wit, zwarte deksel en accenten, een drie-strepen klauwteken).
> Publiceer de game niet in een store zonder toestemming van de merkhouder.

---

## 1. Installeren op je Android-telefoon

Kant-en-klare APK: [`release/MonsterUltraBros-v1.0.0.apk`](release/MonsterUltraBros-v1.0.0.apk)
(SHA-256 in `release/SHA256SUMS.txt`).

* Android **7.0 (API 24) of nieuwer**, ARM-processor (arm64-v8a of armeabi-v7a — vrijwel alle telefoons).
* OpenGL ES 3.0 vereist (alle toestellen van de laatste ~8 jaar).

**Via de telefoon**
1. Kopieer de APK naar je telefoon (USB, Google Drive, e-mail…).
2. Tik op het bestand. Android vraagt om *installeren uit onbekende bronnen* toe te
   staan voor die app (Bestanden/Chrome) — sta het eenmalig toe.
3. Tik op **Installeren** en daarna op **Openen**.

**Via een pc (adb)**
```
adb install -r MonsterUltraBros-v1.0.0.apk
```

De game werkt volledig offline (geen internet-permissie in de APK; de enige
permissie is `VIBRATE` voor haptische feedback).

> De APK is ondertekend met een eigen release-sleutel. Bouw je zelf een nieuwe
> APK met een andere sleutel, verwijder dan eerst de oude installatie
> (Android weigert een update met een andere handtekening; je voortgang gaat dan verloren).

---

## 2. Besturing

| Touch (landschap)                 | Toetsenbord (pc)        | Actie |
|-----------------------------------|-------------------------|-------|
| ◀ ▶ linksonder                    | ← → / A D               | lopen (snelheid bouwt op tot rennen) |
| ⬆ rechtsonder                     | Spatie / ↑ / W / Z      | springen — kort tikken = laag, ingedrukt houden = hoog |
| ⚡ (verschijnt met Energy Surge)   | Shift / X               | energierush (dash) |
| deur-knop (verschijnt bij deuren) | E / ↓ / S               | deur in |
| ⏸ rechtsboven, Android-terugknop  | Esc / P                 | pauze |

* Meerdere vingers tegelijk, en je kunt met een duim van ◀ naar ▶ **schuiven**.
* Coyote time (nog springen net na een rand) en jump buffering (iets te vroeg
  springen telt alsnog) zitten erin.
* Knopgrootte, transparantie, positie (naar binnen/hoger), gevoeligheid en een
  gespiegelde layout zijn instelbaar in **Settings**.
* Gamepads werken ook (D-pad/linker stick, A = springen, X = dash, Start = pauze).

---

## 3. De game

**Werelden en levels**

| Wereld | Levels | Nieuw |
|--------|--------|-------|
| 1 White Hills | 1-1 The Beginning · 1-2 Underground Energy · 1-3 The White Fortress | basis, pijpen, verborgen blokken, liften, lava, vallende platforms — baas **Sugar King** |
| 2 Neon Factory | 2-1 Factory Run · 2-2 Energy Storage (verticaal) · 2-3 The Machine Core | lopende banden, Mega Crushers, drones, energiebarrières — baas **Crusher Prime** |
| 3 Frozen Voltage | 3-1 Frozen Peaks · 3-2 Ice Caverns · 3-3 The Storm Bridge | glad ijs, ijspegels, elektrische zappers, brug over een kloof — baas **Frost Volt** |
| 4 Ultra Dimension | 4-1 Ultra Highway · 4-2 Energy Reactor · 4-3 The Final Overload | boost-pads, snelle platforms, alles door elkaar — eindbaas **The Overload Core** |

Elk level heeft een start, checkpoint(s), een eindvlag, **3 Ultra Shards**, minstens
één **verborgen Energy Core** (achter nepmuren, in bonuskamers achter deuren, op
wolken via een veer of achter een energiebarrière), muntjes en powerblokken.

**Vijanden**: Empty Can (patrouilleert), Sugar Cube (springt onvoorspelbaar, met
zichtbare hurk-waarschuwing), Energy Drone (vuurt energiebollen na een rode
oplaadflits), Corrupted Can (snel, valt niet van randen, stormt op je af),
Static Slime (laadt zich periodiek op — dan niet op springen), Mega Crusher
(slaat op een vast ritme neer, schudt eerst). Vijanden worden pas actief als ze
bijna in beeld komen, zodat niets onverwacht vlak naast je verschijnt.

**Power-ups**: Ultra Boost (sneller), White Shield (vangt één klap op), Energy
Surge (dash die barrières en bakstenen breekt), Mega Can (groter, breekt
bakstenen, vangt een klap op door te krimpen), Double Jump, Ultra Magnet (trekt
muntjes aan), Overload Mode (zeldzaam: onkwetsbaar + snel + verslaat alles).
Actieve power-ups staan in de HUD met een tijdbalk die knippert als ze bijna
aflopen; het blikje krijgt een gekleurde gloed.

**Energie & levens**: het blikje heeft 3 energiecellen; een klap kost één cel
(knipperen = kort onkwetsbaar). Ravijnen, lava/zuur en de tijdslimiet kosten
meteen een leven. 100 muntjes = extra leven. Bij 0 levens: Game Over (opnieuw
proberen of menu).

**Eindbazen** hebben elk een eigen arena, meerdere fases en een duidelijke zwakke plek:
* *Sugar King* — hupt naar je toe, doet dan een grote sprong met schokgolven
  (overspringen!) en is daarna duizelig: spring op zijn kop. Fase 2 roept
  suikerklontjes op, fase 3 slaat twee keer.
* *Crusher Prime* — volgt je onder het plafond, kleurt rood, slaat neer. Vast in de
  vloer opent zijn luik: spring erop en stamp op de groene kern. Later schokgolven en energiebollen.
* *Frost Volt* — vliegende stormwolk: duikt LAAG (overspringen) of HOOG (blijf
  staan), laat bliksem inslaan op knipperende markeringen en zakt daarna
  uitgeput omlaag: dan is hij kwetsbaar. Later ijspegelregen.
* *The Overload Core* — gigantische machine: laserstralen (laag = springen, hoog =
  blijf staan), stuiterende energiebollen, drones. Na twee aanvallen raakt hij
  oververhit en opent de kern: spring of dash ertegenaan.

Na de laatste baas volgt een eindanimatie met aftiteling en de keuze om opnieuw te spelen.

**Score**: munten, vijanden (combo's bij achter elkaar stampen), blokken,
power-ups, shards (1000), cores (2000), vlagbonus (hoger pakken = meer) en
tijdbonus. Het eindscherm telt alles op; de beste score per level wordt bewaard
en levels zijn opnieuw te spelen via **Level Select**.

**Menu's**: Play, Continue (gaat verder bij het laatste level/checkpoint), Level
Select (per wereld, met beste score, shards en core), Settings, Credits.
Pauze: Resume, Restart Level, Settings, Main Menu. De game pauzeert automatisch
bij telefoontjes, app-wissel of schermvergrendeling.

**Settings**: muziek- en effectvolume, trillen aan/uit, knopgrootte,
knoptransparantie, layout (standaard/gespiegeld), knoppen naar binnen/hoger,
aanraakgevoeligheid, touch-knoppen (auto/altijd/verborgen), scherm
(landschap/draaien/portret) en schermschudden. Standaard is landschap; in portret
staat het level bovenin en de knoppen op de grond eronder.

**Opslag**: `user://progress.json` en `user://settings.json` op het toestel. Elke
schrijfactie gaat eerst naar een tijdelijk bestand dat wordt teruggelezen en
gecontroleerd (SHA-256), daarna pas vervangen; de vorige versie blijft als
`.bak` bewaard en wordt gebruikt als het hoofdbestand beschadigd is.

---

## 4. Zelf bouwen (Windows 11)

1. **Godot 4.7.2** (standaard, niet .NET): <https://godotengine.org/download/archive/4.7.2-stable/>.
   Pak uit, bijv. naar `C:\Godot\`.
2. **Export templates**: open Godot → *Editor → Manage Export Templates → Download and Install*.
3. **JDK 17 of 21** (bijv. Eclipse Temurin) en de **Android SDK** — het makkelijkst via
   Android Studio (SDK Manager: *Android SDK Platform 35/36*, *Build-Tools 35+*,
   *Platform-Tools*, *Command-line Tools*).
4. In Godot: *Editor → Editor Settings → Export → Android*: vul **Java SDK Path** en
   **Android SDK Path** in.
5. Maak één keer een eigen release-sleutel (bewaar hem goed, niet in git):
   ```
   keytool -genkeypair -keystore C:\keys\mub-release.keystore -alias monsterultrabros -keyalg RSA -keysize 2048 -validity 10000
   ```
6. Bouwen (test-suite draait automatisch eerst):
   ```powershell
   cd monster-ultra-bros
   $env:GODOT="C:\Godot\Godot_v4.7.2-stable_win64_console.exe"
   $env:MUB_KEYSTORE="C:\keys\mub-release.keystore"
   $env:MUB_KEY_ALIAS="monsterultrabros"
   $env:MUB_KEY_PASS="<jouw wachtwoord>"
   .\build_android.ps1
   ```
   Resultaat: `build\MonsterUltraBros.apk`. (Linux/macOS: `./build_android.sh`.)

Of in de editor: open `monster-ultra-bros/project.godot` → *Project → Export… →
Android → Export Project* (vink "Export With Debug" uit voor een release-build).

Direct op een aangesloten telefoon spelen vanuit de editor kan met het
Android-icoon rechtsboven (USB-debugging aan).

---

## 5. Projectstructuur

```
monster-ultra-bros/
  project.godot, export_presets.cfg, default_bus_layout.tres
  scenes/            boot, main_menu, level_select, game, ending
  scripts/
    autoload/        settings (+input, trillen), save_system, game_state,
                     audio_manager, fx (pooling), ui_theme
    player/          player.gd (besturing, physics, power-ups), shield_fx.gd
    level/           level.gd (levelbouwer + spelregels), level_data.gd (parser),
                     tiles.gd (TileSet-fabriek), game_camera.gd, parallax_bg.gd,
                     objects/ (platforms, veer, deur, checkpoint, vlag, zapper,
                     ijspegel, boost-pad, Mega Crusher)
    enemies/         enemy.gd (basis) + 5 vijanden + projectile.gd
    bosses/          boss.gd (basis), boss_part.gd, boss_hazard.gd + 4 bazen
    items/           collectible.gd, powerup_item.gd, block_effects.gd
    ui/              hud, touch_controls, pause/settings/level complete/game over,
                     main_menu, level_select, credits, ending
  levels/            1-1.txt … 4-3.txt (tekstformaat, legenda in level_data.gd)
  assets/            gegenereerde sprites, tiles, achtergronden, UI, font, audio
  tests/             test-suite + ontwikkeltools
  tools/             Python-generatoren (art, audio, levels) en theme-baker
  release/           kant-en-klare APK
```

**Levels bewerken**: elk level is een tekstbestand; één teken = één tegel van
16×16 (`#` grond, `=` baksteen, `?`/`!` blokken, `e` Empty Can, `$` shard, `@`
core, `%` nepmuur, `m---` bewegend platform, enz. — zie `LEGEND` in
`scripts/level/level_data.gd`). De levels zijn opgebouwd met
`tools/levels/build_levels.py`; draai daarna de tests om bereikbaarheid te controleren.

**Assets opnieuw genereren** (Python 3 met Pillow, numpy, scipy, fontTools):
```
python3 tools/art/gen_all.py      # sprites, tiles, achtergronden, UI, font
python3 tools/audio/gen_all.py    # 12 muziekstukken + 38 geluidseffecten
python3 tools/levels/build_levels.py
godot --headless --path . res://tools/make_theme.tscn   # UI-thema
```

---

## 6. Tests

```
godot --headless --path . --fixed-fps 60 res://tests/test_runner.tscn
```
79 testfuncties / 533 controles, allemaal groen (± 8 s). Zie [TESTS.md](TESTS.md)
voor wat er getest is, wat er handmatig is gecontroleerd en wat nog op een echt
toestel gecontroleerd moet worden.

---

## 7. Bekende beperkingen / open punten

* **Niet getest op een echt Android-toestel.** De APK is gebouwd, ondertekend en
  gecontroleerd (`apksigner verify`, manifest, inhoud), en de geëxporteerde
  inhoud is op desktop gestart en gerenderd — maar in de bouwomgeving was geen
  telefoon en geen ARM-emulator beschikbaar. Zie de checklist in TESTS.md.
* Android-systeemgebaren aan de schermranden kan een app niet volledig blokkeren.
  De game draait in *immersive mode* (eerste veeg toont alleen de balken) en de
  knoppen houden afstand van de randen; met "knoppen naar binnen" kun je extra marge geven.
* Portretmodus is speelbaar maar krap (±15 tegels breed); landschap is de bedoelde modus.
* De muziek is synthetische chiptune; balans en mix zijn objectief gecontroleerd
  (geen clipping, naadloze loops), maar niet op het gehoor beoordeeld.
* Op schermen met een niet-gehele schaalfactor (bijv. 2,5×) zijn pixels iets
  ongelijk; op gangbare 1080p-telefoons is de schaal precies 4×.
* De moeilijkheidsgraad is afgesteld met een bereikbaarheidsmodel en
  geautomatiseerde tests; echte speeltests kunnen nog fijnafstelling opleveren
  (bijv. timing van bazen, plaats van checkpoints).
