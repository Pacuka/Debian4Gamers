#!/usr/bin/env bash

# Function to print logs to console and log file
print_log() {
    echo -e "$1"
    echo -e "$1" >> installation.log
}

# Function to upgrade system packages
upgradeSystem() {
    sudo apt update && sudo apt upgrade -y
}

# Function to install Steam and tools
installSteamAndTools() {
    upgradeSystem
    print_log "\n#################### Installing tools and Steam ####################\n"
    sudo flatpak install -y flathub com.valvesoftware.Steam
    installFreedesktopVulkanLayers
    sudo apt clean
}

# Function to install Vulkan capture support for OBS Studio
installVKCapture() {
    sudo apt install -y pkg-config cmake libobs-dev libvulkan-dev libgl-dev libegl-dev libx11-dev libxcb1-dev libwayland-client0 wayland-scanner++
    cd /tmp || exit
    git clone https://github.com/nowrep/obs-vkcapture.git
    cd obs-vkcapture || exit
    mkdir build && cd build
    cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release ..
    make && sudo make install
    print_log "1. Add Game Capture to your OBS scene."
    print_log "2. Start the game with capture enabled obs-gamecapture %command%."
    print_log "3. (Recommended) Start the game with only Vulkan capture enabled env OBS_VKCAPTURE=1 %command%."
}

# Function to install Freedesktop Vulkan layers
installFreedesktopVulkanLayers() {
    sudo flatpak install -y org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/23.08
    sudo flatpak install -y org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/23.08
}

# Function to install flatpak applications based on user selection
installFlatpakApps() {
    # Set all options as selected by default
    InstallOptions=$(whiptail --separate-output --title "Flatpak Apps Options" --checklist \
        "Choose Flatpak Apps to Install" 20 78 12 \
        "1" "Install Discord" ON \
        "2" "Install ProtonUp-Qt" ON \
        "3" "Install Spotify" ON \
        "4" "Install Bottles" ON \
        "5" "Install GPU Screen Recorder" ON \
        "6" "Install OBS-Studio" ON \
        "7" "Install Helvum" ON \
        "8" "Install Heroic Launcher" ON \
        "9" "Install Telegram" ON \
        "10" "Install Proton VPN" ON \
        "11" "Install Piper (Gaming mouse configuration utility)" ON \
        "12" "Install OpenRGB (RGB lighting control)" ON 3>&1 1>&2 2>&3)

    if [ -z "$InstallOptions" ]; then
        echo "No option was selected (user hit Cancel or unselected all options)"
    else
        for Option in $InstallOptions; do
            case "$Option" in
                "1")
                    sudo flatpak install -y flathub com.discordapp.Discord
                    sudo flatpak install -y flathub io.github.trigg.discover_overlay
                    ;;
                "2")
                    sudo flatpak install -y flathub net.davidotek.pupgui2
                    ;;
                "3")
                    sudo flatpak install -y flathub com.spotify.Client
                    ;;
                "4")
                    sudo flatpak install -y flathub com.usebottles.bottles
                    installFreedesktopVulkanLayers
                    ;;
                "5")
                    sudo flatpak install -y flathub com.dec05eba.gpu_screen_recorder
                    ;;
                "6")
                    installVKCapture
                    sudo flatpak install -y com.obsproject.Studio
                    sudo flatpak install -y org.freedesktop.Platform.GStreamer.gstreamer-vaapi/x86_64/23.08
                    sudo flatpak install -y com.obsproject.Studio.Plugin.Gstreamer/x86_64/stable
                    sudo flatpak install -y com.obsproject.Studio.Plugin.BackgroundRemoval
                    sudo flatpak install -y org.freedesktop.Platform.VulkanLayer.OBSVkCapture/x86_64/23.08
                    sudo flatpak install -y com.obsproject.Studio.Plugin.OBSVkCapture/x86_64/stable
                    ;;
                "7")
                    sudo flatpak install -y flathub org.pipewire.Helvum
                    ;;
                "8")
                    sudo flatpak install -y flathub com.heroicgameslauncher.hgl
                    installFreedesktopVulkanLayers
                    ;;
                "9")
                    sudo flatpak install -y flathub org.telegram.desktop
                    ;;
                "10")
                    sudo apt install -y libayatana-appindicator3-1 gir1.2-ayatanaappindicator3-0.1
                    sudo flatpak install -y flathub com.protonvpn.www
                    ;;
                "11")
                    sudo apt install ratbagd
                    sudo flatpak install -y flathub org.freedesktop.Piper
                    ;;
                "12")
                    sudo flatpak install flathub org.openrgb.OpenRGB
                    wget https://openrgb.org/releases/release_0.9/openrgb-udev-install.sh
                    chmod +x openrgb-udev-install.sh
                    bash openrgb-udev-install.sh
                    ;;
                *)
                    echo "Unsupported item $Options!" >&2
                    exit 1
                    ;;
            esac
        done
    fi
}

