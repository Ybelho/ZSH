# ==============================================================================
#  .zshrc portable — macOS / Linux / WSL
#  - S'auto-installe (zinit + plugins) au premier lancement, il faut juste git
#  - Active les outils modernes seulement s'ils sont installés (fzf, zoxide, eza…)
#  - Les réglages propres à une machine et les secrets vont dans ~/.zshrc.local
#    (ce fichier n'est PAS versionné)
# ==============================================================================

# --- Profilage optionnel : ZPROF=1 zsh -i -c exit ------------------------------
[[ -n "$ZPROF" ]] && zmodload zsh/zprof

# --- Variables de base ---------------------------------------------------------
export EDITOR="${EDITOR:-$(command -v nvim || command -v vim || echo vi)}"
export VISUAL="$EDITOR"
export PAGER="${PAGER:-less}"
export LESS='-R -F -i -M -X'
export LANG="${LANG:-en_US.UTF-8}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# --- PATH (sans doublons, seuls les dossiers existants sont ajoutés) ------------
typeset -U path fpath
_prepend_path() { [[ -d "$1" ]] && path=("$1" $path) }
_prepend_path /usr/local/bin
_prepend_path /opt/homebrew/bin          # Homebrew Apple Silicon
_prepend_path /home/linuxbrew/.linuxbrew/bin
_prepend_path "$HOME/.cargo/bin"
_prepend_path "$HOME/go/bin"
_prepend_path "$HOME/.local/bin"
_prepend_path "$HOME/bin"
unfunction _prepend_path

# Homebrew (variables d'environnement)
if command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv 2>/dev/null)"
fi

# --- Historique ----------------------------------------------------------------
mkdir -p "$XDG_STATE_HOME/zsh" "$XDG_CACHE_HOME/zsh"
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY          # horodatage
setopt SHARE_HISTORY             # partagé entre terminaux
setopt HIST_IGNORE_ALL_DUPS      # supprime les anciens doublons
setopt HIST_IGNORE_SPACE         # " commande" = pas enregistrée (pratique pour les secrets)
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY               # !! affiche avant d'exécuter
setopt HIST_FIND_NO_DUPS

# --- Options du shell ----------------------------------------------------------
setopt AUTO_CD                   # "dossier" suffit pour y aller
setopt AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT
setopt EXTENDED_GLOB
setopt GLOB_DOTS                 # inclut les fichiers cachés dans les globs
setopt INTERACTIVE_COMMENTS      # autorise les # en interactif
setopt NO_BEEP
setopt NO_FLOW_CONTROL           # libère Ctrl-S / Ctrl-Q
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END

# --- Gestionnaire de plugins : zinit (auto-installé) --------------------------
ZINIT_HOME="$XDG_DATA_HOME/zinit/zinit.git"
if [[ ! -f "$ZINIT_HOME/zinit.zsh" ]]; then
  if command -v git >/dev/null 2>&1; then
    print -P "%F{33}▓▒░ Installation de zinit…%f"
    mkdir -p "${ZINIT_HOME:h}"
    git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" \
      && print -P "%F{34}▓▒░ zinit installé%f" \
      || print -P "%F{160}▓▒░ Échec de l'installation de zinit%f"
  fi
fi

