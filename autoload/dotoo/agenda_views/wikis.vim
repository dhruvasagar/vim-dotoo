let s:wiki_headlines = {}
function! s:build_wikis(dotoo, ...)
  let force = a:0 ? a:1 : 0
  let filters_header = dotoo#agenda#filters_header()
  if force || empty(wiki_headlines)
    let s:wiki_headlines = {}
    for dotoo in values(a:dotoo)
      let headlines = dotoo.filter("v:val.file =~? 'notes'")
      call dotoo#agenda#apply_filters(headlines)
      let s:wiki_headlines[dotoo.file] = headlines
    endfor
  endif
  let wikis = []
  for file in keys(s:wiki_headlines)
    let headlines = s:wiki_headlines[file]
    for headline in headlines
      let wiki = printf('%s %10s: %-70s %s', '',
            \ fnamemodify(fnamemodify(headline.file, ':s?.*\zenotes??'), ':r'),
            \ headline.todo_title(),
            \ headline.tags)
      call add(wikis, wiki)
    endfor
  endfor
  if empty(wikis)
    call add(wikis, printf('%2s %s', '', 'No Wiki Headlines!'))
  endif
  let header = []
  call add(header, 'Wikis')
  if !empty(filters_header) | call add(header, filters_header) | endif
  call insert(wikis, join(header, ', '))
  return wikis
endfunction

let s:wikis_view = {
      \ 'key': 'w',
      \ 'name': 'Wikis',
      \}
function! s:wikis_view.content(dotoos, ...) dict
  let force = a:0 ? a:1 : 1
  return s:build_wikis(a:dotoos, force)
endfunction

function! dotoo#agenda_views#wikis#register()
  call dotoo#agenda#register_view(s:wikis_view)
endfunction
