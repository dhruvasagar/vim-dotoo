if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

function! s:RefileAndClose()
  let dotoo = dotoo#parser#parse({'lines': getline(1,'$'), 'force': 1})
  let headline = dotoo.headlines[0]
  if g:dotoo#capture#clock | call dotoo#clock#stop(headline) | endif
  set nomodified
  silent exe 'keepalt' 'split' g:dotoo#capture#refile_to
  call append('$', headline.serialize())
  wq
endfunction

augroup BufWrite
  au!

  autocmd BufHidden <buffer> call s:RefileAndClose()
augroup END
nnoremap <buffer> <silent> <C-A> :<C-U>call dotoo#increment_date()<CR>
nnoremap <buffer> <silent> <C-X> :<C-U>call dotoo#decrement_date()<CR>
