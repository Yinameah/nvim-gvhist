# Gvhist

An history for `gv` (visual selection)

# What why

`gv` is a great shortcut. Allows to re select the last visual selection.

Recently, I've been working from nvim with repl in jupyter style extensively, and I started to miss circling back in selection history.

(Very happy with [yarepl](https://github.com/milanglacier/yarepl.nvim), shout out to the author)

Did not find anything useful on the topic, so wrote this small plugin.

# How

## Installation

With lazy.nvim :
```lua
return {
    "Yinameah/nvim-gvhist",
    opts = { hist_max },
},
```

## Usage


