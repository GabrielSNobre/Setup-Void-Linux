#!/bin/bash

#Failsafe
set -e

echo -e "\nSetup for Wayland"
echo -e "\nSway + Foot + Yazi + Firefox + Neovim"

sleep 3

echo -e "\nUpdating and Adding all repos"
sudo xbps-install -Syu
sudo xbps-install -y void-repo-multilib void-repo-nonfree void-repo-multilib-nonfree

sleep 2

echo -e "\nInstalling the software"
sudo xbps-install -Sy \
	sway \
	firefox \
	dbus \
	elogind \
	neovim \
	yazi \
	foot \
	rofi \
	base-devel \
	git \
	wget \
	curl \
	zip \
	7zip \
	xdg-utils \
	xdg-user-dirs \
	mesa-dri \
	mesa-vaapi \
	mesa-opencl \
	pipewire \
	wireplumber \
	pavucontrol \
	polkit \
	autotiling \
	lm_sensors \
	swaylock \
	noto-fonts-emoji \
	dejavu-fonts \
	nerd-fonts-ttf \
	nerd-fonts-symbols-ttf

echo -e "\nSetting up basic services"
sudo ln -s /etc/sv/{elogind, dbus, polkitd} /var/service/
sudo sensors-detect --auto

sleep 2
echo -e "\nSetting up audio server"
sudo mkdir -p /etc/pipewire/pipewire.conf.d
sudo ln -s /usr/share/examples/wireplumber/10-wireplumber.conf /etc/pipewire/pipewire.conf.d/
sudo ln -s /usr/share/examples/pipewire/20-pipewire-pulse.conf /etc/pipewire/pipewire.conf.d/

sleep 2
echo -e "\nSetting up User Directories"
xdg-user-dirs-update

sleep 2
echo -e "\nAdding basic configurations"
mkdir .wallpaper
wget -O ~/.wallpaper/wallpaper.jpg "https://unsplash.com/photos/05KFkDsxDjk/download?force=true&w=1920"
mkdir -p ~/.config/sway/scripts
cat > ~/.config/sway/config << 'EOF'

# Mod Key as SUPER
set $mod Mod4

# Main Terminal
set $term foot

# Main menu
set $menu rofi -show-icons -show drun

# Default Wallpaper
output * bg ~/.wallpaper/wallpaper.jpg fill

# Main Binds

# Terminal
bindsym $mod+Return exec $term

# Kill Window
bindsym $mod+q kill

# Exec Menu
bindsym $mod+space exec $menu

# Reload Sway
bindsym $mod+Shift+r reload

# Launch Exit Menu
bindsym $mod+Shift+e exec ~/.config/sway/scripts/exit.sh

# Launch Yazi (File Explorer)
bindsym $mod+e exec foot yazi

# Lauch Firefox
bindsym $mod+f exec firefox

# Basic workspaces
bindsym $mod+1 workspace number 1
bindsym $mod+2 workspace number 2
bindsym $mod+3 workspace number 3
bindsym $mod+4 workspace number 4
bindsym $mod+5 workspace number 5

bindsym $mod+Shift+1 move container to workspace number 1
bindsym $mod+Shift+2 move container to workspace number 2
bindsym $mod+Shift+3 move container to workspace number 3
bindsym $mod+Shift+4 move container to workspace number 4
bindsym $mod+Shift+5 move container to workspace number 5

# Layouts
bindsym $mod+w layout toggle tabbed 
bindsym $mod+e layout toggle split

# Fullscreen
$mod+Shift+f toggle fullscreen

# Resizing
bindsym $mod+Shift+l resize shrink width 20px
bindsym $mod+Shift+h resize grow width 20px
bindsym $mod+Shift+k resize grow height 20px
bindsym $mod+Shift+j resize shrink height 20px

# Focus
bindsym $mod+l focus right
bindsym $mod+h focus left 
bindsym $mod+k focus up 
bindsym $mod+j focus down 

# Basic Status Bar
bar {
	position top
	status_command ~/.config/sway/scripts/bar.sh
	colors {
		 statusline #ffffff
		 background #323232
		 inactive_workspace #32323200 #32323200 #5c5c5c
	}
}

# Startup
exec pipewire &
exec autotiling &
exec --no-startup-id dbus-update-activation-environment --all &

# Input
input "type:keyboard" {
	xkb_layout "us"
	xkb_variant "intl"
}

input "type:pointer" {
	accel_profiles "flat"
	pointer_accel 0
}

gaps inner 7
gaps outer 7
for_window [class="^.*"] border pixel 2


include /etc/sway/config.d/*

EOF

cat > ~/.config/sway/scripts/exit.sh << 'EOF' 
#!/bin/bash

options="Logout\nLock Screen\nSuspend\nReboot\nShutdow"
choice=$(echo -e "$options" | rofi -dmenu -p -i "Option" -theme-str 'window {width:15%;} listview {lines:5;}')

case "$choice" in 
	"Logout")
		swaymsg exit
		;;
	"Lock Screen")
		swaylock
		;;
	"Suspend")
		loginctl suspend
		;;
	"Reboot")
		loginctl reboot
		;;
	"Shutdow")
		loginctl shutdown
		;;
esac
EOF

cat > ~/.config/sway/scripts/bar.sh << 'EOF'
#!/bin/bash

while true; do
    # CPU - via /proc/stat
    cpu=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {printf "%.0f%%", usage}')
    
    # MEM - via /proc/meminfo 
    mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    mem_avail=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    mem_used=$((mem_total - mem_avail))
    mem_percent=$((mem_used * 100 / mem_total))
    mem_used_mb=$((mem_used / 1024))
    mem_total_mb=$((mem_total / 1024))
    mem="${mem_used_mb}M/${mem_total_mb}M (${mem_percent}%)"
    
    # TEMP
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        temp=$(( $(cat /sys/class/thermal/thermal_zone0/temp) / 1000 ))
        temp_display="${temp}°C"
    else
        temp_display="N/A"
    fi
    
    # ROOT
    root=$(df -h / | awk 'NR==2 {print $4 "/" $2 " (" $5 ")"}')
    
    echo " : $cpu |  : $mem_percent% |  : $temp_display | $(date '+%d/%m/%Y %H:%M')"
    sleep 1
done
EOF

sleep 2
echo -e "\nConfiguring Login Session"
cat > ~/.bash_profile << 'EOF'
#.bash_profile

if [ -z $DISPLAY ] && [ "$(tty)" == "/dev/tty1" ] ; then
	exec dbus-run-session sway
fi

[ -f $HOME/.bashrc ] && . $HOME/.bashrc
EOF

echo -e "\nFinishing setup. Restarting..."
sleep 2
sudo shutdown -r now

