if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

setl foldlevel=1
setl commentstring=#\ %s
setl foldexpr=DotooFoldExpr()
setl foldmethod=expr
setl foldtext=getline(v:foldstart)
setl omnifunc=dotoo#autocompletion#omni

let s:syntax = dotoo#parser#lexer#syntax()
function! DotooFoldExpr()
  let line = getline(v:lnum)
  if s:syntax.directive.matches(line)
    return 0
  elseif s:syntax.headline.matches(line)
    let level = len(s:syntax.headline.matchlist(line)[0])
    return '>'.level
  elseif s:syntax.properties.matches(line)
    return 'a1'
  elseif s:syntax.logbook.matches(line)
    return 'a1'
  elseif s:syntax.drawer_end.matches(line)
    return 's1'
  else
    return '='
  endif
endfunction

let s:local_cycle_state = {}

function! s:DotooCycle(expand) abort
  " fold cycle states :
  " 0 - folded
  " 1 - showing children
  " 2 - showing subtree
  let file = expand('%:p')
  let line = line('.')

  if !has_key(s:local_cycle_state, file)
    let s:local_cycle_state[file] = {}
  endif

  let cfl = foldlevel('.')

  if cfl == 0
    if a:expand
      normal! zr
    else
      normal! zm
    endif
    return
  endif

  if !has_key(s:local_cycle_state[file], line)
    let s:local_cycle_state[file][line] = 0
    " when fold is open, default it to `showing subtree` state unless a state
    " has already been set for that line
    if foldclosed('.') == -1 && !has_key(s:local_cycle_state[file], line)
      normal! zj
      if foldlevel('.') > cfl " is a child node
        if foldclosed('.') == -1 "child node is open
          let s:local_cycle_state[file][line] = 2
        else
          let s:local_cycle_state[file][line] = 1
        endif
      endif
      normal! zk
    endif
  endif

  let cycle_state = s:local_cycle_state[file][line]
  if a:expand
    if cycle_state == 0
      normal! zo
    elseif cycle_state == 1
      normal! zczO
    else
      normal! zX
    end
    let s:local_cycle_state[file][line] = (cycle_state + 1) % 3
  else
    if cycle_state == 0
      normal! zO
    elseif cycle_state == 1
      normal! zX
    else
      normal! zx
    end
    let s:local_cycle_state[file][line] = (cycle_state - 1) % 3
  endif
endfunction

nnoremap <silent> <Plug>(dotoo-cycle) :<C-U>call <SID>DotooCycle(1)<CR>
nnoremap <silent> <Plug>(dotoo-cycle-rev) :<C-U>call <SID>DotooCycle(0)<CR>

" autocmd! TextChanged,TextChangedI <buffer> call dotoo#parser#parsefile({})
autocmd! BufWritePost <buffer> call dotoo#parser#parsefile({'force': 1})

iabbrev <expr> <buffer> <silent> :time: '['.strftime(g:dotoo#time#time_format).']'
iabbrev <expr> <buffer> <silent> :date: '['.strftime(g:dotoo#time#date_day_format).']'
iabbrev <expr> <buffer> <silent> :datetime: '['.strftime(g:dotoo#time#datetime_format).']'

if !g:dotoo_disable_mappings
  if !hasmapto('<Plug>(dotoo-clock-start)')
    nmap <buffer> gI <Plug>(dotoo-clock-start)
  endif
  if !hasmapto('<Plug>(dotoo-clock-stop)')
    nmap <buffer> gO <Plug>(dotoo-clock-stop)
  endif
  if !hasmapto('<Plug>(dotoo-headline-move-menu)')
    nmap <buffer> gM <Plug>(dotoo-headline-move-menu)
  endif
  if !hasmapto('<Plug>(dotoo-headline-change-todo)')
    nmap <buffer> cit <Plug>(dotoo-headline-change-todo)
  endif
  if !hasmapto('<Plug>(dotoo-checkbox-toggle)')
    nmap <buffer> cic <Plug>(dotoo-checkbox-toggle)
  endif
  if !hasmapto('<Plug>(dotoo-date-increment)')
    nmap <buffer> <C-A> <Plug>(dotoo-date-increment)
  endif
  if !hasmapto('<Plug>(dotoo-date-decrement)')
    nmap <buffer> <C-X> <Plug>(dotoo-date-decrement)
  endif
  if !hasmapto('<Plug>(dotoo-link-follow)')
    nmap <buffer> <CR> <Plug>(dotoo-link-follow)
  endif
  if !hasmapto('<Plug>(dotoo-link-back)')
    nmap <buffer> <BS> <Plug>(dotoo-link-back)
  endif
  if !hasmapto('<Plug>(dotoo-date-normalize)')
    nmap <buffer> <C-C><C-C> <Plug>(dotoo-date-normalize)
  endif
  if !hasmapto('<Plug>(dotoo-cycle)')
    nmap <buffer> <Tab> <Plug>(dotoo-cycle)
  endif
  if !hasmapto('<Plug>(dotoo-cycle-rev)')
    nmap <buffer> <S-Tab> <Plug>(dotoo-cycle-rev)
  endif
endif

command! -buffer -nargs=? DotooAdjustDate call dotoo#date#adjust(<q-args>)
