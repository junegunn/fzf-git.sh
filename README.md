fzf-git.sh
==========

bash and zsh key bindings for Git objects, powered by [fzf][fzf].

[fzf]: https://github.com/junegunn/fzf

Installation
------------

1. Install the latest version of [fzf][fzf]
2. Source [fzf-git.sh](fzf-git.sh) file from your .bashrc or .zshrc.

Usage
-----

* <kbd>CTRL-G</kbd><kbd>CTRL-F</kbd> for **F**iles
* <kbd>CTRL-G</kbd><kbd>CTRL-B</kbd> for **B**ranches
* <kbd>CTRL-G</kbd><kbd>CTRL-T</kbd> for **T**ags
* <kbd>CTRL-G</kbd><kbd>CTRL-R</kbd> for **R**emotes
* <kbd>CTRL-G</kbd><kbd>CTRL-H</kbd> for commit **H**ashes
* <kbd>CTRL-G</kbd><kbd>CTRL-S</kbd> for **S**tashes

Customization
-------------

```sh
# Redefine this function to change the options
_fzf_git_fzf() {
  fzf-tmux -p80%,60% -- \
    --layout=reverse --multi --height=50% --min-height=20 --border \
    --preview-window='right,50%,border-left' \
    --bind='ctrl-/:change-preview-window(down,50%,border-top|hidden|)' "$@"
}
```
