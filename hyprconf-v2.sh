#!/bin/bash

# color defination
red="\e[1;31m"
green="\e[1;32m"
yellow="\e[1;33m"
blue="\e[1;34m"
megenta="\e[1;1;35m"
cyan="\e[1;36m"
orange="\x1b[38;5;214m"
end="\e[1;0m"

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
printf " \n \n"

###------ Startup ------###

### === Chemins & log ===========================================
dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
log_dir="$dir/Logs"
log="$log_dir/hyprconf-v2.log"
mkdir -p "$log_dir"
touch "$log"

### === Couleurs (adapte si tu les as déjà ailleurs) ============
green='\033[0;32m'
orange='\033[0;33m'
cyan='\033[0;36m'
yellow='\033[1;33m'
blue='\033[0;34m'
magenta='\033[0;35m'
red='\033[0;31m'
end='\033[0m'

### === Messages =================================================
msg() {
    local actn=$1
    local msg=$2

    case $actn in
        act) printf "${green}=>${end} %s\n" "$msg" ;;
        ask) printf "${orange}??${end} %s\n" "$msg" ;;
        dn)  printf "${cyan}::${end} %s\n\n" "$msg" ;;
        att) printf "${yellow}!!${end} %s\n" "$msg" ;;
        nt)  printf "${blue}\$\$${end} %s\n" "$msg" ;;
        skp) printf "${magenta}[ SKIP ]${end} %s\n" "$msg" ;;
        err)
            printf "${red}>< Ohh sheet! an error..${end}\n   %s\n" "$msg"
            sleep 1
            ;;
        *) printf "%s\n" "$msg" ;;
    esac
}

### === Détection du gestionnaire de paquets =====================
PKG_MGR=""
if command -v pacman &>/dev/null; then
    PKG_MGR="pacman"
elif command -v dnf &>/dev/null; then
    PKG_MGR="dnf"
elif command -v zypper &>/dev/null; then
    PKG_MGR="zypper"
else
    msg err "Aucun gestionnaire de paquets supporté trouvé (pacman/dnf/zypper)."
    exit 1
fi

### === AUR helper (Arch seulement) =============================
aur_helper=""

if [[ "$PKG_MGR" == "pacman" ]]; then
    aur_helper="$(command -v yay || command -v paru || true)"

    if [[ -z "$aur_helper" ]]; then
        msg act "Installation de yay (AUR helper)..."
        sudo pacman -S --needed --noconfirm git base-devel
        tmp_dir="$(mktemp -d)"
        git clone https://aur.archlinux.org/yay-bin.git "$tmp_dir/yay-bin"
        cd "$tmp_dir/yay-bin"
        makepkg -si --noconfirm
        cd - >/dev/null
        aur_helper="$(command -v yay || command -v paru || true)"
    fi
fi

### === Fonctions utilitaires ====================================
is_installed() {
    local pkg="$1"

    case "$PKG_MGR" in
        pacman)
            # on teste d'abord pacman, puis éventuellement l’aur helper
            if pacman -Q "$pkg" &>/dev/null; then
                return 0
            fi
            if [[ -n "$aur_helper" ]] && "$aur_helper" -Q "$pkg" &>/dev/null; then
                return 0
            fi
            ;;
        dnf)
            rpm -q "$pkg" &>/dev/null && return 0
            ;;
        zypper)
            zypper se -i "$pkg" 2>/dev/null | grep -q "^i. *$pkg" && return 0
            ;;
    esac

    return 1
}

install_pkg() {
    local pkg="$1"

    if is_installed "$pkg"; then
        msg skp "$pkg est déjà installé. On passe."
        return
    fi

    msg act "Installation de $pkg..."

    case "$PKG_MGR" in
        pacman)
            if [[ -n "$aur_helper" ]]; then
                "$aur_helper" -S --noconfirm "$pkg" >/dev/null 2>&1 || true
            else
                sudo pacman -S --noconfirm "$pkg" >/dev/null 2>&1 || true
            fi
            ;;
        dnf)
            sudo dnf install -y "$pkg" >/dev/null 2>&1 || true
            ;;
        zypper)
            sudo zypper in -y "$pkg" >/dev/null 2>&1 || true
            ;;
    esac

    if is_installed "$pkg"; then
        msg dn "$pkg a été installé avec succès !"
        printf "[ DONE ] - %s was installed successfully!\n" "$pkg" | tee -a "$log" >/dev/null
    else
        msg err "$pkg a échoué à l'installation."
        printf "[ ERROR ] - Sorry, could not install %s!\n" "$pkg" | tee -a "$log" >/dev/null
    fi
}

