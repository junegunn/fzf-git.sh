fzf-git.sh
==========

bash and zsh key bindings for Git objects, powered by [fzf][fzf].

<img width="1680" alt="image" src="https://user-images.githubusercontent.com/700826/185568470-20d70937-eea4-4274-aec5-14dfe7ee2de6.png">

Each binding will allow you to browse through Git objects of a certain type,
and select the objects you want to paste to your command-line.

[fzf]: https://github.com/junegunn/fzf
[fzf-tmux]: https://github.com/junegunn/fzf/blob/master/bin/fzf-tmux
[zsh-vi-mode]: https://github.com/jeffreytse/zsh-vi-mode

Installation
------------

1. Install the latest version of [fzf][fzf] (including [fzf-tmux][fzf-tmux])
    * (Optional) Install [bat](https://github.com/sharkdp/bat) for
      syntax-highlighted file previews
1. Source [fzf-git.sh](https://raw.githubusercontent.com/junegunn/fzf-git.sh/main/fzf-git.sh) file from your .bashrc or .zshrc

Usage
-----

### List of bindings

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
  fzf-tmux -p80%,60% -- \
    --layout=reverse --multi --height=50% --min-height=20 --border \
    --border-label-pos=2 \
    --color='header:italic:underline,label:blue' \
    --preview-window='right,50%,border-left' \
    --bind='ctrl-/:change-preview-window(down,50%,border-top|hidden|)' "$@"
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

Note for [zsh-vi-mode] users
----------------------------

The built-in vi mode for zsh should work fine, but if you use the [zsh-vi-mode]
plugin for ZSH then you will need to add the following to your `.zshrc` file
in order to use the key bindings:

```sh
# Set key bindings for zsh-vi-mode insert mode.
function zvm_after_init() {
  zvm_bindkey viins "^P" up-line-or-beginning-search
  zvm_bindkey viins "^N" down-line-or-beginning-search
  for o in files branches tags remotes hashes stashes lreflogs each_ref; do
    eval "zvm_bindkey viins '^g^${o[1]}' fzf-git-$o-widget"
    eval "zvm_bindkey viins '^g${o[1]}' fzf-git-$o-widget"
  done
}
# Set key bindings for zsh-vi-mode normal and visual modes.
function zvm_after_lazy_keybindings() {
  for o in files branches tags remotes hashes stashes lreflogs each_ref; do
    eval "zvm_bindkey vicmd '^g^${o[1]}' fzf-git-$o-widget"
    eval "zvm_bindkey vicmd '^g${o[1]}' fzf-git-$o-widget"
    eval "zvm_bindkey visual '^g^${o[1]}' fzf-git-$o-widget"
    eval "zvm_bindkey visual '^g${o[1]}' fzf-git-$o-widget"
  done
}
```
