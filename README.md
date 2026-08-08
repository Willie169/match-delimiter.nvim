# match-delimiter.nvim

## Installation

Install the plugin with your preferred package manager, e.g., [folke/lazy.nvim](https://github.com/folke/lazy.nvim):
```lua
return {
    "Willie169/match-delimiter.nvim",
    config = function()
        require("match-delimiter"),setup()
    end
}
```

## Configuration

Default configuration:
```lua
require("match-delimiter"),setup({
	ignored_ts_nodes = {
		"line_comment",
		"comment",
		"string",
	},
	width = 40,
    mappings = {
        round = "<leader>(",
        square = "<leader>[",
        curly = "<leader>{",
    },
})
```

