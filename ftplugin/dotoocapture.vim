if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

setl commentstring=#\ %s

function! s:RefileAndClose()
  let dotoo = dotoo#parser#parse({'lines': getline(1,'$'), 'force': 1})
  let headline = dotoo.headlines[0]
  if g:dotoo#capture#clock | call dotoo#clock#stop(headline) | endif
  set nomodified
  call dotoo#move_headline(headline, b:capture_target)
  wq
endfunction

augroup BufWrite
  au!

  autocmd BufHidden <buffer> call s:RefileAndClose()
augroup END

nmap <buffer> <C-A> <Plug>DotooIncrementDate
nmap <buffer> <C-X> <Plug>DotooIncrementDate
nmap <buffer> cic   <Plug>DotooCheckboxToggle
