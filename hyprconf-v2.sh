#!/usr/bin/env bash
set -euo pipefail

# ========= Couleurs ========= #
red="\e[1;31m"
green="\e[1;32m"
yellow="\e[1;33m"
blue="\e[1;34m"
magenta="\e[1;35m"
cyan="\e[1;36m"
orange="\x1b[38;5;214m"
end="\e[0m"

# ========= ASCII Art ========= #
display_text() {
    cat << "EOF"
    __  __                                  ____    _    _____ 
   / / / /_  ______  ______________  ____  / __/   | |  / /__ \
  / /_/ / / / / __ \/ ___/ ___/ __ \/ __ \/ /______| | / /__/ /
 / __  / /_/ / /_/ / /  / /__/ /_/ / / / / __/_____/ |/ // __/ 
/_/ /_/\__, / .___/_/   \___/\____/_/ /_/_/        |___//____/ 
      /____/_/                                                 

EOF
}

clear && display_text
printf "\n\n"

# ========= Log ========= #
dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
log_dir="$dir/Logs"
log="$log_dir/hyprconf-v2.log"
mkdir -p "$log_dir"
touch "$log"

# ========= Messages ========= #
msg() {
    local actn=$1
    local txt=$2

    case $actn in
        act) printf "${green}=>${end} %s\n" "$txt" ;;
        ask) printf "${orange}??${end} %s\n" "$txt" ;;
        dn)  printf "${cyan}::${end} %s\n\n" "$txt" ;;
        att) printf "${yellow}!!${end} %s\n" "$txt" ;;
        nt)  printf "${blue}\$\$${end} %s\n" "$txt" ;;
        skp) printf "${magenta}[ SKIP ]${end} %s\n" "$txt" ;;
        err)
            printf "${red}>< Ohh sheet! an error..${end}\n   %s\n" "$txt"
            sleep 1
            ;;
        *) printf "%s\n" "$txt" ;;
    esac
}

# ========= Vérification Arch / pacman ========= #
if ! command -v pacman &>/dev/null; then
    msg err "Ce script est Arch-only et nécessite pacman."
    exit 1
fi

# ========= AUR helper (yay) ========= #
aur_helper="$(command -v yay || true)"

if [[ -z "$aur_helper" ]]; then
    msg act "Installation de yay (AUR helper)..."
    sudo pacman -S --needed --noconfirm git base-devel
    tmp_dir="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay-bin.git "$tmp_dir/yay-bin"
    cd "$tmp_dir/yay-bin"
    makepkg -si --noconfirm
    cd - >/dev/null
    aur_helper="$(command -v yay || true)"
fi

if [[ -z "$aur_helper" ]]; then
    msg err "Impossible d'installer ou de trouver yay."
    exit 1
fi

# ========= Fonctions utilitaires ========= #
is_installed() {
    local pkg="$1"
    # yay -Q gère repo + AUR
    if "$aur_helper" -Q "$pkg" &>/dev/null; then
        return 0
    fi
    return 1
}

install_pkg() {
    local pkg="$1"

    if is_installed "$pkg"; then
        msg skp "$pkg est déjà installé. On passe."
        return
    fi

    msg act "Installation de $pkg..."
    if "$aur_helper" -S --noconfirm "$pkg" >/dev/null 2>&1; then
        msg dn "$pkg a été installé avec succès !"
        printf "[ DONE ] - %s was installed successfully!\n" "$pkg" | tee -a "$log" >/dev/null
    else
        msg err "$pkg a échoué à l'installation."
        printf "[ ERROR ] - Sorry, could not install %s!\n" "$pkg" | tee -a "$log" >/dev/null
    fi
}

# ========= Listes de paquets ========= #
installable_pkgs=(
    gum
    parallel
)

installable_fonts=(
    ttf-font-awesome
    ttf-cascadia-code-nerd
    ttf-jetbrains-mono-nerd
    ttf-meslo-nerd
    noto-fonts
    noto-fonts-emoji
)

_hypr=(
    hyprland
    hyprlock
    hypridle
    hyprcursor
    # hyprpolkitagent
)

other_packages=(
    btop
    curl
    dunst
    fastfetch
    imagemagick
    jq
    konsole
    kitty
    kvantum
    kvantum-qt5
    less
    lxappearance
    mpv-mpris
    network-manager-applet
    networkmanager
    neovim
    nodejs
    npm
    ntfs-3g
    nvtop
    nwg-look
    os-prober
    pacman-contrib
    pamixer
    pavucontrol
    parallel        # doublon géré par la dédup
    pciutils
    polkit-kde-agent
    power-profiles-daemon
    python-pywal
    python-gobject
    qt5ct
    qt5-svg
    qt6ct-kde
    qt6-svg
    qt5-graphicaleffects
    qt5-quickcontrols2
    ripgrep
    rofi-wayland
    satty
    swaync
    swww
    unzip
    waybar
    wget
    wl-clipboard
    xorg-xrandr
    yazi
    zip
)

