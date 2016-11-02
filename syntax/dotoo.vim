" Borrowed from jceb/vim-orgmode

" Org Markup: {{{
" Support org authoring markup as closely as possible
" (we're adding two markdown-like variants for =code= and blockquotes)
" -----------------------------------------------------------------------------

" Inline markup
" *bold*, /italic/, _underline_, +strike-through+, =code=, ~verbatim~
" Note:
" - /italic/ is rendered as reverse in most terms (works fine in gVim, though)
" - +strike-through+ doesn't work on Vim / gVim
" - the non-standard `code' markup is also supported
" - =code= and ~verbatim~ are also supported as block-level markup, see below.
" Ref: http://orgmode.org/manual/Emphasis-and-monospace.html
"syntax match org_bold /\*[^ ]*\*/

if exists('b:current_syntax')
  finish
endif

" FIXME: Always make dotoo_bold syntax define before dotoo_heading syntax
"        to make sure that dotoo_heading syntax got higher priority(help :syn-priority) than dotoo_bold.
"        If there is any other good solution, please help fix it.
syntax region dotoo_bold      start="\S\@<=\*\|\*\S\@="   end="\S\@<=\*\|\*\S\@="  keepend oneline
syntax region dotoo_italic    start="\S\@<=\/\|\/\S\@="   end="\S\@<=\/\|\/\S\@="  keepend oneline
syntax region dotoo_underline start="\S\@<=_\|_\S\@="       end="\S\@<=_\|_\S\@="    keepend oneline
syntax region dotoo_code      start="\S\@<==\|=\S\@="       end="\S\@<==\|=\S\@="    keepend oneline
syntax region dotoo_code      start="\S\@<=`\|`\S\@="       end="\S\@<='\|'\S\@="    keepend oneline
syntax region dotoo_verbatim  start="\S\@<=\~\|\~\S\@="     end="\S\@<=\~\|\~\S\@="  keepend oneline

