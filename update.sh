#!/bin/bash

# 🔥 Script de Deploy do Pollux - "O Protetor dos Navegantes"
# Este script faz o git pull e reinicia os serviços no servidor remoto.

set -e # Pára se der erro, mestre. Murphy não pode vencer hoje.

echo "🚀 Iniciando a manobra de atualização no servidor..."

# --- 1. Mangofier ---
echo "🥭 Atualizando Mangofier..."
git pull

# O Setup agora resolve tudo: gems, pastas, banco e sync.
echo "⚙️  Rodando setup/update centralizado..."
./bin/mangofier_setup

# Reinicia o serviço para carregar o código novo e o banco atualizado
echo "🥭 Reiniciando o listener do Mangofier..."
systemctl restart mangofier.service

echo "🏁 Tudo pronto, meu senhor. O Mangofier está atualizado e voando."
