if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

if !g:dotoo_disable_mappings
  nmap <buffer> <nowait> q :<C-U>quit<CR>
  nmap <buffer> <nowait> C <Plug>(dotoo-capture)

  if !hasmapto('<Plug>(dotoo-agenda-refresh)')
    nmap <buffer> <nowait> r <Plug>(dotoo-agenda-refresh)
  endif
  if !hasmapto('<Plug>(dotoo-agenda-save-files)')
    nmap <buffer> <nowait> s <Plug>(dotoo-agenda-save-files)
  endif
  if !hasmapto('<Plug>(dotoo-agenda-headline-move)')
    nmap <buffer> <nowait> m <Plug>(dotoo-agenda-headline-move)
  endif
  if !hasmapto('<Plug>(dotoo-agenda-headline-change-todo)')
    nmap <buffer> <nowait> c <Plug>(dotoo-agenda-headline-change-todo)
  endif
  if !hasmapto('<Plug>(dotoo-agenda-headline-undo-change)')
    nmap <buffer> <nowait> u <Plug>(dotoo-agenda-headline-undo-change)
  endif
  if !hasmapto('<Plug>(dotoo-agenda-headline-clock-start)')
    nmap <buffer> <nowait> i <Plug>(dotoo-agenda-headline-clock-start)
  endif
  if !hasmapto('<Plug>(dotoo-agenda-headline-clock-stop)')
    nmap <buffer> <nowait> o <Plug>(dotoo-agenda-headline-clock-stop)
  endif
  if !hasmapto('<Plug>(dotoo-agenda-filter)')
    nmap <buffer> <nowait> / <Plug>(dotoo-agenda-filter)
  endif

  nmap <buffer> <silent> <nowait> <CR> :<C-U>call dotoo#agenda#goto_headline('edit')<CR>
  nmap <buffer> <silent> <nowait> <C-S> :<C-U>call dotoo#agenda#goto_headline('split')<CR>
  nmap <buffer> <silent> <nowait> <C-V> :<C-U>call dotoo#agenda#goto_headline('vsplit')<CR>
  nmap <buffer> <silent> <nowait> <C-T> :<C-U>call dotoo#agenda#goto_headline('tabe')<CR>
  nmap <buffer> <silent> <nowait> <Tab> <C-V>
endif
