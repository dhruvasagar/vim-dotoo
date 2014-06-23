if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

nnoremap <buffer> <silent> gC :<C-U>call dotoo#capture#capture()<CR>
