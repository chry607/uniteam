# ESDA Crossy Road (Philippines-themed)

A Crossy Road-style endless hopper: cross sidewalks, roads full of jeepneys/tricycles/
multicabs/motorcycles, and the occasional PNR-style train crossing.

## Setup

1. Open Godot **4.3+**.
2. "Import" → select the `project.godot` file in this folder (or just copy the whole
   `esda_crossy_road` folder wherever you keep your projects, then open it from the
   Project Manager).
3. Press **F5** (or the Play button). It'll ask which scene is main the first time only
   if `run/main_scene` didn't stick — just pick `Main.tscn`.

That's it — no scenes need to be hand-built in the editor. `Main.gd` builds the
camera, UI, player, and lanes entirely in code at runtime.

## Controls

- Arrow keys or **WASD** to hop one tile at a time (up/down/left/right).
- You die if a vehicle or the train overlaps your tile.
- Score = furthest row reached. High score is saved locally (`user://highscore.save`).

## How it's structured

- `Main.tscn` / `scripts/Main.gd` — game manager. Spawns the player, generates lanes
  ahead of you as you progress, moves the camera (forward-only, like the original
  game), and owns the score/game-over UI.
- `scripts/Player.gd` (`PlayerPawn`, `Area2D`) — grid-based movement with a quick
  tween "hop." Emits `moved(row)` and `died`.
- `scripts/Lane.gd` (`RoadLane`, `Node2D`) — one horizontal strip. Three types:
  - `SAFE` — sidewalk/grass, no hazards.
  - `ROAD` — spawns vehicles at a random interval, in a random direction/speed.
  - `RAIL` — flashes a warning light, then a train sweeps the whole lane (instant kill
    if you're on it), then cools down.
- `scripts/Vehicle.gd` (`RoadVehicle`, `Area2D`) — jeepney, tricycle, multicab, or
  motorcycle. Drawn with `_draw()` using flat shapes/colors so there's no dependency
  on missing textures.

## Customizing / next steps

- **Swap in real art**: replace the `ColorRect`/`_draw()` calls in `Player.gd` and
  `Vehicle.gd` with a `Sprite2D` or `AnimatedSprite2D` and load your groupmates' art
  the same way you're doing textures in your wire-cutting game.
- **Tile size**: change `TILE_SIZE` (currently `100`) in `Player.gd`, `Lane.gd`, and
  `Main.gd` if you want a different scale (must match across all three).
- **Difficulty ramp**: in `Main.gd`'s `_generate_lane()`, make `speed`/`spawn_interval`
  scale with `row` so later lanes get harder.
- **Old lane cleanup**: lanes behind the player are never freed right now (fine for a
  short session, but for long play sessions you'll want to `queue_free()` lanes once
  `row < max_row - N`).
- **Isometric look**: if you want the classic Crossy Road iso-camera feel instead of
  top-down, that's a bigger change — happy to help with that separately if you want it.
