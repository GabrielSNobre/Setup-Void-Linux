#!/bin/bash

# Caso script falhe, finaliza a execuçao
set -e

echo -e "======================================\n"
echo -e "===== SCRIPT DE SETUP VOID LINUX =====\n"
echo -e "======================================\n"

echo -e "Atualizando sistema...\n"
sudo xbps-install -Syu

echo -e "Adicionando repos extras...\n"
sudo xbps-install -Sy void-repo-multilib void-repo-nonfree void-repo-multilib-nonfree

echo -e "Instalando pacotes minimos...\n"
sudo xbps-install -Sy \
	i3 i3status \
	neovim \
	xorg-minimal \
	xinit \
	xf86-input-libinput \
	mesa-dri \
	mesa-vaapi \
	mesa-opencl \
	ripgrep \
	base-devel \
	git \
	wget \
	curl \
	dbus \
	elogind \
	polkit \
	wpa_gui \
	pipewire wireplumber pavucontrol \
	feh \
	xauth \
	alacritty \
	autotiling \
	rofi \
	picom \
	i3-lock

echo -e "\nInicializando serviços básicos..."
sudo ln -s /etc/sv/dbus /var/service
sudo ln -s /etc/sv/elogind /var/service
sudo ln -s /etc/sv/polkitd /var/service

echo -e "\nConfigurando servidor de audio..."
sudo mkdir -p /etc/pipewire/pipewire.conf.d
sudo ln -s /usr/share/examples/wireplumber/10-wireplumber.conf /etc/pipewire/pipewire.conf.d
sudo ln -s /usr/share/examples/pipewire/20-pipewire-pulse.conf /etc/pipewire/pipewire.conf.d

mkdir ~/.wallpaper
wget -O ~/.wallpaper/wallpaper.png "https://github.com/mngshm/voidwall/blob/main/assets/walls/5.png" &> /dev/null || echo "Falha no download do wallpaper"

echo -e "\nCriando scripts de inicializaçao.."
mkdir -p ~/.config/i3/scripts

cat > ~/.config/i3/config << 'EOF'
# Configuraçao simples para o i3
# Autor: Gabriel Nobre

# Tecla Modificadora Principal como Super(Windows)
set $mod Mod4

# Terminal
set $term alacritty

# Menu lançador de Apps
set $menu rofi -show -show-icons drun

# Fonte Padrão do i3, utiliza também a fonte basica do xorg
font pango:monospace 10

# Inicializaçao dos programas iniciais minimos

# Servidor de audio pipewire
exec --no-startup-id pipewire

# Wallpaper basico
exec_always --no-startup-id feh --bg-fill ~/.wallpaper/wallpaper.png

# Compositor de janelas, para remover tearing e dar transparencia às janelas
exec_always --no-startup-id picom

# Programa simples para ativar uma divisão mais dinâmica das janelas
exec_always --no-startup-id autotiling


# Binds básicas para uso do i3

bindsym $mod+Return exec $term				# Executa o Terminal
bindsym $mod+Space exec $menu				# Executa o Menu Lançador
bindsym $mod+q kill							# Mata a Janela
bindsym $mod+Shift+r i3-msg reload			# Reinicia o i3
bindsym $mod+Shift+Space floating toggle	# Deixa a janela em modo flutuante

# Abre o menu de saída do sistema
bindsym $mod+Shift+e exec ~/.config/i3/scripts/exit-menu.sh

# Define a tecla Super(Windows) como a controladora prinicipal das janelas
floating_modifier $mod

# Controle de Workspaces

# A definição do numero de workspaces é pessoal, mas para uso comum, 5 são suficientes
bindsym $mod+1 workspace number 1
bindsym $mod+2 workspace number 2
bindsym $mod+3 workspace number 3
bindsym $mod+4 workspace number 4
bindsym $mod+5 workspace number 5

# Configuraçao de redirecionamento de janelas para workspace específico
bindsym $mod+Shift+1 move container to workspace number 1
bindsym $mod+Shift+2 move container to workspace number 2
bindsym $mod+Shift+3 move container to workspace number 3
bindsym $mod+Shift+4 move container to workspace number 4
bindsym $mod+Shift+5 move container to workspace number 5

