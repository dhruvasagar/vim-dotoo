if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

function! s:RefileAndClose()
  let dotoo = dotoo#parser#parse({'key': 'capture', 'lines': getline(1,'$'), 'force': 1})
  let headline = dotoo.headlines[0]
  if g:dotoo#capture#clock | call dotoo#clock#stop(headline) | endif
  silent exe 'edit' g:dotoo#capture#refile
  call append('$', headline.serialize())
  write
  quit
endfunction

augroup BufWrite
  au!

  autocmd BufWriteCmd <buffer> call s:RefileAndClose()
augroup END
