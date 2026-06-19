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

require("bufferline").setup {
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

vim.keymap.set('n', 'j', 'gj', { noremap = true })
vim.keymap.set('n', 'k', 'gk', { noremap = true })
vim.opt.whichwrap:append("<,>,[,],h,l") -- arrow keys wrap across lines

vim.keymap.set('n', '<leader>e', '<cmd>Neotree focus<cr>', { desc = 'Focus neo-tree' })
vim.keymap.set('n', '<leader>eg', '<cmd>Neotree focus git_status<cr>', { desc = 'Focus neo-tree in git status' })

-- Neotree - Focus on opened file
local is_quitting = false
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function() is_quitting = true end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
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

-- Configure LSP Servers (built-in Neovim 0.11+)
vim.lsp.config('ts_ls', {
  init_options = { hostInfo = 'neovim' },
})
vim.lsp.config('eslint', {})
vim.lsp.enable('ts_ls')
vim.lsp.enable('eslint')

-- LSP Keymaps (auto-attached to buffers with LSP)
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
  callback = function(ev)
    vim.schedule(function()
      local function map(lhs, rhs)
        vim.api.nvim_buf_set_keymap(ev.buf, 'n', lhs, '<cmd>lua ' .. rhs .. '<CR>', { silent = true })
      end
      map('gd', 'vim.lsp.buf.definition()')
      map('K', 'vim.lsp.buf.hover()')
      map('gr', 'vim.lsp.buf.references()')
      map('<leader>rn', 'vim.lsp.buf.rename()')
      map('<leader>ca', 'vim.lsp.buf.code_action()')
      map('<leader>d', 'vim.diagnostic.open_float()')
      map('[d', 'vim.diagnostic.goto_prev()')
      map(']d', 'vim.diagnostic.goto_next()')
    end)
  end,
})

-- autocompletion
require('blink.cmp').setup({
  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },
  },
  keymap = {
    preset = 'default',
    ['<CR>'] = { 'select_and_accept', 'fallback' },
    ['<Tab>'] = { 'select_next', 'fallback' },
    ['<S-Tab>'] = { 'select_prev', 'fallback' },
  },
})

require('rainbow-delimiters.setup').setup({})

require('render-markdown').setup({})

