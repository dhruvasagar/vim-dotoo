function! s:log_summary_line(title, time, pad)
  let [time, title] = [a:time, a:title]
  if a:pad | let [time, title] = [' '.time.' ', ' '.title.' '] | endif
  return printf('|%-50.50s|%10s|', title, time)
endfunction

function! s:log_summary_line_separator()
  return s:log_summary_line(repeat('-',50), repeat('-',10), 0)
endfunction

function! s:build_log_summary(date, dotoo_values)
  let all_log_summaries = []
  for dotoo in values(a:dotoo_values)
    let log_summaries = []
    let total_log_summary = 0
    let dotoo_summaries = dotoo.log_summary(a:date, 'day')
    for dotoo_summary in dotoo_summaries
      call add(log_summaries,
            \  s:log_summary_line(dotoo_summary[0],
            \                     dotoo_summary[1].to_string(g:dotoo#time#time_format),
            \                     1))
      let total_log_summary += dotoo_summary[1].to_seconds() + dotoo_summary[1].datetime.stzoffset
    endfor
    if !empty(log_summaries)
      call insert(log_summaries, s:log_summary_line(dotoo.key, dotoo#time#new(total_log_summary).to_string(g:dotoo#time#time_format), 1))
      call add(log_summaries, s:log_summary_line_separator())
      call extend(all_log_summaries, log_summaries)
    endif
  endfor
  if !empty(all_log_summaries) | call insert(all_log_summaries, s:log_summary_line_separator()) | endif
  return all_log_summaries
endfunction

let s:agenda_log_summary_showing = 0
function! s:log_summary_view(lnum, log_summaries)
  setl modifiable
  if a:lnum < line('$')
    silent exe (a:lnum + 1).',$:delete'
  endif
  if s:agenda_log_summary_showing
    let lnum = a:lnum + 1
    silent call setline(lnum, 'Log Summary:')
    if empty(a:log_summaries)
      silent call setline(lnum+1, 'No Clocked Tasks')
    else
      silent call setline(lnum+1, a:log_summaries)
    endif
  endif
  setl nomodified
  setl nomodifiable
endfunction

function! dotoo#agenda#log_summary#show(date, agenda_dotoos, lnum)
  call s:log_summary_view(a:lnum, s:build_log_summary(a:date, a:agenda_dotoos))
endfunction

function! dotoo#agenda#log_summary#toggle(date, agenda_dotoos, lnum)
  let s:agenda_log_summary_showing = !s:agenda_log_summary_showing
  call dotoo#agenda#log_summary#show(a:date, a:agenda_dotoos, a:lnum)
endfunction
