# Hyprland Dotfiles

Modular Hyprland rice with 6-component theme-aware styling across kitty, hyprland, waybar, rofi, swaync, and wlogout. Wallpaper-driven auto-theming, dual-monitor brightness (laptop via brightnessctl, external via ddcutil), screenshot/media helpers, clipboard history (cliphist), idle management (hypridle), and cinematic hyprlock.

Tested on Ubuntu 26.04. Designed to be portable across **Ubuntu, Fedora, Arch, NixOS**.

## Features

- **Modular Hyprland config** — split into `modules/` for easy editing
- **6-component theme-aware styling** — kitty, hyprland, waybar, rofi, swaync, wlogout
- **Six hand-curated themes**: `catppuccin-mocha`, `gruvbox-dark`, `gruvbox-light`, `nord`, `dracula`, `tokyo-night`
- **Atomic theme switching** via `theme-set <name>` with 5-way validation before any change
- **Wallpaper-driven auto-theming** — pick wallpaper, theme follows (optional, toggleable)
- **Auto/manual mode** — wallpaper changes auto-match theme (or stay put)
- **Dual-monitor brightness** — laptop via `brightnessctl`, external via `ddcutil`, both on hardware keys
- **Auto-detected monitor layout** (eDP-1 + HDMI-A-1)
- **swww wallpaper daemon** with restore-at-boot
- **Waybar** with default layout, theme-aware
- **SwayNC** notifications (theme-aware), DND + panel toggle
- **Hypridle** — 5 min idle → lock screen, 15 min idle → suspend
- **Cliphist** — clipboard history with rofi picker (Super+Alt+V)
- **Wlogout** — theme-aware logout menu with 6 buttons (Shutdown, Reboot, Logout, Lock, Hibernate, Sleep)
- **Hyprlock** — cinematic minimalist design with current wallpaper background + subtle blur
- **UX scripts**: `screenshot.sh` (6 variants), `media_control.sh` (playerctl), `theme-doctor` (sanity check)
- **Rofi picker theme inheritance** via `style-dmenu.rasi`

## Quick start

```bash
git clone https://github.com/senthan-07/hyprland-dots.git ~/hyprland-dots
cd ~/hyprland-dots
./install.sh           # link dotfiles only
./install.sh packages   # also install system packages (needs sudo)
```

For NixOS, see `README.md` package list and add to your `configuration.nix` manually.

## Keybinds

### Window management

| Combo | Action |
|---|---|
| `Super + Return` | Terminal (kitty) |
| `Super + D` | App launcher (rofi — uses `style-1.rasi`) |
| `Super + E` | File manager (nautilus) |
| `Super + Q` | Kill active window |
| `Super + 1-0` | Switch workspace |
| `Super + Shift + 1-0` | Move window to workspace |
| `Super + L` | Lock screen (hyprlock) |
| `Super + M` | Logout menu (wlogout — 6 buttons, theme-aware) |
| `Super + V` | Toggle floating |
| `Super + P` | Pseudo-tile |
| `Super + arrows` | Move focus |
| `Super + Shift + S` | Toggle scratchpad |
| `Super + Shift + N` | SwayNC notification panel |
| `Super + N` | SwayNC toggle Do Not Disturb |
| `Super + Alt + V` | Cliphist clipboard manager (rofi picker) |
| `Super + Shift + T` | Theme picker (rofi — uses `style-dmenu.rasi`) |
| `Super + W` | Wallpaper picker (rofi — uses `style-dmenu.rasi`) |

### Screenshots

| Combo | Action |
|---|---|
| `Print` | Area screenshot (slurp region) |
| `Shift + Print` | Full screen screenshot |
| `Super + Ctrl + Print` | 5-second delayed full screen |
| `XF86Favorites` | Full screen screenshot (legacy key) |

All screenshots save to `~/Pictures/Screenshots/` and copy to clipboard. `screenshot.sh` is the source script.

### Media keys

| Combo | Action |
|---|---|
| `XF86AudioRaiseVolume` | Volume up (wpctl) |
| `XF86AudioLowerVolume` | Volume down (wpctl) |
| `XF86AudioMute` | Toggle mute (wpctl) |
| `XF86AudioMicMute` | Toggle mic mute (wpctl) |
| `XF86AudioNext/Prev/Pause/Play` | playerctl (Spotify, Firefox, mpv, etc.) |

### Brightness

| Combo | Action |
|---|---|
| `XF86MonBrightnessUp/Down` | Laptop screen ±5% |
| `Super + XF86MonBrightnessUp/Down` | External monitor ±5% |

