function __fzf_git_sh
    # Get the absolute path to the parent directory of this script (i.e. the
    # parent directory of fzf-git.sh) to use in the key bindings to avoid
    # having to modify `$PATH`.
    set --function fzf_git_sh_path (realpath (status dirname))

    set --function result (SHELL=bash bash "$fzf_git_sh_path/fzf-git.sh" --run $argv | string join ' ')

    if status is-command-substitution && test -n "$result"
        echo -- $result
    else
        commandline --insert $result
        commandline -f repaint
    end
end

set --local commands branches each_ref files hashes lreflogs remotes stashes tags worktrees

for command in $commands
    set --function key (string sub --length=1 $command)

    eval "bind -M default \cg$key   '__fzf_git_sh $command'"
    eval "bind -M insert  \cg$key   '__fzf_git_sh $command'"
    eval "bind -M default \cg\c$key '__fzf_git_sh $command'"
    eval "bind -M insert  \cg\c$key '__fzf_git_sh $command'"
end
