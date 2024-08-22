function! s:find_references() abort
  let fname = expand('%:t:r')
  let pat = fname
  let pdir = expand('%:h:t')
  if pdir !=# 'pages'
    let pat = printf('%s/%s', pdir, fname)
  endif
  silent! exec 'grep! "' . pat . '"' g:dotoo#home
  " Remove the current file from the results
  exec 'Cfilter!' expand('%')
  copen
endfunction

function! dotoo#references#show()
  return s:find_references()
endfunction