aur_packages=(
    cava
    grimblast-git
    hyprsunset
    hyprland-qtutils
    tty-clock
    pyprland
    wlogout
)

dolphin=(
    ark
    crudini
    dolphin
    gwenview
    okular
)

# ========= Installation des paquets ========= #
printf "\n\n"

all_pkgs=(
    "${installable_pkgs[@]}"
    "${installable_fonts[@]}"
    "${_hypr[@]}"
    "${other_packages[@]}"
    "${aur_packages[@]}"
    "${dolphin[@]}"
)

declare -A seen
for pkg in "${all_pkgs[@]}"; do
    if [[ -n "${seen[$pkg]:-}" ]]; then
        continue
    fi
    seen["$pkg"]=1
    install_pkg "$pkg"
done

msg dn "Toutes les installations de paquets sont terminées."
sleep 2 && clear

# ========= Directories & variables ========= #
hypr_dir="$HOME/.config/hypr"
scripts_dir="$hypr_dir/scripts"
fonts_dir="$HOME/.local/share/fonts"

msg act "Now setting up the pre installed Hyprland configuration..."
sleep 1

mkdir -p "$HOME/.config"
backup_dir="$HOME/.config/backup_hyprconfV2-${USER}"

dirs=(
    btop
    fastfetch
    fish
    gtk-3.0
    gtk-4.0
    hypr
    kitty
    Kvantum
    menus
    nvim
    nwg-look
    qt5ct
    qt6ct
    rofi
    satty
    swaync
    waybar
    wlogout
    xfce4
    xsettingsd
    yazi
    dolphinrc
    kwalletmanagerrc
    kwallertc
)

# ========= Backup configs ========= #
if [[ -d "$backup_dir" ]]; then
    msg att "$backup_dir existe déjà. Archivage..."
    cd "$HOME/.config"
    archive_dir="archive_hyprconfV2-${USER}"
    mkdir -p "$archive_dir"
    tar -czf "${archive_dir}/backup_hyprconfV2-$(date +%d-%m-%Y_%H-%M)-${USER}.tar.gz" "backup_hyprconfV2-${USER}" &>/dev/null
    rm -rf "backup_hyprconfV2-${USER}"
    msg dn "backup_hyprconfV2-${USER} a été archivé dans $archive_dir."
fi

mkdir -p "$backup_dir"
for confs in "${dirs[@]}"; do
    dir_path="$HOME/.config/$confs"
    if [[ -d "$dir_path" || -f "$dir_path" ]]; then
        mv "$dir_path" "$backup_dir/" 2>&1 | tee -a "$log"
    fi
done

[[ -d "$backup_dir/hypr" ]] && msg dn "Tout a été sauvegardé dans $backup_dir."
sleep 1

# ========= Virtual Machine tweaks ========= #
if hostnamectl | grep -q 'Chassis: vm'; then
    msg att "Vous utilisez ce script dans une machine virtuelle..."
    msg act "Adaptation de la configuration pour VM..."
    sed -i '/env = WLR_NO_HARDWARE_CURSORS,1/s/^#//' "$dir/config/hypr/confs/env.conf"
    sed -i '/env = WLR_RENDERER_ALLOW_SOFTWARE,1/s/^#//' "$dir/config/hypr/confs/env.conf"
    mv "$dir/config/hypr/confs/monitor.conf" "$dir/config/hypr/confs/monitor-back.conf"
    cp "$dir/config/hypr/confs/monitor-vbox.conf" "$dir/config/hypr/confs/monitor.conf"
fi

sleep 1

