if exists('g:autoloaded_dotoo')
  finish
endif
let g:autoloaded_dotoo = 1

" Helper Functions
function! dotoo#get_headline(...)
  return call('dotoo#parser#headline#get', a:000)
endfunction
