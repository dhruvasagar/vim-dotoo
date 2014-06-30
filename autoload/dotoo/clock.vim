if exists('g:autoloaded_dotoo_clock')
  finish
endif
let g:autoloaded_dotoo_clock = 1

let s:syntax = dotoo#parser#lexer#syntax()
let s:clocking_headlines = []
let s:current_clocking_headline = {}
function! dotoo#clock#start()
  if s:syntax.headline.matches(getline('.'))
    let headline = dotoo#get_headline()
    call headline.start_clock()
    let s:current_clocking_headline = headline
    call insert(s:clocking_headlines, headline)
  endif
endfunction

function! dotoo#clock#stop()
  if s:syntax.headline.matches(getline('.'))
    let headline = dotoo#get_headline()
    if headline == s:current_clocking_headline
      if !empty(s:clocking_headlines)
        call remove(s:clocking_headlines, 0)
        let s:current_clocking_headline = get(s:clocking_headlines, 0, {})
      else
        let s:current_clocking_headline = {}
      endif
    endif
  endif
  call headline.stop_clock()
endfunction

function! dotoo#clock#summary()
  if !empty(s:current_clocking_headline)
    return s:current_clocking_headline.logbook.clocking_summary() .
          \ ' ' .
          \ s:current_clocking_headline.title[:10]
  endif
  return ''
endfunction
