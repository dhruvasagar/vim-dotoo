function! s:is_split_open(headline)
  return get(a:headline, 'split_open', 0)
endfunction

function! dotoo#headline#open(...) abort
  let cmd = a:0 ? a:1 : 'split'
  if expand('%:p') !=# a:headline.file
    if cmd ==# 'split'
      let a:headline.split_open = 1
      let a:headline.split_winnr = winnr()
    endif
    silent exec 'noauto' cmd a:headline.file
  endif
endfunction

function! dotoo#headline#close()
  if is_split_open(a:headline)
    hide
    exec a:headline.split_winnr . 'wincmd w'
    call remove(a:headline, 'split_open')
    call remove(a:headline, 'split_winnr')
  endif
endfunction

function! dotoo#headline#save(...) abort
  let cmd = a:0 ? a:1 : 'split'
  let old_view = winsaveview()
  call a:headline.open(cmd)
  call a:headline.delete()
  call append(a:headline.lnum-1, a:headline.serialize())
  silent write
  call a:headline.close()
  call winrestview(old_view)
endfunction

function! dotoo#headline#delete()
  silent exec self.lnum.','.self.last_lnum.':delete'
endfunction

function! dotoo#headline#undo(headline)
  call dotoo#headline#open(a:headline)
  normal! u
  call dotoo#headline#close(a:headline)
endfunction

function! dotoo#headline#start_clock(headline, ...)
  let persist = a:0 ? a:1 : 1
  if !a:headline.is_clocking()
    call a:headline.logbook.start_clock()
    if persist | call dotoo#headline#save(a:headline) | endif
  endif
endfunction

function! dotoo#headline#stop_clock(headline, ...)
  let persist = a:0 ? a:1 : 1
  if a:headline.is_clocking()
    call a:headline.logbook.stop_clock()
    if persist | call dotoo#headline#save(a:headline) | endif
  endif
endfunction
