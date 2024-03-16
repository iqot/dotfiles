setlocal foldmethod=indent
let b:ale_linters = ['pylint']
autocmd BufWritePost *.py execute ':Black'
