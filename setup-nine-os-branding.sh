#!/bin/bash
# ================================================================
#  Nine OS — Script de Branding Completo
#  Configura: Plymouth boot, SDDM login, KDE wallpapers
#
#  Uso: sudo bash setup-nine-os-branding.sh
# ================================================================
set -euo pipefail

# ── Caminhos ────────────────────────────────────────────────────
# SUDO_USER é definido pelo sudo; se vazio, tenta logname como fallback
_REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo $USER)}"
NINE_IMAGES="/home/$_REAL_USER/nineimages"
PLYMOUTH_DIR="/usr/share/plymouth/themes/nine-os"
WALLPAPER_DIR="/usr/share/wallpapers/nine-os"

# ── Helpers ─────────────────────────────────────────────────────
RED='\033[0;31m'; GRN='\033[0;32m'; YLW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "\n${GRN}==>${NC} $*"; }
warn() { echo -e "${YLW}[!]${NC} $*"; }
err()  { echo -e "${RED}[ERRO]${NC} $*"; exit 1; }
ok()   { echo -e "    ${GRN}✓${NC} $*"; }

# ================================================================
# 0. Pré-checks
# ================================================================
[[ $EUID -ne 0 ]] && err "Execute como root: sudo bash $0"

log "Verificando arquivos em $NINE_IMAGES ..."
[[ -f "$NINE_IMAGES/logo.png"  ]]              || err "logo.png não encontrado em $NINE_IMAGES"
[[ -f "$NINE_IMAGES/title.png" ]]              || err "title.png não encontrado em $NINE_IMAGES"
[[ -f "$NINE_IMAGES/stoneriver_glassnine.png" ]] || err "stoneriver_glassnine.png não encontrado"
# stoneriver_lock pode ter qualquer extensão (.png, .jpg, sem extensão…)
LOCK_SRC=$(compgen -G "$NINE_IMAGES/stoneriver_lock*" | head -n1 || true)
[[ -n "$LOCK_SRC" ]] || err "stoneriver_lock não encontrado em $NINE_IMAGES (verifique o nome com: ls ~/nineimages/)"
ok "Todos os arquivos encontrados"

command -v plymouth-set-default-theme &>/dev/null \
    || err "Plymouth não instalado. Execute: paru -S plymouth plymouth-theme-spinner"

# ================================================================
# 1. TEMA PLYMOUTH
# ================================================================
log "Criando tema Plymouth 'nine-os' ..."
mkdir -p "$PLYMOUTH_DIR"

# Copiar logo e título
cp "$NINE_IMAGES/logo.png"  "$PLYMOUTH_DIR/logo.png"
cp "$NINE_IMAGES/title.png" "$PLYMOUTH_DIR/title.png"
ok "logo.png e title.png copiados"

