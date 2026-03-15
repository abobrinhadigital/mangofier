#!/bin/bash

# 🔥 Script de Deploy do Pollux - "O Protetor dos Navegantes"
# Este script faz o git pull e reinicia os serviços no servidor remoto.

set -e # Pára se der erro, mestre. Murphy não pode vencer hoje.

echo "🚀 Iniciando a manobra de atualização no servidor..."

# --- 1. Mangofier ---
echo "🥭 Atualizando Mangofier..."
git pull

# Se o senhor mudar alguma biblioteca, o bundle se encarrega
echo "💎 Verificando dependências (bundle)..."
bundle install 

# Reinicia o serviço para o Listener carregar o código novo
echo "🥭 Reiniciando o listener do Mangofier..."
systemctl restart mangofier.service

echo "🏁 Tudo pronto, meu senhor. O Mangofier está atualizado e voando."
