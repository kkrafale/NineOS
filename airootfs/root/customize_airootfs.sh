#!/bin/bash
set -e

# lsb-release pós-instalação (evita conflito com pacote)
cat > /etc/lsb-release << 'EOF'
DISTRIB_ID=NineOS
DISTRIB_RELEASE=1.0
DISTRIB_CODENAME=stone-river
DISTRIB_DESCRIPTION="NineOS 1.0 (Stone River)"
EOF

# Criar usuário live
if ! id nineuser &>/dev/null; then
    useradd -m -G wheel,audio,video,storage,optical,network \
        -s /bin/bash -c "Nine Live" nineuser
fi
echo "nineuser:nineos" | chpasswd
passwd -d nineuser

# Sudo sem senha
echo "nineuser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/nineuser
chmod 440 /etc/sudoers.d/nineuser

# Copiar configs do skel para nineuser
cp -r /etc/skel/. /home/nineuser/
chown -R nineuser:nineuser /home/nineuser/
chmod 700 /home/nineuser

echo "customize_airootfs.sh OK"
