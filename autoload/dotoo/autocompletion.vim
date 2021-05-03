let s:directives = ['#+TITLE', '#+AUTHOR', '#+EMAIL', '#+NAME', '#+BEGIN_SRC', '#+END_SRC', '#+BEGIN_EXAMPLE', '#+END_EXAMPLE']
let s:properties = [':PROPERTIES:', ':END:', ':LOGBOOK:', ':STYLE:', ':REPEAT_TO_STATE:']
let s:metadata = ['DEADLINE', 'CLOSED', 'SCHEDULED', 'CLOCK']
let s:list_items = ['- ', '- [ ] ']
let s:todo_keywords = filter(copy(g:dotoo#parser#todo_keywords), 'v:val !=? "|"')

let s:contexts = [
      \ { 'rgx': '^#+\?\(\w\+\)\?$', 'list': s:directives },
      \ { 'rgx': '^:\(\w\+\)\?$', 'list': s:properties },
      \ { 'rgx': '\(^\*\+\s\+\)\@<=\(\w\+\)\?$', 'list': s:todo_keywords },
      \ { 'rgx': '\(^\s*\)\@<=-\s*\[\?\s*$', 'list': s:list_items },
      \ { 'rgx': '^\(\w\+\)\?$', 'list': s:directives + s:properties + s:metadata + s:list_items },
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

  let results = []
  for context in s:contexts
    if (!empty(a:base) && a:base =~? context.rgx) || line =~? context.rgx
      call extend(results, map(filter(copy(context.list), 'v:val =~? "^".a:base'), '{"word": v:val, "menu": "[DT]"}'))
    endif
  endfor

  return results
endfunction
