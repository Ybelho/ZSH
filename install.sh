#!/usr/bin/env bash
# Installe le .zshrc de ce repo via un lien symbolique.
# Usage :
#   git clone https://github.com/<toi>/dotfiles ~/dotfiles && ~/dotfiles/install.sh
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$HOME/.zshrc"

if ! command -v zsh >/dev/null 2>&1; then
  echo "⚠  zsh n'est pas installé. Installe-le d'abord :"
  echo "   macOS  : brew install zsh (déjà présent par défaut)"
  echo "   Debian : sudo apt install zsh"
  echo "   Fedora : sudo dnf install zsh"
  echo "   Arch   : sudo pacman -S zsh"
  exit 1
fi

# Sauvegarde l'ancien .zshrc s'il existe et n'est pas déjà notre lien
if [[ -e "$TARGET" && ! -L "$TARGET" ]]; then
  backup="$TARGET.backup.$(date +%Y%m%d-%H%M%S)"
  mv "$TARGET" "$backup"
  echo "→ Ancien .zshrc sauvegardé dans $backup"
fi

ln -sfn "$DOTFILES/.zshrc" "$TARGET"
echo "✓ $TARGET → $DOTFILES/.zshrc"

# Fichier local pour les secrets (jamais commité)
if [[ ! -f "$HOME/.zshrc.local" ]]; then
  cat > "$HOME/.zshrc.local" <<'EOF'
# Réglages propres à cette machine — NE PAS COMMITER
# export GITHUB_TOKEN=...
# alias work='cd ~/projets/boulot'
EOF
  echo "✓ ~/.zshrc.local créé (pour tes secrets et réglages machine)"
fi

# Propose de faire de zsh le shell par défaut
if [[ "${SHELL##*/}" != "zsh" ]]; then
  read -r -p "Faire de zsh ton shell par défaut ? [o/N] " ans
  if [[ "$ans" =~ ^[oOyY]$ ]]; then
    chsh -s "$(command -v zsh)"
    echo "✓ Shell changé (effectif à la prochaine connexion)"
  fi
fi

echo
echo "Terminé. Lance 'exec zsh' : les plugins s'installent au premier démarrage."
echo "Outils optionnels recommandés : fzf zoxide eza bat fd ripgrep starship"
