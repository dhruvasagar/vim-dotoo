if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

nnoremap <buffer> <silent> <nowait> q :<C-U>quit<CR>
nnoremap <buffer> <silent> <nowait> C :<C-U>call dotoo#capture#capture()<CR>
nnoremap <buffer> <silent> <nowait> s :<C-U>call dotoo#agenda#save_files()<CR>
nnoremap <buffer> <silent> <nowait> r :<C-U>call dotoo#agenda#refresh_view()<CR>
nnoremap <buffer> <silent> <nowait> m :<C-U>call dotoo#agenda#move_headline()<CR>
nnoremap <buffer> <silent> <nowait> c :<C-U>call dotoo#agenda#change_headline_todo()<CR>
nnoremap <buffer> <silent> <nowait> u :<C-U>call dotoo#agenda#undo_headline_change()<CR>
nnoremap <buffer> <silent> <nowait> i :<C-U>call dotoo#agenda#start_headline_clock()<CR>
nnoremap <buffer> <silent> <nowait> o :<C-U>call dotoo#agenda#stop_headline_clock()<CR>
nnoremap <buffer> <silent> <nowait> / :<C-U>call dotoo#agenda#filter_agendas()<CR>
nnoremap <buffer> <silent> <nowait> <CR> :<C-U>call dotoo#agenda#goto_headline('edit')<CR>
nnoremap <buffer> <silent> <nowait> <C-S> :<C-U>call dotoo#agenda#goto_headline('split')<CR>
nnoremap <buffer> <silent> <nowait> <C-V> :<C-U>call dotoo#agenda#goto_headline('vsplit')<CR>
nnoremap <buffer> <silent> <nowait> <C-T> :<C-U>call dotoo#agenda#goto_headline('tabe')<CR>
nmap <buffer> <silent> <Tab> <C-V>
