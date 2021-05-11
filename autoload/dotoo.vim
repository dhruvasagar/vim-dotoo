if exists('g:autoloaded_dotoo')
  finish
endif
let g:autoloaded_dotoo = 1

" Helper Functions
function! dotoo#get_headline(...)
  return call('dotoo#parser#headline#get', a:000)
endfunction

function! dotoo#move_headline(headline, target)
  call a:headline.open()
  call a:headline.delete()
  silent write
  call a:headline.close()
  if type(a:target) == type({})
    call a:target.add_headline(a:headline)
    call a:target.save()
  else
    let target = bufname(a:target)
    if empty(target) " file hasn't been loaded in vim
      if dotoo#utils#is_dotoo_file(a:target)
        let target = a:target
      else
        let target = g:dotoo#capture#refile
      end
    endif
    call writefile(a:headline.serialize(), target, 'a')
  endif
endfunction

function! dotoo#move_headline_menu(headline)
  let target_title = input('Enter target: ', '', 'customlist,dotoo#agenda#headline_complete')
  redraw!
  let target = dotoo#agenda#get_headline_by_title(target_title)
  call dotoo#move_headline(a:headline, target)
endfunction

function! dotoo#change_todo(...)
  let headline = a:0 ? a:1 : dotoo#get_headline()
  let selection = dotoo#utils#change_todo_menu()
  if !empty(selection)
    call headline.change_todo(selection)
    call headline.save()
  endif
endfunction
