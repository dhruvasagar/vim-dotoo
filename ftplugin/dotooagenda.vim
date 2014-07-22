if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

nnoremap <buffer> <silent> <nowait> q :<C-U>quit<CR>
nnoremap <buffer> <silent> <nowait> C :<C-U>call dotoo#capture#capture()<CR>
nnoremap <buffer> <silent> <nowait> s :<C-U>call dotoo#agenda#save_files()<CR>
nnoremap <buffer> <silent> <nowait> r :<C-U>call dotoo#agenda#refresh_view()<CR>
