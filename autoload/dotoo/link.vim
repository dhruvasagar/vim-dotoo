let s:link_regex = '\v\[\[([^\]]*)(\]\[)?([^\]]*)\]\]'

call dotoo#utils#set('dotoo#link#default_path', printf("%s/%s", g:dotoo#home, 'pages'))

function! s:parse_links()
  let line = getline('.')
  let matches = []
  call substitute(line, s:link_regex, '\=add(matches, submatch(0))', 'g')
  let links = []
  for m in matches
    let idx = stridx(line, m)
    call add(links, { 'link': m, 'start': idx, 'end': idx + len(m) })
  endfor
  return links
endfunction

let s:link_stack = []
let g:link_stack = s:link_stack
function! s:add_to_link_stack(bufnr)
  let winid = winnr()
  let item = {'bufnr': a:bufnr, 'from': extend([bufnr()], getcurpos())}
  call add(s:link_stack, item)
endfunction

function! s:pop_from_link_stack()
  if empty(s:link_stack) | return | endif

  let last_entry = remove(s:link_stack, -1)
  let bfnr = last_entry.from[0]
  if bufnr() != bfnr
    exec 'buffer' bfnr
  endif
  call setpos('.', last_entry.from[1:])
endfunction

function! s:goto_headline(headline)
  if empty(a:headline)
    return 0
  endif
  call s:add_to_link_stack(bufnr(a:headline.file))
  call dotoo#agenda#goto_headline('edit', a:headline)
  return 1
endfunction

function! s:goto_headline_by_title(link)
  return s:goto_headline(dotoo#agenda#find_headline_by_title(a:link))
endfunction

function! s:goto_headline_by_title_pointer(link)
  if a:link[0] !=# '*'
    return 0
  endif
  return s:goto_headline(dotoo#agenda#find_headline_by_title(a:link[1:]))
endfunction

function! s:goto_headline_by_custom_id(link)
  if a:link[0] !=# '#'
    return 0
  endif
  return s:goto_headline(dotoo#agenda#find_headline_by_property('CUSTOM_ID', a:link[1:]))
endfunction


function! s:goto_headline_by_dedicated_target(link)
  let val = '<<\s*'.a:link.'\s*>>'
  return s:goto_headline(dotoo#agenda#find_headline_by_title_or_content(val))
endfunction

function! s:goto_file(link)
  let file = a:link

  if a:link =~# '^file:'
    let file = substitute(file, '^file:', '', '')
  endif

  " relative file
  if !empty(file) && file =~# '^\.'
    let file = substitute(file, '^\.', expand('%:p:h'), '')
  elseif !empty(g:dotoo#link#default_path)
    let file = printf("%s/%s", g:dotoo#link#default_path ,file)
    if !dotoo#utils#is_dotoo_file(file)
      let file = printf("%s.dotoo", file)
    endif
  endif

  call s:add_to_link_stack(bufnr(file))
  exe 'edit' file
  return 1
endfunction

function! s:goto_url(link)
  if a:link =~? '^https\?:\/\/'
    if !exists('g:loaded_netrwPlugin')
      echohl WarningMsg
      echom 'netrw plugin must be loaded in order to open urls.'
      echohl NONE
      return 0
    endif
    call netrw#BrowseX(a:link, netrw#CheckIfRemote())
    return 1
  endif
  return 0
endfunction

" see:
" https://orgmode.org/manual/Internal-Links.html#Internal-Links
" https://orgmode.org/manual/External-Links.html#External-Links
function! dotoo#link#follow(cmd) abort
  let links = s:parse_links()
  let col = col('.') - 1
  let link_on_cursor = get(filter(links, 'col >= v:val.start && col <= v:val.end'), 0, {})
  if empty(link_on_cursor)
    return
  endif
  let parts = matchlist(link_on_cursor.link, s:link_regex)
  let link = trim(parts[1])
  let follow_options = [
        \ 'goto_headline_by_custom_id',
        \ 'goto_headline_by_title_pointer',
        \ 'goto_url',
        \ 'goto_file',
        \ 'goto_headline_by_dedicated_target',
        \ 'goto_headline_by_title'
        \ ]
  for opt in follow_options
    let result = call('s:'.opt, [link])
    if !empty(result)
      break
    endif
  endfor
endfunction

function! dotoo#link#stack() abort
  return string(s:link_stack)
endfunction

function! dotoo#link#back() abort
  call s:pop_from_link_stack()
endfunction
