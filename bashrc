# https://github.com/segfault24/shell-config
# To kickstart a new system:
#   curl -f https://raw.githubusercontent.com/segfault24/shell-config/refs/heads/main/bashrc -o ~/.bashrc
#   source ~/.bashrc && update-shell-config

# Basically always install these: nano git gpg curl jq bash-completion
# Probably want these too: tmux az kubectl krew helm gh
# Love some krew plugins: ctx ns explore tree topology who-can stern score neat ingress-nginx

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# Self-update
update-shell-config() {
  mkdir -p ~/bin ~/.kube/ ~/.krew/bin
  [[ ! -f ~/.bashrc_local ]] && touch ~/.bashrc_local

  echo "Downloading bashrc"
  curl -sSf https://raw.githubusercontent.com/segfault24/shell-config/refs/heads/main/bashrc -o ~/.bashrc
  echo "Downloading nanorc"
  curl -sSf https://raw.githubusercontent.com/segfault24/shell-config/refs/heads/main/nanorc -o ~/.nanorc
  echo "Downloading toprc"
  curl -sSf https://raw.githubusercontent.com/segfault24/shell-config/refs/heads/main/toprc -o ~/.toprc
  if [[ "$(uname)" == "MINGW"* ]]; then
    echo "Downloading minttyrc"
    curl -sSf https://raw.githubusercontent.com/segfault24/shell-config/refs/heads/main/minttyrc -o ~/.minttyrc
  fi
  if [[ "$(uname)" == "Linux" ]]; then
    echo "Downloading complete_alias.sh"
    curl -sSf https://raw.githubusercontent.com/cykerway/complete-alias/refs/heads/master/complete_alias -o ~/.complete_alias.sh
  fi
  echo "Downloading git-prompt.sh"
  curl -sSf https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh -o ~/.git-prompt.sh
  echo "Downloading git-completion.bash"
  curl -sSf https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.git-completion.bash
  if command -v kubectl >/dev/null 2>&1; then
    echo "Generating kubectl-completion.bash.inc"
    kubectl completion bash > ~/.kube/kubectl-completion.bash.inc
  fi
  echo "Downloading kubectx"
  curl -sSf https://raw.githubusercontent.com/ahmetb/kubectx/refs/heads/master/kubectx -o ~/bin/kubectx
  chmod 750 ~/bin/kubectx
  echo "Downloading kubens"
  curl -sSf https://raw.githubusercontent.com/ahmetb/kubectx/refs/heads/master/kubens -o ~/bin/kubens
  chmod 750 ~/bin/kubens
  echo "Downloading kubectx-completion.bash.inc"
  curl -sSf https://raw.githubusercontent.com/ahmetb/kubectx/refs/heads/master/completion/kubectx.bash -o ~/.kube/kubectx-completion.bash.inc
  echo "Downloading kubens-completion.bash.inc"
  curl -sSf https://raw.githubusercontent.com/ahmetb/kubectx/refs/heads/master/completion/kubens.bash -o ~/.kube/kubens-completion.bash.inc

  source ~/.bashrc
}
clean-shell-config() {
  rm -f ~/.nanorc ~/.toprc ~/.minttyrc
  rm -f ~/.complete_alias.sh ~/.git-prompt.sh ~/.git-completion.bash
  rm -f ~/.kube/kubectl-completion.bash.inc
  rm -f ~/bin/kubectx ~/.kube/kubectx-completion.bash.inc
  rm -f ~/bin/kubens ~/.kube/kubens-completion.bash.inc
}

# Commands with common cross platform options
alias ..='cd ..'
alias ...='cd ../../'
alias ....='cd ../../../'
alias .....='cd ../../../../'
alias cd..='cd ..'
alias rm='rm -I'
alias h='history | tail -n 30'
alias j='jobs -l'
alias du='du -h'
alias df='df -Tha'
alias mkdir='mkdir -pv'
mcd() { mkdir -pv "$1"; cd "$1" || return; }
alias please='sudo !!'
if ! command -v clear >/dev/null 2>&1; then
  alias clear='printf "\e[H\e[2J"'
