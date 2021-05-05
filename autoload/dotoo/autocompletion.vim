let s:directives = ['#+TITLE', '#+AUTHOR', '#+EMAIL', '#+NAME', '#+BEGIN_SRC', '#+END_SRC', '#+BEGIN_EXAMPLE', '#+END_EXAMPLE']
let s:properties = [':PROPERTIES:', ':END:', ':LOGBOOK:', ':STYLE:', ':REPEAT_TO_STATE:', ':CUSTOM_ID:']
let s:metadata = ['DEADLINE', 'CLOSED', 'SCHEDULED', 'CLOCK']
let s:list_items = ['- ', '- [ ] ']
let s:todo_keywords = filter(copy(g:dotoo#parser#todo_keywords), 'v:val !=? "|"')

function! s:find_by_custom_id_property(base)
  if empty(a:base[1:])
    let filter = printf("get(get(v:val, 'properties', {}), 'CUSTOM_ID', '') !=? ''")
  else
    let filter = printf("get(get(v:val, 'properties', {}), 'CUSTOM_ID', '') =~? '^%s'", a:base[1:])
  end
  let headlines = dotoo#agenda#find_headlines(filter)
  return map(headlines, '"#".v:val.properties.CUSTOM_ID')
endfunction

function! s:find_by_title_pointer(base)
  let filter = printf("v:val.title =~? '^%s'", a:base[1:])
  let headlines = dotoo#agenda#find_headlines(filter)
  return map(headlines, '"*".v:val.title')
endfunction

function! s:find_by_dedicated_target(base)
  let filter = printf("v:val.title =~? '<<%s[^>]*>>' || join(v:val.content, ' ') =~? '<<%s[^>]*>>'", a:base, a:base)
  let headlines = dotoo#agenda#find_headlines(filter)
  let results = []
  for headline in headlines
    call substitute(headline.title, printf('<<\(%s[^>]*\)>>', a:base), '\=add(results, submatch(1))', 'g')
    call substitute(join(headline.content, ' '), printf('<<\(%s[^>]*\)>>', a:base), '\=add(results, submatch(1))', 'g')
  endfor
  return results
endfunction

function! s:find_by_title(base)
  let filter = printf("v:val.title =~? '^%s'", a:base)
  let headlines = dotoo#agenda#find_headlines(filter)
  return map(headlines, 'v:val.title')
endfunction

function! s:fetch_links(base) abort
  let base = trim(a:base)

  if base[0] ==# '#'
    return s:find_by_custom_id_property(base)
  endif

  if base[0] ==# '*'
    return s:find_by_title_pointer(base)
  endif

  let results = s:find_by_dedicated_target(base)
  call extend(results, s:find_by_title(base))
  return results
endfunction

function! s:fetch_tags(base)
  let base = trim(a:base)
  let filter = printf("v:val.tags =~? '^%s'", base)
  let headlines = dotoo#agenda#find_headlines(filter)
  return map(headlines, 'v:val.tags')
endfunction

let s:contexts = [
      \ { 'rgx': '\v^#\+?(\w+)?$', 'list': s:directives },
      \ { 'rgx': '\v^:(\w+)?$', 'list': s:properties },
      \ { 'rgx': '\v(^\*+\s+)@<=(\w+)?$', 'list': s:todo_keywords },
      \ { 'rgx': '\v(^\s*)@<=-\s*\[?\s*$', 'list': s:list_items },
      \ { 'rgx': '\v((^|\s+)\[\[)@<=((\*|#)?(\w+))?', 'fetcher': function('s:fetch_links'), 'list': [] },
      \ { 'rgx': '\v(\s+)@<=:((\w|:)+)?$', 'fetcher': function('s:fetch_tags'), 'list': [] },
      \ { 'rgx': '\v^(\w+)?$', 'list': s:directives + s:properties + s:metadata + s:list_items },
      \ ]

function! dotoo#autocompletion#omni(findstart, base)
  let line = getline('.')[0:(col('.') - 1)]
  if a:findstart
    for context in s:contexts
      let m = match(line, context.rgx)
      if m > -1
        return m
      endif
    endfor
    return 0
  endif

  let line = line.a:base
  let results = []
  for context in s:contexts
    if line =~? context.rgx
      let items = filter(copy(context.list), 'v:val =~? "^".a:base')
      if has_key(context, 'fetcher')
        let items = call(context.fetcher, [a:base])
      endif
      call extend(results, map(items, '{"word": v:val, "menu": "[DT]"}'))
    endif
  endfor

  return results
endfunction
