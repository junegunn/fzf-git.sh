fzf-git.sh
==========

bash, zsh, and fish key bindings for Git objects, powered by [fzf][fzf].

<img width="1680" alt="image" src="https://user-images.githubusercontent.com/700826/185568470-20d70937-eea4-4274-aec5-14dfe7ee2de6.png">

Each binding will allow you to browse through Git objects of a certain type,
and select the objects you want to paste to your command-line.

[fzf]: https://github.com/junegunn/fzf

Installation
------------

* Install the latest version of [fzf][fzf]
    * (Optional) Install [bat](https://github.com/sharkdp/bat) for
      syntax-highlighted file previews
    * Git v2.42.0 or later is required for the `git for-each-ref` binding
* Update your shell configuration file
    * bash or zsh
        * Source [fzf-git.sh](https://raw.githubusercontent.com/junegunn/fzf-git.sh/main/fzf-git.sh) file from your .bashrc or .zshrc
    * fish
        * Source [fzf-git.fish](https://raw.githubusercontent.com/junegunn/fzf-git.sh/main/fzf-git.fish) from your config.fish

Usage
-----

### List of bindings

* <kbd>CTRL-G</kbd><kbd>?</kbd> to show this list
* <kbd>CTRL-G</kbd><kbd>CTRL-F</kbd> for **F**iles
* <kbd>CTRL-G</kbd><kbd>CTRL-B</kbd> for **B**ranches
* <kbd>CTRL-G</kbd><kbd>CTRL-T</kbd> for **T**ags
* <kbd>CTRL-G</kbd><kbd>CTRL-R</kbd> for **R**emotes
* <kbd>CTRL-G</kbd><kbd>CTRL-H</kbd> for commit **H**ashes
* <kbd>CTRL-G</kbd><kbd>CTRL-S</kbd> for **S**tashes
* <kbd>CTRL-G</kbd><kbd>CTRL-L</kbd> for ref**l**ogs
* <kbd>CTRL-G</kbd><kbd>CTRL-W</kbd> for **W**orktrees
* <kbd>CTRL-G</kbd><kbd>CTRL-E</kbd> for **E**ach ref (`git for-each-ref`)

> [!WARNING]
> You may have issues with these bindings in the following cases:
>
> * <kbd>CTRL-G</kbd><kbd>CTRL-B</kbd> will not work if
>   <kbd>CTRL-B</kbd> is used as the tmux prefix
> * <kbd>CTRL-G</kbd><kbd>CTRL-S</kbd> will not work if flow control is enabled,
>   <kbd>CTRL-S</kbd> will freeze the terminal instead
>     * (`stty -ixon` will disable it)
>
> To workaround the problems, you can use
> <kbd>CTRL-G</kbd><kbd>*{key}*</kbd> instead of
> <kbd>CTRL-G</kbd><kbd>CTRL-*{KEY}*</kbd>.
>

> [!WARNING]
> If zsh's `KEYTIMEOUT` is too small (e.g. 1), you may not be able
> to hit two keys in time.

### Inside fzf

* <kbd>TAB</kbd> or <kbd>SHIFT-TAB</kbd> to select multiple objects
* <kbd>CTRL-/</kbd> to change preview window layout
* <kbd>CTRL-O</kbd> to open the object in the web browser (in GitHub URL scheme)

Customization
-------------

```sh
# Redefine this function to change the options
_fzf_git_fzf() {
  fzf --height 50% --tmux 90%,70% \
    --layout reverse --multi --min-height 20+ \
    --no-separator --header-border horizontal \
    --border-label-pos 2 \
    --color 'label:blue' \
    --preview-window 'right,50%' --preview-border line \
    --bind "${FZF_GIT_KEY_TOGGLE_PREVIEW:-ctrl-/}:change-preview-window(down,50%|hidden|)" "$@"
}
```

Defining shortcut commands
--------------------------

Each binding is backed by `_fzf_git_*` function so you can do something like
this in your shell configuration file.

```sh
gco() {
  _fzf_git_each_ref --no-multi | xargs git checkout
}

gswt() {
  cd "$(_fzf_git_worktrees --no-multi)"
}
```

Environment Variables
---------------------

### General

| Variable                | Description                                              | Default                                         |
| ----------------------- | -------------------------------------------------------- | ----------------------------------------------- |
| `BAT_STYLE`             | Specifies the style for displaying files using `bat`     | `full`                                          |
| `FZF_GIT_CAT`           | Defines the preview command used for displaying the file | `bat --style=$BAT_STYLE --color=$FZF_GIT_COLOR` |
| `FZF_GIT_COLOR`         | Set to `never` to suppress colors in the list            | `always`                                        |
| `FZF_GIT_FZF_CUSTOM_ARGS` | Appends custom arguments to every fzf invocation       |                                                 |
| `FZF_GIT_PAGER`         | Specifies the pager command for the preview window       | `$(git config --get core.pager)`                |
| `FZF_GIT_PREVIEW_COLOR` | Set to `never` to suppress colors in the preview window  | `always`                                        |

### Inside fzf

Binding values use the key names accepted by [fzf], such as `ctrl-e` or `f2`.
Export them so that bindings and their labels are also available to child
processes.

```sh
export FZF_GIT_KEY_OPEN_EDITOR=f2
export FZF_GIT_KEY_SHOW_ALL=ctrl-a
```

| Variable                            | Action                                      | Default     |
| ----------------------------------- | ------------------------------------------- | ----------- |
| `FZF_GIT_KEY_ACCEPT_WITHOUT_REMOTE` | Accept a ref without its remote prefix      | `alt-enter` |
| `FZF_GIT_KEY_DROP_STASH`            | Drop the selected stash                     | `ctrl-x`    |
| `FZF_GIT_KEY_LIST_FILES`            | List files from the selected commits        | `alt-f`     |
| `FZF_GIT_KEY_LIST_HASHES`           | List commit hashes for the selected branch  | `alt-h`     |
| `FZF_GIT_KEY_OPEN_BROWSER`          | Open the selected object in the web browser | `ctrl-o`    |
| `FZF_GIT_KEY_OPEN_EDITOR`           | Open the selected object in the editor      | `alt-e`     |
| `FZF_GIT_KEY_REMOVE_WORKTREE`       | Remove the selected worktree                | `ctrl-x`    |
| `FZF_GIT_KEY_SHOW_ALL`              | Include remote branches, hashes, or refs    | `alt-a`     |
| `FZF_GIT_KEY_SHOW_DIFF`             | Show the selected commit's diff             | `ctrl-d`    |
| `FZF_GIT_KEY_TOGGLE_PREVIEW`        | Change the preview window layout            | `ctrl-/`    |
| `FZF_GIT_KEY_TOGGLE_RAW`            | Toggle raw mode                             | `alt-r`     |
| `FZF_GIT_KEY_TOGGLE_SORT`           | Toggle sorting                              | `ctrl-s`    |

### Shell launcher bindings

Launcher values must be single alphanumeric characters, except that the help
key can also be `?`. The prefix is always combined with `CTRL`; action keys are
bound both with and without `CTRL`. For example, these settings bind files to
<kbd>CTRL-X</kbd><kbd>P</kbd> and <kbd>CTRL-X</kbd><kbd>CTRL-P</kbd>:

```sh
export FZF_GIT_LAUNCHER_PREFIX=x
export FZF_GIT_LAUNCHER_FILES=p
```

Set launcher variables before sourcing the script.

| Variable                       | Action                     | Default |
| ------------------------------ | -------------------------- | ------- |
| `FZF_GIT_LAUNCHER_PREFIX`      | Prefix for every launcher  | `g`     |
| `FZF_GIT_LAUNCHER_FILES`       | List files                 | `f`     |
| `FZF_GIT_LAUNCHER_BRANCHES`    | List branches              | `b`     |
| `FZF_GIT_LAUNCHER_TAGS`        | List tags                  | `t`     |
| `FZF_GIT_LAUNCHER_REMOTES`     | List remotes               | `r`     |
| `FZF_GIT_LAUNCHER_HASHES`      | List commit hashes         | `h`     |
| `FZF_GIT_LAUNCHER_STASHES`     | List stashes               | `s`     |
| `FZF_GIT_LAUNCHER_REFLOGS`     | List reflogs               | `l`     |
| `FZF_GIT_LAUNCHER_WORKTREES`   | List worktrees             | `w`     |
| `FZF_GIT_LAUNCHER_EACH_REF`    | List each ref              | `e`     |
| `FZF_GIT_LAUNCHER_HELP`        | Show the binding list      | `?`     |