### === Listes de paquets ========================================

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
    parallel        # doublon géré par la dédup plus bas
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

### === Installation ==============================================

printf "\n\n"

# On fusionne tout dans une seule liste
all_pkgs=(
    "${installable_pkgs[@]}"
    "${installable_fonts[@]}"
    "${_hypr[@]}"
    "${other_packages[@]}"
    "${aur_packages[@]}"
    "${dolphin[@]}"
)

# Déduplication pour éviter les installations doubles
declare -A seen
for pkg in "${all_pkgs[@]}"; do
    # si déjà vu, on skip
    if [[ -n "${seen[$pkg]:-}" ]]; then
        continue
    fi
    seen["$pkg"]=1
    install_pkg "$pkg"
done

msg dn "Toutes les installations sont terminées."
sleep 2 && clear
# Directories ----------------------------
hypr_dir="$HOME/.config/hypr"
scripts_dir="$hypr_dir/scripts"
fonts_dir="$HOME/.local/share/fonts"

msg act "Now setting up the pre installed Hyprland configuration..."sleep 1

mkdir -p ~/.config
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


# if some main directories exists, backing them up.
if [[ -d "$HOME/.config/backup_hyprconfV2-${USER}" ]]; then
    msg att "a backup_hyprconfV2-${USER} directory was there. Archiving it..."
    cd "$HOME/.config"
    mkdir -p "archive_hyprconfV2-${USER}"
    tar -czf "archive_hyprconfV2-${USER}/backup_hyprconfV2-$(date +%d-%m-%Y_%I-%M-%p)-${USER}.tar.gz" "backup_hyprconfV2-${USER}" &> /dev/null
    rm -rf "backup_hyprconfV2-${USER}"
    msg dn "backup_hyprconfV2-${USER} was archived inside archive_hyprconfV2-${USER} directory..." && sleep 1
fi

for confs in "${dirs[@]}"; do
    mkdir -p "$HOME/.config/backup_hyprconfV2-${USER}"
    dir_path="$HOME/.config/$confs"
    if [[ -d "$dir_path" || -f "$dir_path" ]]; then
        mv "$dir_path" "$HOME/.config/backup_hyprconfV2-${USER}/" 2>&1 | tee -a "$log"
    fi
done

[[ -d "$HOME/.config/backup_hyprconfV2-${USER}/hypr" ]] && msg dn "Everything has been backuped in $HOME/.config/backup_hyprconfV2-${USER}..."

sleep 1

####################################################################


#_____ for virtual machine
# Check if the configuration is in a virtual box
if hostnamectl | grep -q 'Chassis: vm'; then
    msg att "You are using this script in a Virtual Machine..."
    msg act "Setting up things for you..." 
    sed -i '/env = WLR_NO_HARDWARE_CURSORS,1/s/^#//' "$dir/config/hypr/confs/env.conf"
    sed -i '/env = WLR_RENDERER_ALLOW_SOFTWARE,1/s/^#//' "$dir/config/hypr/confs/env.conf"
    mv "$dir/config/hypr/confs/monitor.conf" "$dir/config/hypr/confs/monitor-back.conf"
    cp "$dir/config/hypr/confs/monitor-vbox.conf" "$dir/config/hypr/confs/monitor.conf"
fi

sleep 1


#####################################################
# cloning the dotfiles repository into ~/.config/hypr
#####################################################

