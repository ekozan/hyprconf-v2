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

# finding the presend directory and log file
# dir="$(dirname "$(realpath "$0")")"
dir=`pwd`
# log directory
log_dir="$dir/Logs"
log="$dir/Logs/hyprconf-v2.log"
mkdir -p "$log_dir"
touch "$log"

# message prompts
msg() {
    local actn=$1
    local msg=$2

    case $actn in
        act)
            printf "${green}=>${end} $msg\n"
            ;;
        ask)
            printf "${orange}??${end} $msg\n"
            ;;
        dn)
            printf "${cyan}::${end} $msg\n\n"
            ;;
        att)
            printf "${yellow}!!${end} $msg\n"
            ;;
        nt)
            printf "${blue}\$\$${end} $msg\n"
            ;;
        skp)
            printf "${magenta}[ SKIP ]${end} $msg\n"
            ;;
        err)
            printf "${red}>< Ohh sheet! an error..${end}\n   $msg\n"
            sleep 1
            ;;
        *)
            printf "$msg\n"
            ;;
    esac
}


install() {
    local pkg=${1}

    if command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm $1
    elif command -v dnf &> /dev/null; then
        sudo dnf install $1 -y
    elif command -v zypper &> /dev/null; then
        sudo zypper in $1 -y
    fi
}
aur_helper=$(command -v yay || command -v paru) # find the aur helper

# skip already insalled packages
skip_installed() {

    [[ -z "$installed_cache" ]] && touch "$installed_cache"

    if "$aur_helper" -Q "$1" &> /dev/null; then
        msg skp "$1 is already installed. Skipping..." && sleep 0.1
        if ! grep -qx "$1" "$installed_cache"; then
            echo "$1" >> "$installed_cache"
        fi
    fi
}


# package installation function..
install_package() {

    msg act "Installing $1..."
    "$aur_helper" -S --noconfirm "$1" &> /dev/null

    if "$aur_helper" -Q "$1" &> /dev/null; then
        msg dn "$1 was installed successfully!"
    else
        msg err "$1 failed to install. Maybe therer is an issue..."
    fi
}

# Need to install 2 packages (gum and parallel)________________________
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

# any other packages will be installed from here
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
    parallel
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

printf "\n\n"

for pkg in "${installable_pkgs[@]}"; do
    if sudo pacman -Q "$pkg" &> /dev/null || rpm -q "$pkg" &> /dev/null || sudo zypper se -i "$pkg" &> /dev/null; then
        msg dn "Everything is fine. Proceeding to the next step"
    else
        msg att "Need to install $pkg. It's important."
        install "$pkg" &> /dev/null
    fi
done

for _pkgs in  "${installable_fonts[@]}" "${_hypr[@]}" "${other_packages[@]}" "${aur_packages[@]}" "${dolphin[@]}"; do
    install_package "$_pkgs"
    if sudo pacman -Q "$_pkgs" &>/dev/null; then
        echo "[ DONE ] - $_pkgs was installed successfully!\n" 2>&1 | tee -a "$log" &>/dev/null
    else
        echo "[ ERROR ] - Sorry, could not install $_pkgs!\n" 2>&1 | tee -a "$log" &>/dev/null
    fi
done



sleep 2 && clear

for fonts in "${installable_fonts[@]}"; do
    if sudo pacman -Q "$fonts" &> /dev/null || rpm -q "$fonts" &> /dev/null || sudo zypper se -i "$fonts" &> /dev/null; then
        msg dn "Everything is fine. Proceeding to the next step"
    else
        msg att "Need to install $pkg. It's important."
        install "$fonts" &> /dev/null
    fi
done

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
