if exists('g:autoloaded_dotoo_agenda')
  finish
endif
let g:autoloaded_dotoo_agenda = 1

call dotoo#utils#set('dotoo#agenda#warning_days', '30d')
call dotoo#utils#set('dotoo#agenda#files', ['~/Documents/dotoo-files/*.dotoo'])

" Private API {{{1
function! s:agenda_modified(mod)
  let &l:modified = a:mod
endfunction

let s:dotoo_files = []
let s:agenda_dotoos = {}
function! s:parse_dotoos(file,...)
  let force = a:0 ? a:1 : 0
  if index(s:dotoo_files, a:file) < 0
    call add(s:dotoo_files, a:file)
  endif
  let dotoos = dotoo#parser#parsefile({'file': a:file, 'force': force})
  let s:agenda_dotoos[a:file] = dotoos
endfunction

function! s:load_agenda_files(...)
  let force = a:0 ? a:1 : 0
  if force | let s:dotoo_files = [] | endif
  if force | let s:agenda_dotoos = {} | endif
  for agenda_file in g:dotoo#agenda#files
    for orgfile in glob(agenda_file, 1, 1)
      call s:parse_dotoos(orgfile, force)
    endfor
  endfor
endfunction

function! s:agenda_views_menu()
  let views = keys(s:agenda_views)
  let acceptable_input = '['.join(copy(views),'').']'
  call map(views, '"(".s:agenda_views[v:val].key.") ".s:agenda_views[v:val].name')
  call add(views, 'Select agenda view: ')
  let selected = dotoo#utils#getchar(join(views, "\n"), acceptable_input)
  let sel = []
  if !empty(selected)
    let sel = s:agenda_views[selected]
  endif
  return !empty(sel) ? sel : {}
endfunction

function! s:has_agenda_file(...)
  let afile = a:0 ? a:1 : expand('%:p')
  for agenda_file in g:dotoo#agenda#files
    for orgfile in glob(agenda_file, 1, 1)
      if orgfile ==# afile | return 1 | endif
    endfor
  endfor
endfunction

