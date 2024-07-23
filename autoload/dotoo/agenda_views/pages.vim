if exists('g:autoloaded_dotoo_agenda_views_pages')
  finish
endif
let g:autoloaded_dotoo_agenda_views_pages = 1

let s:pages_deadlines = {} "{{{1
function! s:build_pages(dotoos, ...)
  let force = a:0 ? a:1 : 0
  let filters_header = dotoo#agenda#filters_header()
  if force || empty(s:pages_deadlines)
    let s:pages_deadlines = {}
    for dotoo in values(a:dotoos)
      let headlines = dotoo.filter("v:val.file =~? g:dotoo#link#pages_path")
      call dotoo#agenda#apply_filters(headlines)
      let s:pages_deadlines[dotoo.file] = headlines
    endfor
  endif
  let pages = []
  for file in keys(s:pages_deadlines)
    let headlines = s:pages_deadlines[file]
    for headline in headlines
      let note = printf('%s %10s: %2s %-70s %s', '',
            \ headline.key,
            \ headline.priority,
            \ headline.todo_title(),
            \ headline.tags)
      call add(pages, note)
    endfor
  endfor
  if empty(pages)
    call add(pages, printf('%2s %s', '', 'No pages!'))
  endif
  let header = []
  call add(header, 'pages')
  if !empty(filters_header) | call add(header, filters_header) | endif
  call insert(pages, join(header, ', '))
  return pages
endfunction

let s:pages_view = {
      \ 'key': 'p',
      \ 'name': 'pages',
      \}
function! s:pages_view.content(dotoos, ...) dict
  let force = a:0 ? a:1 : 0
  return s:build_pages(a:dotoos, force)
endfunction

function! dotoo#agenda_views#pages#register()
  call dotoo#agenda#register_view(s:pages_view)
endfunction
