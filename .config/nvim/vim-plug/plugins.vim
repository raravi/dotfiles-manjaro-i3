" auto-install vim-plug
let data_dir = '~/.config/nvim/autoload/plug.vim'
if empty(glob(data_dir))
  silent execute '!curl -fLo '.data_dir.' --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
endif

" Run PlugInstall if there are missing plugins
autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \| PlugInstall --sync | source ~/.config/nvim/init.lua
\| endif

call plug#begin('~/.config/nvim/autoload/plugged')

  Plug 'folke/tokyonight.nvim' " Theme - Tokyo Night

  Plug 'nvim-lua/plenary.nvim'
  Plug 'nvim-tree/nvim-web-devicons'
  Plug 'MunifTanjim/nui.nvim'
  Plug 'nvim-neo-tree/neo-tree.nvim', { 'branch': 'v3.x' }

  Plug 'sindrets/diffview.nvim'
  Plug 'nvim-telescope/telescope.nvim'
  Plug 'NeogitOrg/neogit'

  Plug 'lewis6991/gitsigns.nvim'

  Plug 'akinsho/bufferline.nvim', { 'tag': '*' }

  Plug 'kdheepak/lazygit.nvim'

call plug#end()
