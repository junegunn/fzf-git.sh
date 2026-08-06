function __fzf_git_sh
    # Get the absolute path to the parent directory of this script (i.e. the
    # parent directory of fzf-git.sh) to use in the key bindings to avoid
    # having to modify `$PATH`.
    set --function fzf_git_sh_path (realpath (status dirname))

    if test "$argv" = list_bindings
        SHELL=bash bash "$fzf_git_sh_path/fzf-git.sh" --run $argv
        commandline -f repaint
        return
    end

    set --function result (SHELL=bash bash "$fzf_git_sh_path/fzf-git.sh" --run $argv | string join ' ')

    if status is-command-substitution && test -n "$result"
        echo -- $result
    else
        commandline --insert $result
        commandline -f repaint
    end
end

function __fzf_git_list_bindings
    set --function fzf_git_sh_path (realpath (status dirname))
    bash "$fzf_git_sh_path/fzf-git.sh" --run list_bindings
    commandline -f repaint
end

set --local commands branches each_ref files hashes lreflogs remotes stashes tags worktrees
set --local prefix g
set --local help_key '?'
set -q FZF_GIT_LAUNCHER_PREFIX; and set prefix $FZF_GIT_LAUNCHER_PREFIX
set -q FZF_GIT_LAUNCHER_HELP; and set help_key $FZF_GIT_LAUNCHER_HELP

if not string match --quiet --regex '^[a-zA-Z0-9]$' -- $prefix
    echo "fzf-git: launcher keys must be a single alphanumeric character" >&2
    return 1
end

if not string match --quiet --regex '^[a-zA-Z0-9?]$' -- $help_key
    echo "fzf-git: the launcher help key must be a single alphanumeric character or '?'" >&2
    return 1
end

bind -M default 'ctrl-g,?' '__fzf_git_sh list_bindings'
bind -M insert  'ctrl-g,?' '__fzf_git_sh list_bindings'

for command in $commands
    set --function key (string sub --length=1 $command)
    set --function variable FZF_GIT_LAUNCHER_(string upper $command)
    test $command = lreflogs; and set variable FZF_GIT_LAUNCHER_REFLOGS
    set -q $variable; and set key $$variable

    if not string match --quiet --regex '^[a-zA-Z0-9]$' -- $key
        echo "fzf-git: launcher keys must be a single alphanumeric character" >&2
        continue
    end

    eval "bind -M default \c$prefix$key   '__fzf_git_sh $command'"
    eval "bind -M insert  \c$prefix$key   '__fzf_git_sh $command'"
    eval "bind -M default \c$prefix\c$key '__fzf_git_sh $command'"
    eval "bind -M insert  \c$prefix\c$key '__fzf_git_sh $command'"
end

eval "bind -M default \c$prefix$help_key '__fzf_git_list_bindings'"
eval "bind -M insert  \c$prefix$help_key '__fzf_git_list_bindings'"