hi def dotoo_bold      term=bold      cterm=bold      gui=bold
hi def dotoo_italic    term=italic    cterm=italic    gui=italic
hi def dotoo_underline term=underline cterm=underline gui=underline
" }}}
" Headings: {{{
"" Enable Syntax HL: {{{
let s:contains = ' contains=dotoo_timestamp,dotoo_subtask_percent,dotoo_subtask_number,dotoo_subtask_percent_100,'.
      \ 'dotoo_subtask_number_all,dotoo_list_checkbox,dotoo_bold,dotoo_italic,dotoo_underline,' .
      \ 'dotoo_code,dotoo_verbatim'
if g:dotoo_heading_shade_leading_stars == 1
  let s:contains .= ',dotoo_shade_stars'
  syntax match dotoo_shade_stars /^\*\{2,\}/me=e-1 contained
  hi def link dotoo_shade_stars Ignore
else
  hi clear dotoo_shade_stars
endif

for ind in range(1, g:dotoo_heading_highlight_levels)
  exec 'syntax match dotoo_heading' . ind . ' /^\*\{' . ind . '\}\s.*/' . s:contains
  exec 'hi def link dotoo_heading' . ind . ' ' . g:dotoo_heading_highlight_colors[(ind - 1) % g:dotoo_heading_highlight_levels]
endfor
" }}}
" }}}
" Todo Keywords: {{{
"" Enable Syntax HL: {{{
let s:todo_headings = ''
for ind in range(1, g:dotoo_heading_highlight_levels)
  if empty(s:todo_headings)
    let s:todo_headings = 'containedin=dotoo_heading' . ind
  else
    let s:todo_headings .= ',dotoo_heading' . ind
  endif
endfor

if !exists('g:loaded_dotoo_syntax')
  let g:loaded_dotoo_syntax = 1

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
    if type(a:faces) == type([])
      let l:style = []
      for l:f in a:faces
        let l:_f = [l:f]
        if type(l:f) == type([]) | let l:_f = l:f | endif
        for l:g in l:_f
          if type(l:g) == type('') && l:g =~ '^:'
            if l:g !~ '[\t ]' | continue | endif
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
          elseif type(l:g) == type('')
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
          let l:group = 'dotoo_todo_keyword_face_' . l:_i
          call s:ExtendHighlightingGroup(l:default_group, l:group, s:InterpretFaces(l:j[1]))
          break
        endif
      endfor
      exec 'syntax match dotoo_todo_keyword_' . l:_i . ' /\*\{1,\}\s\{1,\}\zs' . l:_i .'\(\s\|$\)/he=e-1 ' . a:todo_headings . ' contains=@NoSpell'
      exec 'hi def link dotoo_todo_keyword_' . l:_i . ' ' . l:group
    endfor
  endfunction
endif

call s:ReadTodoKeywords(g:dotoo#parser#todo_keywords, s:todo_headings)
unlet! s:todo_headings
" }}}
" }}}
" Timestamps: {{{
"[2003-09-16 Tue] | <2003-09-16 Tue>
syn match dotoo_timestamp /\([\<\[]\d\d\d\d-\d\d-\d\d \a\a\a[\>\]]\)/
"[2003-09-16 Tue 12:00] | <2003-09-16 Tue 12:00>
syn match dotoo_timestamp /\([\<\[]\d\d\d\d-\d\d-\d\d \a\a\a \d\d:\d\d[\>\]]\)/
"[2003-09-16 Tue +1m] | <2003-09-16 Tue +1m>
syn match dotoo_timestamp /\([\<\[]\d\d\d\d-\d\d-\d\d \a\a\a +\d\+[ymwdhs][\>\]]\)/
"[2003-09-15 Tue 12:00 +1m] | <2003-09-16 Tue 12:00 +1m>
syn match dotoo_timestamp /\([\<\[]\d\d\d\d-\d\d-\d\d \a\a\a \d\d:\d\d +\d\+[ymwdhs][\>\]]\)/
"[2003-09-16 Tue]--[2003-09-16 Tue]
syn match dotoo_timestamp /\(\[\d\d\d\d-\d\d-\d\d \a\a\a\]--\[\d\d\d\d-\d\d-\d\d \a\a\a\]\)/
"[2003-09-16 Tue 12:00]--[2003-09-16 Tue 12:00]
syn match dotoo_timestamp /\(\[\d\d\d\d-\d\d-\d\d \a\a\a \d\d:\d\d\]--\[\d\d\d\d-\d\d-\d\d \a\a\a \d\d:\d\d\]\)/

syn match dotoo_timestamp /\(\[%%(diary-float.\+\]\)/

hi def link dotoo_timestamp SpecialKey

" }}}
" Deadline And Schedule: {{{
syn match dotoo_deadline_scheduled /^\s*\(DEADLINE\|CLOSED\|SCHEDULED\):/
hi def link dotoo_deadline_scheduled PreProc
" }}}
" Hyperlinks: {{{
syntax match hyperlink	"\[\{2}[^][]*\(\]\[[^][]*\)\?\]\{2}" contains=hyperlinkBracketsLeft,hyperlinkURL,hyperlinkBracketsRight containedin=ALL
syntax match hyperlinkBracketsLeft	contained "\[\{2}"     conceal
syntax match hyperlinkURL				    contained "[^][]*\]\[" conceal
syntax match hyperlinkBracketsRight	contained "\]\{2}"     conceal
hi def link hyperlink Underlined
" }}}
" Comments: {{{
syntax match dotoo_comment /^#.*/
hi def link dotoo_comment Comment

" }}}
" Lists: {{{

" Ordered Lists:
" 1. list item
" 1) list item
syn match dotoo_list_ordered "^\s*\(\a\|\d\+\)[.)]\(\s\|$\)" nextgroup=dotoo_list_item 
hi def link dotoo_list_ordered Identifier

" Unordered Lists:
" - list item
" * list item
" + list item
" + and - don't need a whitespace prefix
syn match dotoo_list_unordered "^\(\s*[-+]\|\s\+\*\)\(\s\|$\)" nextgroup=dotoo_list_item 
hi def link dotoo_list_unordered Identifier

" Definition Lists:
" - Term :: expl.
" 1) Term :: expl.
syntax match dotoo_list_def /.*\s\+::/ contained
hi def link dotoo_list_def PreProc
"
" }}}
" Bullet Lists: {{{
syntax match dotoo_list_item /.*$/ contained contains=dotoo_subtask_percent,dotoo_subtask_number,dotoo_subtask_percent_100,dotoo_subtask_number_all,dotoo_list_checkbox,dotoo_bold,dotoo_italic,dotoo_underline,dotoo_code,dotoo_verbatim,dotoo_timestamp,dotoo_timestamp_inactive,dotoo_list_def 
syntax match dotoo_list_checkbox /\[[ X-]]/ contained
hi def link dotoo_list_checkbox     PreProc

" }}}
" Block Delimiters: {{{
syntax case ignore
syntax match  dotoo_block_delimiter /^#+BEGIN_.*/
syntax match  dotoo_block_delimiter /^#+END_.*/
syntax match  dotoo_key_identifier  /^#+[^ ]*:/
syntax match  dotoo_title           /^#+TITLE:.*/  contains=dotoo_key_identifier
hi def link dotoo_block_delimiter Comment
hi def link dotoo_key_identifier  Comment
hi def link dotoo_title           Title
" }}}
" Block Markup: {{{
" we consider all BEGIN/END sections as 'verbatim' blocks (inc. 'quote', 'verse', 'center')
" except 'example' and 'src' which are treated as 'code' blocks.
" Note: the non-standard '>' prefix is supported for quotation lines.
" Note: the '^:.*" rule must be defined before the ':PROPERTIES:' one below.
" TODO: http://vim.wikia.com/wiki/Different_syntax_highlighting_within_regions_of_a_file
syntax match  dotoo_verbatim /^\s*>.*/
syntax match  dotoo_code     /^\s*:.*/
syntax region dotoo_verbatim start="^\s*#+BEGIN_.*"      end="^\s*#+END_.*"      keepend contains=dotoo_block_delimiter
syntax region dotoo_code     start="^\s*#+BEGIN_SRC"     end="^\s*#+END_SRC"     keepend contains=dotoo_block_delimiter
syntax region dotoo_code     start="^\s*#+BEGIN_EXAMPLE" end="^\s*#+END_EXAMPLE" keepend contains=dotoo_block_delimiter
hi def link dotoo_code     String
hi def link dotoo_verbatim String
" }}}
" Properties: {{{
syn region Error matchgroup=dotoo_properties_delimiter start=/^\s*:PROPERTIES:\s*$/ end=/^\s*:END:\s*$/ contains=dotoo_property keepend
syn match dotoo_property /^\s*:[^\t :]\+:\s\+[^\t ]/ contained contains=dotoo_property_value
syn match dotoo_property_value /:\s\zs.*/ contained
hi def link dotoo_properties_delimiter PreProc
hi def link dotoo_property             Statement
hi def link dotoo_property_value       Constant
" Break down subtasks
syntax match dotoo_subtask_number /\[\d*\/\d*]/ contained
syntax match dotoo_subtask_percent /\[\d*%\]/ contained
syntax match dotoo_subtask_number_all /\[\(\d\+\)\/\1\]/ contained
syntax match dotoo_subtask_percent_100 /\[100%\]/ contained

hi def link dotoo_subtask_number String
hi def link dotoo_subtask_percent String
hi def link dotoo_subtask_percent_100 Identifier
hi def link dotoo_subtask_number_all Identifier

" }}}
" Plugin SyntaxRange: {{{
" This only works if you have SyntaxRange installed:
" https://github.com/vim-scripts/SyntaxRange

" BEGIN_SRC
if exists('g:loaded_SyntaxRange')
  call SyntaxRange#Include('#+BEGIN_SRC\ vim', '#+END_SRC', 'vim', 'comment')
  call SyntaxRange#Include('#+BEGIN_SRC\ python', '#+END_SRC', 'python', 'comment')
  call SyntaxRange#Include('#+BEGIN_SRC\ c', '#+END_SRC', 'c', 'comment')
  " cpp must be below c, otherwise you get c syntax hl for cpp files
  call SyntaxRange#Include('#+BEGIN_SRC\ cpp', '#+END_SRC', 'cpp', 'comment')
  call SyntaxRange#Include('#+BEGIN_SRC\ ruby', '#+END_SRC', 'ruby', 'comment')
  " call SyntaxRange#Include('#+BEGIN_SRC\ lua', '#+END_SRC', 'lua', 'comment')
  " call SyntaxRange#Include('#+BEGIN_SRC\ lisp', '#+END_SRC', 'lisp', 'comment')

  " LaTeX
  call SyntaxRange#Include('\\begin[.*]{.*}', '\\end{.*}', 'tex')
  call SyntaxRange#Include('\\begin{.*}', '\\end{.*}', 'tex')
  call SyntaxRange#Include('\\\[', '\\\]', 'tex')
endif
" }}}

let b:current_syntax = 'dotoo'
