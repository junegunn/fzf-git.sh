# The MIT License (MIT)
#
# Copyright (c) 2024 Junegunn Choi
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

# shellcheck disable=SC2039
[[ $0 == - ]] && return

__fzf_git_color() {
  if [[ -n $NO_COLOR ]]; then
    echo never
  elif [[ $# -gt 0 ]] && [[ -n $FZF_GIT_PREVIEW_COLOR ]]; then
    echo "$FZF_GIT_PREVIEW_COLOR"
  else
    echo "${FZF_GIT_COLOR:-always}"
  fi
}

__fzf_git_cat() {
  if [[ -n $FZF_GIT_CAT ]]; then
    echo "$FZF_GIT_CAT"
    return
  fi

  # Sometimes bat is installed as batcat
  _fzf_git_bat_options="--style='${BAT_STYLE:-full}' --color=$(__fzf_git_color .) --pager=never"
  if command -v batcat > /dev/null; then
    echo "batcat $_fzf_git_bat_options"
  elif command -v bat > /dev/null; then
    echo "bat $_fzf_git_bat_options"
  else
    echo cat
  fi
}

__fzf_git_pager() {
  local pager
  pager="${FZF_GIT_PAGER:-${GIT_PAGER:-$(git config --get core.pager 2> /dev/null)}}"
  echo "${pager:-cat}"
}

__fzf_git_key_label() {
  printf '%s' "$1" | tr '[:lower:]' '[:upper:]'
}

__fzf_git_launcher_prefix() {
  printf '%s' "${FZF_GIT_LAUNCHER_PREFIX:-g}"
}

__fzf_git_launcher_key() {
  case "$1" in
    files)         printf '%s' "${FZF_GIT_LAUNCHER_FILES:-f}" ;;
    branches)      printf '%s' "${FZF_GIT_LAUNCHER_BRANCHES:-b}" ;;
    tags)          printf '%s' "${FZF_GIT_LAUNCHER_TAGS:-t}" ;;
    remotes)       printf '%s' "${FZF_GIT_LAUNCHER_REMOTES:-r}" ;;
    hashes)        printf '%s' "${FZF_GIT_LAUNCHER_HASHES:-h}" ;;
    stashes)       printf '%s' "${FZF_GIT_LAUNCHER_STASHES:-s}" ;;
    lreflogs)      printf '%s' "${FZF_GIT_LAUNCHER_REFLOGS:-l}" ;;
    worktrees)     printf '%s' "${FZF_GIT_LAUNCHER_WORKTREES:-w}" ;;
    each_ref)      printf '%s' "${FZF_GIT_LAUNCHER_EACH_REF:-e}" ;;
    ?list_bindings) printf '%s' "${FZF_GIT_LAUNCHER_HELP:-?}" ;;
  esac
}

__fzf_git_validate_launcher_key() {
  case "$1" in
    [a-zA-Z0-9]) return 0 ;;
    '?') [[ $2 == allow-question ]] && return 0 ;;
  esac

  echo "fzf-git: launcher keys must be a single alphanumeric character" >&2
  return 1
}

