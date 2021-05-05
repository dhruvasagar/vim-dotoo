if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

setl commentstring=#\ %s
setl omnifunc=dotoo#autocompletion#omni

function! s:RefileAndClose()
  if &modified && confirm("Save changes ?", "&Yes\n&No") != 1
    setl nomodified
    return
  endif
  call dotoo#capture#refile_now()
endfunction

augroup BufWrite
  au!

  autocmd BufHidden <buffer> call s:RefileAndClose()
augroup END

iabbrev <expr> <buffer> <silent> :date: '['.strftime(g:dotoo#time#date_day_format).']'
iabbrev <expr> <buffer> <silent> :time: '['.strftime(g:dotoo#time#datetime_format).']'

if !g:dotoo_disable_mappings
  if !hasmapto('<Plug>(dotoo-checkbox-toggle)')
    nmap <buffer> cic <Plug>(dotoo-checkbox-toggle)
  endif
  if !hasmapto('<Plug>(dotoo-date-increment)')
    nmap <buffer> <C-A> <Plug>(dotoo-date-increment)
  endif
  if !hasmapto('<Plug>(dotoo-date-decrement)')
    nmap <buffer> <C-X> <Plug>(dotoo-date-decrement)
  endif
  if !hasmapto('<Plug>(dotoo-date-normalize)')
    nmap <buffer> <C-C><C-C> <Plug>(dotoo-date-normalize)
  endif
endif

command! -buffer -nargs=? DotooAdjustDate call dotoo#date#adjust(<q-args>)
