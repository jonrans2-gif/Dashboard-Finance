# Testoverzicht — Monster Ultra Bros.

Laatste run: Godot 4.7.2, headless, `--fixed-fps 60` (deterministisch).

```
godot --headless --path . --fixed-fps 60 res://tests/test_runner.tscn
TESTS: 79 test functions, 533 checks, 0 failed
```

De tests draaien de **echte** game-code: een echte `Level` met `Player`,
vijanden en physics, opgebouwd uit kleine testkaarten of uit de 12 echte
levelbestanden. Ze controleren gedrag (posities, snelheden, toestanden,
opgeslagen bestanden), niet of scripts bestaan.

## 1. Uitgevoerde geautomatiseerde tests (alle geslaagd)

| Suite | Wat wordt gecontroleerd |
|-------|-------------------------|
| `test_save` | atomisch schrijven, checksum, afgekapt/aangepast bestand afgewezen, terugvallen op `.bak`, beste score / shards / unlocks, continue-punt, herladen van schijf |
| `test_physics` | variabele spronghoogte (vast: ≥4 tegels, tik: klein hupje), loopsprong ≥5 tegels ver, versnelling → loop → rensnelheid, slippen bij omkeren, stoppen, coyote time, géén luchtsprong daarna, jump buffer, maximale valsnelheid, exact op de vloer landen |
| `test_collision` | muur stopt een geboost blikje, dash tunnelt niet door blokken, eenrichtingsplatform, plafond stopt sprong, Mega groeit pas met genoeg ruimte (en zit nooit vast), bewegend platform neemt je mee, ijs glijdt, lopende band duwt |
| `test_enemies` | patrouille + omkeren bij muren, Corrupted Can blijft op zijn platform, stampen verslaat + stuitert + punten, zijcontact kost energie + onkwetsbaarheid, opgeladen slijm niet te stampen, drone schiet, suikerklontje springt, vijanden buiten beeld blijven slapen, blok-bump verslaat vijand erop |
| `test_items` | muntjes + score, 100 muntjes = leven, energieblok → munt + "gebruikt", powerblok → power-up + oppakken, baksteen breekt alleen als Mega, verborgen blok verschijnt van onderen, magneet, shard/core per poging geregistreerd, nepmuur onthult geheim |
| `test_powerups` | Boost (sneller), Shield (vangt klap), Mega (krimpt i.p.v. energie), Double Jump, Energy Surge (dash breekt barrière), Overload (onkwetsbaar, verslaat vijanden), aflopen van tijdelijke power-ups, oppakken uit level |
| `test_damage` | onkwetsbaarheidsframes, 3 klappen = dood + doodsanimatie, stekels, lava/zuur, ravijn, tijd op |
| `test_checkpoints` | activeren (index, vlag, energie bijgevuld, continue opgeslagen), respawn op checkpoint, verzamelde shards blijven weg na dood, levens & game over |
| `test_pause` | pauze bevriest vijanden, platforms en timer en hervat daarna; pauzemenu werkt tijdens pauze en de terugknop hervat; ingedrukte touch-knoppen worden losgelaten bij pauzeren |
| `test_completion` | vlag → level klaar, tijd- en vlagbonus, score, opslag (voltooid, volgend level ontgrendeld, beste score, continue), hoger pakken = meer bonus, vlag in baslevel verborgen tot de baas verslagen is |
| `test_bosses` | arena sluit en camera vergrendelt; per baas: doorloopt ≥4 aanvalstoestanden, geen schade buiten het kwetsbare moment, precies `max_hp` treffers in het kwetsbare moment, `defeated`-signaal, vlag verschijnt |
| `test_touch` | indrukken/loslaten, twee duimen tegelijk, schuiven tussen knoppen, aanraken buiten knoppen doet niets, verborgen dash niet bruikbaar, grootte/gespiegelde layout/gevoeligheid, afstand tot schermrand, pauzeknop |
| `test_levels` | alle 12 levels: één start/vlag, 3 shards, ≥1 core, checkpoint, deurparen, lengte, baasinstellingen + arena ≥ schermbreedte, alle lay-outs uniek, **bereikbaarheid** (zie hieronder), laden en draaien in de echte game, ≥5 vijanden |