if [[ $1 == --list ]]; then
  shift
  if [[ $# -eq 1 ]]; then
    branches() {
      git branch "$@" --sort=-committerdate --sort=-HEAD --format=$'%(HEAD) %(color:yellow)%(refname:short) %(color:green)(%(committerdate:relative))\t%(color:blue)%(subject)%(color:reset)' --color=$(__fzf_git_color) | column -ts$'\t'
    }
    refs() {
      git for-each-ref "$@" --sort=-creatordate --sort=-HEAD --color=$(__fzf_git_color) --format=$'%(if:equals=refs/remotes)%(refname:rstrip=-2)%(then)%(color:magenta)remote-branch%(else)%(if:equals=refs/heads)%(refname:rstrip=-2)%(then)%(color:brightgreen)branch%(else)%(if:equals=refs/tags)%(refname:rstrip=-2)%(then)%(color:brightcyan)tag%(else)%(if:equals=refs/stash)%(refname:rstrip=-2)%(then)%(color:brightred)stash%(else)%(color:white)%(refname:rstrip=-2)%(end)%(end)%(end)%(end)\t%(color:yellow)%(refname:short) %(color:green)(%(creatordate:relative))\t%(color:blue)%(subject)%(color:reset)' | column -ts$'\t'
    }
    hashes() {
      git log --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=$(__fzf_git_color) "$@" $LIST_OPTS
    }
    case "$1" in
      branches)
        echo "$(__fzf_git_key_label "${FZF_GIT_KEY_OPEN_BROWSER:-ctrl-o}") (open in browser) ╱ $(__fzf_git_key_label "${FZF_GIT_KEY_SHOW_ALL:-alt-a}") (show all branches)"
        echo "$(__fzf_git_key_label "${FZF_GIT_KEY_LIST_HASHES:-alt-h}") (list commit hashes)"
        branches
        ;;
      all-branches)
        echo "$(__fzf_git_key_label "${FZF_GIT_KEY_OPEN_BROWSER:-ctrl-o}") (open in browser) ╱ $(__fzf_git_key_label "${FZF_GIT_KEY_ACCEPT_WITHOUT_REMOTE:-alt-enter}") (accept without remote)"
        echo "$(__fzf_git_key_label "${FZF_GIT_KEY_LIST_HASHES:-alt-h}") (list commit hashes)"
        branches -a
        ;;
      hashes)
        echo "$(__fzf_git_key_label "${FZF_GIT_KEY_OPEN_BROWSER:-ctrl-o}") (open in browser) ╱ $(__fzf_git_key_label "${FZF_GIT_KEY_SHOW_DIFF:-ctrl-d}") (diff) ╱ $(__fzf_git_key_label "${FZF_GIT_KEY_TOGGLE_SORT:-ctrl-s}") (toggle sort)"
        echo "$(__fzf_git_key_label "${FZF_GIT_KEY_TOGGLE_RAW:-alt-r}") (toggle raw mode) ╱ $(__fzf_git_key_label "${FZF_GIT_KEY_LIST_FILES:-alt-f}") (list files) ╱ $(__fzf_git_key_label "${FZF_GIT_KEY_SHOW_ALL:-alt-a}") (show all hashes)"
        hashes
        ;;
      all-hashes)
        echo "$(__fzf_git_key_label "${FZF_GIT_KEY_OPEN_BROWSER:-ctrl-o}") (open in browser) ╱ $(__fzf_git_key_label "${FZF_GIT_KEY_SHOW_DIFF:-ctrl-d}") (diff)"
        echo "$(__fzf_git_key_label "${FZF_GIT_KEY_TOGGLE_SORT:-ctrl-s}") (toggle sort) ╱ $(__fzf_git_key_label "${FZF_GIT_KEY_LIST_FILES:-alt-f}") (list files)"
        hashes --all
        ;;
      refs)
        echo "$(__fzf_git_key_label "${FZF_GIT_KEY_OPEN_BROWSER:-ctrl-o}") (open in browser) ╱ $(__fzf_git_key_label "${FZF_GIT_KEY_OPEN_EDITOR:-alt-e}") (examine in editor) ╱ $(__fzf_git_key_label "${FZF_GIT_KEY_SHOW_ALL:-alt-a}") (show all refs)"
        refs --exclude='refs/remotes'
        ;;
      all-refs)
        echo "$(__fzf_git_key_label "${FZF_GIT_KEY_OPEN_BROWSER:-ctrl-o}") (open in browser) ╱ $(__fzf_git_key_label "${FZF_GIT_KEY_OPEN_EDITOR:-alt-e}") (examine in editor) ╱ $(__fzf_git_key_label "${FZF_GIT_KEY_ACCEPT_WITHOUT_REMOTE:-alt-enter}") (accept without remote)"
        refs
        ;;
      *) exit 1 ;;
    esac
  elif [[ $# -gt 1 ]]; then
    set -e

    branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
    if [[ $branch == HEAD ]]; then
      branch=$(git describe --exact-match --tags 2> /dev/null || git rev-parse --short HEAD)
    fi

    # Only supports GitHub for now
    case "$1" in
      commit)
        hash=$(grep -o "[a-f0-9]\{7,\}" <<< "$2" | head -n 1)
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
      file) path=/blob/$branch/$(git rev-parse --show-prefix)$2 ;;
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

    case "$OSTYPE" in
      darwin*)
        open "$url$path"
        ;;
      msys)
        # Git-Bash on Windows
        start "$url$path"
        ;;
      linux*)
        # Handle WSL on Windows
        if uname -a | grep -i -q Microsoft && command -v powershell.exe; then
          powershell.exe -NoProfile start "$url$path"
        else
          xdg-open "$url$path"
        fi
        ;;
      *)
        # fall back to xdg-open for BSDs, etc.
        xdg-open "$url$path"
        ;;
    esac
    exit 0
  fi
