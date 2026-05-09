# PATH
export PATH="$HOME/.local/bin:$PATH"

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="gnzh"
plugins=(aws direnv gh git nvm)
COMPLETION_WAITING_DOTS="true"

# Lazy-load nvm via the omz plugin for faster shell startup.
# https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/nvm#lazy-startup
zstyle ':omz:plugins:nvm' autoload yes

source $ZSH/oh-my-zsh.sh

# Per-context aliases and env vars are loaded from $ZSH_CUSTOM/*.zsh
# (auto-sourced by oh-my-zsh above).

# Editor
alias vsc="code ."

# Git
alias gc="git commit -m"
alias gca="git commit -a -m"
alias gp="git push origin HEAD"
alias gpu="git pull origin"
alias gst="git status"
alias glog="git log --graph --topo-order --pretty='%w(100,0,6)%C(yellow)%h%C(bold)%C(black)%d %C(cyan)%ar %C(green)%an%n%C(bold)%C(white)%s %N' --abbrev-commit"
alias gdiff="git diff"
alias gco="git checkout"
alias gb='git branch'
alias gba='git branch -a'
alias gadd='git add'
alias ga='git add -p'
alias gcoall='git checkout -- .'
alias gr='git remote'
alias gre='git reset'

# Dirs
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."

# Docker
alias dco="docker compose"
alias dps="docker ps"
alias dpa="docker ps -a"
alias dl="docker ps -l -q"
alias dx="docker exec -it"

# Misc
alias cl='clear'
