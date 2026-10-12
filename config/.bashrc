# ~/.bashrc — Git Bash, zsh-flavoured

# ---------------------------------------------------------------- history
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups
HISTIGNORE="ls:ll:la:cd:pwd:exit:clear"
shopt -s histappend cmdhist
shopt -s autocd cdspell dirspell globstar nocaseglob checkwinsize 2>/dev/null
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# ---------------------------------------------------------------- env
export EDITOR="${EDITOR:-notepad}"
export LESS="-R -F -X"
export CLAUDE_CODE_GIT_BASH_PATH="C:\\Program Files\\Git\\bin\\bash.exe"
# winget portable apps (fzf, zoxide, claude)
[ -d "$LOCALAPPDATA/Microsoft/WinGet/Links" ] && PATH="$PATH:$(cygpath -u "$LOCALAPPDATA")/Microsoft/WinGet/Links"

# ---------------------------------------------------------------- completion
if ! declare -F __git_complete >/dev/null; then
  for f in /mingw64/share/git/completion/git-completion.bash /usr/share/bash-completion/completions/git; do
    [ -f "$f" ] && . "$f" && break
  done
fi

# ---------------------------------------------------------------- ls & friends
alias ls='ls --color=auto --group-directories-first -F'
alias ll='ls -lh'
alias la='ls -lhA'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias grep='grep --color=auto'
alias c='clear'
alias reload='source ~/.bashrc && echo "bashrc reloaded"'
alias e.='explorer.exe .'
alias cc='claude'
alias ccc='claude --continue'
mkcd() { mkdir -p "$1" && cd "$1"; }

# ---------------------------------------------------------------- git (oh-my-zsh style)
alias g='git'
alias gst='git status -sb'
alias ga='git add'
alias gaa='git add --all'
alias gap='git add -p'
alias gc='git commit -v'
alias gcm='git commit -m'
alias gca='git commit -v --amend'
alias gcan='git commit --amend --no-edit'
alias gco='git checkout'
alias gsw='git switch'
alias gswc='git switch -c'
alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gd='git diff'
alias gds='git diff --staged'
alias gf='git fetch --all --prune'
alias gl='git pull'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpsup='git push --set-upstream origin "$(git branch --show-current)"'
alias grb='git rebase'
alias grbi='git rebase -i'
alias grbc='git rebase --continue'
alias grba='git rebase --abort'
alias gm='git merge'
alias gsta='git stash push'
alias gstp='git stash pop'
alias gstl='git stash list'
alias grs='git restore'
alias grss='git restore --staged'
alias glog='git log --graph --pretty=format:"%C(magenta)%h%Creset %C(auto)%d%Creset %s %C(green)(%cr) %C(blue)<%an>%Creset" --abbrev-commit'
alias gloga='glog --all'
alias gcl='git clone'
alias gwip='git add -A && git commit --no-verify -m "wip"'
alias gundo='git reset --soft HEAD~1'

# Tab-completion for the aliases
if declare -F __git_complete >/dev/null; then
  __git_complete g __git_main
  __git_complete gco _git_checkout;  __git_complete gsw _git_switch
  __git_complete gswc _git_switch;   __git_complete gb _git_branch
  __git_complete gbd _git_branch;    __git_complete gm _git_merge
  __git_complete grb _git_rebase;    __git_complete gd _git_diff
  __git_complete ga _git_add;        __git_complete gp _git_push
  __git_complete gl _git_pull;       __git_complete gf _git_fetch
  __git_complete grs _git_restore
fi

# fzf-powered git helpers
gcb() {  # fuzzy checkout branch (local + remote)
  local b
  b=$(git branch -a --sort=-committerdate --format='%(refname:short)' | grep -v HEAD |
      fzf --height 40% --reverse --prompt='branch> ' --preview 'git log --oneline --graph --color=always -20 {}') || return
  git switch "${b#origin/}" 2>/dev/null || git switch -c "${b#origin/}" --track "$b"
}
gshow() {  # fuzzy browse commits
  git log --oneline --color=always | fzf --ansi --reverse --no-sort \
    --preview 'git show --color=always {1}' --bind 'enter:execute(git show --color=always {1} | less -R)'
}
gadd() {  # fuzzy pick files to stage
  local files
  files=$(git status -s | fzf -m --reverse --preview 'git diff --color=always -- {2}' | awk '{print $2}') || return
  [ -n "$files" ] && git add $files && git status -sb
}

# ---------------------------------------------------------------- tools
command -v fzf >/dev/null && {
  export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border=rounded --info=inline \
  --color=bg+:#313244,spinner:#f5e0dc,hl:#f38ba8,fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
  --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8,selected-bg:#45475a,border:#6c7086"
  eval "$(fzf --bash 2>/dev/null)"   # Ctrl+R history, Ctrl+T files, Alt+C cd
}
command -v zoxide >/dev/null && eval "$(zoxide init bash)"          # z <dir>, zi
command -v starship >/dev/null && eval "$(starship init bash)"