## Architecture

The rice uses a **base + theme split** across 6 themed components. `theme-set <name>` atomically validates all 6 theme files, then updates symlinks for each. Theme files contain only colors; layout lives in base files. See [`CONVENTIONS.md`](./CONVENTIONS.md) for details.

```
kitty.conf = base + theme.conf       (concatenated, atomic temp+rename)
hyprland   → themes/current.conf      (symlink → themes/<name>.conf)
waybar     → themes/current.css       (style.css @imports themes/current.css)
rofi       → themes/current.rasi      (style-dmenu.rasi @imports themes/current.rasi via shared/colors.rasi)
swaync     → themes/current.css       (style.css @imports themes/current.css)
wlogout    → themes/current.css       (style.css @imports themes/current.css)
```

When you run `theme-set nord`, every themed component switches. Rofi pickers (theme-rofi, clipboard-manager, wallpaper-picker) and wlogout all follow automatically.

## Brightness control — the smart part

The `brightness` script handles two backends:

```bash
brightness laptop up     # +5% on internal (brightnessctl, ~50ms)
brightness laptop down   # -5% on internal
brightness ext up        # +5% on external (ddcutil -b 5, ~300ms)
brightness ext down      # -5% on external
```

**Why this works correctly with `ddcutil`:**

`ddcutil getvcp` returns a **cached value**, not the live monitor value. A naive read-modify-write script reads the same stale number on every keypress, so nothing actually changes. We work around this by using `ddcutil setvcp 10 + <delta>` — a relative write that the monitor handles itself, bypassing the read entirely.

**Finding your external monitor's I2C bus:**
```bash
ddcutil detect | grep -A2 "Display 1"
```
Then edit `home/.local/bin/brightness` and change `EXT_BUS=5` to your bus number.

## Install

### Quick (Ubuntu/Fedora/Arch — assumes packages already installed)

```bash
git clone https://github.com/senthan-07/hyprland-dots.git ~/hyprland-dots
cd ~/hyprland-dots
./install.sh           # link dotfiles only
```

### Full (install packages + dotfiles)

```bash
./install.sh all
```

### Just packages

```bash
./install.sh packages   # installs hyprland, waybar, swaync, hypridle, cliphist, etc.
```

### NixOS

Add packages to your `configuration.nix`:

```nix
environment.systemPackages = with pkgs; [
  hyprland swww hyprlock hyprpolkitagent hypridle
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
  waybar swaync kitty
  grim slurp swappy wl-clipboard playerctl wireplumber
  brightnessctl ddcutil
  rofi cliphist
];

users.users.youruser.extraGroups = [ "video" "i2c" ];
```

Then run `./install.sh link` to copy dotfiles.

## Post-install

1. **Drop a wallpaper** at `~/Pictures/wallpapers/default.jpg` (or any filename)
2. **Log out & back in** so the `video` group change takes effect (needed for `brightnessctl`)
3. **Reload Hyprland**: `hyprctl reload`

## File layout

