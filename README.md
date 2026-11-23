# dotfiles

Mon `.zshrc` portable (macOS / Linux / WSL).

## Installation sur une nouvelle machine

```sh
git clone https://github.com/<toi>/dotfiles ~/dotfiles
~/dotfiles/install.sh
exec zsh
```

Au premier lancement, zinit et les plugins s'installent tout seuls (il faut juste `git`).

## Outils optionnels (activés automatiquement s'ils sont présents)

| Outil | Rôle |
|---|---|
| `fzf` | Ctrl-R historique, Ctrl-T fichiers, Alt-C dossiers, complétion Tab |
| `zoxide` | `z projet` pour sauter dans un dossier |
| `eza` | `ls` moderne avec icônes et statut git |
| `bat` | `cat` avec coloration |
| `fd`, `ripgrep` | recherche rapide |
| `starship` | prompt (sinon un prompt maison avec git s'affiche) |
| `direnv`, `mise` | variables / versions par projet |

```sh
# macOS
brew install fzf zoxide eza bat fd ripgrep starship
# Debian / Ubuntu
sudo apt install fzf zoxide eza bat fd-find ripgrep
```

## Réglages par machine et secrets

Tout ce qui est propre à une machine (tokens, alias pro…) va dans `~/.zshrc.local`, qui est chargé en dernier et **n'est jamais commité**.

## Commandes utiles

- `reload` : recharge le shell
- `zupdate` : met à jour zinit et les plugins
- `ZPROF=1 zsh -i -c exit` : mesure le temps de démarrage
