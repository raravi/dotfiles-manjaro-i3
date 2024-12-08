vim.cmd([[

" Source Plugins from Vim Plug
source $HOME/.config/nvim/vim-plug/plugins.vim

" Set Theme
colorscheme tokyonight-night

]])

require('neo-tree').setup {
  source_selector = {
    winbar = true,
    statusline = false
  }
}

require('gitsigns').setup {
  current_line_blame = true,
}

require('neogit').setup {
  kind = "split_below_all"
}

vim.opt.number         = true       -- line numbering
vim.opt.tabstop        = 2          -- tab space

-- Indentation Settings
vim.opt.expandtab      = true       -- converts tabs to spaces
vim.opt.shiftwidth     = 2
vim.opt.softtabstop    = 2

-- Search and Replace
--To ignore case in searches, unless capital letters are used
vim.opt.ignorecase     = true
vim.opt.smartcase      = true

-- Highlight Search Results
vim.opt.hlsearch       = true

-- Syntax Highlighting
vim.opt.syntax         = "on"

-- Enabling true color terminal allows Neovim to utilize 24-bit RGB color values, providing 
-- a more extensive and accurate range of colors
vim.opt.termguicolors  = true
require("bufferline").setup{
  options = {
    indicator = {
      icon = '/ ',
      style = 'icon'
    },
    separator_style = "slant",
    offsets = {
      {
        filetype = "neo-tree",
        text = "Neotree",
        separator = true
      }
    }
  }
}

-- Enable Spellchecking
vim.opt.spell          = true
vim.opt.spelllang      = "en_us"

vim.g.mapleader = ";"

-- ESC in insert & visual mode
vim.keymap.set("i", "jk", "<esc>")
vim.keymap.set("v", "jk", "<ESC>")

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })

vim.keymap.set('n', '<leader>lg', '<cmd>LazyGit<cr>', { desc = 'Open lazy git' })