fi

if [[ $- =~ i ]] || [[ $1 = --run ]]; then # ----------------------------------

if [[ $__fzf_git_fzf ]]; then
  eval "$__fzf_git_fzf"
else
  # Redefine this function to change the options
  _fzf_git_fzf() {
    local -a custom_args=()
    if [[ -n ${FZF_GIT_FZF_CUSTOM_ARGS:-} ]]; then
      if [[ -n ${ZSH_VERSION:-} ]]; then
        custom_args=("${(z)FZF_GIT_FZF_CUSTOM_ARGS}")
      else
        read -r -a custom_args <<< "$FZF_GIT_FZF_CUSTOM_ARGS"
      fi
    fi

    fzf --height 50% --tmux 90%,70% \
      --layout reverse --multi --min-height 20+ \
      --no-separator --header-border horizontal \
      --border-label-pos 2 \
      --color 'label:blue' \
      --preview-window 'right,50%' --preview-border line \
      --bind "${FZF_GIT_KEY_TOGGLE_PREVIEW:-ctrl-/}:change-preview-window(down,50%|hidden|)" \
      "${custom_args[@]}" "$@"
  }
fi

_fzf_git_check() {
  git rev-parse > /dev/null 2>&1 && return

  [[ -n $TMUX ]] && tmux display-message "Not in a git repository"
  return 1
}

__fzf_git=${BASH_SOURCE[0]:-${(%):-%x}}
__fzf_git=$(readlink -f "$__fzf_git" 2> /dev/null || /usr/bin/ruby --disable-gems -e 'puts File.expand_path(ARGV.first)' "$__fzf_git" 2> /dev/null)

_fzf_git_files() {
  _fzf_git_check || return
  local root query extract_file_name
  root=$(git rev-parse --show-toplevel)
  [[ -n "$(git rev-parse --show-prefix)" ]] && query='!../ '

  read -r -d "" extract_file_name <<'EOF'
"$(cut -c4- <<< {} | sed 's/.* -> //;s/^"//;s/"$//;s/\\"/"/g')"
EOF

  (
    git -c core.quotePath=false -c color.status=$(__fzf_git_color) status --short --no-branch --untracked-files=all
    git -c core.quotePath=false ls-files "$root" | grep -vxFf <(
      git -c core.quotePath=false status --short --untracked-files=no |
        cut -c4- | sed -e 's/.* -> //' -e '/^"[^"\\]*"$/ { s/^"//;s/"$//; }'
      echo :
    ) | sed 's/^/   /'
  ) |
    _fzf_git_fzf -m --ansi --nth 2..,.. \
      --border-label '📁 Files ' \
      --header "$(__fzf_git_key_label "${FZF_GIT_KEY_OPEN_BROWSER:-ctrl-o}") (open in browser) ╱ $(__fzf_git_key_label "${FZF_GIT_KEY_OPEN_EDITOR:-alt-e}") (open in editor)" \
      --bind "${FZF_GIT_KEY_OPEN_BROWSER:-ctrl-o}:execute-silent:bash \"$__fzf_git\" --list file $extract_file_name" \
      --bind "${FZF_GIT_KEY_OPEN_EDITOR:-alt-e}:execute:${EDITOR:-vim} $extract_file_name" \
      --query "$query" \
      --preview "git -c core.quotePath=false diff --no-ext-diff --color=$(__fzf_git_color .) -- $extract_file_name | $(__fzf_git_pager); $(__fzf_git_cat) $extract_file_name" "$@" |
    cut -c4- | sed 's/.* -> //'
}