# Layouts
bindsym $mod+w layout toggle tabbed 	# Define o Layout das janelas como em Abas
bindsym $mod+e layout toggle split		# Define elas de volta para as janelas divididas
bindsym $mod+v split v					# Split Vertical
bindsym $mod+b split h					# Split Horinzontal


# Fullscreen
bindsym $mod+f fullscreen toggle

# Movimentação pelo sistema
bindsym $mod+l focus right
bindsym $mod+h focus left
bindsym $mod+k focus up
bindsym $mod+j focus down

# Cresce ou diminui as janelas
bindsym $mod+Shift+l resize shrink width 20px 	# Cresce para direita
bindsym $mod+Shift+h resize grow width 20px		# Cresce para esquerda


# Barra superior simples
bar {
	status_command i3status --config ~/.config/i3status/config
	position top
	mode dock
	workspace_buttons yes
	tray_output primary
	font pango:monospace 8
}

# Import de funcionamentos básicos para o i3
include /etc/i3/config.d/*
EOF

cat > ~/.config/i3/scripts/exit-menu.sh << 'EOF'
#!/bin/bash

options="  Logout\n  Bloquear\n  Suspender\n  Reiniciar\n  Sair"

choice=$(echo -e "$options" | rofi -dmenu -p "Sistema" -theme-str 'window {width: 15%;} listview {lines: 5;}')

case "$choice" in
    "  Sair")
        loginctl poweroff
        ;;
    "  Reiniciar")
        loginctl reboot
        ;;
    "  Bloquear")
        if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
            swaylock
        else
            i3lock
        fi
        ;;
    "  Suspender")
        loginctl suspend
        ;;
    "  Logout")
        if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
            swaymsg exit
        else
            i3-msg exit
        fi
        ;;
esac
EOF

sudo chmod +x ~/.config/i3/scripts/exit-menu.sh

mkdir ~/.config/picom
cat > ~/.config/picom/picom.conf << 'EOF'
# Sobra desativada
shadow = false

# Desativa desfoque
blur-method = "none"

# Opacidade
inactive-opacity = 1
active-opacity = 1
frame-opacity = 1

detect-client-opacity = true

# Vsync (previne screen tearing)
vsync = true

# Otimizações
use-damage = true
glx-swap-method = "undefined"
xrender-sync-fence = false
backend = "xrender"

# Exclusões de sombras
shadow-exclude = [
    "name = 'Notification'",
    "class_g = 'Conky'",
    "class_g ?= 'Notify-osd'",
    "class_g = 'Cairo-clock'"
]
EOF

mkdir ~/.config/i3status
cat > ~/.config/i3status/config << 'EOF'
general {
    colors = true
    interval = 1
}

order += "wireless _first_"
order += "volume master"
order += "cpu_temperature 0"
order += "cpu_usage"
order += "memory"
order += "load"
order += "disk /"
order += "tztime local"

wireless _first_ {
    format = "WIFI: %quality%% %essid"
    format_down = "WIFI: down"
}

volume master {
    format = "VOL: %volume"
    format_muted = "VOL: muted"
    mixer = "default"
    mixer_idx = 0
}

cpu_temperature 0 {
    format = "TEMP: %degrees°C"
    path = "/sys/class/thermal/thermal_zone0/temp"
}

cpu_usage {
    format = "CPU: %usage%%"
}

memory {
    format = "RAM: %used / %total"
    format_used = "RAM: %used"
    format_free = "RAM: free"
    threshold_degraded = "10%"
    format_degraded = "RAM: %free (FREE)"
}

load {
    format = "LOAD: %1min"
}

disk / {
    format = "HD: %free"
    format_used = "HD: %used"
    prefix_type = "binary"
}

tztime local {
    format = "%H:%M - %d/%m"
}
EOF

echo -e "\nConfigurando inicialização via TTY..."
cat > ~/.xinitrc << 'EOF'
#!/bin/bash

#Config do teclado
setxkbmap br abnt2
exec dbus-run-session i3
EOF

cat > ~/.bash_profile << 'EOF'
#!/bin/bash
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
	exec startx
fi

[ -f $HOME/.bashrc ] && . $HOME/.bashrc
EOF

sudo chmod +x ~/.xinitrc

echo -e "\n Configuraçoes finalizadas, reiniciando..."
sudo shutdown -r now
