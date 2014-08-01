if exists('g:autoloaded_dotoo_agenda_views_refiles')
  finish
endif
let g:autoloaded_dotoo_agenda_views_refiles = 1

let s:refiles = {}
function! s:build_refiles(dotoos, ...)
  let force = a:0 ? a:1 : 0
  let filters_header = dotoo#agenda#filters_header()
  if force || empty(s:refiles)
    let s:refiles = {}
    for dotoo in values(a:dotoos)
      let headlines = dotoo.filter("v:val.file =~# 'refile'")
      call dotoo#agenda#apply_filters(headlines, 'file')
      let s:refiles[dotoo.file] = headlines
    endfor
  endif
  let refiles = []
  call dotoo#agenda#headlines([])
  for file in keys(s:refiles)
    let key = fnamemodify(file, ':p:t:r')
    let headlines = s:refiles[file]
    call dotoo#agenda#headlines(headlines, 1)
    for headline in headlines
      let refile = printf('%s %10s: %-70s %s', '',
            \ headline.key,
            \ headline.todo_title(),
            \ headline.tags)
      call add(refiles, refile)
    endfor
  endfor
  if empty(refiles)
    call add(refiles, printf('%2s %s', '', 'No REFILES!'))
  endif
  let header = []
  call add(header, 'Refiles')
  if !empty(filters_header) | call add(header, filters_header) | endif
  call insert(refiles, join(header, ', '))
  return refiles
endfunction

let s:view_name = 'refiles'
let s:refile_view = {}
function! s:refile_view.content(dotoos, ...) dict
  let force = a:0 ? a:1 : 0
  return s:build_refiles(a:dotoos, force)
endfunction

function! dotoo#agenda_views#refiles#register()
  call dotoo#agenda#register_view(s:view_name, s:refile_view)
endfunction
