alias gp='git push'
alias gl='git pull'

alias gs='git status'
alias gd='git diff'

alias gc='git clone'
alias gcr='git clone --recursive'

alias gw='git switch'

alias ga='git add'

alias gm='git commit'
alias gma='git commit -a'
alias gck='git checkout'
alias gckb='git checkout -b'

alias gfa='git fetch --all && git fetch --all'

alias gpa='git pushall'                      # Push to all remotes
alias gpf='git push --force'

alias gaa='git add .'                        # Add all files
alias gau='git add --update'                 # Add only tracked files

alias gmf='git commit --fixup'               # Create fixup commit
alias gms='git commit --squash'              # Create squash commit

alias grs='git reset --soft'                 # Soft reset (keep changes staged)
alias grm='git reset --mixed'                # Mixed reset (keep changes unstaged)

alias glog='git log --graph --oneline --all'  # Graph view of all branches

alias gst='git stash'                        # Stash changes
alias gstp='git stash pop'                   # Apply stashed changes
alias gstl='git stash list'                  # List stashes

alias grg='git remote get-url'
alias grgs='git remote set-url'

alias grm='git remote -v'                    # List remotes with URLs
alias grp='git remote prune origin'          # Remove deleted remote branches

alias gbl='git branch -a'                    # List all branches (local + remote)
alias gbd='git branch -d'                    # Delete branch safely
alias gbdf='git branch -D'                   # Force delete branch

gsu() {
    if [[ -z "$1" ]]; then
        echo "Usage: gsu <remote>/<branch>"
        return 1
    fi
    git branch --set-upstream-to="$1"
}

gbr() {
    if [[ $# -ne 2 ]]; then
        echo "Usage: gbr <old-name> <new-name>"
        return 1
    fi
    git branch -m "$1" "$2"
    git fetch origin
    git branch -u "origin/$2" "$2"
    git remote set-head origin -a
}

# Cherry-pick by commit message pattern
gcp() {
    if [[ -z "$1" ]]; then
        echo "Usage: gcp <commit-message-pattern>"
        return 1
    fi
    git log --oneline --all | grep "$1" | cut -d' ' -f1 | head -1 | xargs -r git cherry-pick
}

# Quick commit and push
gcp_push() {
    git commit -m "${1:-Quick commit}" && git push
}

# Undo last commit (keep changes)
gundo() {
    git reset --soft HEAD~1
}

# Show current branch name
gbname() {
    git rev-parse --abbrev-ref HEAD
}