if [[ -f "$ZINIT_HOME/zinit.zsh" ]]; then
  source "$ZINIT_HOME/zinit.zsh"

  # Complétions supplémentaires (avant compinit)
  zinit light zsh-users/zsh-completions

  # Initialisation de la complétion (cache rafraîchi une fois par jour)
  autoload -Uz compinit
  _zcompdump="$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"
  if [[ -n $_zcompdump(#qN.mh+24) || ! -f $_zcompdump ]]; then
    compinit -d "$_zcompdump"
  else
    compinit -C -d "$_zcompdump"
  fi
  unset _zcompdump
  zinit cdreplay -q

  # Plugins (ordre important : syntax-highlighting en dernier)
  zinit light Aloxaf/fzf-tab                         # complétion via fzf
  zinit light zsh-users/zsh-autosuggestions          # suggestions grisées
  zinit light zsh-users/zsh-history-substring-search # ↑/↓ filtrés
  zinit light zdharma-continuum/fast-syntax-highlighting

  # Quelques snippets Oh My Zsh utiles, sans charger tout OMZ
  zinit snippet OMZP::sudo          # Échap x2 = ajoute sudo
  zinit snippet OMZP::extract       # extract fichier.(zip|tar.gz|…)
else
  # Repli sans zinit
  autoload -Uz compinit && compinit -d "$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"
fi

# --- Style de complétion -------------------------------------------------------
zmodload zsh/complist
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no                    # fzf-tab gère le menu
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':fzf-tab:*' switch-group '<' '>'
if command -v eza >/dev/null 2>&1; then
  zstyle ':fzf-tab:complete:(cd|z|__zoxide_z):*' fzf-preview 'eza -1 --color=always --icons $realpath'
else
  zstyle ':fzf-tab:complete:(cd|z|__zoxide_z):*' fzf-preview 'ls -1 --color=always $realpath 2>/dev/null || ls -1 $realpath'
fi

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=40

# --- Raccourcis clavier --------------------------------------------------------
bindkey -e                                    # mode emacs (mettre -v pour vi)
bindkey '^[[A' history-substring-search-up    # ↑
bindkey '^[[B' history-substring-search-down  # ↓
bindkey '^P'   history-substring-search-up
bindkey '^N'   history-substring-search-down
bindkey '^[[1;5C' forward-word                # Ctrl →
bindkey '^[[1;5D' backward-word               # Ctrl ←
bindkey '^[[H'  beginning-of-line             # Début
bindkey '^[[F'  end-of-line                   # Fin
bindkey '^[[3~' delete-char                   # Suppr
bindkey '^ '    autosuggest-accept            # Ctrl-Espace accepte la suggestion
autoload -Uz edit-command-line && zle -N edit-command-line
bindkey '^X^E' edit-command-line              # éditer la commande dans $EDITOR

# --- Intégrations d'outils (activées seulement si présents) -------------------
_has() { command -v "$1" >/dev/null 2>&1 }

# fzf : Ctrl-R historique, Ctrl-T fichiers, Alt-C dossiers
if _has fzf; then
  if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)
  else
    for f in /usr/share/fzf/key-bindings.zsh /usr/share/doc/fzf/examples/key-bindings.zsh \
             "$HOME/.fzf.zsh"; do
      [[ -f $f ]] && source "$f" && break
    done
  fi
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline'
  if _has fd; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi
  _has bat && export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 {}'"
fi

_has zoxide && eval "$(zoxide init zsh)"          # z dossier / zi interactif
_has direnv && eval "$(direnv hook zsh)"          # .envrc par projet
_has mise   && eval "$(mise activate zsh)"        # versions node/python/…

# --- Alias ---------------------------------------------------------------------
# ls
if _has eza; then
  alias ls='eza --group-directories-first --icons=auto'
  alias ll='eza -lh --git --group-directories-first --icons=auto'
  alias la='eza -lah --git --group-directories-first --icons=auto'
  alias lt='eza --tree --level=2 --icons=auto'
else
  if ls --color=auto >/dev/null 2>&1; then
    alias ls='ls --color=auto --group-directories-first'
  else
    alias ls='ls -G'   # macOS / BSD
  fi
  alias ll='ls -lh'
  alias la='ls -lAh'
fi

# cat / grep
_has bat    && alias cat='bat --paging=never'
_has batcat && ! _has bat && alias cat='batcat --paging=never' bat='batcat'
_has fdfind && ! _has fd  && alias fd='fdfind'
alias grep='grep --color=auto'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'
alias d='dirs -v | head -10'

# Sécurité
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
alias mkdir='mkdir -p'

# Git
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gco='git checkout'
alias gsw='git switch'
alias gb='git branch'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline --graph --decorate -20'
alias gla='git log --oneline --graph --decorate --all'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpl='git pull --rebase'
alias gst='git stash'
alias gstp='git stash pop'

# Divers
alias reload='exec zsh'
alias zshrc='$EDITOR ~/.zshrc'
alias path='print -l $path'
alias ports='lsof -i -P -n | grep LISTEN'
alias myip='curl -s https://ifconfig.me; echo'
alias h='history 1 | tail -30'
_has nvim && alias vim='nvim'
_has docker && alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'

# Alias globaux
alias -g G='| grep'
alias -g L='| less'
alias -g H='| head'
alias -g T='| tail'
alias -g NE='2>/dev/null'

# --- Fonctions -----------------------------------------------------------------
# Crée un dossier et y entre
mkcd() { mkdir -p -- "$1" && cd -- "$1" }

# Remonte de N dossiers : up 3
up() { local n=${1:-1}; cd "$(printf '../%.0s' {1..$n})" }

# Sauvegarde rapide d'un fichier : bak fichier -> fichier.bak.20261123-1530
bak() { cp -a -- "$1" "$1.bak.$(date +%Y%m%d-%H%M)" }

# Cherche un process
psg() { ps aux | grep -v grep | grep -i -- "$1" }

# Dossier temporaire jetable
tmpd() { cd "$(mktemp -d)" }

# Ouvre fichier/URL avec l'app par défaut, quel que soit l'OS
o() {
  if [[ "$OSTYPE" == darwin* ]]; then open "${@:-.}"
  elif _has wslview; then wslview "${@:-.}"
  else xdg-open "${@:-.}" >/dev/null 2>&1
  fi
}

# Met à jour les plugins zinit
zupdate() { zinit self-update && zinit update --all --parallel }

# --- Prompt --------------------------------------------------------------------
# Starship s'il est installé (https://starship.rs), sinon prompt maison avec git.
if _has starship; then
  eval "$(starship init zsh)"
else
  autoload -Uz vcs_info add-zsh-hook
  zstyle ':vcs_info:*' enable git
  zstyle ':vcs_info:git:*' check-for-changes true
  zstyle ':vcs_info:git:*' stagedstr '%F{green}+%f'
  zstyle ':vcs_info:git:*' unstagedstr '%F{yellow}*%f'
  zstyle ':vcs_info:git:*' formats ' %F{magenta} %b%f%c%u'
  zstyle ':vcs_info:git:*' actionformats ' %F{magenta} %b%f %F{red}(%a)%f%c%u'

  _prompt_timer_start() { _cmd_start=$EPOCHREALTIME }
  _prompt_precmd() {
    vcs_info
    _cmd_time=''
    if [[ -n $_cmd_start ]]; then
      local elapsed=$(( EPOCHREALTIME - _cmd_start ))
      (( elapsed > 3 )) && _cmd_time=" %F{yellow}${$(printf '%.1f' $elapsed)}s%f"
      unset _cmd_start
    fi
  }
  zmodload zsh/datetime
  add-zsh-hook preexec _prompt_timer_start
  add-zsh-hook precmd  _prompt_precmd
  setopt PROMPT_SUBST

  # user@host affiché seulement en SSH
  _prompt_host=''
  [[ -n $SSH_CONNECTION ]] && _prompt_host='%F{cyan}%n@%m%f '

  PROMPT='
${_prompt_host}%F{blue}%~%f${vcs_info_msg_0_}${_cmd_time}
%(?.%F{green}.%F{red})❯%f '
  RPROMPT='%(?..%F{red}✘ %?%f)'
fi

unfunction _has 2>/dev/null

# --- Réglages locaux (non versionnés : secrets, tokens, alias pro…) -----------
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

[[ -n "$ZPROF" ]] && zprof
