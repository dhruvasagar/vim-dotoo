" Borrowed from jceb/vim-orgmode

" TODO do we really need a separate syntax file for the agenda?
"      - Most of the stuff here is also in syntax.org
"      - DRY!
if exists('b:current_syntax')
  finish
endif

syn match dotoo_todo_key /\[\zs[^]]*\ze\]/
hi def link dotoo_todo_key Identifier

"" Load Settings: {{{
if !exists('g:dotoo_heading_highlight_colors')
  let g:dotoo_heading_highlight_colors = ['Title', 'Constant', 'Identifier', 'Statement', 'PreProc', 'Type', 'Special']
endif

if !exists('g:dotoo_heading_highlight_levels')
  let g:dotoo_heading_highlight_levels = len(g:dotoo_heading_highlight_colors)
endif

if !exists('g:dotoo_heading_shade_leading_stars')
  let g:dotoo_heading_shade_leading_stars = 1
endif
"}}}

let s:todo_headings = ''
let s:i = 1
while s:i <= g:dotoo_heading_highlight_levels
  if s:todo_headings == ''
    let s:todo_headings = 'containedin=dotoo_heading' . s:i
  else
    let s:todo_headings = s:todo_headings . ',dotoo_heading' . s:i
  endif
  let s:i += 1
endwhile
unlet! s:i

if !exists('g:loaded_dotooagenda_syntax')
  let g:loaded_dotooagenda_syntax = 1

  function! s:ExtendHighlightingGroup(base_group, new_group, settings)
    let l:base_hi = ''
    redir => l:base_hi
    silent execute 'highlight ' . a:base_group
    redir END
    let l:group_hi = substitute(split(l:base_hi, '\n')[0], '^' . a:base_group . '\s\+xxx', '', '')
    execute 'highlight ' . a:new_group . l:group_hi . ' ' . a:settings
  endfunction

  function! s:InterpretFaces(faces)
    let l:res_faces = ''
    if type(a:faces) == 3
      let l:style = []
      for l:f in a:faces
        let l:_f = [l:f]
        if type(l:f) == 3
          let l:_f = l:f
        endif
        for l:g in l:_f
          if type(l:g) == 1 && l:g =~ '^:'
            if l:g !~ '[\t ]'
              continue
            endif
            let l:k_v = split(l:g)
            if l:k_v[0] == ':foreground'
              let l:gui_color = ''
              let l:found_gui_color = 0
              for l:color in split(l:k_v[1], ',')
                if l:color =~ '^#'
                  let l:found_gui_color = 1
                  let l:res_faces = l:res_faces . ' guifg=' . l:color
                elseif l:color != ''
                  if l:color !~ '^\d\+$'
                    let l:gui_color = l:color
                  endif
                  let l:res_faces = l:res_faces . ' ctermfg=' . l:color
                endif
              endfor
              if ! l:found_gui_color && l:gui_color != ''
                let l:res_faces = l:res_faces . ' guifg=' . l:gui_color
              endif
            elseif l:k_v[0] == ':background'
              let l:gui_color = ''
              let l:found_gui_color = 0
              for l:color in split(l:k_v[1], ',')
                if l:color =~ '^#'
                  let l:found_gui_color = 1
                  let l:res_faces = l:res_faces . ' guibg=' . l:color
                elseif l:color != ''
                  if l:color !~ '^\d\+$'
                    let l:gui_color = l:color
                  endif
                  let l:res_faces = l:res_faces . ' ctermbg=' . l:color
                endif
              endfor
              if ! l:found_gui_color && l:gui_color != ''
                let l:res_faces = l:res_faces . ' guibg=' . l:gui_color
              endif
            elseif l:k_v[0] == ':weight' || l:k_v[0] == ':slant' || l:k_v[0] == ':decoration'
              if index(l:style, l:k_v[1]) == -1
                call add(l:style, l:k_v[1])
              endif
            endif
          elseif type(l:g) == 1
            " TODO emacs interprets the color and automatically determines
            " whether it should be set as foreground or background color
            let l:res_faces = l:res_faces . ' ctermfg=' . l:k_v[1] . ' guifg=' . l:k_v[1]
          endif
        endfor
      endfor
      let l:s = ''
      for l:i in l:style
        if l:s == ''
          let l:s = l:i
        else
          let l:s = l:s . ','. l:i
        endif
      endfor
      if l:s != ''
        let l:res_faces = l:res_faces . ' term=' . l:s . ' cterm=' . l:s . ' gui=' . l:s
      endif
    elseif type(a:faces) == 1
      " TODO emacs interprets the color and automatically determines
      " whether it should be set as foreground or background color
      let l:res_faces = l:res_faces . ' ctermfg=' . a:faces . ' guifg=' . a:faces
    endif
    return l:res_faces
  endfunction

  function! s:ReadTodoKeywords(keywords, todo_headings)
    let l:default_group = 'Todo'
    for l:i in a:keywords
      if type(l:i) == 3
        call s:ReadTodoKeywords(l:i, a:todo_headings)
        continue
      endif
      if l:i == '|'
        let l:default_group = 'Question'
        continue
      endif
      " strip access key
      let l:_i = substitute(l:i, "\(.*$", "", "")

      let l:group = l:default_group
      for l:j in g:dotoo_todo_keyword_faces
        if l:j[0] == l:_i
          let l:group = 'dotootodo_todo_keyword_face_' . l:_i
          call s:ExtendHighlightingGroup(l:default_group, l:group, s:InterpretFaces(l:j[1]))
          break
        endif
      endfor
      exec 'syntax match dotootodo_todo_keyword_' . l:_i . ' /' . l:_i .'/ ' . a:todo_headings . ' contains=@NoSpell'
      exec 'hi def link dotootodo_todo_keyword_' . l:_i . ' ' . l:group
    endfor
  endfunction
endif

call s:ReadTodoKeywords(g:dotoo#parser#todo_keywords, s:todo_headings)
unlet! s:todo_headings

" Timestamps
"[2003-09-16 Tue]
syn match dotoo_timestamp /\(\[\d\d\d\d-\d\d-\d\d \a\a\a\]\)/
"[2003-09-16 Tue 12:00]
syn match dotoo_timestamp /\(\[\d\d\d\d-\d\d-\d\d \a\a\a \d\d:\d\d\]\)/
"\[2003-09-16 Tue 12:00-12:30\]
syn match dotoo_timestamp /\(\[\d\d\d\d-\d\d-\d\d \a\a\a \d\d:\d\d-\d\d:\d\d\]\)/
"\[2003-09-16 Tue\]--[2003-09-16 Tue]
syn match dotoo_timestamp /\(\[\d\d\d\d-\d\d-\d\d \a\a\a\]--\[\d\d\d\d-\d\d-\d\d \a\a\a\]\)/
"\[2003-09-16 Tue 12:00\]--[2003-09-16 Tue 12:00]
syn match dotoo_timestamp /\(\[\d\d\d\d-\d\d-\d\d \a\a\a \d\d:\d\d\]--\[\d\d\d\d-\d\d-\d\d \a\a\a \d\d:\d\d\]\)/
"[2003-09-16 Tue +1m]
syn match dotoo_timestamp /\(\[\d\d\d\d-\d\d-\d\d \a\a\a +\d\+[ymwdhs]\]\)/
"[2003-09-15 Tue 12:00 +1m]
syn match dotoo_timestamp /\(\[\d\d\d\d-\d\d-\d\d \a\a\a \d\d:\d\d +\d\+[ymwdhs]\]\)/

syn match dotoo_timestamp /\(\[%%(diary-float.\+\]\)/
hi def link dotoo_timestamp SpecialKey

" ... ago, In ... "
syn match dotoo_time_ago /:\zs\s*[^:]*ago\ze:/
hi def link dotoo_time_ago Comment

syn match dotoo_time_in /:\zs\s*In[^:]*\ze:/
hi def link dotoo_time_in Statement

syn match dotoo_file_name /^\s*[^:]*\ze:/
hi def link dotoo_file_name Function

syn match dotoo_header /\%1l/
hi def link dotoo_header Constant

syn match dotoo_tags /\s\+:.*:$/
hi def link dotoo_tags Delimiter

" special wordk
syn match now /now\ze:/
hi def link now Error

syn match today /TODAY$/
hi def link today PreProc

syn match week_agenda /^Week Agenda:$/
hi def link week_agenda PreProc

" Hyperlinks
syntax match hyperlink	"\[\{2}[^][]*\(\]\[[^][]*\)\?\]\{2}" contains=hyperlinkBracketsLeft,hyperlinkURL,hyperlinkBracketsRight containedin=ALL
syntax match hyperlinkBracketsLeft		contained "\[\{2}" conceal
syntax match hyperlinkURL				contained "[^][]*\]\[" conceal
syntax match hyperlinkBracketsRight		contained "\]\{2}" conceal
hi def link hyperlink Underlined

let b:current_syntax = 'dotooagenda'
