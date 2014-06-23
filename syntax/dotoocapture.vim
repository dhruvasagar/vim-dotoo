if exists('b:current_syntax')
  finish
endif

" Load dotoo syntax
runtime! syntax/dotoo.vim
unlet b:current_syntax

let b:current_syntax = 'dotoocapture'
