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
  let acceptable_input = '['.join(map(copy(views), 'v:val[0]'),'').']'
  call map(views, '"(".tolower(v:val[0]).") ".v:val')
  call add(views, 'Select agenda view: ')
  let selected = dotoo#utils#getchar(join(views, "\n"), acceptable_input)
  let sel = []
  if !empty(selected)
    let sel = filter(keys(s:agenda_views), "v:val =~# '^'.selected.'.*'")
  endif
  return !empty(sel) ? sel[0] : ''
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
  if expand('%:e') ==# 'dotoo' && !s:has_agenda_file()
    if dotoo#utils#getchar('Do you wish to add the current file in agenda files? (y/n): ', '[yn]') == 'y'
      call s:add_agenda_file()
      return 1
    endif
  endif
  return 0
endfunction

let s:tmpfile = tempname()
function! s:edit(cmd)
  silent exe a:cmd s:tmpfile
  if a:cmd =~# 'pedit' | wincmd P | endif
  setl winheight=20
  setl buftype=acwrite nobuflisted
  setl readonly nomodifiable nofoldenable nolist
  setf dotooagenda
endfunction

function! s:view_cleanup(view_name)
  let view = get(s:agenda_views, a:view_name, {})
  if has_key(view, 'cleanup')
    call s:edit('pedit!')
    call view.cleanup()
  endif
endfunction

function! s:show_view(view_name, force)
  let view = get(s:agenda_views, a:view_name, {})
  if has_key(view, 'content')
    let content = view.content(s:agenda_dotoos, a:force)
    let old_view = winsaveview()
    call s:edit('pedit!')
    setl modifiable
    silent normal! ggdG
    silent call setline(1, content)
    setl nomodified nomodifiable
    if has_key(view, 'setup') | call view.setup() | endif
    call winrestview(old_view)
  endif
endfunction

" Public API {{{1
let s:agenda_headlines = []
function! dotoo#agenda#headlines(...)
  if a:0
    if a:0 == 1
      let s:agenda_headlines = a:1
    elseif a:0 == 2 && a:2
      if type(a:1) == type([])
        call extend(s:agenda_headlines, a:1)
      else
        call add(s:agenda_headlines, a:1)
      endif
    endif
  endif
  return s:agenda_headlines
endfunction

function! dotoo#agenda#goto_headline(cmd)
  let headline = s:agenda_headlines[line('.')-2]
  if a:cmd ==# 'edit' | quit | split | endif
  exec a:cmd '+'.headline.lnum headline.file
  if empty(&filetype) | edit | endif
  normal! zv
endfunction

function! dotoo#agenda#start_headline_clock()
  let old_view = winsaveview()
  call dotoo#agenda#goto_headline('edit')
  call dotoo#clock#start()
  call dotoo#agenda#refresh_view()
  call s:agenda_modified(1)
  call winrestview(old_view)
endfunction

function! dotoo#agenda#stop_headline_clock()
  let old_view = winsaveview()
  call dotoo#agenda#goto_headline('edit')
  call dotoo#clock#stop()
  call dotoo#agenda#refresh_view()
  call s:agenda_modified(1)
  call winrestview(old_view)
endfunction

function! dotoo#agenda#change_headline_todo()
  let headline = s:agenda_headlines[line('.')-2]
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

function! dotoo#agenda#undo_headline_change() "{{{1
  let headline = s:agenda_headlines[line('.')-2]
  let old_view = winsaveview()
  call headline.undo()
  call dotoo#agenda#refresh_view()
  call winrestview(old_view)
endfunction

let s:agenda_views = {}
function! dotoo#agenda#register_view(name, plugin) abort
  if type(a:plugin) == type({})
    let s:agenda_views[a:name] = a:plugin
  endif
endfunction

function! dotoo#agenda#save_files()
  let old_view = winsaveview()
  for _file in s:dotoo_files
    if bufexists(_file)
      exec 'buffer' _file
      write
    endif
  endfor
  setl nomodified
  call dotoo#agenda#refresh_view()
  call winrestview(old_view)
endfunction

function! dotoo#agenda#get_headline_by_title(file_title)
  if a:file_title =~# '\.'
    let [filekey, title] = split(a:file_title, '\.')
    let dotoo = get(s:agenda_dotoos, bufname(filekey), '')
    if !empty(dotoo)
      let headlines = dotoo.filter("v:val.title =~# '" . title . "'")
      if !empty(headlines) | return headlines[0] | endif
    endif
  else
    return a:file_title
  endif
endfunction

function! dotoo#agenda#move_headline(headline)
  let headline = s:agenda_headlines[line('.')-2]
  call dotoo#move_headline(headline, a:headline)
  call dotoo#agenda#refresh_view()
endfunction

function! dotoo#agenda#headline_complete(ArgLead, CmdLine, CursorPos)
  let headlines = []
  for key in keys(s:agenda_dotoos)
    let _key = fnamemodify(key, ':p:t:r')
    if empty(a:ArgLead) || _key =~# '^'.a:ArgLead[:stridx(a:ArgLead, '.')-1]
      if _key ==# a:ArgLead
        call add(headlines, _key)
      endif
      let dotoo = s:agenda_dotoos[key]
      if !empty(a:ArgLead) && a:ArgLead =~# '\..'
        let title = split(a:ArgLead, '\.')[1]
        let hdlns = dotoo.filter("v:val.title =~# '^" .title. "'")
      else
        let hdlns = dotoo.filter('1')
      endif
      call extend(headlines, map(hdlns, "_key . '.' . v:val.title"))
    else
      let dotoo = s:agenda_dotoos[key]
      let hdlns = dotoo.filter("v:val.title =~# '^" . a:ArgLead . "'")
      call extend(headlines, map(hdlns, "_key . '.' . v:val.title"))
    endif
  endfor
  " for dotoo in values(s:agenda_dotoos)
  "   let hs = dotoo.filter(pattern)
  "   call extend(headlines, map(hs, 'v:val.title'))
  " endfor
  return headlines
endfunction

let s:current_view = ''
function! dotoo#agenda#agenda()
  let old_view = s:current_view
  let s:current_view = s:agenda_views_menu()
  if old_view !=# s:current_view | call s:view_cleanup(old_view) | endif
  let force = s:add_agenda_file_menu()
  call s:load_agenda_files(force)
  call s:show_view(s:current_view, force)
endfunction

function! dotoo#agenda#refresh_view(...)
  let force = a:0 ? a:1 : 1
  call s:load_agenda_files(force)
  call s:show_view(s:current_view, force)
endfunction