### Bereikbaarheid van de levels
`tests/reachability.gd` doet een zoektocht over alle plekken waar het blikje kan
staan, met een **voorzichtiger** model dan de echte physics: lopen, vallen,
springen (verplichte route max. 3 tegels omhoog, optionele items max. 4; de echte
sprong haalt 4,4 tegels), beperkte horizontale reikwijdte, vrije boog, veren,
deuren, bewegende/vallende platforms. Resultaat voor alle 12 levels: vlag
bereikbaar, alle 36 shards bereikbaar, alle 12 cores bereikbaar (cores achter een
energiebarrière alleen met Energy Surge, die dan in dat level beschikbaar is).

### Individuele testfuncties
- ✅ `test_save.test_corrupt_main_falls_back_to_backup`
- ✅ `test_save.test_game_state_continue_point`
- ✅ `test_save.test_progress_persists_to_disk`
- ✅ `test_save.test_progress_rules`
- ✅ `test_save.test_roundtrip`
- ✅ `test_save.test_truncated_and_tampered_files_rejected`
- ✅ `test_physics.test_acceleration_and_run_build_up`
- ✅ `test_physics.test_coyote_time`
- ✅ `test_physics.test_fall_speed_is_capped`
- ✅ `test_physics.test_jump_buffer`
- ✅ `test_physics.test_no_jump_long_after_ledge`
- ✅ `test_physics.test_running_jump_reach`
- ✅ `test_physics.test_variable_jump_height`
- ✅ `test_collision.test_ceiling_stops_jump`
- ✅ `test_collision.test_conveyor_pushes`
- ✅ `test_collision.test_dash_into_wall`
- ✅ `test_collision.test_ice_is_slippery`
- ✅ `test_collision.test_mega_waits_for_head_room`
- ✅ `test_collision.test_moving_platform_carries_player`
- ✅ `test_collision.test_one_way_platform`
- ✅ `test_collision.test_wall_stops_player_at_full_speed`
- ✅ `test_enemies.test_bumping_block_knocks_out_enemy_on_top`
- ✅ `test_enemies.test_charged_slime_cannot_be_stomped`
- ✅ `test_enemies.test_corrupted_can_does_not_walk_off_ledges`
- ✅ `test_enemies.test_drone_fires_projectiles`
- ✅ `test_enemies.test_empty_can_patrols_and_turns_at_walls`
- ✅ `test_enemies.test_enemies_wait_outside_the_view`
- ✅ `test_enemies.test_side_contact_hurts`
- ✅ `test_enemies.test_stomp_defeats_and_bounces`
- ✅ `test_enemies.test_sugar_cube_hops`
- ✅ `test_items.test_brick_only_breaks_when_mega`
- ✅ `test_items.test_energy_block_gives_token_and_turns_used`
- ✅ `test_items.test_hidden_block_appears_from_below`
- ✅ `test_items.test_hundred_tokens_give_a_life`
- ✅ `test_items.test_magnet_pulls_tokens`
- ✅ `test_items.test_power_block_spawns_powerup`
- ✅ `test_items.test_secret_wall_reveals`
- ✅ `test_items.test_shard_and_core_recorded_for_attempt`
- ✅ `test_items.test_token_pickup`
- ✅ `test_powerups.test_double_jump`
- ✅ `test_powerups.test_energy_surge_dash_breaks_barrier`
- ✅ `test_powerups.test_mega_can_absorbs_hit_by_shrinking`
- ✅ `test_powerups.test_overload_is_invincible_and_defeats_enemies`
- ✅ `test_powerups.test_powerup_pickup_from_level`
- ✅ `test_powerups.test_timed_powers_expire`
- ✅ `test_powerups.test_ultra_boost_raises_top_speed`
- ✅ `test_powerups.test_white_shield_absorbs_one_hit`
- ✅ `test_damage.test_goo_is_deadly`
- ✅ `test_damage.test_invulnerability_after_hit`
- ✅ `test_damage.test_pit_is_deadly`
- ✅ `test_damage.test_spikes_hurt`
- ✅ `test_damage.test_three_hits_kill`
- ✅ `test_damage.test_timer_runs_out`
- ✅ `test_checkpoints.test_checkpoint_activation`
- ✅ `test_checkpoints.test_collected_shards_stay_collected_after_death`
- ✅ `test_checkpoints.test_lives_and_game_over`
- ✅ `test_checkpoints.test_respawn_at_checkpoint`
- ✅ `test_pause.test_pause_freezes_everything`
- ✅ `test_pause.test_pause_menu_runs_while_paused`
- ✅ `test_pause.test_touch_released_on_pause`
- ✅ `test_completion.test_boss_level_goal_hidden_until_defeat`
- ✅ `test_completion.test_goal_completes_level`
- ✅ `test_completion.test_higher_grab_gives_bigger_bonus`
- ✅ `test_bosses.test_arena_locks_and_spawns_boss`
- ✅ `test_bosses.test_crusher_prime`
- ✅ `test_bosses.test_frost_volt`
- ✅ `test_bosses.test_overload_core`
- ✅ `test_bosses.test_sugar_king`
- ✅ `test_touch.test_hidden_dash_cannot_be_pressed`
- ✅ `test_touch.test_move_and_jump_together`
- ✅ `test_touch.test_pause_button`
- ✅ `test_touch.test_press_and_release`
- ✅ `test_touch.test_size_layout_and_sensitivity_settings`
- ✅ `test_touch.test_slide_between_buttons`
- ✅ `test_touch.test_touch_outside_buttons_ignored`
- ✅ `test_levels.test_level_structure`
- ✅ `test_levels.test_levels_are_completable`
- ✅ `test_levels.test_levels_are_distinct`
- ✅ `test_levels.test_levels_load_and_run`

