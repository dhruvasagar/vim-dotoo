if exists('g:autoloaded_dotoo')
  finish
endif
let g:autoloaded_dotoo = 1

" Helper Functions
function! dotoo#get_headline(file, lnum)
  return dotoo#parser#headline#get(a:file, a:lnum)
endfunction
