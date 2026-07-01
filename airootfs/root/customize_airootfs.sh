#!/bin/bash

# Sobrescrever lsb-release DEPOIS que os pacotes foram instalados
cat > /etc/lsb-release << 'LSBEOF'
DISTRIB_ID=NineOS
DISTRIB_RELEASE=1.0
DISTRIB_CODENAME=stone-river
DISTRIB_DESCRIPTION="NineOS 1.0 (Stone River)"
LSBEOF

echo "lsb-release configurado com sucesso"
