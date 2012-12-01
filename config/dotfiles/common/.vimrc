" based in the runtime debian
runtime! debian.vim

" syntax highlighting
if has("syntax")
    syntax on
endif

" background light
set background=light

" re-open in the last position
if has("autocmd")
    au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif

" indentation rules
if has("autocmd")
    filetype plugin indent on
endif

" show matching brackets
set showmatch

" do case insensitive matching
set ignorecase