# Function to install apt packages
installAptPackage() {
    package=$1
    print_log "\n#################### Installing $package ####################\n"
    sudo apt update
    sudo apt install -y $package
    sudo apt clean
    print_log "\n#################### $package installed ####################\n"
}

# Function to install flatpak packages
installFlatpakPackage() {
    package=$1
    print_log "\n#################### Installing $package - flatpak ####################\n"
    sudo flatpak install -y flathub $package
    print_log "\n#################### $package installed ####################\n"
}

# Function to install selected applications
installSelectedApps() {
    upgradeSystem
    user_choice=$(zenity --list --checklist --width='1000' --height='1000' \
        --title="APP Telepítő Script base by Airman & RAVE (Magyarosította balage79)" \
        --text="Válassz az alábbi programok közül:" \
        --column="Válassz" --column="Programnév / Leírás" \
        FALSE "GNOME Screenshot - gyorsbillentyűs képernyőkép létrehozás" \
        FALSE "GNOME Clocks - ébresztő, világóra, stopper, időzítő" \
        FALSE "GameMode" \
        FALSE "Neofetch - terminálos rendszerinfó megjelenítő" \
        FALSE "Input-Remapper 2.0 - egér/bill. gomb konfiguráló, macro író progi" \
        FALSE "Lutris - Game launchereket, és egyéb appokat futtató környezet" \
        FALSE "KVM QEMU - virtualizáció, virtuális gépek futtatása" \
        FALSE "Librewolf - Firefox ESR alapú webböngésző" \
        FALSE "FreeTube - Adatlopás-mentes YouTube-kliens" \
        FALSE "OnlyOffice - Legujabb MS Office Linuxos megfeleloje - LIBREOFFICE-t TOROLNI FOGJA!" \
        FALSE "DosBox - Régi, DOS-os játék emulátor" \
        FALSE "Pavucontrol - Apponkénti hangerőszabályzás/konfigurálás" \
        FALSE "KeepassXC - Jelszókezelő, az adatbázist titkosítva tárolja a PC-n" \
        FALSE "Darktable - Adobe Lightroom Linuxos megfelelője" \
        FALSE "VLC - médialejátszó" \
        FALSE "QBittorrent - torrent kliens" \
        FALSE "Kdenlive - Linuxos videószerkesztő program" \
        FALSE "Easy Effects - Hangkártyát vezérlő program (Hangeffektek)" \
        FALSE "Parabolic - Videóletöltő, működik minden platformon" \
        FALSE "Vibrant - Szín szaturáció beállító program" \
        FALSE "Csak a FO Monitoron jelenjen meg a Login Screen - Tobb monitoros setupoknal" \
        FALSE "MangoHud/Goverlay - MSI Afterburner Linuxos megfelelője, FPS kijelzés, stb." \
        FALSE "GTKStressTesting - CPU Monitorozas es Stress Test Program" \
        FALSE "HD Sentinel - Merevlemez állapot ellenőrző program" \
        FALSE "XFBurn - DVD / CD író program")

    if [[ $? -eq 1 ]]; then
        print_log "${bold}${yellow}Cancelled by User. Exiting!${normal}"
        exit 1
    fi

    for choice in $user_choice; do
        case "$choice" in
            "GNOME Screenshot - gyorsbillentyűs képernyőkép létrehozás")
                installAptPackage gnome-screenshot
                ;;
            "GNOME Clocks - ébresztő, világóra, stopper, időzítő")
                installAptPackage gnome-clocks
                sudo rsync -ap --info=progress2 /usr/share/sounds/Yaru/stereo/complete.oga /usr/share/sounds/freedesktop/stereo/
                sudo rsync -ap --info=progress2 alarm-clock*.oga /usr/share/sounds/freedesktop/stereo
                ;;
            "GameMode")
                installAptPackage gamemode
                ;;
            "Neofetch - terminálos rendszerinfó megjelenítő")
                installAptPackage neofetch
                ;;
            "Input-Remapper 2.0 - egér/bill. gomb konfiguráló, macro író progi")
                installAptPackage input-remapper
                ;;
            "Lutris - Game launchereket, és egyéb appokat futtató környezet")
                installAptPackage lutris
                ;;
            "KVM QEMU - virtualizáció, virtuális gépek futtatása")
                installAptPackage qemu-kvm
                ;;
            "Librewolf - Firefox ESR alapú webböngésző")
                installAptPackage librewolf
                ;;
            "FreeTube - Adatlopás-mentes YouTube-kliens")
                installAptPackage freetube
                ;;
            "OnlyOffice - Legujabb MS Office Linuxos megfeleloje - LIBREOFFICE-t TOROLNI FOGJA!")
                installAptPackage onlyoffice-desktopeditors
                ;;
            "DosBox - Régi, DOS-os játék emulátor")
                installAptPackage dosbox
                ;;
            "Pavucontrol - Apponkénti hangerőszabályzás/konfigurálás")
                installAptPackage pavucontrol
                ;;
            "KeepassXC - Jelszókezelő, az adatbázist titkosítva tárolja a PC-n")
                installAptPackage keepassxc
                ;;
            "Darktable - Adobe Lightroom Linuxos megfelelője")
                installAptPackage darktable
                ;;
            "VLC - médialejátszó")
                installAptPackage vlc
                ;;
            "QBittorrent - torrent kliens")
                installAptPackage qbittorrent
                ;;
            "Kdenlive - Linuxos videószerkesztő program")
                installAptPackage kdenlive
                ;;
            "Easy Effects - Hangkártyát vezérlő program (Hangeffektek)")
                installAptPackage easyeffects
                ;;
            "Parabolic - Videóletöltő, működik minden platformon")
                installFlatpakPackage com.github.ereio.parabolic
                ;;
            "Vibrant - Szín szaturáció beállító program")
                installAptPackage vibrant
                ;;
            "Csak a FO Monitoron jelenjen meg a Login Screen - Tobb monitoros setupoknal")
                sudo cp /usr/share/X11/xorg.conf.d/90-monitor.conf /etc/X11/xorg.conf.d
                ;;
            "MangoHud/Goverlay - MSI Afterburner Linuxos megfelelője, FPS kijelzés, stb.")
                installAptPackage mangohud
                installAptPackage goverlay
                ;;
            "GTKStressTesting - CPU Monitorozas es Stress Test Program")
                installAptPackage gtkstress
                ;;
            "HD Sentinel - Merevlemez állapot ellenőrző program")
                installAptPackage hdsentinel
                ;;
            "XFBurn - DVD / CD író program")
                installAptPackage xfburn
                ;;
            *)
                print_log "Unknown choice: $choice"
                ;;
        esac
    done

    print_log "All selected applications have been installed."
}

# Main script starts here
main() {
    installSteamAndTools
    installFlatpakApps
    installSelectedApps
}

# Execute main function
main