_fzf_git_tree_files() {
  _fzf_git_check || return

  local treeish cdup prefix
  cdup="$(git rev-parse --show-cdup)"
  prefix="$(git rev-parse --show-prefix)"
  for treeish in "$@"; do
    git diff-tree --root --no-commit-id --name-only --line-prefix="$cdup" "$treeish" -r
  done | sort -u | sed "s|^$cdup$prefix||" |
    _fzf_git_fzf -m \
      --border-label "📂 Files in $* " \
      --header "$(__fzf_git_key_label "${FZF_GIT_KEY_OPEN_BROWSER:-ctrl-o}") (open in browser) ╱ $(__fzf_git_key_label "${FZF_GIT_KEY_OPEN_EDITOR:-alt-e}") (open in editor)" \
      --bind "${FZF_GIT_KEY_OPEN_BROWSER:-ctrl-o}:execute-silent:bash \"$__fzf_git\" --list file {}" \
      --bind "${FZF_GIT_KEY_OPEN_EDITOR:-alt-e}:execute:${EDITOR:-vim} {}" \
      --preview "git -c core.quotePath=false diff --no-ext-diff --color=$(__fzf_git_color .) -- {} | $(__fzf_git_pager); $(__fzf_git_cat) {}"
}

_fzf_git_branches() {
  _fzf_git_check || return

  local shell
  [[ -n ${BASH_VERSION:-} ]] && shell=bash || shell=zsh

  bash "$__fzf_git" --list branches |
  __fzf_git_fzf=$(declare -f _fzf_git_fzf) _fzf_git_fzf --ansi \
    --border-label '🌲 Branches ' \
    --header-lines 2 \
    --tiebreak begin \
    --preview-window down,border-top,40% \
    --color hl:underline,hl+:underline \
    --no-hscroll \
    --bind "${FZF_GIT_KEY_TOGGLE_PREVIEW:-ctrl-/}:change-preview-window(down,70%|hidden|)" \
    --bind "${FZF_GIT_KEY_OPEN_BROWSER:-ctrl-o}:execute-silent:bash \"$__fzf_git\" --list branch {}" \
    --bind "${FZF_GIT_KEY_SHOW_ALL:-alt-a}:change-border-label(🌳 All branches)+reload:bash \"$__fzf_git\" --list all-branches" \
    --bind "${FZF_GIT_KEY_LIST_HASHES:-alt-h}:become:LIST_OPTS=\$(cut -c3- <<< {} | cut -d' ' -f1) $shell \"$__fzf_git\" --run hashes" \
    --bind "${FZF_GIT_KEY_ACCEPT_WITHOUT_REMOTE:-alt-enter}:become:printf '%s\n' {+} | cut -c3- | sed 's@[^/]*/@@'" \
    --preview "git log --oneline --graph --date=short --color=$(__fzf_git_color .) --pretty='format:%C(auto)%cd %h%d %s' \$(cut -c3- <<< {} | cut -d' ' -f1) --" "$@" |
  sed 's/^\* //' | awk '{print $1}' # Slightly modified to work with hashes as well
}

