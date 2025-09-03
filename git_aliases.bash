alias gp='git push'
alias gl='git pull'

alias gs='git status'

alias gc='git clone'
alias gcr='git clone --recursive'

alias gw='git switch'

alias ga='git add'

alias gm='git commit'
alias gma='git commit -a'

alias gfa='git fetch --all && git fetch --all'

alias gd='git diff'

alias grst="git reset"
alias grsth="git reset --hard"

gsu() {
    git branch --set-upstream-to="$1"
}

alias gck='git checkout'
alias gck='git checkout -b'

alias grg='git remote get-url'
alias grs='git remote set-url'
alias gra='git remote add'

alias grb='git rebase'

gbr() {
    git branch -m $1 $2
    git fetch origin
    git branch -u origin/$2 $2
    git remote set-head origin -a
}

alias gsb='git submodule update --init --recursive'
alias gsd='git submodule deinit --all --force'
