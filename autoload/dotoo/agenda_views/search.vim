if exists('g:autoloaded_dotoo_agenda_views_search')
  finish
endif
let g:autoloaded_dotoo_agenda_views_search = 1

function! s:build_search_expr() abort
  let search_keys = ['file', 'todo', 'priority', 'title', 'tags', 'content']
  let search_term = s:search_view.term
  let search_expr = ''
  for key in search_keys
    if key == 'content'
      let search_expr .= " || join(v:val.".key.", ' ') =~? '" . search_term . "'"
    else
      if empty(search_expr)
        let search_expr .= "v:val.".key." =~? '" . search_term . "'"
      else
        let search_expr .= " || v:val.".key." =~? '" . search_term . "'"
      endif
    endif
  endfor
  return search_expr
endfunction

let s:search_headlines = {}
function! s:build_search(dotoos, ...) abort
  let force = a:0 ? a:1 : 1
  let filters_header = dotoo#agenda#filters_header()
  if force || empty(s:search_headlines)
    let s:search_headlines = {}
    for dotoo in values(a:dotoos)
      let headlines = dotoo.filter(s:build_search_expr())
      call dotoo#agenda#apply_filters(headlines)
      let s:search_headlines[dotoo.file] = headlines
    endfor
  endif
  let search_results = []
  for file in keys(s:search_headlines)
    let headlines = s:search_headlines[file]
    for headline in headlines
      let search_result = printf('%s %10s: %2s %-70s %s', '',
            \ headline.key,
            \ headline.priority,
            \ headline.todo_title(),
            \ headline.tags)
      call add(search_results, search_result)
    endfor
  endfor
  if empty(search_results)
    call add(search_results, printf('%2s %s', '', 'No search results!'))
  endif
  let header = []
  call add(header, 'Search: `' . s:search_view.term . '`')
  if !empty(filters_header) | call add(header, filters_header) | endif
  call insert(search_results, join(header, ', '))
  return search_results
endfunction

let s:search_view = {
      \ 'key': 's',
      \ 'name': 'Search',
      \ 'term': '',
      \}

function! s:search_view.content(dotoos, ...) dict
  let force = a:0 ? a:1 : 1
  if force
    let self.term = input('Search: ', self.term)
  endif
  return s:build_search(a:dotoos, force)
endfunction

function! dotoo#agenda_views#search#register()
  call dotoo#agenda#register_view(s:search_view)
endfunction