_fzf_git_tags() {
  _fzf_git_check || return
  git tag --sort -version:refname |
  _fzf_git_fzf --preview-window right,70% \
    --border-label '📛 Tags ' \
    --header "$(__fzf_git_key_label "${FZF_GIT_KEY_OPEN_BROWSER:-ctrl-o}") (open in browser)" \
    --bind "${FZF_GIT_KEY_OPEN_BROWSER:-ctrl-o}:execute-silent:bash \"$__fzf_git\" --list tag {}" \
    --bind "${FZF_GIT_KEY_TOGGLE_RAW:-alt-r}:toggle-raw" \
    --preview "git show --color=$(__fzf_git_color .) {} | $(__fzf_git_pager)" "$@"
}

_fzf_git_hashes() {
  _fzf_git_check || return
  bash "$__fzf_git" --list hashes |
  _fzf_git_fzf --ansi --no-sort --bind "${FZF_GIT_KEY_TOGGLE_SORT:-ctrl-s}:toggle-sort,${FZF_GIT_KEY_TOGGLE_RAW:-alt-r}:toggle-raw" \
    --border-label '🍡 Hashes ' \
    --header-lines 2 \
    --bind "${FZF_GIT_KEY_OPEN_BROWSER:-ctrl-o}:execute-silent:bash \"$__fzf_git\" --list commit {}" \
    --bind "${FZF_GIT_KEY_SHOW_DIFF:-ctrl-d}:execute:grep -o '[a-f0-9]\{7,\}' <<< {} | head -n 1 | xargs git diff --color=$(__fzf_git_color) > /dev/tty" \
    --bind "${FZF_GIT_KEY_SHOW_ALL:-alt-a}:change-border-label(🍇 All hashes)+reload:bash \"$__fzf_git\" --list all-hashes" \
    --bind "${FZF_GIT_KEY_LIST_FILES:-alt-f}:become:echo ::tree_files;
      awk 'match(\$0, /[a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9]*/) { print substr(\$0, RSTART, RLENGTH) }' {+f} |
        xargs bash \"$__fzf_git\" --run tree_files" \
    --color hl:underline,hl+:underline \
    --preview "grep -o '[a-f0-9]\{7,\}' <<< {} | head -n 1 | xargs git show --color=$(__fzf_git_color .) | $(__fzf_git_pager)" "$@" |
  awk '
    NR==1 && $0=="::tree_files" {
      mode="tree_files"
      next
    }

    mode=="tree_files" {
      print
      next
    }

    match($0, /[a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9]*/) {
      print substr($0, RSTART, RLENGTH)
    }
  '
}

_fzf_git_remotes() {
  _fzf_git_check || return
  git remote -v | awk '{print $1 "\t" $2}' | uniq |
  _fzf_git_fzf --tac \
    --border-label '📡 Remotes ' \
    --header "$(__fzf_git_key_label "${FZF_GIT_KEY_OPEN_BROWSER:-ctrl-o}") (open in browser)" \
    --bind "${FZF_GIT_KEY_OPEN_BROWSER:-ctrl-o}:execute-silent:bash \"$__fzf_git\" --list remote {1}" \
    --preview-window right,70% \
    --preview "git log --oneline --graph --date=short --color=$(__fzf_git_color .) --pretty='format:%C(auto)%cd %h%d %s' '{1}/$(git rev-parse --abbrev-ref HEAD)' --" "$@" |
  cut -d$'\t' -f1
}

_fzf_git_stashes() {
  _fzf_git_check || return
  git stash list | _fzf_git_fzf \
    --border-label '🥡 Stashes ' \
    --header "$(__fzf_git_key_label "${FZF_GIT_KEY_DROP_STASH:-ctrl-x}") (drop stash)" \
    --bind "${FZF_GIT_KEY_DROP_STASH:-ctrl-x}:reload(git stash drop -q {1}; git stash list)" \
    -d: --preview "git show --first-parent --color=$(__fzf_git_color .) {1} | $(__fzf_git_pager)" "$@" |
  cut -d: -f1
}

