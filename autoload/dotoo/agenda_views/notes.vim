if exists('g:autoloaded_dotoo_agenda_views_notes')
  finish
endif
let g:autoloaded_dotoo_agenda_views_notes = 1

let s:notes_deadlines = {} "{{{1
function! s:build_notes(dotoos, ...)
  let force = a:0 ? a:1 : 0
  let filters_header = dotoo#agenda#filters_header()
  if force || empty(s:notes_deadlines)
    let s:notes_deadlines = {}
    for dotoo in values(a:dotoos)
      let headlines = dotoo.filter("v:val.tags =~? 'note'")
      call dotoo#agenda#apply_filters(headlines)
      let s:notes_deadlines[dotoo.file] = headlines
    endfor
  endif
  let notes = []
  call dotoo#agenda#headlines([])
  for file in keys(s:notes_deadlines)
    let headlines = s:notes_deadlines[file]
    call dotoo#agenda#headlines(headlines, 1)
    for headline in headlines
      let note = printf('%s %10s: %-70s %s', '',
            \ headline.key,
            \ headline.todo_title(),
            \ headline.tags)
      call add(notes, note)
    endfor
  endfor
  if empty(notes)
    call add(notes, printf('%2s %s', '', 'No NOTES!'))
  endif
  let header = []
  call add(header, 'Notes')
  if !empty(filters_header) | call add(header, filters_header) | endif
  call insert(notes, join(header, ', '))
  return notes
endfunction

let s:view_name = 'notes'
let s:notes_view = {}
function! s:notes_view.content(dotoos, ...) dict
  let force = a:0 ? a:1 : 0
  return s:build_notes(a:dotoos, force)
endfunction

function! dotoo#agenda_views#notes#register()
  call dotoo#agenda#register_view(s:view_name, s:notes_view)
endfunction
