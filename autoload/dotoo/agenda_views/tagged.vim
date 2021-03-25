if exists('g:autoloaded_dotoo_agenda_views_tagged')
  finish
endif
let g:autoloaded_dotoo_agenda_views_tagged = 1

let s:tagged_deadlines = {} "{{{1
function! s:build_tagged(dotoos, ...)
  let force = a:0 ? a:1 : 0
  let filters_header = dotoo#agenda#filters_header()
  if force || empty(s:tagged_deadlines)
    let s:tagged_deadlines = {}
    for dotoo in values(a:dotoos)
      let headlines = dotoo.filter("!empty(v:val.tags)")
      call dotoo#agenda#apply_filters(headlines)
      let s:tagged_deadlines[dotoo.file] = headlines
    endfor
  endif
  let tagged = []
  for file in keys(s:tagged_deadlines)
    let headlines = s:tagged_deadlines[file]
    for headline in headlines
      let note = printf('%s %10s: %-70s %s', '',
            \ headline.key,
            \ headline.todo_title(),
            \ headline.tags)
      call add(tagged, note)
    endfor
  endfor
  if empty(tagged)
    call add(tagged, printf('%2s %s', '', 'No Headlines!'))
  endif
  let header = []
  call add(header, 'All headlines with Tags')
  if !empty(filters_header) | call add(header, filters_header) | endif
  call insert(tagged, join(header, ', '))
  return tagged
endfunction

let s:tagged_view = {
      \ 'key': 'T',
      \ 'name': 'Tagged',
      \}
function! s:tagged_view.content(dotoos, ...) dict
  let force = a:0 ? a:1 : 0
  return s:build_tagged(a:dotoos, force)
endfunction

function! s:tagged_view.short_key() dict
  return "T"
endfunction

function! dotoo#agenda_views#tagged#register()
  call dotoo#agenda#register_view(s:tagged_view)
endfunction
