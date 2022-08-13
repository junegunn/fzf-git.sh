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

if [[ $- =~ i ]]; then
# -----------------------------------------------------------------------------

# Redefine this function to change the options
_fzf_git_fzf() {
  fzf-tmux -p80%,60% --layout=reverse --multi --height 50% --min-height 20 --border --bind ctrl-/:toggle-preview "$@"
}

_fzf_git_check() {
  git rev-parse HEAD > /dev/null 2>&1
}

# Sometimes bat is installed as batcat
export _fzf_git_cat=cat
if command -v batcat > /dev/null; then
  _fzf_git_cat="batcat --style='${BAT_STYLE:-numbers}' --color=always --pager=never"
elif command -v bat > /dev/null; then
  _fzf_git_cat="bat --style='${BAT_STYLE:-numbers}' --color=always --pager=never"
fi

_fzf_git_files() {
  _fzf_git_check || return
  (git -c color.status=always status --short
   git ls-files | grep -vf <(git status -s | grep '^[^?]' | cut -c4-) | sed 's/^/   /') |
  _fzf_git_fzf -m --ansi --nth 2..,.. \
    --prompt 'Git Files> ' \
    --preview "git diff --color=always -- {-1} | sed 1,4d; $_fzf_git_cat {-1}" |
  cut -c4- | sed 's/.* -> //'
}

_fzf_git_branches() {
  _fzf_git_check || return
  git branch -a --color=always | grep -v '/HEAD\s' | sort |
  _fzf_git_fzf --ansi --tac --preview-window right,70% \
    --prompt 'Git Branches> ' \
    --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1)' |
  sed 's/^..//' | cut -d' ' -f1 |
  sed 's#^remotes/##'
}

_fzf_git_tags() {
  _fzf_git_check || return
  git tag --sort -version:refname |
  _fzf_git_fzf --preview-window right,70% \
    --prompt 'Git Tags> ' \
    --preview 'git show --color=always {}'
}

_fzf_git_hashes() {
  _fzf_git_check || return
  git log --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=always |
  _fzf_git_fzf --ansi --no-sort --bind 'ctrl-s:toggle-sort' \
    --prompt 'Git Hashes> ' \
    --header 'Press CTRL-S to toggle sort' \
    --preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | xargs git show --color=always' |
  grep -o "[a-f0-9]\{7,\}"
}

_fzf_git_remotes() {
  _fzf_git_check || return
  git remote -v | awk '{print $1 "\t" $2}' | uniq |
  _fzf_git_fzf --tac \
    --prompt 'Git Remotes> ' \
    --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" {1}/"$(git rev-parse --abbrev-ref HEAD)"' |
  cut -d$'\t' -f1
}

_fzf_git_stashes() {
  _fzf_git_check || return
  git stash list | _fzf_git_fzf \
    --prompt 'Git Stashes> ' \
    -d: --preview 'git show --color=always {1}' |
  cut -d: -f1
}

if [[ -n $BASH_VERSION ]]; then
  bind '"\er": redraw-current-line'
  bind '"\C-g\C-f": "$(_fzf_git_files)\e\C-e\er"'
  bind '"\C-g\C-b": "$(_fzf_git_branches)\e\C-e\er"'
  bind '"\C-g\C-t": "$(_fzf_git_tags)\e\C-e\er"'
  bind '"\C-g\C-h": "$(_fzf_git_hashes)\e\C-e\er"'
  bind '"\C-g\C-r": "$(_fzf_git_remotes)\e\C-e\er"'
  bind '"\C-g\C-s": "$(_fzf_git_stashes)\e\C-e\er"'
elif [[ -n $ZSH_VERSION ]]; then
  _fzf_git_join() {
    local item
    while read item; do
      echo -n "${(q)item} "
    done
  }

  _fzf_git_init() {
    local o
    for o in $@; do
      eval "fzf-git-$o-widget() { local result=\$(_fzf_git_$o | _fzf_git_join); zle reset-prompt; LBUFFER+=\$result }"
      eval "zle -N fzf-git-$o-widget"
      eval "bindkey '^g^${o[1]}' fzf-git-$o-widget"
    done
  }
  _fzf_git_init files branches tags remotes hashes stashes
fi

# -----------------------------------------------------------------------------
fi
