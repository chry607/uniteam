# Difficulty Level: Pinoy

A Filipino satirical party-game shell (*Difficulty Level: Pinoy*) inspired by *WarioWare* and early Cartoon Network flash games — now wired to the Uniteam minigames + SFX bank.

## Requirements

- **Godot 4.7+** (tested with 4.7 stable)

## Run

1. Open the **`main menu/`** folder in Godot (this is the combined project)
2. Press **F5** (main scene: `scenes/main.tscn`)

The separate `games + sfx/uniteam` folder is the original minigame project; its content lives under `minigames/` and `audio/` here.

## State flow

```
Splash → Main Menu → Countdown → Minigame ⇄ Transition → Game Over → Results → Main Menu
```

### Real minigames (anti-repeat rotation)

| ID | Display name | Scene |
|----|--------------|--------|
| `cut_wires` | Cut the Jumper Wires! | `minigames/cut-the-jumper-wires/game_wire.tscn` |
| `crossy_edsa` | Crossy the EDSA! | `minigames/crossy-road/Main.tscn` |
| `lrt_balance` | LRT Balance! | `minigames/lrt-balance/game_LRTbalance.tscn` |

Each minigame emits `game_finished("win"|"lose")`. `MinigameHost` bridges that into `GameState.finish_minigame(success)`.

## Controls

| Input | Action |
|--------|--------|
| Any key / click | Leave splash |
| Mouse / keyboard / gamepad | Navigate menus / play minigames |
| **Esc** / Start | Pause during minigame |

## Project layout

```
game/           GameState, ScoreManager, UIManager, AudioEvents, MinigameRegistry, AudioBridge
components/     GameButton, Card, Modal, HUD, Timer, Lives, Score, Transition, Toast…
scenes/         Splash, MainMenu, Pause, GameOver, Results, Settings, MinigameHost…
minigames/      Real microgames (from Uniteam)
audio/          AudioController + SFX / music bank
scripts/minigames/  MinigameBase for future drops
assets/fonts/   Fredoka, Nunito, Baloo 2
styles/         Theme
```

## Architecture (shell ↔ games)

1. **MAGLARO!** → `GameState.start_run()` → pick next entry from `MinigameRegistry`
2. Countdown overlay shows name + intro
3. `MinigameHost` instantiates the PackedScene
4. Minigame uses `AudioController` for in-game SFX
5. On `game_finished`, shell scores / lives / transition / game over
6. `AudioBridge` maps shell events → round win/lose, game-done, music restart

### Adding another minigame

1. Drop a scene under `minigames/` that emits `signal game_finished(result: String)` with `"win"` or `"lose"`
2. Append an entry in `game/minigame_registry.gd` (`id`, `display_name`, `intro`, `scene`)
3. Call `AudioController` for any new SFX as needed

Optional: extend `MinigameBase` and adapt the host if you prefer `completed(success: bool)`.

## Audio

- **Autoload:** `AudioController` (`audio/audio_controller.tscn`) — music + SFX used by minigames
- **Autoload:** `AudioBridge` — connects `AudioEvents` / run lifecycle to that bank
- Shell hooks still live on `AudioEvents` for UI-only cues

## License note

Fan / parody prototype. Not affiliated with Metro Trains or the official *Dumb Ways to Die* franchise.