function! s:add_agenda_file(...)
  let file = a:0 ? a:1 : expand('%:p')
  call add(g:dotoo#agenda#files, file)
endfunction

function! s:add_agenda_file_menu()
  if &filetype ==# 'dotoo' && !s:has_agenda_file()
    if dotoo#utils#getchar('Do you wish to add the current file in agenda files? (y/n): ', '[yn]') == 'y'
      call s:add_agenda_file()
      return 1
    endif
  endif
  return 0
endfunction

let s:tmpfile = tempname()
function! s:edit(cmd)
  silent exe 'keepalt' a:cmd s:tmpfile
  if a:cmd =~# 'pedit' | wincmd P | endif
  setl winheight=20
  setl buftype=acwrite nobuflisted
  setl readonly nomodifiable nofoldenable nolist
  setf dotooagenda
endfunction

function! s:view_cleanup(view)
  if has_key(a:view, 'cleanup')
    call s:edit('pedit!')
    call a:view.cleanup()
  endif
endfunction

function! s:show_view(view, force)
  if has_key(a:view, 'content')
    let content = a:view.content(s:agenda_dotoos, a:force)
    let old_view = winsaveview()
    call s:edit('pedit!')
    setl modifiable
    silent normal! ggdG
    silent call setline(1, content)
    setl nomodified nomodifiable
    if has_key(a:view, 'setup') | call a:view.setup() | endif
    call winrestview(old_view)
  endif
endfunction

function! s:get_headline_under_cursor() abort
  let csplit = split(getline('.'), ':\s\+')
  let fkey = trim(csplit[0])
  let htitle = escape(trim(split(csplit[-1], ':')[0]), '[]')
  if htitle =~# "'"
    let htitle = substitute(htitle, "'", "''", "g")
  endif
  for dotoos in values(s:agenda_dotoos)
    if dotoos.file !~# '\v'.fkey.'.{-}\.(dotoo|org)$' | continue | endif
    let headlines = dotoos.filter("v:val.todo_title() =~# '".htitle."'")
    if !empty(headlines) | return headlines[0] | endif
  endfor
endfunction

" Public API {{{1
function! dotoo#agenda#goto_headline(cmd, ...)
  let headline = get(a:, 1, {})
  if empty(headline)
    let headline = s:get_headline_under_cursor()
  endif
  if empty(headline) | return | endif
  if a:cmd ==# 'edit' && &filetype ==# 'dotooagenda' | quit | split | endif
  exec a:cmd '+'.headline.lnum headline.file
  if empty(&filetype) | edit | endif
  normal! zv
endfunction

function! dotoo#agenda#start_headline_clock()
  let headline = s:get_headline_under_cursor()
  if empty(headline) | return | endif
  call dotoo#clock#start(headline)
  call s:agenda_modified(1)
endfunction

function! dotoo#agenda#stop_headline_clock()
  let headline = s:get_headline_under_cursor()
  if empty(headline) | return | endif
  call dotoo#clock#stop(headline)
  call s:agenda_modified(1)
endfunction

function! dotoo#agenda#change_headline_todo()
  let headline = s:get_headline_under_cursor()
  if empty(headline) | return | endif
  let selected = dotoo#utils#change_todo_menu()
  if !empty(selected)
    call headline.change_todo(selected)
    let old_view = winsaveview()
    call headline.save()
    call dotoo#agenda#refresh_view(0)
    call s:agenda_modified(getbufvar(bufnr('#'), '&modified'))
    call winrestview(old_view)
  endif
endfunction

function! dotoo#agenda#undo_headline_change()
  let headline = s:get_headline_under_cursor()
  if empty(headline) | return | endif
  let old_view = winsaveview()
  call headline.undo()
  call dotoo#agenda#refresh_view()
  call winrestview(old_view)
endfunction

let s:agenda_views = {}
function! dotoo#agenda#register_view(plugin) abort
  if type(a:plugin) == type({})
    let s:agenda_views[a:plugin.key] = a:plugin
  endif
endfunction

function! dotoo#agenda#save_files()
  let old_view = winsaveview()
  for _file in s:dotoo_files
    if bufexists(_file)
      exec 'buffer' _file
      silent write
    endif
  endfor
  setl nomodified
  call dotoo#agenda#refresh_view()
  call winrestview(old_view)
endfunction

function! dotoo#agenda#get_headline_by_title(file_title)
  if a:file_title =~# ':'
    call s:load_agenda_files()
    let [filekey, title] = split(a:file_title, ':')
    let filekey = substitute(filekey, '\.\(dotoo\|org\)$', '', '')
    let bufname = bufname(filekey . '.{dotoo,org}')
    let dotoo = ''
    if !empty(bufname)
      let dotoo = get(s:agenda_dotoos, bufname, '')
    endif
    if empty(dotoo)
      let bufname = get(filter(keys(s:agenda_dotoos), 'fnamemodify(v:val, ":t:r") ==# filekey'), 0, '')
      if !empty(bufname)
        let dotoo = get(s:agenda_dotoos, bufname, '')
      endif
    endif
    if !empty(dotoo)
      let headlines = dotoo.filter("v:val.title =~# '" . title . "'")
      if !empty(headlines) | return headlines[0] | endif
    endif
  else
    let bufname = bufname(a:file_title . '.{dotoo,org}')
    if !empty(bufname)
      return bufname
    endif
    call s:load_agenda_files()
    let filekey = substitute(a:file_title, '\.\(dotoo\|org\)$', '', '')
    let bufname = get(filter(keys(s:agenda_dotoos), 'fnamemodify(v:val, ":t:r") ==# filekey'), 0, '')
    if !empty(bufname)
      return bufname
    endif
    return a:file_title
  endif
endfunction

function! dotoo#agenda#move_headline()
  let headline = s:get_headline_under_cursor()
  if empty(headline) | return | endif
  call dotoo#move_headline_menu(headline)
  call dotoo#agenda#refresh_view()
endfunction

function! dotoo#agenda#headline_complete(ArgLead, CmdLine, CursorPos)
  let headlines = []
  for key in keys(s:agenda_dotoos)
    let _key = fnamemodify(key, ':p:t:r')
    if empty(a:ArgLead) || _key =~# '^'.a:ArgLead[:stridx(a:ArgLead, ':')-1]
      if _key =~# '^'.a:ArgLead
        call add(headlines, _key)
      endif
      let dotoo = s:agenda_dotoos[key]
      if !empty(a:ArgLead) && a:ArgLead =~# ':.'
        let title = split(a:ArgLead, ':')[1]
        let hdlns = dotoo.filter("v:val.title =~# '^" .title. "'")
      else
        let hdlns = dotoo.filter('1')
      endif
      call extend(headlines, map(hdlns, "_key . ':' . v:val.title"))
    else
      let dotoo = s:agenda_dotoos[key]
      let hdlns = dotoo.filter("v:val.title =~# '^" . a:ArgLead . "'")
      call extend(headlines, map(hdlns, "_key . ':' . v:val.title"))
    endif
  endfor
  return headlines
endfunction

let s:filters = {}
function! dotoo#agenda#filter_agendas()
  let type = input('Filter by: ', '', 'customlist,dotoo#agenda#filter_complete')
  if empty(type)
    let s:filters = {}
  else
    let filter_by = input('Select '.type.': ', '', 'customlist,dotoo#agenda#filter_'.type.'_complete')
    if !empty(filter_by)
      let s:filters[type] = filter_by
    elseif has_key(s:filters, type)
      call remove(s:filters, type)
    endif
  endif
  redraw!
  call dotoo#agenda#refresh_view()
endfunction

function! dotoo#agenda#apply_filters(headlines, ...)
  let exceptions = a:000
  for key in keys(s:filters)
    if index(exceptions, key) >= 0 | continue | endif
    if key ==# 'content'
      call filter(a:headlines, "join(v:val[key], '\n') =~? '" . s:filters[key] . "'")
    else
      call filter(a:headlines, "v:val[key] =~? '" . s:filters[key] . "'")
    endif
  endfor
endfunction

function! dotoo#agenda#filters_header()
  if !empty(s:filters)
    return 'Filters: ' . join(map(items(s:filters), "v:val[0].'='.v:val[1]"), ', ')
  endif
endfunction

function! dotoo#agenda#filter_file_complete(A,L,P)
  let file_names = map(keys(s:agenda_dotoos), "fnamemodify(v:val, ':p:t:r')")
  return filter(file_names, 'v:val =~? a:A')
endfunction

function! dotoo#agenda#filter_tags_complete(A,L,P)
  let tags = []
  for key in keys(s:agenda_dotoos)
    let dotoo = s:agenda_dotoos[key]
    let headlines = dotoo.filter('1')
    let htags = dotoo#utils#flatten(map(headlines, 'split(v:val.tags, ":")'))
    call filter(htags, '!empty(v:val) && v:val =~? "^".a:A')
    call extend(tags, htags)
  endfor
  return uniq(sort(tags))
endfunction

function! dotoo#agenda#filter_todo_complete(A,L,P)
  let todos = dotoo#utils#flatten(g:dotoo#parser#todo_keywords)
  return filter(todos, "v:val !~# '\|' && v:val =~? a:A")
endfunction

function! dotoo#agenda#filter_complete(A,L,P)
  let ops = ['file', 'tags', 'todo', 'title', 'content']
  return filter(ops, 'v:val =~? a:A')
endfunction

function! s:find_headline(filter)
  for dotoos in values(s:agenda_dotoos)
    let headlines = dotoos.filter(a:filter)
    if !empty(headlines) | return headlines[0] | endif
  endfor
endfunction

function! dotoo#agenda#find_headline_by_title(title)
  return s:find_headline("v:val.title =~? '".a:title."'")
endfunction

function! dotoo#agenda#find_headlines(filter)
  let result = []
  for dotoos in values(s:agenda_dotoos)
    let headlines = dotoos.filter(a:filter)
    call extend(result, headlines)
  endfor
  return result
endfunction

function! dotoo#agenda#find_headline_by_property(prop_name, prop_value)
  return s:find_headline("get(get(v:val, 'properties', {}), '".a:prop_name."', '') ==? '".a:prop_value."'")
endfunction

function! dotoo#agenda#find_headline_by_title_or_content(val)
  return s:find_headline("v:val.title =~? '".a:val."' || join(v:val.content, ' ') =~? '".a:val."'")
endfunction

function! dotoo#agenda#load()
  let s:dotoo_agenda_loaded = 1
  " Register Agenda Views
  call dotoo#agenda_views#todos#register()
  call dotoo#agenda_views#notes#register()
  call dotoo#agenda_views#agenda#register()
  call dotoo#agenda_views#refiles#register()
  call dotoo#agenda_views#tagged#register()
  call dotoo#agenda_views#search#register()

  " Register Agenda View Plugins
  call dotoo#agenda_views#plugins#log_summary#register()
endfunction

let s:current_view = {}
function! dotoo#agenda#agenda()
  if !exists('s:dotoo_agenda_loaded')
  	call dotoo#agenda#load()
  endif
  let force = 1
  let old_view = s:current_view
  let s:current_view = s:agenda_views_menu()
  if !empty(old_view) && old_view !=# s:current_view | call s:view_cleanup(old_view) | endif
  call s:add_agenda_file_menu()
  call s:load_agenda_files(force)
  call s:show_view(s:current_view, force)
endfunction

function! dotoo#agenda#refresh_view(...)
  let force = a:0 ? a:1 : 1
  call s:load_agenda_files(force)
  call s:show_view(s:current_view, force)
endfunction
