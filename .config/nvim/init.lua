vim.cmd([[

" Source Plugins from Vim Plug
source $HOME/.config/nvim/vim-plug/plugins.vim

" Set Theme
colorscheme tokyonight-night
" colorscheme catppuccin-frappe

]])

require('neo-tree').setup {
  close_if_last_window = true,
  source_selector = {
    winbar = true,
    statusline = false
  },
  filesystem = {
    filtered_items = {
      visible = true,
      never_show = {
        ".git"
      }
    }
  }
}

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
    },
    close_command = "Bdelete! %d",
  }
}

require('gitsigns').setup {
  current_line_blame = true,
}

require('neogit').setup {
  kind = "split_below_all"
}

require('Comment').setup()

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

vim.keymap.set('n', '<leader>bn', '<cmd>bnext<cr>', { desc = 'Buffer next' })
vim.keymap.set('n', '<leader>bp', '<cmd>bprevious<cr>', { desc = 'Buffer previous' })
vim.keymap.set('n', '<leader>bd', '<cmd>Bdelete<cr>', { desc = 'Buffer delete (keep window)' })

vim.keymap.set('n', '<leader>lg', '<cmd>LazyGit<cr>', { desc = 'Open lazy git' })

vim.opt.whichwrap:append("<,>,[,],h,l") -- arrow keys wrap across lines

vim.keymap.set('n', '<leader>e', '<cmd>Neotree focus<cr>', { desc = 'Focus neo-tree' })
vim.keymap.set('n', '<leader>eg', '<cmd>Neotree focus git_status<cr>', { desc = 'Focus neo-tree in git status' })

-- Neotree - Focus on opened file
local is_quitting = false
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function() is_quitting = true end,
})

vim.api.nvim_create_autocmd("BufEnter", {
  callback = function(args)
    if is_quitting then return end
    if vim.bo.filetype == "neo-tree" or vim.bo.buftype ~= "" then
      return
    end
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "neo-tree" then
        vim.schedule(function()
          local current_win = vim.api.nvim_get_current_win()
          vim.cmd("Neotree reveal")
          vim.api.nvim_set_current_win(current_win)
        end)    
        break
      end      
    end
  end,
})

