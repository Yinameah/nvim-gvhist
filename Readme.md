# Gvhist

An history for `gv` (visual selection)

# What why

`gv` is a great shortcut. Allows to re select the last visual selection.

Recently, I've been working from nvim with repl in jupyter style extensively, and I started to miss circling back in selection history.

(Very happy with [yarepl](https://github.com/milanglacier/yarepl.nvim), shout out to the author)

Did not find anything useful on the topic, so wrote this small plugin.

![screencast](demo.gif)

# How

## Installation

With lazy.nvim :
```lua
return {
    "Yinameah/nvim-gvhist",
    opts = {
	-- Max number of selection to remember
	-- This is a per window number
	hist_max = 100,
	-- If set to false, no mapping will be set.
	default_mapping = true,
    },
},
```

## Usage

The plugin provides only two functions :
- `require("gvhist").sel_prev()` 
- `require("gvhist").sel_next()` 

By default, they are mapped to `<c-p>` & `<c-n>` in visual mode only, but you can disable this and map it the way you like.

The selection history is per window, but nothing special is done when the buffer is modified, which means the selection history will end up all over the place.
`GvhistClear` user command is provided to delete the history in case of need.
