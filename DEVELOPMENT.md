# PI Alert development notes

## Current scope

PI Alert detects Power Infusion on the player and plays one selected alert sound per application.

## Compatibility

The initial TOC targets Retail interface `120007` (Retail patch 12.0.7). The aura API must still be tested in the live client because Blizzard can restrict aura data during combat.

## Release packaging

Run:

```bash
lua tests/run.lua
lua tests/addon_integration.lua
bash scripts/package.sh
```

The resulting ZIP is in `dist/` and contains only the `PIAlert/` addon folder.
