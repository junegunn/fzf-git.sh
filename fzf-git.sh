# The MIT License (MIT)
#
# Copyright (c) 2022 Junegunn Choi
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

if [[ $# -eq 1 ]]; then
  branches() {
    git branch "$@" --sort=-committerdate --sort=-HEAD --format=$'%(HEAD) %(color:yellow)%(refname:short) %(color:green)(%(committerdate:relative))\t%(color:blue)%(subject)%(color:reset)' --color=always | column -ts$'\t'
  }
  refs() {
    git for-each-ref --sort=-creatordate --sort=-HEAD --color=always --format=$'%(refname) %(color:green)(%(creatordate:relative))\t%(color:blue)%(subject)%(color:reset)' |
      eval "$1" |
      sed 's#^refs/remotes/#\x1b[95mremote-branch\t\x1b[33m#; s#^refs/heads/#\x1b[92mbranch\t\x1b[33m#; s#^refs/tags/#\x1b[96mtag\t\x1b[33m#; s#refs/stash#\x1b[91mstash\t\x1b[33mrefs/stash#' |
      column -ts$'\t'
  }
  case "$1" in
    branches)
      echo $'CTRL-O (open in browser) ╱ ALT-A (show all branches)\n'
      branches
      ;;
    all-branches)
      echo $'CTRL-O (open in browser)\n'
      branches -a
      ;;
    refs)
      echo $'CTRL-O (open in browser) ╱ ALT-E (examine in editor) ╱ ALT-A (show all refs)\n'
      refs 'grep -v ^refs/remotes'
      ;;
    all-refs)
      echo $'CTRL-O (open in browser) ╱ ALT-E (examine in editor)\n'
      refs 'cat'
      ;;
    nobeep) ;;
    *) exit 1 ;;
  esac
elif [[ $# -gt 1 ]]; then
  set -e

  branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
  if [[ $branch = HEAD ]]; then
    branch=$(git describe --exact-match --tags 2> /dev/null || git rev-parse --short HEAD)
  fi

  # Only supports GitHub for now
  case "$1" in
    commit)
      hash=$(grep -o "[a-f0-9]\{7,\}" <<< "$2")
      path=/commit/$hash
      ;;
    branch|remote-branch)
      branch=$(sed 's/^[* ]*//' <<< "$2" | cut -d' ' -f1)
      remote=$(git config branch."${branch}".remote || echo 'origin')
      branch=${branch#$remote/}
      path=/tree/$branch
      ;;
    remote)
      remote=$2
      path=/tree/$branch
      ;;
    file) path=/blob/$branch/$2 ;;
    tag)  path=/releases/tag/$2 ;;
    *)    exit 1 ;;
  esac

  remote=${remote:-$(git config branch."${branch}".remote || echo 'origin')}
  remote_url=$(git remote get-url "$remote" 2> /dev/null || echo "$remote")

  if [[ $remote_url =~ ^git@ ]]; then
    url=${remote_url%.git}
    url=${url#git@}
    url=https://${url/://}
  elif [[ $remote_url =~ ^http ]]; then
    url=${remote_url%.git}
  fi

  case "$(uname -s)" in
    Darwin) open "$url$path"     ;;
    *)      xdg-open "$url$path" ;;
  esac
  exit 0
fi

if [[ $- =~ i ]]; then
# -----------------------------------------------------------------------------

# Redefine this function to change the options
_fzf_git_fzf() {
  fzf-tmux -p80%,60% -- \
    --layout=reverse --multi --height=50% --min-height=20 --border \
    --color='header:italic:underline' \
    --preview-window='right,50%,border-left' \
    --bind='ctrl-/:change-preview-window(down,50%,border-top|hidden|)' "$@"
}

_fzf_git_check() {
  git rev-parse HEAD > /dev/null 2>&1 && return

  [[ -n $TMUX ]] && tmux display-message "Not in a git repository"
  return 1
}

__fzf_git=${BASH_SOURCE[0]:-${(%):-%x}}
__fzf_git=$(readlink -f "$__fzf_git" 2> /dev/null || /usr/bin/ruby --disable-gems -e 'puts File.expand_path(ARGV.first)' "$__fzf_git" 2> /dev/null)

if [[ -z $_fzf_git_cat ]]; then
  # Sometimes bat is installed as batcat
  export _fzf_git_cat="cat"
  _fzf_git_bat_options="--style='${BAT_STYLE:-full}' --color=always --pager=never"
  if command -v batcat > /dev/null; then
    _fzf_git_cat="batcat $_fzf_git_bat_options"
  elif command -v bat > /dev/null; then
    _fzf_git_cat="bat $_fzf_git_bat_options"
  fi
fi

_fzf_git_files() {
  _fzf_git_check || return
  (git -c color.status=always status --short
   git ls-files | grep -vxFf <(git status -s | grep '^[^?]' | cut -c4-; echo :) | sed 's/^/   /') |
  _fzf_git_fzf -m --ansi --nth 2..,.. \
    --prompt '📁 Files> ' \
    --header $'CTRL-O (open in browser) ╱ ALT-E (open in editor)\n\n' \
    --bind "ctrl-o:execute-silent:bash $__fzf_git file {-1}" \
    --bind "alt-e:execute:${EDITOR:-vim} {-1} > /dev/tty" \
    --preview "git diff --no-ext-diff --color=always -- {-1} | sed 1,4d; $_fzf_git_cat {-1}" "$@" |
  cut -c4- | sed 's/.* -> //'
}

