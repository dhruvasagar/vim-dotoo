if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

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

function! s:DotooCycle(expand) abort
  if foldclosed('.') == -1
    let cflvl = foldlevel('.')
    normal! zj
    let nflvl = foldlevel('.')
    let nfc = foldclosed('.')
    exec "normal! \<C-o>"
    if nflvl > cflvl
      if nfc != -1
        if a:expand
          normal! zxzczO
        else
          normal! zc
        endif
      else
        if a:expand
          normal! zc
        else
          normal zxzczo
        endif
      endif
    else
      normal! zc
    endif
  else
    normal! zxzczo
  endif
endfunction

nnoremap <silent> <Plug>(dotoo-cycle) :<C-U>call <SID>DotooCycle(1)<CR>
nnoremap <silent> <Plug>(dotoo-cycle-rev) :<C-U>call <SID>DotooCycle(0)<CR>

" autocmd! TextChanged,TextChangedI <buffer> call dotoo#parser#parsefile({})
autocmd! BufWritePost <buffer> call dotoo#parser#parsefile({'force': 1})

iabbrev <expr> <buffer> <silent> :date: '['.strftime(g:dotoo#time#date_day_format).']'
iabbrev <expr> <buffer> <silent> :time: '['.strftime(g:dotoo#time#datetime_format).']'

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
