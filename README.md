# MoveWindow.spoon

A [Hammerspoon](https://www.hammerspoon.org/) Spoon for moving, resizing, and maximizing the focused window with keyboard shortcuts.

## Features

- Move window pixel-by-pixel in any direction (with key-repeat)
- Grow or shrink window symmetrically from center, respecting screen margins
- Resize is edge-aware: expands away from a fixed edge instead of going off-screen
- Toggle maximize: fills the screen (minus margin); pressing again restores the previous size and position
- All operations clamp to the screen boundary with a configurable margin

## Hotkeys

| Shortcut | Action |
|----------|--------|
| `Ctrl+Alt+H` | Move window left |
| `Ctrl+Alt+L` | Move window right |
| `Ctrl+Alt+K` | Move window up |
| `Ctrl+Alt+J` | Move window down |
| `Alt+Shift+=` | Grow window |
| `Alt+Shift+-` | Shrink window |
| `Alt+F` | Toggle maximize |

All move/resize hotkeys support key-repeat for continuous movement.

## Requirements

- [Hammerspoon](https://www.hammerspoon.org/) ≥ 1.0
- Accessibility permissions granted to Hammerspoon

## Installation

Copy `MoveWindow.spoon` into `~/.hammerspoon/Spoons/`, then add to your `init.lua`:

```lua
hs.loadSpoon("MoveWindow")
spoon.MoveWindow:start()
```

## Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `moveStep` | `10` | Pixels to move per keypress |
| `resizeStep` | `20` | Pixels to grow/shrink per keypress |
| `margin` | `8` | Screen edge margin (should match Marginator if used together) |

```lua
spoon.MoveWindow.moveStep = 20
spoon.MoveWindow.margin   = 12
spoon.MoveWindow:start()
```

## API

| Method | Description |
|--------|-------------|
| `:start()` | Bind all hotkeys |

## License

MIT
