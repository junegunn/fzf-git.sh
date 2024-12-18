function __fzf_git_fish
    commandline --insert (eval $argv)
end

set commands branches each_ref files hashes lreflogs remotes stashes tags worktrees

for command in $commands
    set key (string sub --end=1 $command)

    eval "bind \cg$key \"__fzf_git_fish 'bash fzf-git.sh --run $command'\""
    eval "bind \cg\c$key \"__fzf_git_fish 'bash fzf-git.sh --run $command'\""
end