mkdir -p "$HOME/.config"
cp -r "$dir/config"/* "$HOME/.config/" && sleep 0.5
if [[ ! -d "$HOME/.local/share/fastfetch" ]]; then
    mv "$HOME/.config/fastfetch" "$HOME/.local/share/"
fi

sleep 1

if [[ -d "$scripts_dir" ]]; then
    # make all the scripts executable...
    chmod +x "$scripts_dir"/* 2>&1 | tee -a "$log"
    chmod +x "$HOME/.config/fish/functions"/* 2>&1 | tee -a "$log"
    msg dn "All the necessary scripts have been executable..."
    sleep 1
else
    msg err "Could not find necessary scripts.."
fi

# Install Fonts
msg act "Installing some fonts..."
if [[ ! -d "$fonts_dir" ]]; then
	mkdir -p "$fonts_dir"
fi

cp -r "$dir/extras/fonts" "$fonts_dir"
msg act "Updating font cache..."
sudo fc-cache -fv 2>&1 | tee -a "$log" &> /dev/null

# Setup dolphin files
if [[ -f "$HOME/.local/state/dolphinstaterc" ]]; then
    mv "$HOME/.local/state/dolphinstaterc" "$HOME/.local/state/dolphinstaterc.back"
    cp "$dir/extras/dolphinstaterc" "$HOME/.local/state/"
fi


wayland_session_dir=/usr/share/wayland-sessions
if [ -d "$wayland_session_dir" ]; then
    msg att "$wayland_session_dir found..."
else
    msg att "$wayland_session_dir NOT found, creating..."
    sudo mkdir $wayland_session_dir 2>&1 | tee -a "$log"
    sudo cp "$dir/extras/hyprland.desktop" /usr/share/wayland-sessions/ 2>&1 | tee -a "$log"
fi


############################################################
# setting theme
###########################################################
# setting up the waybar
ln -sf "$HOME/.config/waybar/configs/full-top" "$HOME/.config/waybar/config"
ln -sf "$HOME/.config/waybar/style/full-top.css" "$HOME/.config/waybar/style.css"

themeFile="$HOME/.config/hypr/.cache/.theme"
touch "$themeFile" && echo "Catppuccin" > "$themeFile"

"$HOME/.config/config/hypr/scripts/Wallpaper.sh" &> /dev/null

# hyprland themes
hyprTheme="$HOME/.config/hypr/confs/themes/Catppuccin.conf"
ln -sf "$hyprTheme" "$HOME/.config/hypr/confs/decoration.conf"

# rofi themes
rofiTheme="$HOME/.config/rofi/colors/Catppuccin.rasi"
ln -sf "$rofiTheme" "$HOME/.config/rofi/themes/rofi-colors.rasi"

# Kitty themes
kittyTheme="$HOME/.config/kitty/colors/Catppuccin.conf"
ln -sf "$kittyTheme" "$HOME/.config/kitty/theme.conf"

# Apply new colors dynamically
kill -SIGUSR1 $(pidof kitty)

# waybar themes
waybarTheme="$HOME/.config/waybar/colors/Catppuccin.css"
ln -sf "$waybarTheme" "$HOME/.config/waybar/style/theme.css"

# wlogout themes
wlogoutTheme="$HOME/.config/wlogout/colors/Catppuccin.css"
ln -sf "$wlogoutTheme" "$HOME/.config/wlogout/colors.css"

# set swaync colors
swayncTheme="$HOME/.config/swaync/colors/Catppuccin.css"
ln -sf "$swayncTheme" "$HOME/.config/swaync/colors.css"

# Setting VS Code extension based on theme selection
settingsFile="$HOME/.config/Code/User/settings.json"
[[ -d "$settingsFile" ]] && sed -i "s|\"workbench.colorTheme\": \".*\"|\"workbench.colorTheme\": \"Catppuccin Mocha\"|" "$settingsFile"

# setting qt theme
crudini --set "$HOME/.config/Kvantum/kvantum.kvconfig" General theme "Catppuccin"
crudini --set ~/.config/kdeglobals Icons Theme "Tela-circle-dracula"

"$HOME/.config/hypr/scripts/wallcache.sh" &> /dev/null
"$HOME/.config/config/hypr/scripts/Refresh.sh" &> /dev/null

#############################################
# setting lock screen
#############################################
ln -sf "$HOME/.config/hypr/lockscreens/hyprlock-1.conf" "$HOME/.config/hypr/hyprlock.conf"

msg dn "Script execution was successful! Now logout and log back in and enjoy your hyprland..." && sleep 1

# === ___ Script Ends Here ___ === #