_fzf_git_lreflogs() {
  _fzf_git_check || return
  git reflog --color=$(__fzf_git_color) --format="%C(blue)%gD %C(yellow)%h%C(auto)%d %gs" | _fzf_git_fzf --ansi \
    --border-label '📒 Reflogs ' \
    --bind "${FZF_GIT_KEY_TOGGLE_RAW:-alt-r}:toggle-raw" \
    --preview "git show --color=$(__fzf_git_color .) {1} | $(__fzf_git_pager)" "$@" |
  awk '{print $1}'
}

_fzf_git_each_ref() {
  _fzf_git_check || return
  bash "$__fzf_git" --list refs | _fzf_git_fzf --ansi \
    --nth 2,2.. \
    --tiebreak begin \
    --border-label '☘️  Each ref ' \
    --header-lines 1 \
    --preview-window down,border-top,40% \
    --color hl:underline,hl+:underline \
    --no-hscroll \
    --bind "${FZF_GIT_KEY_TOGGLE_PREVIEW:-ctrl-/}:change-preview-window(down,70%|hidden|)" \
    --bind "${FZF_GIT_KEY_OPEN_BROWSER:-ctrl-o}:execute-silent:bash \"$__fzf_git\" --list {1} {2}" \
    --bind "${FZF_GIT_KEY_OPEN_EDITOR:-alt-e}:execute:${EDITOR:-vim} <(git show {2}) < /dev/tty > /dev/tty" \
    --bind "${FZF_GIT_KEY_SHOW_ALL:-alt-a}:change-border-label(🍀 Every ref)+reload:bash \"$__fzf_git\" --list all-refs" \
    --bind "${FZF_GIT_KEY_ACCEPT_WITHOUT_REMOTE:-alt-enter}:become:printf '%s\n' {+2} | sed 's@[^/]*/@@'" \
    --preview "git log --oneline --graph --date=short --color=$(__fzf_git_color .) --pretty='format:%C(auto)%cd %h%d %s' {2} --" \
    --accept-nth 2 \
    "$@"
}

_fzf_git_worktrees() {
  _fzf_git_check || return
  git worktree list | _fzf_git_fzf \
    --border-label '🌴 Worktrees ' \
    --header "$(__fzf_git_key_label "${FZF_GIT_KEY_REMOVE_WORKTREE:-ctrl-x}") (remove worktree)" \
    --bind "${FZF_GIT_KEY_REMOVE_WORKTREE:-ctrl-x}:reload(git worktree remove {1} > /dev/null; git worktree list)" \
    --preview "
      git -c color.status=$(__fzf_git_color .) -C {1} status --short --branch
      echo
      git log --oneline --graph --date=short --color=$(__fzf_git_color .) --pretty='format:%C(auto)%cd %h%d %s' {2} --
    " "$@" |
  awk '{print $1}'
}

_fzf_git_list_bindings() {
  local prefix
  prefix=$(__fzf_git_launcher_prefix)

  cat <<EOF

$(__fzf_git_key_label "ctrl-$prefix") $(__fzf_git_key_label "$(__fzf_git_launcher_key '?list_bindings')") to show this list
$(__fzf_git_key_label "ctrl-$prefix") $(__fzf_git_key_label "ctrl-$(__fzf_git_launcher_key files)") for Files
$(__fzf_git_key_label "ctrl-$prefix") $(__fzf_git_key_label "ctrl-$(__fzf_git_launcher_key branches)") for Branches
$(__fzf_git_key_label "ctrl-$prefix") $(__fzf_git_key_label "ctrl-$(__fzf_git_launcher_key tags)") for Tags
$(__fzf_git_key_label "ctrl-$prefix") $(__fzf_git_key_label "ctrl-$(__fzf_git_launcher_key remotes)") for Remotes
$(__fzf_git_key_label "ctrl-$prefix") $(__fzf_git_key_label "ctrl-$(__fzf_git_launcher_key hashes)") for commit Hashes
$(__fzf_git_key_label "ctrl-$prefix") $(__fzf_git_key_label "ctrl-$(__fzf_git_launcher_key stashes)") for Stashes
$(__fzf_git_key_label "ctrl-$prefix") $(__fzf_git_key_label "ctrl-$(__fzf_git_launcher_key lreflogs)") for reflogs
$(__fzf_git_key_label "ctrl-$prefix") $(__fzf_git_key_label "ctrl-$(__fzf_git_launcher_key worktrees)") for Worktrees
$(__fzf_git_key_label "ctrl-$prefix") $(__fzf_git_key_label "ctrl-$(__fzf_git_launcher_key each_ref)") for Each ref (git for-each-ref)
EOF
}