fi
alias c='clear'
alias sym='cd $(pwd -P)'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# Platform specific commands and commands with platform-specific options
case "$(uname)" in
  CYGWIN* | MINGW* | Linux)
    alias ls='ls -hF --color=auto'
    alias sl='ls -hF --color=auto'
    alias la='ls -AhF --color=auto'
    alias al='ls -AhF --color=auto'
    alias ll='ls -lhF --color=auto'
    alias lla='ls -AlhF --color=auto'
    alias lt='ls -sShF --color=auto'
    alias free='free -mt'
    ;;
  FreeBSD)
    alias ls='ls -hF -G'
    alias la='ls -AhF -G'
    alias ll='ls -lhF -G'
    alias lla='ls -AlhF -G'
    ;;
  *)
esac

# git
alias ga='git add'
alias gs='git status'
alias gb='git branch'
alias gd='git diff'
alias gdc='git diff --cached'
alias gds='git diff --stat'
alias gc='git checkout'
alias grso='git remote show origin'
if [[ -r ~/.git-completion.bash ]]; then
  source ~/.git-completion.bash
  __git_complete ga _git_add
  __git_complete gs _git_status
  __git_complete gb _git_branch
  __git_complete gd _git_diff
  __git_complete gdc _git_diff
  __git_complete gds _git_diff
  __git_complete gc _git_checkout
  __git_complete grso _git_remote
fi
git-sync() {
  branch=$(git rev-parse --abbrev-ref HEAD)
  branches=$(git remote show origin -n | grep "merges with" | tr -s ' ' | cut -d' ' -f2)
  cd "$(git rev-parse --show-toplevel)" || return
  git remote update --prune
  git stash push
  for b in $branches; do
    git checkout "$b"
    git pull
  done
  git checkout "$branch"
  git stash pop
}
git-fire() {
  branch=$(git rev-parse --abbrev-ref HEAD)
  fire_branch="fire-${branch}-$(git config user.email)-$(date +%s)"
  git checkout -b "${fire_branch}"
  cd "$(git rev-parse --show-toplevel)" || exit 1
  git add -A
  git commit -m "Fire! ${fire_branch}" --no-verify
  git push --no-verify --set-upstream origin "${fire_branch}"
}
export GIT_PS1_SHOWDIRTYSTATE=1
# set __git_ps1 in case we don't have git stuff yet
__git_ps1() { echo -n ""; }
[[ -r ~/.git-prompt.sh ]] && source ~/.git-prompt.sh

# Kubernetes
alias kc='kubectl'
kubeon() { export SHOW_KUBE_PS1=1; }
kubeoff() { export SHOW_KUBE_PS1=0; }
__kube_ps1() {
  if [[ $SHOW_KUBE_PS1 -ne 0 ]]; then
    KUBECTX=$(kubectl config current-context 2>/dev/null)
    KUBENS=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)
    echo -n " ${KUBECTX}:${KUBENS}"
  fi
}
if [[ -r ~/.kube/kubectl-completion.bash.inc ]]; then
  source ~/.kube/kubectl-completion.bash.inc
  complete -o default -F __start_kubectl kc
fi
[[ -r ~/.kube/kubectx-completion.bash.inc ]] && source ~/.kube/kubectx-completion.bash.inc
[[ -r ~/.kube/kubens-completion.bash.inc ]] && source ~/.kube/kubens-completion.bash.inc
export PATH="$PATH:${KREW_ROOT:-$HOME/.krew}/bin"

# With help from https://bash-prompt-generator.org
if [[ "$EUID" -gt 0 ]]; then
  # users
  PS1='\[\e[32m\]\h\[\e[95m\]$(__kube_ps1)\[\e[0m\]\[\e[38;5;39m\]$(__git_ps1 " %s")\[\e[0m\] \[\e[33m\]\w\[\e[0m\] \$ '
else
  # root
  PS1='\[\e[38;5;160m\]\h\[\e[95m\]$(__kube_ps1)\[\e[0m\]\[\e[38;5;39m\]$(__git_ps1 " %s")\[\e[0m\] \[\e[33m\]\w\[\e[0m\] # '
fi

export PATH="$PATH:$HOME/bin"
export EDITOR=nano

[[ -r ~/.bashrc_local ]] && source ~/.bashrc_local

# Ensure we can still do tab-completion with aliases (broken on windows git-bash)
if [[ "$(uname)" == "Linux" && -r ~/.complete_alias.sh ]]; then
  source ~/.complete_alias.sh
  complete -F _complete_alias "${!BASH_ALIASES[@]}"
fi

# Do not place any system-specific customizations in ~/.bashrc or they will get wiped in the next update. Use ~/.bashrc_local for that.
