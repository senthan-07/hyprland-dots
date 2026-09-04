# Hyprland Dotfiles

Modular Hyprland rice with waybar, mako, hyprlock, kitty, and dual-monitor brightness control (laptop + external via DDC/CI).

Tested on Ubuntu 26.04. Designed to be portable across **Ubuntu, Fedora, Arch, NixOS**.

## Features

- **Modular Hyprland config** — split into `modules/` for easy editing
- **Dual-monitor brightness** — laptop via `brightnessctl`, external via `ddcutil`, both on hardware keys
- **Auto-detected monitor layout** (eDP-1 + HDMI-A-1)
- **Hyprpaper** with cover-fit wallpaper
- **Waybar** with default layout, themable via CSS
- **Mako** notifications with matugen-derived theme
- **Hyprlock** with screenshot-blur background

## Keybinds

| Combo | Action |
|---|---|
| `Super + Return` | Terminal (kitty) |
| `Super + D` | App launcher (rofi) |
| `Super + E` | File manager (nautilus) |
| `Super + Q` | Kill active window |
| `Super + 1-0` | Switch workspace |
| `Super + Shift + 1-0` | Move window to workspace |
| `Super + L` | Lock screen (hyprlock) |
| `Super + S` | Toggle scratchpad |
| `Super + V` | Toggle floating |
| `Super + P` | Pseudo-tile |
| `Super + arrows` | Move focus |
| `Print` | Screenshot region |
| `Shift + Print` | Screenshot region (5s delay) |
| `XF86Favorites` | Full screenshot |
| `XF86Audio*` | Volume / mute / mic |
| `XF86MonBrightness*` | Laptop brightness (5%) |
| `Super + XF86MonBrightness*` | External monitor brightness (5%) |

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
./install.sh packages   # installs hyprland, waybar, mako, etc. via your distro's package manager
```

### NixOS

Add packages to your `configuration.nix`:

```nix
environment.systemPackages = with pkgs; [
  hyprland hyprpaper hyprlock hyprpolkitagent
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
  waybar mako kitty
  grim slurp wl-clipboard
  brightnessctl ddcutil
  rofi playerctl wireplumber
];

users.users.youruser.extraGroups = [ "video" "i2c" ];
```

Then run `./install.sh link` to copy dotfiles.

## Post-install

1. **Drop a wallpaper** at `~/Pictures/wallpapers/default.jpg` (or edit `hyprpaper.conf`)
2. **Log out & back in** so the `video` group change takes effect (needed for `brightnessctl`)
3. **Reload Hyprland**: `hyprctl reload`

## File layout

```
hyprland-dots/
├── install.sh                          # distro-agnostic installer
├── home/
│   ├── .config/
│   │   ├── hypr/
│   │   │   ├── hyprland.conf           # main entry, sources modules/*
│   │   │   ├── hyprlock.conf
│   │   │   ├── hyprpaper.conf
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
│   │   ├── waybar/
│   │   └── mako/
│   └── .local/
│       └── bin/
│           └── brightness              # the dual-monitor brightness script
└── wallpapers/
    └── README.md
```

## Tweaking per-machine

- **Monitor layout** → `home/.config/hypr/modules/monitors.conf`
- **External monitor's I2C bus** → `home/.local/bin/brightness` (change `EXT_BUS=5`)
- **Wallpaper path** → `home/.config/hypr/hyprpaper.conf`
- **Default apps** (terminal, browser, etc.) → `home/.config/hypr/modules/variables.conf`

## Troubleshooting

**Brightness keys do nothing:**
- Make sure `~/.local/bin` is in your shell PATH (or use the `/usr/local/bin` symlink the installer creates).
- Log out and back in for `video` group to take effect.
- Test the script directly: `brightness ext up` — should print `ext: 50% → 55%`.

**External monitor brightness stuck:**
- Run `ddcutil -b <BUS> setvcp 10 + 5` directly to verify the bus.
- Your bus might differ from 5 — find it with `ddcutil detect`.

**Hyprpaper crashes on startup:**
- Make sure `/usr/lib/systemd/user/hyprpaper.service` is masked: `sudo systemctl mask --user hyprpaper.service` (so it doesn't conflict with `exec-once = hyprpaper`).
- Verify the wallpaper path exists.
