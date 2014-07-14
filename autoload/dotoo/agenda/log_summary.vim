" Log Summary Agenda Plugin {{{1
let s:plugin_name = 'log_summary'
let s:log_summary_plugin = {'showing': 0, 'mapped': 0}
function! s:log_summary_plugin.line(title, time, pad) dict "{{{2
  let [time, title] = [a:time, a:title]
  if a:pad | let [time, title] = [' '.time.' ', ' '.title.' '] | endif
  return printf('|%-50.50s|%10s|', title, time)
endfunction

function! s:log_summary_plugin.line_separator() dict "{{{2
  return self.line(repeat('-',50), repeat('-',10), 0)
endfunction

function! s:log_summary_plugin.map() dict "{{{2
  if self.mapped | return | endif
  let self.mapped = 1
  exec 'nnoremap <buffer> <silent> <nowait> R :<C-U>call dotoo#agenda#toggle_agenda_plugin("' . s:plugin_name . '")<CR>'
endfunction

function! s:log_summary_plugin.build_summaries(date, dotoo_values) dict "{{{2
  let all_summaries = []
  for dotoo in values(a:dotoo_values)
    let summaries = []
    let total = 0
    let dotoo_summaries = dotoo.log_summary(a:date, 'day')
    for dotoo_summary in dotoo_summaries
      call add(summaries,
            \  self.line(dotoo_summary[0],
            \            dotoo_summary[1].to_string(g:dotoo#time#time_format),
            \            1))
      let total += dotoo_summary[1].to_seconds() + dotoo_summary[1].datetime.stzoffset
    endfor
    if !empty(summaries)
      call insert(summaries, self.line(dotoo.key, dotoo#time#new(total).to_string(g:dotoo#time#time_format), 1))
      call add(summaries, self.line_separator())
      call extend(all_summaries, summaries)
    endif
  endfor
  if !empty(all_summaries) | call insert(all_summaries, self.line_separator()) | endif
  return all_summaries
endfunction

function! s:log_summary_plugin.view(log_summaries) dict "{{{2
  setl modifiable
  if self.showing
    let self.start_line = line('$') + 1
    let lnum = self.start_line
    let lines = ['Log Summary:']
    if empty(a:log_summaries)
      call add(lines, 'No Clocked Tasks')
    else
      call extend(lines, a:log_summaries)
    endif
    silent call append(self.start_line - 1, lines)
    let self.end_line = self.start_line + len(lines) - 1
  elseif has_key(self, 'start_line') && has_key(self, 'end_line')
    silent exe self.start_line.','.self.end_line.':delete'
    call remove(self, 'start_line')
    call remove(self, 'end_line')
  endif
  setl nomodified
  setl nomodifiable
endfunction

function! s:log_summary_plugin.show(date, agenda_dotoos) dict "{{{2
  call self.map()
  let summaries = self.build_summaries(a:date, a:agenda_dotoos)
  call self.view(summaries)
endfunction

function! s:log_summary_plugin.toggle(date, agenda_dotoos) dict "{{{2
  let self.showing = !self.showing
  call self.show(a:date, a:agenda_dotoos)
endfunction

function! dotoo#agenda#log_summary#register_agenda_plugin() "{{{1
  call dotoo#agenda#register_agenda_plugin(s:plugin_name, s:log_summary_plugin)
endfunction
