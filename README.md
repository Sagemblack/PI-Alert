# PI Alert

PI Alert plays a selected sound once whenever your character gains the priest **Power Infusion** buff.

## Features

- Detects Power Infusion on the player (spell ID `10060`)
- Plays once per application rather than on every aura update
- Five built-in World of Warcraft sounds
- Custom `.ogg` or `.mp3` file paths
- Selectable audio channel, with `Master` as the default
- Optional large on-screen `POWER INFUSION` alert
- Modern WoW Settings panel with enable, visual-alert, test and WeakAuras Moan preset controls
- Optional party/raid Power Infusion tracking, disabled by default
- Named group alerts with a customizable `POWER INFUSION: {name}` template
- Independent group text and group sound toggles with a separate group sound profile
- Safe visual customization settings for alert text, duration, scale, position, and color
- `/pialert reset` and expanded `/pialert status` diagnostics
- Lightweight and dependency-free

## Commands

| Command | Purpose |
| --- | --- |
| `/pialert` or `/pia` | Show help |
| `/pialert on` | Enable alerts |
| `/pialert off` | Disable alerts |
| `/pialert sound raidwarning` | Select Raid Warning |
| `/pialert sound readycheck` | Select Ready Check |
| `/pialert sound alarm` | Select Alarm |
| `/pialert sound tell` | Select Whisper notification |
| `/pialert sound auction` | Select Auction House sound |
| `/pialert channel Master` | Select an audio channel |
| `/pialert preset moan` | Select WeakAuras' `moan.ogg` preset |
| `/pialert visual on` / `off` | Toggle the on-screen alert |
| `/pialert group on` / `off` | Track party/raid member Power Infusion (off by default) |
| `/pialert grouptext on` / `off` | Toggle named group alert text |
| `/pialert groupsound on` / `off` | Toggle the separate group alert sound |
| `/pialert grouptest` | Preview the configured group alert |
| `/pialert reset` | Restore safe defaults |
| `/pialert status` | Show current settings and path |
| `/pialert options` | Open the graphical settings panel |
| `/pialert test` | Preview the selected sound |

Valid channels are `Master`, `SFX`, `Dialog`, `Ambience`, and `Music`.

## Custom sounds

WoW addons cannot open an operating-system file picker. Put your sound in another addon/media folder, restart WoW, and configure its path:

```text
/pialert custom Interface\AddOns\MyMedia\pi.ogg
/pialert sound custom
/pialert test
```

Keeping personal sounds in a separate addon prevents an updater from deleting them when PI Alert is upgraded.

WeakAuras' bundled sound can be selected directly:

```text
/pialert preset moan
/pialert test
```

If the sound file was added or updated while WoW was running, log out and back in (or reload after the file exists). WoW must discover addon sound files before playback.

## Installation

Extract the release so the game contains:

```text
World of Warcraft/_retail_/Interface/AddOns/PIAlert/PIAlert.toc
```

Restart WoW or reload the interface, then enable **PI Alert** in the AddOns menu.

## Testing status

The core and mocked WoW integration tests run under Lua 5.1. Group tracking uses `C_UnitAuras.GetAuraDataByIndex` when available and falls back to legacy `UnitAura`; an in-game Retail test is still required to confirm visibility and the exact current aura restrictions. The Settings panel exposes the safe boolean controls and preview actions; text/media editing remains available through slash commands where client UI compatibility varies.

## License

MIT
