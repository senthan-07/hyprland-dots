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

    # Package list per distro. Tool names vary slightly across distros.
    # Common set: hyprland + ecosystem (swww, hypridle, swaync, waybar, rofi, kitty),
    # capture utilities (grim, slurp, swappy, wl-clipboard), media (playerctl, wireplumber),
    # notification (swaync), clipboard (cliphist), brightness (brightnessctl, ddcutil),
    # nautilus (file manager).
    local pkgs=()
    case "$distro" in
        ubuntu|debian|pop)
            pkgs=(
                hyprland hyprlock hyprpolkitagent hypridle
                xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
                swaync waybar kitty
                grim slurp swappy wl-clipboard
                playerctl wireplumber
                brightnessctl ddcutil
                rofi cliphist
                sway-backgrounds nautilus
                # swww installed via cargo (not in apt for Ubuntu 26); install with:
                #   cargo install swww --locked
                # or use the github release binary:
                #   https://github.com/Horus645/swww/releases
            )
            command -v sudo >/dev/null && SUDO=sudo || SUDO=
            $SUDO apt update
            $SUDO apt install -y "${pkgs[@]}"
            ;;

        fedora)
            pkgs=(
                hyprland hyprlock hyprpolkitagent hypridle
                xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
                swaync waybar kitty
                grim slurp swappy wl-clipboard
                playerctl wireplumber
                brightnessctl ddcutil
                rofi cliphist
                sway-backgrounds nautilus
                # swww may need cargo install on Fedora:
                #   cargo install swww --locked
            )
            command -v sudo >/dev/null && SUDO=sudo || SUDO=
            $SUDO dnf install -y "${pkgs[@]}"
            ;;

        arch|manjaro|endeavouros)
            pkgs=(
                hyprland hyprlock hyprpolkitagent hypridle
                xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
                swaync waybar kitty
                grim slurp swappy wl-clipboard
                playerctl wireplumber
                brightnessctl ddcutil
                rofi cliphist
                sway-backgrounds nautilus
                # swww: yay -S swww
                # or: cargo install swww --locked
            )
            command -v sudo >/dev/null && SUDO=sudo || SUDO=
            $SUDO pacman -S --needed --noconfirm "${pkgs[@]}"
            ;;

        opensuse*)
            pkgs=(
                hyprland hyprlock hyprpolkitagent hypridle
                xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
                swaync waybar kitty
                grim slurp swappy wl-clipboard
                playerctl wireplumber
                brightnessctl ddcutil
                rofi cliphist
                nautilus
                # swww: cargo install swww --locked
            )
            command -v sudo >/dev/null && SUDO=sudo || SUDO=
            $SUDO zypper install -y "${pkgs[@]}"
            ;;

        nixos)
            warn "NixOS detected — add packages to configuration.nix instead."
            warn "Then run: ./install.sh link   to copy dotfiles only."
            ;;

        *)
            warn "Unknown distro '$distro'."
            warn "Install equivalents of: hyprland, hyprlock, hypridle, swaync, waybar,"
            warn "kitty, grim, slurp, swappy, wl-clipboard, playerctl, cliphist,"
            warn "brightnessctl, ddcutil, rofi."
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

    # swww — wallpaper daemon. NOT in apt on Ubuntu 26; build from source.
    # Provides: swww, swww-daemon
    if ! command -v swww >/dev/null 2>&1; then
        log "Building swww from source (not in apt for Ubuntu)..."
        local builddeps=(
            git cargo
            libx11-dev libwayland-dev libxkbcommon-dev
            libseat-dev scdoc
        )
        case "$distro" in
            ubuntu|debian|pop)
                command -v sudo >/dev/null && SUDO=sudo || SUDO=
                $SUDO apt install -y "${builddeps[@]}" || warn "Failed to install builddeps"
                ;;
            fedora)
                command -v sudo >/dev/null && SUDO=sudo || SUDO=
                $SUDO dnf install -y git cargo rust \
                    libX11-devel wayland-devel libxkbcommon-devel \
                    libseat-devel scdoc \
                    || warn "Failed to install builddeps"
                ;;
            arch|manjaro|endeavouros)
                command -v sudo >/dev/null && SUDO=sudo || SUDO=
                $SUDO pacman -S --needed --noconfirm git cargo base-devel \
                    libx11 wayland libxkbcommon libseat scdoc \
                    || warn "Failed to install builddeps"
                ;;
        esac

        if command -v cargo >/dev/null 2>&1; then
            log "Installing swww via cargo..."
            $SUDO cargo install swww --locked || warn "swww cargo install failed — install manually: https://github.com/Horus645/swww"
        fi
    fi

    # hyprland-guiutils — not in apt on Ubuntu, build from source.
    # Provides: hyprland-welcome, hyprland-dialog, hyprland-run, hyprland-update-screen
    if ! command -v hyprland-welcome >/dev/null 2>&1; then
        log "Building hyprland-guiutils from source (not in apt)..."
        local builddeps=(
            git cmake build-essential pkg-config
            libhyprlang-dev libhyprutils-dev libhyprtoolkit-dev
            libpixman-1-dev libxkbcommon-dev libdrm-dev libcairo2-dev
        )
        case "$distro" in
            ubuntu|debian|pop)
                command -v sudo >/dev/null && SUDO=sudo || SUDO=
                $SUDO apt install -y "${builddeps[@]}" || warn "Failed to install builddeps"
                ;;
            fedora)
                command -v sudo >/dev/null && SUDO=sudo || SUDO=
                $SUDO dnf install -y git cmake gcc-c++ pkgconfig \
                    hyprlang-devel hyprutils-devel hyprtoolkit-devel \
                    pixman-devel libxkbcommon-devel libdrm-devel cairo-devel \
                    || warn "Failed to install builddeps"
                ;;
            arch|manjaro|endeavouros)
                command -v sudo >/dev/null && SUDO=sudo || SUDO=
                $SUDO pacman -S --needed --noconfirm git cmake base-devel pkgconf \
                    hyprlang hyprutils hyprtoolkit \
                    pixman libxkbcommon libdrm cairo \
                    || warn "Failed to install builddeps"
                ;;
        esac

        local builddir
        builddir="$(mktemp -d)"
        git clone --depth 1 https://github.com/hyprwm/hyprland-guiutils.git "$builddir/hyprland-guiutils" \
            && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local \
                   -S "$builddir/hyprland-guiutils" -B "$builddir/hyprland-guiutils/build" \
            && cmake --build "$builddir/hyprland-guiutils/build" -j"$(nproc)" \
            && $SUDO cmake --install "$builddir/hyprland-guiutils/build" \
            && log "hyprland-guiutils installed" \
            || warn "hyprland-guiutils build failed — install manually if needed"
        rm -rf "$builddir"
    fi
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
    # (Themes/current.css/rasi are symlinks — symlinking them again is fine.)
    for app in kitty waybar swaync wlogout; do
        mkdir -p "$HOME_DIR/.config/$app"
        for f in "$REPO_ROOT"/home/.config/$app/*; do
            [[ -f "$f" ]] || continue   # ← only real files
            link_file "$f" "$HOME_DIR/.config/$app/$(basename "$f")"
        done
        # Also link files inside app subdirs (themes/, icons/)
        for sub in themes icons; do
            [[ -d "$REPO_ROOT/home/.config/$app/$sub" ]] || continue
            mkdir -p "$HOME_DIR/.config/$app/$sub"
            for f in "$REPO_ROOT"/home/.config/$app/$sub/*; do
                [[ -f "$f" ]] || continue
                link_file "$f" "$HOME_DIR/.config/$app/$sub/$(basename "$f")"
            done
        done
    done

    # Rofi — special: has shared/colors.rasi and shared/fonts.rasi wrapper
    mkdir -p "$HOME_DIR/.config/rofi/shared"
    for f in "$REPO_ROOT"/home/.config/rofi/shared/*; do
        [[ -f "$f" ]] || continue
        link_file "$f" "$HOME_DIR/.config/rofi/shared/$(basename "$f")"
    done

    # Fish shell
    mkdir -p "$HOME_DIR/.config/fish/functions"
    for f in "$REPO_ROOT"/home/.config/fish/*; do
        [[ -f "$f" ]] || continue
        link_file "$f" "$HOME_DIR/.config/fish/$(basename "$f")"
    done
    for f in "$REPO_ROOT"/home/.config/fish/functions/*; do
        [[ -f "$f" ]] || continue
        link_file "$f" "$HOME_DIR/.config/fish/functions/$(basename "$f")"
    done

    # Scripts — symlink to ~/.local/bin AND /usr/local/bin
    # (Hyprland's exec PATH doesn't include ~/.local/bin, so we need
    #  either /usr/local/bin symlink or absolute path in keybinds.)
    mkdir -p "$HOME_DIR/.local/bin"
    for f in "$REPO_ROOT"/home/.local/bin/*; do
        [[ -f "$f" ]] || continue
        link_file "$f" "$HOME_DIR/.local/bin/$(basename "$f")"
        chmod +x "$HOME_DIR/.local/bin/$(basename "$f")"
    done

    if [[ -w /usr/local/bin ]]; then
        for f in "$REPO_ROOT"/home/.local/bin/*; do
            [[ -f "$f" ]] || continue
            ln -sfn "$HOME_DIR/.local/bin/$(basename "$f")" /usr/local/bin/$(basename "$f")
        done
        log "Linked all scripts to /usr/local/bin (system PATH)"
    elif command -v sudo >/dev/null; then
        for f in "$REPO_ROOT"/home/.local/bin/*; do
            [[ -f "$f" ]] || continue
            sudo ln -sfn "$HOME_DIR/.local/bin/$(basename "$f")" /usr/local/bin/$(basename "$f")
        done
        log "Linked all scripts to /usr/local/bin (system PATH)"
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
log "Run 'theme-doctor' to verify the theme system is healthy."