fi # --------------------------------------------------------------------------

if [[ $1 = --run ]]; then
  shift
  type=$1
  shift
  eval "_fzf_git_$type" "$@"

elif [[ $- =~ i ]]; then # ------------------------------------------------------
if [[ -n "${BASH_VERSION:-}" ]]; then
  __fzf_git_init() {
    bind -m emacs-standard '"\er":  redraw-current-line'
    bind -m emacs-standard '"\C-z": vi-editing-mode'
    bind -m vi-command     '"\C-z": emacs-editing-mode'
    bind -m vi-insert      '"\C-z": emacs-editing-mode'

    local o c prefix
    prefix=$(__fzf_git_launcher_prefix)
    __fzf_git_validate_launcher_key "$prefix" || return

    for o in "$@"; do
      c=$(__fzf_git_launcher_key "$o")
      if [[ $o == '?list_bindings' ]]; then
        __fzf_git_validate_launcher_key "$c" allow-question || continue
        bind -x "\"\C-$prefix$c\": _fzf_git_list_bindings"
        continue
      fi
      __fzf_git_validate_launcher_key "$c" || continue
      bind -m emacs-standard '"\C-'$prefix'\C-'$c'": " \C-u \C-a\C-k`_fzf_git_'$o'`\e\C-e\C-y\C-a\C-y\ey\C-h\C-e\er \C-h"'
      bind -m vi-command     '"\C-'$prefix'\C-'$c'": "\C-z\C-'$prefix'\C-'$c'\C-z"'
      bind -m vi-insert      '"\C-'$prefix'\C-'$c'": "\C-z\C-'$prefix'\C-'$c'\C-z"'
      bind -m emacs-standard '"\C-'$prefix$c'":    " \C-u \C-a\C-k`_fzf_git_'$o'`\e\C-e\C-y\C-a\C-y\ey\C-h\C-e\er \C-h"'
      bind -m vi-command     '"\C-'$prefix$c'":    "\C-z\C-'$prefix$c'\C-z"'
      bind -m vi-insert      '"\C-'$prefix$c'":    "\C-z\C-'$prefix$c'\C-z"'
    done
  }
elif [[ -n "${ZSH_VERSION:-}" ]]; then
  __fzf_git_join() {
    local item
    while read -r item; do
      echo -n -E "${(q)${(Q)item}} "
    done
  }

  __fzf_git_init() {
    setopt localoptions no_glob
    local m o c prefix
    prefix=$(__fzf_git_launcher_prefix)
    __fzf_git_validate_launcher_key "$prefix" || return

    for o in "$@"; do
      c=$(__fzf_git_launcher_key "$o")
      if [[ $o == '?list_bindings' ]];then
        __fzf_git_validate_launcher_key "$c" allow-question || continue
        eval "fzf-git-$o-widget() { zle -M '$(_fzf_git_list_bindings)' }"
      else
        __fzf_git_validate_launcher_key "$c" || continue
        eval "fzf-git-$o-widget() { local result=\$(_fzf_git_$o | __fzf_git_join); zle reset-prompt; LBUFFER+=\$result }"
      fi
      eval "zle -N fzf-git-$o-widget"
      for m in emacs vicmd viins; do
        eval "bindkey -M $m '^$prefix^$c' fzf-git-$o-widget"
        eval "bindkey -M $m '^$prefix$c' fzf-git-$o-widget"
      done
    done
  }
fi
__fzf_git_init files branches tags remotes hashes stashes lreflogs each_ref worktrees '?list_bindings'

fi # --------------------------------------------------------------------------
