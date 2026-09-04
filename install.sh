#!/usr/bin/env bash
# Install Hyprland dotfiles — distro-agnostic
# Tested on: Ubuntu 26.04, Fedora 41+, Arch Linux, openSUSE Tumbleweed
#
# Usage:
#   ./install.sh            # install dotfiles only (no packages)
#   ./install.sh packages   # install system packages too (needs sudo)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="${HOME}"

# ---------- helpers ----------
log()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m  %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

# ---------- detect distro ----------
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

# ---------- package install ----------
install_packages() {
    local distro
    distro=$(detect_distro)
    log "Detected distro: $distro"

    # Common package list across distros. Tool names vary slightly.
    local pkgs=()
    case "$distro" in
        ubuntu|debian|pop)
            pkgs=(
                hyprland hyprpaper hyprlock hyprpolkitagent
                xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
                waybar mako-notifier kitty
                grim slurp wl-clipboard
                brightnessctl ddcutil
                rofi playerctl wireplumber
                nautilus
            )
            command -v sudo >/dev/null && SUDO=sudo || SUDO=
            $SUDO apt update
            $SUDO apt install -y "${pkgs[@]}"
            ;;

        fedora)
            pkgs=(
                hyprland hyprpaper hyprlock hyprpolkitagent
                xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
                waybar mako kitty
                grim slurp wl-clipboard
                brightnessctl ddcutil
                rofi playerctl wireplumber
                nautilus
            )
            command -v sudo >/dev/null && SUDO=sudo || SUDO=
            $SUDO dnf install -y "${pkgs[@]}"
            ;;

        arch|manjaro|endeavouros)
            pkgs=(
                hyprland hyprpaper hyprlock hyprpolkitagent
                xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
                waybar mako kitty
                grim slurp wl-clipboard
                brightnessctl ddcutil
                rofi playerctl wireplumber
                nautilus
            )
            command -v sudo >/dev/null && SUDO=sudo || SUDO=
            $SUDO pacman -S --needed --noconfirm "${pkgs[@]}"
            ;;

        opensuse*)
            pkgs=(
                hyprland hyprpaper hyprlock hyprpolkitagent
                xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
                waybar mako kitty
                grim slurp wl-clipboard
                brightnessctl ddcutil
                rofi playerctl wireplumber
                nautilus
            )
            command -v sudo >/dev/null && SUDO=sudo || SUDO=
            $SUDO zypper install -y "${pkgs[@]}"
            ;;

        nixos)
            warn "NixOS detected — add hyprland, hyprpaper, etc. to configuration.nix instead."
            warn "Then run: ./install.sh link   to copy dotfiles only."
            ;;

        *)
            warn "Unknown distro '$distro'."
            warn "Install equivalents of: hyprland, hyprpaper, hyprlock, waybar, mako,"
            warn "kitty, grim, slurp, wl-clipboard, brightnessctl, ddcutil, rofi."
            ;;
    esac

    # Add user to groups needed for backlight + i2c access.
    local user_groups=(video i2c)
    for g in "${user_groups[@]}"; do
        if getent group "$g" >/dev/null; then
            if ! id -nG "$USER" | grep -qw "$g"; then
                log "Adding $USER to group '$g'"
                command -v sudo >/dev/null && SUDO=sudo || SUDO=
                $SUDO usermod -aG "$g" "$USER" \
                    || warn "Could not add to group '$g' — run manually: sudo usermod -aG $g $USER"
            fi
        fi
    done
}

# ---------- symlink helper ----------
link_file() {
    local src="$1" dst="$2"
    if [[ -e "$dst" ]] && [[ ! -L "$dst" ]]; then
        local backup="${dst}.bak.$(date +%s)"
        warn "Existing $dst → backing up to $backup"
        mv "$dst" "$backup"
    fi
    mkdir -p "$(dirname "$dst")"
    ln -sfn "$src" "$dst"
    log "Linked $dst → $src"
}

# ---------- symlink dotfiles ----------
link_dotfiles() {
    log "Linking dotfiles into $HOME_DIR"

    # Hyprland — symlink top-level FILES only (skip the modules/ directory).
    for f in "$REPO_ROOT"/home/.config/hypr/*; do
        [[ -f "$f" ]] || continue   # ← skip directories
        link_file "$f" "$HOME_DIR/.config/hypr/$(basename "$f")"
    done
    # Symlink individual files inside modules/
    mkdir -p "$HOME_DIR/.config/hypr/modules"
    for f in "$REPO_ROOT"/home/.config/hypr/modules/*; do
        [[ -f "$f" ]] || continue   # ← only real files
        link_file "$f" "$HOME_DIR/.config/hypr/modules/$(basename "$f")"
    done

    # Other apps — symlink files inside each app's config dir.
    for app in kitty waybar mako; do
        mkdir -p "$HOME_DIR/.config/$app"
        for f in "$REPO_ROOT"/home/.config/$app/*; do
            [[ -f "$f" ]] || continue   # ← only real files
            link_file "$f" "$HOME_DIR/.config/$app/$(basename "$f")"
        done
    done

    # Brightness script — symlink to ~/.local/bin AND /usr/local/bin
    # (Hyprland's exec PATH doesn't include ~/.local/bin, so we need
    #  either /usr/local/bin symlink or absolute path in keybinds.)
    mkdir -p "$HOME_DIR/.local/bin"
    link_file "$REPO_ROOT/home/.local/bin/brightness" "$HOME_DIR/.local/bin/brightness"
    chmod +x "$HOME_DIR/.local/bin/brightness"

    if [[ -w /usr/local/bin ]]; then
        ln -sfn "$HOME_DIR/.local/bin/brightness" /usr/local/bin/brightness
        log "Linked /usr/local/bin/brightness (system PATH)"
    elif command -v sudo >/dev/null; then
        sudo ln -sfn "$HOME_DIR/.local/bin/brightness" /usr/local/bin/brightness \
            && log "Linked /usr/local/bin/brightness (system PATH)" \
            || warn "Could not symlink to /usr/local/bin — brightness keys will use ~/.local/bin"
    fi

    # Wallpaper — placeholder note
    log "Remember to drop your wallpaper into $HOME_DIR/Pictures/wallpapers/default.jpg"
}

# ---------- main ----------
case "${1:-link}" in
    packages) install_packages ;;
    link|"")  link_dotfiles ;;
    all)
        install_packages
        link_dotfiles
        ;;
    *)
        echo "usage: $0 [packages|link|all]" >&2
        exit 1
        ;;
esac

log "Done."
log "Reload Hyprland with: hyprctl reload"
log "If brightness keys don't work, log out & back in for the 'video' group change to take effect."
