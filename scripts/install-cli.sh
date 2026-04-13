#!/bin/bash
# Installe la commande `prm` pour lancer Prism depuis le terminal
set -e

cd "$(dirname "$0")/.."

INSTALL_DIR="/usr/local/bin"
CMD_NAME="prm"

echo "Installation de la commande '${CMD_NAME}'..."

# Compiler si nécessaire
if [ ! -f bin/prism ]; then
  echo "Compilation..."
  crystal build src/prism.cr -o bin/prism
fi

# Créer le wrapper
cat > "${INSTALL_DIR}/${CMD_NAME}" << 'SCRIPT'
#!/bin/bash
# Prism — AsciiDoc Editor
# Usage: prm [fichier.adoc | dossier]

PRISM_BIN=""

# Chercher le binaire
if [ -f "/Applications/Prism.app/Contents/MacOS/Prism" ]; then
  PRISM_BIN="/Applications/Prism.app/Contents/MacOS/Prism"
elif command -v prism &> /dev/null; then
  PRISM_BIN="$(command -v prism)"
elif [ -f "$HOME/prod-aloli/prism/bin/prism" ]; then
  PRISM_BIN="$HOME/prod-aloli/prism/bin/prism"
fi

if [ -z "$PRISM_BIN" ]; then
  echo "Erreur : binaire Prism introuvable."
  echo "Installez Prism.app dans /Applications ou compilez le projet."
  exit 1
fi

exec "$PRISM_BIN" "$@"
SCRIPT

chmod +x "${INSTALL_DIR}/${CMD_NAME}"

echo "Installé : ${INSTALL_DIR}/${CMD_NAME}"
echo ""
echo "Usage :"
echo "  prm                  # Nouveau document"
echo "  prm fichier.adoc     # Ouvrir un fichier"
echo "  prm .                # Ouvrir le premier .adoc du dossier"
echo "  prm ~/docs/          # Ouvrir le premier .adoc du dossier"
