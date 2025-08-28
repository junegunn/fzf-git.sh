function __fzf_git_fish
    commandline --insert (eval $argv | string join ' ')
end

set --local commands branches each_ref files hashes lreflogs remotes stashes tags worktrees

# Get the absolute path to the parent directory of this script (i.e. the parent
# directory of fzf-git.sh) to use in the key bindings to avoid having to modify
# `$PATH`.
set --local fzf_git_sh_path (realpath (status dirname))
echo $fzf_git_sh_path
for command in $commands
    set --function key (string sub --end=1 $command)

    eval "bind \cg$key   '__fzf_git_fish \"bash \'$fzf_git_sh_path/fzf-git.sh\' --run $command\"'"
    eval "bind \cg\c$key '__fzf_git_fish \"bash \'$fzf_git_sh_path/fzf-git.sh\' --run $command\"'"
end