## 2. Handmatig / visueel gecontroleerd (in de bouwomgeving)

* Alle 12 levels gerenderd (Xvfb + Mesa) en doorgelopen met schermafbeeldingen;
  daarbij gevonden en opgelost: zichtbare core door een gat in de nepmuur,
  nepmuren die afweken van de omringende blokken, te brede baasarena's (baas
  buiten beeld), egale achtergrondmuren, gras-randen onder blokken, projectiel
  door de vloer, UI-thema niet toegepast, instellingenpaneel verkeerd gepositioneerd.
* Alle 4 eindbazen in actie gerenderd (aanvallen, kwetsbare fases).
* Hoofdmenu, level select, settings, pauze, level clear, game over gerenderd.
* Resoluties: 1200×540, 960×540, 2400×1080 (20:9 telefoon) en 540×1200 (portret).
* Muziek: geen clipping, gelijkmatige luidheid, loop-punten in de WAV gedetecteerd
  door Godot (jingles loopen niet). Niet op het gehoor beoordeeld.
* APK: gebouwd en ondertekend (`apksigner verify` ok), manifest gecontroleerd
  (minSdk 24, targetSdk 36, arm64-v8a + armeabi-v7a, alleen VIBRATE-permissie),
  inhoud gecontroleerd (12 levels + sprite-metadata aanwezig, tests/tools niet).
* De **inhoud van de APK** (geëxporteerd project) is op desktop gestart: titel­scherm
  en levels 1-1, 2-2, 3-3, 4-3 laden zonder fouten en renderen correct.

## 3. Nog te controleren op een echt Android-toestel

Een Android-emulator kon hier niet draaien (geen hardwarevirtualisatie; de
emulator ondersteunt geen ARM-images op deze host). Controleer daarom zelf:

1. APK installeert (Instellingen → onbekende bronnen toestaan) en start met vliegtuigmodus aan.
2. Landschap is standaard; Settings → Scherm → Portret/Draaien werkt.
3. Touch: lopen + springen tegelijk, schuiven ◀→▶, knopgrootte/positie/gevoeligheid,
   geen per ongeluk Android-terug-gebaar tijdens spelen.
4. Trillen bij klap/power-up, en uit te zetten in Settings.
5. Telefoon vergrendelen / app wisselen / gebeld worden tijdens een level →
   game staat gepauzeerd bij terugkomst, geen vastgelopen knoppen.
6. Android-terugknop: in level = pauze/hervatten; in hoofdmenu = "Quit?".
7. Vloeiend 60 FPS op een middenklasse-toestel; batterijverbruik normaal
   (FPS is begrensd op 60).
8. Voortgang blijft bewaard na afsluiten (Continue, Level Select).
9. Alle levels uitspelen en de vier bazen verslaan; eindanimatie + credits.
