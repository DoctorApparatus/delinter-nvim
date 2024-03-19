# delinter-nvim

`delinter-nvim` is a Neovim plugin designed to enhance your development workflow by automatically adding specific attributes to elements based on linting errors, leveraging the power of Neovim's built-in functionality for precise analysis.

## Features

- **Automatic Attribute Insertion:** Automatically adds specified attributes to elements when triggered.
- **Configurable:** Offers settings to customize behavior based on user preferences.

## Requirements

- Neovim (v0.5.0 or later).

## Installation

You can install `delinter-nvim` using your favorite Neovim package manager. Here are examples for some popular ones:

### Vim-plug

```vim
Plug 'DoctorApparatus/delinter-nvim'
```

### packer.nvim

```lua
use {'DoctorApparatus/delinter-nvim'}
```

### lazy.nvim

```lua
return {
	"DoctorApparatus/delinter-nvim",
	config = function()
		require("delinter-nvim").setup({
			-- Assuming 'filetypes' is the correct key based on our discussion
			filetypes = {
				-- "typescriptreact",
				-- Add other filetypes as needed
			},
			debug = true,
		})
	end,
}

```
## Configuration

`delinter-nvim` is designed to work out of the box, but you can customize its behavior using the setup function. Here is an example configuration with all available options:

```lua
require('delinter-nvim').setup({
    -- Enables detailed debugging information
    debug = false,
})
```

## Usage

Once installed and configured, `delinter-nvim` will automatically add specified attributes to elements based on specific triggers (e.g., linting errors). You can also invoke its functionality manually through a command or keybinding if preferred.

## Contributing

Contributions to `delinter-nvim` are welcome! Please refer to the [CONTRIBUTING.md](CONTRIBUTING.md) file for guidelines.

## License

`delinter-nvim` is released under the MIT License. See the [LICENSE](LICENSE) file for more details.

## Acknowledgments

- Thanks to the Neovim community for the invaluable resources and support.