```
hyprland-dots/
├── install.sh                          # distro-agnostic installer
├── CONVENTIONS.md                      # architecture, file-safety, theme system docs
├── README.md                           # this file
├── home/
│   ├── .config/
│   │   ├── hypr/
│   │   │   ├── hyprland.conf           # main entry, sources modules/*
│   │   │   ├── hypridle.conf           # idle → hyprlock → suspend
│   │   │   ├── hyprlock.conf           # cinematic lock screen (current wallpaper + subtle blur)
│   │   │   └── modules/
│   │   │       ├── monitors.conf       # ⭐ edit this for your screens
│   │   │       ├── keybinds.conf       # ⭐ edit this for your keys
│   │   │       ├── variables.conf      # $terminal, $fileManager, $menu
│   │   │       ├── animations.conf
│   │   │       ├── decorations.conf
│   │   │       ├── environment.conf
│   │   │       ├── input.conf
│   │   │       ├── layout.conf
│   │   │       ├── misc.conf
│   │   │       ├── permissions.conf
│   │   │       ├── windowrules.conf
│   │   │       └── autostart.conf
│   │   ├── kitty/
│   │   │   ├── kitty.conf.base         # settings (settings only, no colors)
│   │   │   ├── kitty.conf              # GENERATED (do not edit)
│   │   │   └── themes/<6 themes>.conf  # hand-mapped color palettes
│   │   ├── hypr/themes/
│   │   │   ├── common.conf             # universal hyprland settings
│   │   │   ├── current.conf → symlink  # GENERATED symlink (do not edit)
│   │   │   └── themes/<6 themes>.conf  # theme-specific border colors
│   │   ├── waybar/
│   │   │   ├── style.css               # layout (@imports themes/current.css)
│   │   │   ├── themes/current.css → symlink  # GENERATED
│   │   │   └── themes/<6 themes>.css   # theme colors
│   │   ├── rofi/
│   │   │   ├── launcher.sh             # app launcher (Super+D)
│   │   │   ├── style-1.rasi            # launcher layout (uses shared/colors.rasi)
│   │   │   ├── style-dmenu.rasi        # picker layout for 3 short-list rofi pickers
│   │   │   ├── shared/colors.rasi      # @imports themes/current.rasi
│   │   │   └── themes/current.rasi → symlink
│   │   ├── swaync/
│   │   │   ├── config.json
│   │   │   ├── style.css               # wrapper (@imports themes/current.css)
│   │   │   └── themes/current.css → symlink
│   │   ├── wlogout/
│   │   │   ├── layout                 # 6 buttons (Shutdown/Reboot/Logout/Lock/Hibernate/Sleep)
│   │   │   ├── style.css               # wrapper (@imports themes/current.css)
│   │   │   ├── icons/                  # 12 PNGs (normal + hover for each button)
│   │   │   └── themes/current.css → symlink
│   │   └── fish/
│   └── .local/
│       └── bin/
│           ├── theme-set               # atomic 6-component theme switcher
│           ├── theme-rofi              # theme picker rofi launcher
│           ├── theme-match             # wallpaper → theme matcher (Python PIL)
│           ├── theme-mode-set          # toggle auto/manual
│           ├── wallpaper-picker        # wallpaper rofi picker
│           ├── wallpaper-set           # apply wallpaper + optional auto-theme
│           ├── wallpaper-restore       # boot wallpaper restore (5s daemon-ready poll)
│           ├── clipboard-manager       # cliphist rofi picker
│           ├── screenshot.sh           # grim + slurp + swappy (6 variants)
│           ├── media_control.sh        # playerctl wrapper
│           ├── theme-doctor             # theme system sanity checker (read-only)
│           └── brightness              # dual-monitor brightness control
└── wallpapers/
    └── README.md
```

## Tweaking per-machine

- **Monitor layout** → `home/.config/hypr/modules/monitors.conf`
- **External monitor's I2C bus** → `home/.local/bin/brightness` (change `EXT_BUS=5`)
- **Theme** → run `theme-set <name>` or press `Super+Shift+T` for the rofi picker
- **Wallpaper** → drop into `~/Pictures/wallpapers/`, then `Super+W`
- **Wallpaper auto-theming toggle** → `theme-mode-set auto|manual`
- **Default apps** (terminal, browser, etc.) → `home/.config/hypr/modules/variables.conf`

## Sanity checking

Run `theme-doctor` (no args) to verify the theme system:

```bash
theme-doctor
```

Reports:
- Current theme name
- All 5+1 themed component files exist
- Symlink integrity (no drift)
- Daemon status (swaync, hypridle, swww, wl-paste)
- Wallpaper cache
- Exits 0 if all OK, non-zero on any failure

## Troubleshooting

**Brightness keys do nothing:**
- Make sure `~/.local/bin` is in your shell PATH (or use the `/usr/local/bin` symlink the installer creates).
- Log out and back in for `video` group to take effect.
- Test the script directly: `brightness ext up` — should print `ext: 50% → 55%`.

**External monitor brightness stuck:**
- Run `ddcutil -b <BUS> setvcp 10 + 5` directly to verify the bus.
- Your bus might differ from 5 — find it with `ddcutil detect`.

**Theme didn't fully apply after `theme-set`:**
- Run `theme-doctor` to see which component is missing.
- The 5+1 themed components use the OPTIONAL pattern — if a theme file is missing for one component, the others still apply.

**Notifications not showing:**
- SwayNC runs via `exec-once = swaync` in autostart.
- Check: `pgrep -x swaync`
- Reload: `pkill -USR1 -x swaync` (only reloads CSS; no full restart needed for theme changes).

**Wlogout button doesn't match theme:**
- Run `theme-doctor` to verify wlogout theme symlink.
- The wlogout layout is at `~/.config/wlogout/layout` (6 buttons).
- Icons are at `~/.config/wlogout/icons/` — do not edit unless adding a button.
