#!/usr/bin/env bash

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

CONFIG_DIRS=(
  "Thunar"
  "fish"
  "gtk-3.0"
  "gtk-4.0"
  "hypr"
  "kitty"
  "rofi"
  "shelly"
  "swaync"
  "waybar"
  "waypaper"
)

PACMAN_PACKAGES=(
  git
  base-devel
  fish
  kitty
  hyprland
  hyprpaper
  waybar
  rofi-wayland
  swaync
  thunar
  gtk3
  gtk4
  xdg-desktop-portal-hyprland
  qt5-wayland
  qt6-wayland
  pipewire
  pipewire-pulse
  wireplumber
  pavucontrol
  grim
  slurp
  wl-clipboard
  brightnessctl
  playerctl
  network-manager-applet
  bluez
  bluez-utils
  ttf-jetbrains-mono-nerd
  noto-fonts
  noto-fonts-emoji
)

AUR_PACKAGES=(
  waypaper
  swww
)

echo "==> Instalando dotfiles do guiv0"
echo "==> Pasta do repo: $REPO_DIR"

if ! command -v pacman >/dev/null 2>&1; then
  echo "Erro: esse instalador foi feito para Arch/CachyOS/Manjaro."
  exit 1
fi

echo "==> Atualizando sistema e instalando pacotes oficiais..."
sudo pacman -Syu --needed --noconfirm "${PACMAN_PACKAGES[@]}"

install_yay() {
  if command -v yay >/dev/null 2>&1; then
    echo "==> yay já instalado."
    return
  fi

  echo "==> Instalando yay..."
  tmpdir="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
  cd "$tmpdir/yay"
  makepkg -si --noconfirm
  cd "$REPO_DIR"
  rm -rf "$tmpdir"
}

install_yay

echo "==> Instalando pacotes AUR..."
yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"

echo "==> Criando backup das configs antigas..."
mkdir -p "$BACKUP_DIR"
mkdir -p "$HOME/.config"

for dir in "${CONFIG_DIRS[@]}"; do
  target="$HOME/.config/$dir"

  if [ -e "$target" ] || [ -L "$target" ]; then
    mkdir -p "$BACKUP_DIR/.config"
    mv "$target" "$BACKUP_DIR/.config/$dir"
    echo "Backup: $target -> $BACKUP_DIR/.config/$dir"
  fi
done

echo "==> Linkando configs..."

for dir in "${CONFIG_DIRS[@]}"; do
  source="$REPO_DIR/$dir"
  target="$HOME/.config/$dir"

  if [ -d "$source" ]; then
    ln -sfn "$source" "$target"
    echo "Linkado: $target -> $source"
  else
    echo "Aviso: pasta não encontrada no repo: $dir"
  fi
done

echo "==> Definindo fish como shell padrão, se instalado..."

if command -v fish >/dev/null 2>&1; then
  fish_path="$(command -v fish)"

  if ! grep -q "$fish_path" /etc/shells; then
    echo "$fish_path" | sudo tee -a /etc/shells
  fi

  chsh -s "$fish_path" || true
fi

echo ""
echo "==> Finalizado."
echo "Backup salvo em: $BACKUP_DIR"
echo "Reinicie a sessão pra Hyprland/Waybar/fish carregarem direito."
