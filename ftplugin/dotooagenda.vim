if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

nnoremap <buffer> <silent> <nowait> q :<C-U>bdelete<CR>
nnoremap <buffer> <silent> <nowait> r :<C-U>call dotoo#agenda#agenda(1)<CR>
nnoremap <buffer> <silent> <nowait> . :<C-U>call dotoo#agenda#shift_current_date('.')<CR>
nnoremap <buffer> <silent> <nowait> f :<C-U>call dotoo#agenda#shift_current_date('+1d')<CR>
nnoremap <buffer> <silent> <nowait> b :<C-U>call dotoo#agenda#shift_current_date('-1d')<CR>
nnoremap <buffer> <silent> <nowait> c :<C-U>call dotoo#agenda#change_headline_todo()<CR>
nnoremap <buffer> <silent> <nowait> u :<C-U>call dotoo#agenda#undo_headline_change()<CR>
nnoremap <buffer> <silent> <nowait> s :<C-U>call dotoo#agenda#save_files()<CR>
nnoremap <buffer> <silent> <nowait> C :<C-U>call dotoo#capture#capture()<CR>
nnoremap <buffer> <silent> <CR> :<C-U>call dotoo#agenda#goto_headline('edit')<CR>
nnoremap <buffer> <silent> <C-S> :<C-U>call dotoo#agenda#goto_headline('split')<CR>
nnoremap <buffer> <silent> <C-V> :<C-U>call dotoo#agenda#goto_headline('vsplit')<CR>
nnoremap <buffer> <silent> <C-T> :<C-U>call dotoo#agenda#goto_headline('tabe')<CR>
nmap <buffer> <silent> <Tab> <C-V>
