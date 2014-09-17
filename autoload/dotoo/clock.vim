if exists('g:autoloaded_dotoo_clock')
  finish
endif
let g:autoloaded_dotoo_clock = 1

let s:syntax = dotoo#parser#lexer#syntax()
function! s:is_current(headline)
  return s:current_clocking_headline ==# {'file': a:headline.file, 'lnum': a:headline.lnum}
endfunction

let s:clocking_headlines = []
let s:current_clocking_headline = {}
function! dotoo#clock#start(...)
  let headline = a:0 ? a:1 : dotoo#get_headline()
  let persist = a:0 == 2 ? a:2 : 1
  if empty(headline) | return | endif
  if !empty(s:current_clocking_headline) && !s:is_current(headline)
    let curr_hl = dotoo#get_headline(s:current_clocking_headline.file, s:current_clocking_headline.lnum)
    " Stop clocking the current clock
    call curr_hl.stop_clock()
  endif
  if !empty(headline.todo)
    " Mark as NEXT
    call headline.change_todo('n')
  endif
  call headline.start_clock(persist)
  let s:current_clocking_headline = {'file': headline.file, 'lnum': headline.lnum}
  call insert(s:clocking_headlines, s:current_clocking_headline)
endfunction

function! dotoo#clock#stop(...)
  let headline = a:0 ? a:1 : dotoo#get_headline()
  let persist = a:0 == 2 ? a:2 : 1
  if empty(headline) | return | endif
  if headline.is_clocking()
    call headline.stop_clock(persist)
    call remove(s:clocking_headlines, 0)
    let s:current_clocking_headline = get(s:clocking_headlines, 0, {})
    " Resume clocking the old stopped clock
    if !empty(s:current_clocking_headline)
      let curr_hl = dotoo#get_headline(s:current_clocking_headline.file, s:current_clocking_headline.lnum)
      call curr_hl.start_clock()
    endif
  endif
endfunction

function! dotoo#clock#summary()
  if !empty(s:current_clocking_headline)
    let curr_hl = dotoo#get_headline(s:current_clocking_headline.file, s:current_clocking_headline.lnum)
    return curr_hl.logbook.clocking_summary() .
          \ ' ' .
          \ curr_hl.title[:10]
  endif
  return ''
endfunction
