if exists('g:autoloaded_dotoo_time')
  finish
endif
let g:autoloaded_dotoo_time = 1

call dotoo#utils#set('dotoo#time#time_ago_short', 0)

call dotoo#utils#set('dotoo#time#date_regex', '\v^(\d{4})-(\d{2})-(\d{2})')
call dotoo#utils#set('dotoo#time#day_regex', '(\w{1,3})')

call dotoo#utils#set('dotoo#time#date_day_regex', g:dotoo#time#date_regex . ' ' .g:dotoo#time#day_regex)

call dotoo#utils#set('dotoo#time#time_regex', '(\d{2}):(\d{2})')
call dotoo#utils#set('dotoo#time#datetime_regex', g:dotoo#time#date_day_regex . ' ' . g:dotoo#time#time_regex)

call dotoo#utils#set('dotoo#time#repeatable_regex', '(\+?\d+[hdmy])')
call dotoo#utils#set('dotoo#time#repeatable_date_regex', g:dotoo#time#date_day_regex . ' ' . g:dotoo#time#repeatable_regex)
call dotoo#utils#set('dotoo#time#repeatable_datetime_regex', g:dotoo#time#datetime_regex . ' ' . g:dotoo#time#repeatable_regex)

call dotoo#utils#set('dotoo#time#date_format', '%Y-%m-%d')
call dotoo#utils#set('dotoo#time#date_day_format', g:dotoo#time#date_format . ' %a')
call dotoo#utils#set('dotoo#time#time_format', '%H:%M')
call dotoo#utils#set('dotoo#time#datetime_format', g:dotoo#time#date_day_format . ' ' . g:dotoo#time#time_format)

" In Vim, -4 / 3 == -1.  Let's return -2 instead.
function! s:div(a, b)
  if a:a < 0 && a:b > 0
    return (a:a - a:b + 1) / a:b
  elseif a:a > 0 && a:b < 0
    return (a:a - a:b - 1) / a:b
  else
    return a:a / a:b
  endif
endfunction

" Julian day (always Gregorian calendar)
function! s:jd(year, mon, day)
  let y = a:year + 4800 - (a:mon <= 2)
  let m = a:mon + (a:mon <= 2 ? 9 : -3)
  let jul = a:day + (153 * m + 2) / 5 + s:div(1461 * y, 4) - 32083
  return jul - s:div(y, 100) + s:div(y, 400) + 38
endfunction
let s:epoch_jd = s:jd(1970, 1, 1)

let s:datetime_methods = {}
function! s:datetime_methods.to_seconds() dict
  return self.sepoch
endfunction

function! s:localtime(...)
  let ts  = a:0 && !empty(a:1) ? a:1 : localtime()
  let rp = a:0 == 2 && !empty(a:2) ? a:2 : ''
  " sepoch    = seconds since epoch (Jan 1, 1970)
  " depoch    = days since epoch
  " stzoffset = timezone offset from UTC in seconds
  " mtzoffset = timezone offset from UTC in minutes
  " htzoffset = timezone offset from UTC in hours
  " the + in +strftime() converts strings into numbers
  let datetime = {
        \  'year'   : +strftime('%Y', ts)
        \, 'month'  : +strftime('%m', ts)
        \, 'day'    : +strftime('%d', ts)
        \, 'hour'   : +strftime('%H', ts)
        \, 'minute' : +strftime('%M', ts)
        \, 'second' : +strftime('%S', ts)
        \, 'sepoch' : +strftime('%s', ts)
        \, 'repeat' : rp
        \}
  let datetime.depoch = s:jd(datetime.year, datetime.month, datetime.day)
        \ - s:epoch_jd
  let real_ts = s:days_to_seconds(datetime.depoch)
        \ + s:hours_to_seconds(datetime.hour)
        \ + s:minutes_to_seconds(datetime.minute)
        \ + datetime.second
  let datetime.stzoffset = (real_ts - ts)
  let datetime.mtzoffset = (real_ts - ts) / 60
  let datetime.htzoffset = datetime.mtzoffset / 60

  call extend(datetime, s:datetime_methods)
  return datetime
endfunction

function! s:minutes_to_seconds(minutes)
  return a:minutes * 60
endfunction

function! s:hours_to_seconds(hours)
  return s:minutes_to_seconds(a:hours * 60)
endfunction

function! s:days_to_seconds(days)
  return s:hours_to_seconds(a:days * 24)
endfunction