_fzf_git_branches() {
  _fzf_git_check || return
  bash "$__fzf_git" branches |
  _fzf_git_fzf --ansi \
    --prompt '🌲 Branches> ' \
    --header-lines 2 \
    --tiebreak begin \
    --preview-window down,border-top,40% \
    --color hl:underline,hl+:underline \
    --no-hscroll \
    --bind 'ctrl-/:change-preview-window(down,70%|hidden|)' \
    --bind "ctrl-o:execute-silent:bash $__fzf_git branch {}" \
    --bind "alt-a:change-prompt(🌳 All branches> )+reload:bash \"$__fzf_git\" all-branches" \
    --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1)' "$@" |
  sed 's/^..//' | cut -d' ' -f1
}

_fzf_git_tags() {
  _fzf_git_check || return
  git tag --sort -version:refname |
  _fzf_git_fzf --preview-window right,70% \
    --prompt '📛 Tags> ' \
    --header $'CTRL-O (open in browser)\n\n' \
    --bind "ctrl-o:execute-silent:bash $__fzf_git tag {}" \
    --preview 'git show --color=always {}' "$@"
}

_fzf_git_hashes() {
  _fzf_git_check || return
  git log --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=always |
  _fzf_git_fzf --ansi --no-sort --bind 'ctrl-s:toggle-sort' \
    --prompt '🍡 Hashes> ' \
    --header $'CTRL-O (open in browser) ╱ CTRL-D (diff) ╱ CTRL-S (toggle sort)\n\n' \
    --bind "ctrl-o:execute-silent:bash $__fzf_git commit {}" \
    --bind 'ctrl-d:execute:grep -o "[a-f0-9]\{7,\}" <<< {} | head -n 1 | xargs git diff > /dev/tty' \
    --color hl:underline,hl+:underline \
    --preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | head -n 1 | xargs git show --color=always' "$@" |
  awk 'match($0, /[a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9]*/) { print substr($0, RSTART, RLENGTH) }'
}

_fzf_git_remotes() {
  _fzf_git_check || return
  git remote -v | awk '{print $1 "\t" $2}' | uniq |
  _fzf_git_fzf --tac \
    --prompt '📡 Remotes> ' \
    --header $'CTRL-O (open in browser)\n\n' \
    --bind "ctrl-o:execute-silent:bash $__fzf_git remote {1}" \
    --preview-window right,70% \
    --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" {1}/"$(git rev-parse --abbrev-ref HEAD)"' "$@" |
  cut -d$'\t' -f1
}

_fzf_git_stashes() {
  _fzf_git_check || return
  git stash list | _fzf_git_fzf \
    --prompt '🥡 Stashes> ' \
    --header $'CTRL-X (drop stash)\n\n' \
    --bind 'ctrl-x:execute-silent(git stash drop {1})+reload(git stash list)' \
    -d: --preview 'git show --color=always {1}' "$@" |
  cut -d: -f1
}

_fzf_git_each_ref() {
  _fzf_git_check || return
  bash "$__fzf_git" refs | _fzf_git_fzf --ansi \
    --nth 2,2.. \
    --tiebreak begin \
    --prompt '☘️  Each ref> ' \
    --header-lines 2 \
    --preview-window down,border-top,40% \
    --color hl:underline,hl+:underline \
    --no-hscroll \
    --bind 'ctrl-/:change-preview-window(down,70%|hidden|)' \
    --bind "ctrl-o:execute-silent:bash $__fzf_git {1} {2}" \
    --bind "alt-e:execute:${EDITOR:-vim} <(git show {2}) > /dev/tty" \
    --bind "alt-a:change-prompt(🍀 Every ref> )+reload:bash \"$__fzf_git\" all-refs" \
    --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" {2}' "$@" |
  awk '{print $2}'
}

if [[ -n "${BASH_VERSION:-}" ]]; then
  __fzf_git_init() {
    bind '"\er": redraw-current-line'
    local o
    for o in "$@"; do
      bind '"\C-g\C-'${o:0:1}'": "`_fzf_git_'$o'`\e\C-e\er"'
      bind '"\C-g'${o:0:1}'": "`_fzf_git_'$o'`\e\C-e\er"'
    done
  }
elif [[ -n "${ZSH_VERSION:-}" ]]; then
  __fzf_git_join() {
    local item
    while read item; do
      echo -n "${(q)item} "
    done
  }

  __fzf_git_init() {
    local o
    for o in "$@"; do
      eval "fzf-git-$o-widget() { local result=\$(_fzf_git_$o | __fzf_git_join); zle reset-prompt; LBUFFER+=\$result }"
      eval "zle -N fzf-git-$o-widget"
      eval "bindkey '^g^${o[1]}' fzf-git-$o-widget"
      eval "bindkey '^g${o[1]}' fzf-git-$o-widget"
    done
  }
fi
__fzf_git_init files branches tags remotes hashes stashes each_ref

# -----------------------------------------------------------------------------
fi
