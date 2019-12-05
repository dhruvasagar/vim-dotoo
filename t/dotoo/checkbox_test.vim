function! s:TestIsHeadline()
  let line = '* TODO Headline Test'
  let result = dotoo#checkbox#is_headline(line)
  call testify#assert#equals(result, 1)
endfunction
call testify#it('IsHeadline should be true', function('s:TestIsHeadline'))

function! s:test(tests, func)
  for test in a:tests
    let result = a:func(test.line)
    call testify#assert#equals(result, test.result)
  endfor
endfunction

function! s:TestIsCheckbox()
  let tests = [
        \ {'line': ' - To do or not to do', 'result': 0},
        \ {'line': ' - [ ] To do or not to do', 'result': 1},
        \ {'line': ' * [ ] To do or not to do', 'result': 1},
        \ {'line': ' + [ ] To do or not to do', 'result': 1},
        \ {'line': ' - [X] To do or not to do', 'result': 1},
        \ {'line': ' * [X] To do or not to do', 'result': 1},
        \ {'line': ' + [X] To do or not to do', 'result': 1},
        \ {'line': ' - [-] To do or not to do', 'result': 1},
        \ {'line': ' * [-] To do or not to do', 'result': 1},
        \ {'line': ' + [-] To do or not to do', 'result': 1},
        \]
  call s:test(tests, function('dotoo#checkbox#is_checkbox'))
endfunction
call testify#it('is_checkbox should correctly identify lines with a checkbox', function('s:TestIsCheckbox'))

function! s:TestIsUnchecked()
  let tests = [
        \ {'line': ' - [ ] To do or not to do', 'result': 1},
        \ {'line': ' * [ ] To do or not to do', 'result': 1},
        \ {'line': ' + [ ] To do or not to do', 'result': 1},
        \ {'line': ' - [X] To do or not to do', 'result': 0},
        \ {'line': ' * [X] To do or not to do', 'result': 0},
        \ {'line': ' + [X] To do or not to do', 'result': 0},
        \ {'line': ' - [-] To do or not to do', 'result': 0},
        \ {'line': ' * [-] To do or not to do', 'result': 0},
        \ {'line': ' + [-] To do or not to do', 'result': 0},
        \]
  call s:test(tests, function('dotoo#checkbox#is_unchecked_checkbox'))
endfunction
call testify#it('is_unchecked_checkbox should correctly identify unchecked checkboxes', function('s:TestIsUnchecked'))

function! s:TestIsPartial()
  let tests = [
        \ {'line': ' - [ ] To do or not to do', 'result': 0},
        \ {'line': ' * [ ] To do or not to do', 'result': 0},
        \ {'line': ' + [ ] To do or not to do', 'result': 0},
        \ {'line': ' - [X] To do or not to do', 'result': 0},
        \ {'line': ' * [X] To do or not to do', 'result': 0},
        \ {'line': ' + [X] To do or not to do', 'result': 0},
        \ {'line': ' - [-] To do or not to do', 'result': 1},
        \ {'line': ' * [-] To do or not to do', 'result': 1},
        \ {'line': ' + [-] To do or not to do', 'result': 1},
        \]
  call s:test(tests, function('dotoo#checkbox#is_partial_checkbox'))
endfunction
call testify#it('is_partial_checkbox should correctly identify partially checked checkboxes', function('s:TestIsPartial'))

function! s:TestIsChecked()
  let tests = [
        \ {'line': ' - [ ] To do or not to do', 'result': 0},
        \ {'line': ' * [ ] To do or not to do', 'result': 0},
        \ {'line': ' + [ ] To do or not to do', 'result': 0},
        \ {'line': ' - [X] To do or not to do', 'result': 1},
        \ {'line': ' * [X] To do or not to do', 'result': 1},
        \ {'line': ' + [X] To do or not to do', 'result': 1},
        \ {'line': ' - [-] To do or not to do', 'result': 0},
        \ {'line': ' * [-] To do or not to do', 'result': 0},
        \ {'line': ' + [-] To do or not to do', 'result': 0},
        \]
  call s:test(tests, function('dotoo#checkbox#is_checked_checkbox'))
endfunction
call testify#it('is_checked_checkbox should correctly identify checked checkboxes', function('s:TestIsChecked'))

function! s:TestIsListItem()
  let tests = [
        \ {'line': ' - [ ] To do or not to do', 'result': 1},
        \ {'line': ' * [ ] To do or not to do', 'result': 1},
        \ {'line': ' + [ ] To do or not to do', 'result': 1},
        \ {'line': ' - [X] To do or not to do', 'result': 1},
        \ {'line': ' * [X] To do or not to do', 'result': 1},
        \ {'line': ' + [X] To do or not to do', 'result': 1},
        \ {'line': ' - [-] To do or not to do', 'result': 1},
        \ {'line': ' * [-] To do or not to do', 'result': 1},
        \ {'line': ' + [-] To do or not to do', 'result': 1},
        \ {'line': ' - To do or not to do', 'result': 1},
        \ {'line': ' * To do or not to do', 'result': 1},
        \ {'line': ' + To do or not to do', 'result': 1},
        \]
  call s:test(tests, function('dotoo#checkbox#is_list_item'))
endfunction
call testify#it('is_list_item should correctly identify checked checkboxes', function('s:TestIsListItem'))