function! s:to_seconds(time)
  let seconds = 0
  if type(a:time) == type(0)
    let seconds = a:time
  elseif type(a:time) == type({})
    if has_key(a:time, 'to_seconds')
      let seconds = a:time.to_seconds()
    endif
  elseif type(a:time) == type('')
    if empty(a:time)
      return s:localtime().to_seconds()
    elseif a:time =~# g:dotoo#time#date_regex.'$' || a:time =~# g:dotoo#time#date_day_regex.'$' || a:time =~# g:dotoo#time#repeatable_date_regex.'$'
      let [y, m, d] = matchlist(a:time, g:dotoo#time#date_regex)[1:3]
      let seconds = s:days_to_seconds(s:jd(y, m, d) - s:epoch_jd)
    elseif a:time =~# g:dotoo#time#datetime_regex.'$' || a:time =~# g:dotoo#time#repeatable_datetime_regex.'$'
      let [y, m, d, a, H, M] = matchlist(a:time, g:dotoo#time#datetime_regex)[1:6]
      let seconds = 0
      let seconds += s:minutes_to_seconds(M)
      let seconds += s:hours_to_seconds(H)
      let seconds += s:days_to_seconds(s:jd(y, m, d) - s:epoch_jd)
    endif
  endif
  let seconds -= s:localtime(seconds).stzoffset
  return seconds
endfunction

function! dotoo#time#start_of(time, span)
  if type(a:time) == type(1) || type(a:time) == type('')
    let time = a:time
  elseif type(a:time) == type({})
    let time = a:time.to_seconds()
  endif
  if a:span ==# 'month'
    return dotoo#time#new(printf('%s-%02s-%02s', strftime('%Y', time), strftime('%m', time), '1'))
  elseif a:span ==# 'week'
    let now = dotoo#time#new(time)
    while now.to_string('%a') !=# 'Mon'
      let now = now.adjust('-1d')
    endwhile
    return now
  elseif a:span ==# 'day'
    return dotoo#time#new(strftime('%Y-%m-%d', time))
  endif
endfunction

function! dotoo#time#end_of(time, span) abort
  let start_of = dotoo#time#start_of(a:time, a:span)
  if a:span ==# 'month'
    return dotoo#time#new(printf('%s-%02s-%02s', strftime('%Y'), strftime('%m')+1, '1')).adjust('-1d')
  elseif a:span ==# 'week'
    return start_of.adjust('+1w -1d')
  elseif a:span ==# 'day'
    return start_of.adjust('+1d')
  endif
endfunction

let s:time_methods = {}
function! s:time_methods.init(...) dict
  let dt = a:0 && !empty(a:1) ? a:1 : ''
  let rp = a:0 == 2 && !empty(a:2) ? a:2 : ''
  if type(dt) == type('')
    if dt =~# g:dotoo#time#repeatable_date_regex . '$'
      let rp = matchlist(dt, g:dotoo#time#repeatable_date_regex)[5]
    elseif dt =~# g:dotoo#time#repeatable_datetime_regex . '$'
      let rp = matchlist(dt, g:dotoo#time#repeatable_datetime_regex)[7]
    endif
  endif
  let self.datetime = s:localtime(s:to_seconds(dt), rp)
  return self
endfunction

function! s:time_methods.repeat() dict
  return self.datetime.repeat
endfunction

function! s:time_methods.to_seconds() dict
  return self.datetime.to_seconds()
endfunction

function! s:time_methods.compare(other) dict
  let [ss1, ss2] = [self.to_seconds(), a:other.to_seconds()]
  return ss1 == ss2 ? 0 : (ss1 > ss2) ? 1 : -1
endfunction

function! s:time_methods.eq(other) dict
  return self.compare(a:other) == 0
endfunction

function! s:time_methods.eq_date(other) dict
  return self.to_string(g:dotoo#time#date_format) ==# a:other.to_string(g:dotoo#time#date_format)
endfunction

function! s:time_methods.before(other) dict
  return self.compare(a:other) == -1
endfunction

function! s:time_methods.after(other) dict
  return self.compare(a:other) == 1
endfunction

function! s:time_methods.between(start, end) dict
  return self.after(a:start) && self.before(a:end)
endfunction

function! s:time_methods.diff(other) dict
  return self.to_seconds() - a:other.to_seconds()
endfunction

function! s:time_methods.diff_in_words(other, ...) dict
  let short = a:0 && !empty(a:1) ? a:1 : 0
  let diff = self.diff(a:other)
  let adiff = abs(diff)
  let diffs = []

  let secs = adiff
  let mins = secs / 60
  let hours = mins / 60
  let days = hours / 24
  let years = days / 365

  let secs = secs % 60
  let mins = mins % 60
  let hours = hours % 24
  let days = days % 365

  if short && diff > 0
    let mins = secs && mins ? mins + 1 : mins
    let hours = mins && hours ? hours + 1 : hours
    let days = hours && days ? days + 1 : days
  endif

  if years | call add(diffs, years.'y') | endif
  if days && (!short || empty(diffs)) | call add(diffs, days.'d') | endif
  if hours && (!short || empty(diffs)) | call add(diffs, hours.'h') | endif
  if mins && (!short || empty(diffs)) | call add(diffs, mins.'m') | endif
  if secs && (!short || empty(diffs)) | call add(diffs, secs.'s') | endif

  if empty(diffs)
    call add(diffs, 'now')
  else
    if diff > 0
      call insert(diffs, 'In')
    elseif diff < 0
      call add(diffs, 'ago')
    endif
  endif

  return join(diffs, ' ')
endfunction

function! s:time_methods.time_ago(...) dict
  let from = s:localtime()
  let short = g:dotoo#time#time_ago_short
  if a:0
    if type(a:1) == type(0)
      let short = a:1
    elseif type(a:1) == type({}) && has_key(a:1, 'to_seconds')
      let from = s:localtime(a:1.to_seconds())
    endif
  endif
  return self.diff_in_words(from, short)
endfunction

function! s:time_methods.to_string(...) dict
  let format = a:0 && !empty(a:1) ? a:1 : g:dotoo#time#date_day_format
  if format ==# g:dotoo#time#date_day_format && strftime(g:dotoo#time#time_format, self.to_seconds()) !=# '00:00'
    let format = g:dotoo#time#datetime_format
  endif
  let str = strftime(format, self.to_seconds())
  if !empty(self.datetime.repeat) | let str .= ' ' . self.datetime.repeat | endif
  return str
endfunction

function! s:time_methods.add(other) dict
  let datetime = self.to_seconds() + a:other.to_seconds()
  return dotoo#time#new(datetime, self.datetime.repeat)
endfunction

function! s:time_methods.sub(other) dict
  let datetime = self.to_seconds() - a:other.to_seconds()
  return dotoo#time#new(datetime, self.datetime.repeat)
endfunction

function! s:time_methods.adjust(amount) dict
  let adjusted = 0
  if type(a:amount) == type('')
    " space separated entries
    " e.g.   1y 2m -3d 4h +5M 6s
    " NOTE: 'm' and 'M' are case sensitive, but the others are not
    let seconds = self.datetime.second
          \ + s:minutes_to_seconds(self.datetime.minute)
          \ + s:hours_to_seconds(self.datetime.hour)
    let [y, m, d] = [self.datetime.year, self.datetime.month, self.datetime.day]
    for amt in split(a:amount, '\s\+')
      let [n, type] = matchlist(amt, '\c\([-+]\?\d\+\)\([ymwdhs]\)')[1:2]
      if type == 'y'
        let y += str2nr(n)
      elseif type ==# 'm'
        let m += str2nr(n)
      elseif type ==# 'w'
        let d += str2nr(n) * 7
      elseif type == 'd'
        let d += str2nr(n)
      elseif type == 'h'
        let seconds += s:hours_to_seconds(str2nr(n))
      elseif type ==# 'M'
        let seconds += s:minutes_to_seconds(str2nr(n))
      elseif type == 's'
        let seconds += str2nr(n)
      else
        throw 'Unknown adjustment type: ' . string(type)
      endif
    endfor
    let seconds += s:days_to_seconds(s:jd(y, m, d) - s:epoch_jd)
    let datetime = s:localtime(seconds)
    let adjusted = 1
  else
    let seconds = s:to_seconds(a:amount)
  endif
  if ! adjusted
    let datetime = s:localtime(self.datetime.to_seconds() + seconds)
  endif
  return dotoo#time#new(datetime, self.datetime.repeat)
endfunction

function! s:time_methods.next_repeat() dict
  let date = dotoo#time#new()
  if empty(self.datetime.repeat)
    return self
  else
    let time = self
    if time.before(date)
      while time.before(date)
        let time = time.adjust(self.datetime.repeat)
      endwhile
    else
      let time = time.adjust(self.datetime.repeat)
    endif
    return time
  endif
endfunction

function! s:time_methods.is_today() dict
  return self.to_string(g:dotoo#time#date_format) ==# dotoo#time#new().to_string(g:dotoo#time#date_format)
endfunction

function! s:time_methods.start_of(span)
  return dotoo#time#start_of(self, a:span)
endfunction

function! s:time_methods.end_of(span)
  return dotoo#time#end_of(self, a:span)
endfunction

function! s:time_methods.repeatable()
  return !empty(get(self.datetime, 'repeat', ''))
endfunction

function! dotoo#time#new(...)
  let dt = a:0 && !empty(a:1) ? a:1 : ''
  let rp = a:0 == 2 && !empty(a:2) ? a:2 : ''
  let obj = {}
  call extend(obj, s:time_methods)
  return obj.init(dt, rp)
endfunction

function! dotoo#time#log(seconds)
  let secs = a:seconds
  let mins = secs / 60
  let hours = mins / 60
  let mins = mins % 60
  let hours = hours % 24
  return dotoo#time#new(printf('%s %02d:%02d', strftime(g:dotoo#time#date_day_format), hours, mins))
endfunction
