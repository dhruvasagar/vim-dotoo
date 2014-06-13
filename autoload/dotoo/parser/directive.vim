if exists('g:autoloaded_dotoo_parser_directive')
  finish
endif
let g:autoloaded_dotoo_parser_directive = 1

let s:directive_methods = {}
function! s:directive_methods.serialize() dict
endfunction

function! dotoo#parser#directive#new(...)
  let token = a:0 ? a:1 : 0
  let directive = {}
  if !empty(token) | let directive[token.content[0]] = token.content[1] | endif
  call extend(directive, s:directive_methods)
  return directive
endfunction
