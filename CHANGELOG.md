# Changelog

## 0.2.5

- Add safe configurable visual alert text, duration, scale, position, and color settings.
- Add optional party/raid Power Infusion tracking using current `C_UnitAuras` APIs with fallbacks; disabled by default.
- Add `/pialert group on|off` and `/pialert reset` commands.
- Expand status diagnostics and Settings panel controls; update version metadata and documentation.

## 0.2.4

- Use the live Settings category ID instead of overwriting it with a string, allowing `/pialert options` to actually open the panel.

## 0.2.3

- Defer `/pialert options` until the chat command finishes processing, preventing the chat edit box from swallowing the command.
- Add an explicit "Opening PI Alert settings..." confirmation.

## 0.2.2

- Make `/pialert options` fall back to opening the registered Settings category object when the category ID is not accepted.

## 0.2.1

- Fix `/pialert options` to open the registered Settings category directly when needed.

## 0.2.0

- Add an optional on-screen `POWER INFUSION` raid-warning alert.
- Add the WeakAuras `moan.ogg` preset.
- Add `/pialert status`, `/pialert visual`, `/pialert preset`, and `/pialert options`.
- Add a modern WoW Settings panel with enable, visual-alert, test-sound, and Moan preset controls.
- Report a helpful diagnostic when WoW refuses to play a custom file.

## 0.1.0-beta.1

- Detect Power Infusion gains on the player.
- Play one alert per buff application.
- Add five built-in sound choices and custom sound paths.
- Add selectable sound channels and slash-command configuration.
