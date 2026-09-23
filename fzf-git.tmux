#!/usr/bin/env bash
#
# tmux key bindings for fzf-git.sh
#
# Add this line to your ~/.tmux.conf
#
#   run-shell /path/to/fzf-git.tmux
#
# fzf-git.sh should be in the same directory.
#
# Each binding starts fzf in a floating pane, and sends the selected objects
# to the pane it was started from, so the bindings work even when the pane is
# running a program other than the shell.
#
# Options, set before run-shell:
#
#   set -g @fzf-git-key g  # Key to press after the prefix key

__fzf_git_tmux=${BASH_SOURCE[0]:-$0}
__fzf_git_tmux=$(readlink -f "$__fzf_git_tmux" 2> /dev/null || /usr/bin/ruby --disable-gems -e 'puts File.expand_path(ARGV.first)' "$__fzf_git_tmux" 2> /dev/null)
__fzf_git=$(dirname "$__fzf_git_tmux")/fzf-git.sh

# Key, function, and description of each binding
__fzf_git_bindings() {
  cat <<'EOF'
? list_bindings to show this list
f files for Files
b branches for Branches
t tags for Tags
r remotes for Remotes
h hashes for commit Hashes
s stashes for Stashes
l lreflogs for reflogs
w worktrees for Worktrees
e each_ref for Each ref (git for-each-ref)
EOF
}

__fzf_git_key() {
  local key
  key=$(tmux show-option -gqv @fzf-git-key)
  echo "${key:-g}"
}

__fzf_git_quote() {
  # The replacement is taken from a variable, as bash 3.2 does not handle
  # backslashes in an inline replacement the same way
  local quote="'\\''"
  printf "'%s'" "${1//\'/$quote}"
}

# Join the selected objects, quoting each of them so that the result can be
# pasted on the command-line
__fzf_git_join() {
  local item sep=
  while IFS= read -r item; do
    [[ -n $item ]] || continue
    printf '%s' "$sep"
    if [[ $item == *[!A-Za-z0-9_@%+=:,./-]* ]]; then
      __fzf_git_quote "$item"
    else
      printf '%s' "$item"
    fi
    sep=' '
  done
}

__fzf_git_list_bindings() {
  local prefix key k desc
  prefix=$(tmux show-option -gv prefix)
  key=$(__fzf_git_key)
  echo
  while read -r k _ desc; do
    echo "  $prefix $key $k $desc"
  done < <(__fzf_git_bindings)
  echo
  echo '  Press any key to close'
  read -rsn1
}

if [[ $# -gt 0 ]]; then # Started by a key binding ------------------------------

if [[ $1 == list_bindings ]]; then
  __fzf_git_list_bindings
  exit
fi

# Reported here instead of on installation, because a message has nowhere to
# go while .tmux.conf is being processed
if [[ ! -r $__fzf_git ]]; then
  tmux display-message "fzf-git.sh not found in $(dirname "$__fzf_git_tmux")"
  exit 0
fi

# Run in the working directory of the pane. fzf starts the floating pane there.
dir=$(tmux display-message -p -t "$TMUX_PANE" '#{pane_current_path}')
[[ -d $dir ]] && cd "$dir"

# SHELL is forced to bash, like in fzf-git.fish, because the tmux server
# environment carries the shell of whoever started it
result=$(SHELL=bash bash "$__fzf_git" --run "$1" | __fzf_git_join)
[[ -n $result ]] && tmux send-keys -t "$TMUX_PANE" -l -- "$result "

# tmux opens a window to report a non-zero exit status of a run-shell command
exit 0

fi # Installing the key bindings -----------------------------------------------

self=$(__fzf_git_quote "$__fzf_git_tmux")

# tmux expands formats in a run-shell command, so '#' has to be doubled there
self_format=${self//#/##}

tmux bind-key "$(__fzf_git_key)" switch-client -T fzf-git

while read -r key type _; do
  if [[ $key == '?' ]]; then
    # The list of bindings is plain text, so a popup is enough
    tmux bind-key -T fzf-git "$key" display-popup -E -w 60 -h 16 "bash $self $type"
  else
    # TMUX_PANE tells fzf which window to open the floating pane in, and this
    # script which pane to send the result to. run-shell is backgrounded so
    # that it does not block key processing for the client.
    tmux bind-key -T fzf-git "$key" run-shell -b "TMUX_PANE=#{pane_id} bash $self_format $type"
  fi
done < <(__fzf_git_bindings)
