fzf-git.sh
==========

**FORK** of  [junegunn/fzf-git.sh](https://github.com/junegunn/fzf-git.sh)


Installation
------------

```sh
FZF_GIT_SCRIPT=~/fzf-git.sh/fzf-git.sh
[ ! -f "$FZF_GIT_SCRIPT" ] && \
  cd $HOME && git clone https://github.com/juanMarinero/fzf-git.sh
source "$FZF_GIT_SCRIPT"
```

Purpose
------------

Integrate **Vim** navigation alike [vimcast-34](http://vimcasts.org/episodes/fugitive-vim-browsing-the-git-object-database/) and  [vimcast-35](http://vimcasts.org/episodes/fugitive-vim-exploring-the-history-of-a-git-repository/).

License
------------

MIT License (MIT)