# Gerar dot.png (bolinha branca 18×18 com transparência)
python3 - <<'PYEOF'
import sys, os
out = '/usr/share/plymouth/themes/nine-os/dot.png'
try:
    from PIL import Image, ImageDraw
    img = Image.new('RGBA', (18, 18), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.ellipse([0, 0, 17, 17], fill=(255, 255, 255, 255))
    img.save(out)
    print("    \033[0;32m✓\033[0m dot.png gerado via Pillow")
except ImportError:
    try:
        import subprocess
        subprocess.run([
            'convert', '-size', '18x18', 'xc:transparent',
            '-fill', 'white', '-draw', 'circle 9,9 9,1', out
        ], check=True)
        print("    \033[0;32m✓\033[0m dot.png gerado via ImageMagick")
    except Exception as e:
        sys.exit(f"Instale python-pillow (pip install Pillow) ou imagemagick: {e}")
PYEOF

# ── nine-os.plymouth ────────────────────────────────────────────
cat > "$PLYMOUTH_DIR/nine-os.plymouth" <<'EOF'
[Plymouth Theme]
Name=Nine OS
Description=Nine OS Boot Screen
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/nine-os
ScriptFile=/usr/share/plymouth/themes/nine-os/nine-os.script
EOF
ok "nine-os.plymouth criado"

# ── nine-os.script (linguagem nativa Plymouth) ──────────────────
cat > "$PLYMOUTH_DIR/nine-os.script" <<'PLYSCRIPT'
# ── Nine OS Plymouth Boot Script ──────────────────────────────
# Fundo preto total
Window.SetBackgroundTopColor(0, 0, 0);
Window.SetBackgroundBottomColor(0, 0, 0);

screen_w = Window.GetWidth();
screen_h = Window.GetHeight();
center_x = Math.Int(screen_w / 2);
center_y = Math.Int(screen_h / 2);

# ── Emblema (logo circular) ────────────────────────────────────
raw_logo = Image("logo.png");
logo_src_w = raw_logo.GetWidth();
logo_src_h = raw_logo.GetHeight();

target_logo_w = 180;
target_logo_h = Math.Int(target_logo_w * logo_src_h / logo_src_w);
logo_img = raw_logo.Scale(target_logo_w, target_logo_h);
logo_spr = Sprite(logo_img);

logo_x = center_x - Math.Int(target_logo_w / 2);
logo_y = center_y - Math.Int(target_logo_h / 2) - 30;
logo_spr.SetPosition(logo_x, logo_y, 1);
logo_spr.SetOpacity(1.0);

# ── Ponto piscante (progresso) ─────────────────────────────────
dot_img = Image("dot.png");
dot_w = dot_img.GetWidth();
dot_h = dot_img.GetHeight();
dot_spr = Sprite(dot_img);

dot_x = center_x - Math.Int(dot_w / 2);
dot_y = logo_y + target_logo_h + 88;
dot_spr.SetPosition(dot_x, dot_y, 2);
dot_spr.SetOpacity(1.0);

# ── Animação de piscar ─────────────────────────────────────────
# Plymouth roda ~50 fps — 25 frames ON / 25 frames OFF ≈ 0.5 s por fase
frame = 0;
CYCLE = 50;
HALF  = 25;

fun refresh_callback() {
    frame = frame + 1;
    phase = frame % CYCLE;
    if (phase < HALF) {
        dot_spr.SetOpacity(1.0);
    } else {
        dot_spr.SetOpacity(0.08);
    }
}

Plymouth.SetRefreshFunction(refresh_callback);
PLYSCRIPT
ok "nine-os.script criado"

# ================================================================
# 2. ATIVAR TEMA E HOOKS
# ================================================================
log "Ativando tema Plymouth 'nine-os' ..."
plymouth-set-default-theme nine-os
ok "Tema definido como padrão"

# Adicionar hook plymouth no mkinitcpio.conf (depois de udev)
MKINIT="/etc/mkinitcpio.conf"
log "Verificando hooks do mkinitcpio ..."
if grep -q "^HOOKS=" "$MKINIT"; then
    if ! grep -q "plymouth" "$MKINIT"; then
        sed -i 's/\(HOOKS=([^)]*udev\)/\1 plymouth/' "$MKINIT"
        ok "Hook 'plymouth' adicionado após 'udev'"
    else
        ok "Hook 'plymouth' já presente"
    fi
fi

# ================================================================
# 3. PARÂMETROS DO KERNEL (quiet splash)
# ================================================================
log "Adicionando 'quiet splash' ao bootloader ..."

if [[ -f /etc/default/grub ]]; then
    if ! grep -q "splash" /etc/default/grub; then
        sed -i \
          's/GRUB_CMDLINE_LINUX_DEFAULT="\([^"]*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 quiet splash"/' \
          /etc/default/grub
        grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null
        ok "GRUB atualizado com quiet splash"
    else
        ok "GRUB já contém splash"
    fi
elif ls /boot/loader/entries/*.conf &>/dev/null 2>&1; then
    PATCHED=0
    for entry in /boot/loader/entries/*.conf; do
        if grep -q "^options" "$entry" && ! grep -q "splash" "$entry"; then
            sed -i 's/^options .*/& quiet splash/' "$entry"
            ok "systemd-boot: splash adicionado em $(basename $entry)"
            PATCHED=1
        fi
    done
    [[ $PATCHED -eq 0 ]] && ok "systemd-boot já contém splash"
else
    warn "Bootloader não detectado. Adicione 'quiet splash' aos parâmetros do kernel manualmente."
fi

# ================================================================
# 4. REBUILD INITRAMFS
# ================================================================
log "Reconstruindo initramfs (pode demorar ~30s) ..."
mkinitcpio -P
ok "Initramfs reconstruído"

# ================================================================
# 5. WALLPAPERS
# ================================================================
log "Copiando wallpapers para $WALLPAPER_DIR ..."
mkdir -p "$WALLPAPER_DIR"

# Desktop
cp "$NINE_IMAGES/stoneriver_glassnine.png" "$WALLPAPER_DIR/"
ok "stoneriver_glassnine.png → desktop"

# Lock / Login — usa LOCK_SRC detectado lá em cima (preserva extensão)
LOCK_BASENAME="$(basename "$LOCK_SRC")"
if [[ -d "$LOCK_SRC" ]]; then
    cp -r "$LOCK_SRC" "$WALLPAPER_DIR/"
else
    cp "$LOCK_SRC" "$WALLPAPER_DIR/"
fi
LOCK_PATH="$WALLPAPER_DIR/$LOCK_BASENAME"
ok "stoneriver_lock → $LOCK_PATH"

DESKTOP_PATH="$WALLPAPER_DIR/stoneriver_glassnine.png"

# ================================================================
# 6. SDDM (tela de login)
# ================================================================
log "Configurando SDDM ..."
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/nine-os.conf <<EOF
[Theme]
Background=$LOCK_PATH
EOF
ok "SDDM background → $LOCK_PATH"

# ================================================================
# 7. KDE — padrões para novos usuários (/etc/skel)
# ================================================================
log "Configurando padrões KDE no /etc/skel ..."
mkdir -p /etc/skel/.config

# Tela de bloqueio
cat > /etc/skel/.config/kscreenlockerrc <<EOF
[Greeter][Wallpaper][org.kde.image][General]
Image=file://$LOCK_PATH
EOF
ok "kscreenlockerrc → $LOCK_PATH"

# Wallpaper da área de trabalho
# Containments 1 e 2 cobrem os casos mais comuns de ID de desktop
cat > /etc/skel/.config/plasma-org.kde.plasma.desktop-appletsrc <<EOF
[Containments][1][Wallpaper][org.kde.image][General]
Image=file://$DESKTOP_PATH

[Containments][2][Wallpaper][org.kde.image][General]
Image=file://$DESKTOP_PATH
EOF
ok "Wallpaper padrão → $DESKTOP_PATH"

# ================================================================
# 8. APLICAR NO USUÁRIO ATUAL
# ================================================================
CURRENT_USER="${SUDO_USER:-}"
if [[ -n "$CURRENT_USER" ]]; then
    USER_HOME="/home/$CURRENT_USER"
    USER_UID="$(id -u "$CURRENT_USER")"
    log "Aplicando configurações para o usuário '$CURRENT_USER' ..."

    mkdir -p "$USER_HOME/.config"

    # Lock screen para usuário atual
    cat > "$USER_HOME/.config/kscreenlockerrc" <<EOF
[Greeter][Wallpaper][org.kde.image][General]
Image=file://$LOCK_PATH
EOF
    chown "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.config/kscreenlockerrc"
    ok "Lock screen configurado"

    # Wallpaper da área de trabalho em tempo real (se sessão KDE ativa)
    DBUS_ADDR="unix:path=/run/user/$USER_UID/bus"
    if sudo -u "$CURRENT_USER" DBUS_SESSION_BUS_ADDRESS="$DBUS_ADDR" \
        plasma-apply-wallpaperimage "$DESKTOP_PATH" 2>/dev/null; then
        ok "Wallpaper do desktop aplicado agora!"
    else
        warn "Sessão KDE não detectada. O wallpaper será aplicado no próximo login."
        # Fallback: script de autostart que roda no primeiro login
        mkdir -p "$USER_HOME/.config/autostart"
        cat > "$USER_HOME/.config/autostart/nine-os-wallpaper.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Nine OS Wallpaper
Exec=bash -c 'plasma-apply-wallpaperimage $DESKTOP_PATH && rm -- ~/.config/autostart/nine-os-wallpaper.desktop'
X-KDE-autostart-phase=2
OnlyShowIn=KDE;
EOF
        chown -R "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/.config/autostart"
        ok "Autostart criado — wallpaper será aplicado no próximo login"
    fi
fi

# ================================================================
# Resumo final
# ================================================================
echo ""
echo -e "${GRN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GRN}║     Nine OS — Branding Aplicado com Sucesso!    ║${NC}"
echo -e "${GRN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo "  🔵 Plymouth   → tema 'nine-os' (emblema + bolinha piscando)"
echo "  🔵 SDDM       → $LOCK_PATH"
echo "  🔵 Lock screen → $LOCK_PATH"
echo "  🔵 Desktop    → $DESKTOP_PATH"
echo ""
echo -e "  ${YLW}Reinicie para ver o novo boot:${NC} sudo reboot"
echo ""
