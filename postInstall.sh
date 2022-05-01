git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
cd ..
rm -rf paru
paru -S ufw xorg pulseaudio gnome gnome-tweaks breeze-gtk beautyline chromium vlc jdk discord lutris 
sudo systemctl enable ufw.service