# ========= Copie des configs ========= #
mkdir -p "$HOME/.config"
cp -r "$dir/config"/* "$HOME/.config/" && sleep 0.5

if [[ ! -d "$HOME/.local/share/fastfetch" ]] && [[ -d "$HOME/.config/fastfetch" ]]; then
    mv "$HOME/.config/fastfetch" "$HOME/.local/share/"
fi

sleep 1

if [[ -d "$scripts_dir" ]]; then
    chmod +x "$scripts_dir"/* 2>&1 | tee -a "$log"
    if [[ -d "$HOME/.config/fish/functions" ]]; then
        chmod +x "$HOME/.config/fish/functions"/* 2>&1 | tee -a "$log"
    fi
    msg dn "Tous les scripts nécessaires ont été rendus exécutables."
    sleep 1
else
    msg err "Impossible de trouver les scripts Hyprland nécessaires..."
fi

# ========= Fonts ========= #
msg act "Installation des fonts..."
mkdir -p "$fonts_dir"
cp -r "$dir/extras/fonts" "$fonts_dir"
msg act "Mise à jour du cache de fonts..."
fc-cache -fv 2>&1 | tee -a "$log" >/dev/null

# ========= Dolphin ========= #
if [[ -f "$HOME/.local/state/dolphinstaterc" ]]; then
    mv "$HOME/.local/state/dolphinstaterc" "$HOME/.local/state/dolphinstaterc.back"
fi

if [[ -f "$dir/extras/dolphinstaterc" ]]; then
    mkdir -p "$HOME/.local/state"
    cp "$dir/extras/dolphinstaterc" "$HOME/.local/state/"
fi

# ========= Session Wayland ========= #
wayland_session_dir=/usr/share/wayland-sessions
if [[ -d "$wayland_session_dir" ]]; then
    msg att "$wayland_session_dir trouvé..."
else
    msg att "$wayland_session_dir non trouvé, création..."
    sudo mkdir -p "$wayland_session_dir" 2>&1 | tee -a "$log"
fi

sudo cp "$dir/extras/hyprland.desktop" "$wayland_session_dir/" 2>&1 | tee -a "$log"

# ========= Thèmes & liens ========= #
# waybar
ln -sf "$HOME/.config/waybar/configs/full-top" "$HOME/.config/waybar/config"
ln -sf "$HOME/.config/waybar/style/full-top.css" "$HOME/.config/waybar/style.css"

# thème courant
themeFile="$HOME/.config/hypr/.cache/.theme"
mkdir -p "$(dirname "$themeFile")"
echo "Catppuccin" > "$themeFile"

# scripts de wallpaper & refresh
if [[ -x "$HOME/.config/hypr/scripts/Wallpaper.sh" ]]; then
    "$HOME/.config/hypr/scripts/Wallpaper.sh" &>/dev/null
fi

hyprTheme="$HOME/.config/hypr/confs/themes/Catppuccin.conf"
ln -sf "$hyprTheme" "$HOME/.config/hypr/confs/decoration.conf"

# rofi
rofiTheme="$HOME/.config/rofi/colors/Catppuccin.rasi"
ln -sf "$rofiTheme" "$HOME/.config/rofi/themes/rofi-colors.rasi"

# kitty
kittyTheme="$HOME/.config/kitty/colors/Catppuccin.conf"
ln -sf "$kittyTheme" "$HOME/.config/kitty/theme.conf"

# reload kitty si lancé
pkill -USR1 kitty 2>/dev/null || true

# waybar theme couleur
waybarTheme="$HOME/.config/waybar/colors/Catppuccin.css"
ln -sf "$waybarTheme" "$HOME/.config/waybar/style/theme.css"

# wlogout
wlogoutTheme="$HOME/.config/wlogout/colors/Catppuccin.css"
ln -sf "$wlogoutTheme" "$HOME/.config/wlogout/colors.css"

# swaync
swayncTheme="$HOME/.config/swaync/colors/Catppuccin.css"
ln -sf "$swayncTheme" "$HOME/.config/swaync/colors.css"

# VS Code
settingsFile="$HOME/.config/Code/User/settings.json"
if [[ -f "$settingsFile" ]]; then
    sed -i 's|"workbench.colorTheme": ".*"|"workbench.colorTheme": "Catppuccin Mocha"|' "$settingsFile"
fi

# Kvantum / icons
crudini --set "$HOME/.config/Kvantum/kvantum.kvconfig" General theme "Catppuccin" || true
crudini --set "$HOME/.config/kdeglobals" Icons Theme "Tela-circle-dracula" || true

# cache & refresh Hypr
if [[ -x "$HOME/.config/hypr/scripts/wallcache.sh" ]]; then
    "$HOME/.config/hypr/scripts/wallcache.sh" &>/dev/null
fi
if [[ -x "$HOME/.config/hypr/scripts/Refresh.sh" ]]; then
    "$HOME/.config/hypr/scripts/Refresh.sh" &>/dev/null
fi

# lockscreen
ln -sf "$HOME/.config/hypr/lockscreens/hyprlock-1.conf" "$HOME/.config/hypr/hyprlock.conf"

msg dn "Script execution was successful! Now logout and log back in and enjoy your hyprland..."
# === ___ Script Ends Here ___ === #
