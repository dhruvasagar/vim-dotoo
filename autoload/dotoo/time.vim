if exists('g:autoloaded_dotoo_time')
  finish
endif
let g:autoloaded_dotoo_time = 1

let g:dotoo#time#date_regex = '\v^(\d{4})-(\d{2})-(\d{2})'
let g:dotoo#time#day_regex = ' (\w{3})'

let g:dotoo#time#date_day_regex = g:dotoo#time#date_regex . g:dotoo#time#day_regex

let g:dotoo#time#time_regex = ' (\d{2}):(\d{2})'
let g:dotoo#time#datetime_regex = g:dotoo#time#date_day_regex . g:dotoo#time#time_regex

let g:dotoo#time#repeatable_regex = ' (\+?\d+[hdmy])'
let g:dotoo#time#repeatable_date_regex = g:dotoo#time#date_day_regex . g:dotoo#time#repeatable_regex
let g:dotoo#time#repeatable_datetime_regex = g:dotoo#time#datetime_regex . g:dotoo#time#repeatable_regex

let g:dotoo#time#date_format = '%Y-%m-%d'
let g:dotoo#time#date_day_format = g:dotoo#time#date_format . ' %a'
let g:dotoo#time#datetime_format = g:dotoo#time#date_day_regex . ' %H:%M'

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

function! s:localtime(...)
  let ts  = a:0 ? a:1 : has('unix') ? reltimestr(reltime()) : localtime() . '.0'
  let rp = a:0 > 1 ? a:2 : ''
  let us  = matchstr(ts, '\.\zs.\{0,6\}')
  let us .= repeat(0, 6 - strlen(us))
  let us  = matchstr(us, '[1-9].*')
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
        \, 'smicro' : us / 1000}
  let datetime.depoch = s:jd(datetime.year, datetime.month, datetime.day)
        \ - s:epoch_jd
  let real_ts = datetime.depoch * 86400 + datetime.hour * 3600 + datetime.minute * 60
        \ + datetime.second
  let datetime.stzoffset = (real_ts - ts)
  let datetime.mtzoffset = (real_ts - ts) / 60
  let datetime.htzoffset = datetime.mtzoffset / 60

  func datetime.to_seconds() dict
    return self.sepoch
  endfunc

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
  let stzoffset = s:localtime().stzoffset
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
  let seconds -= stzoffset
  return seconds
endfunction

function! dotoo#time#start_of(time)
  if a:time ==# 'month'
    return dotoo#time#new(strftime('%Y-%m-') . '01')
  elseif a:time ==# 'day'
    return dotoo#time#new(strftime('%Y-%m-%d'))
  endif
endfunction

function! dotoo#time#new(...)
  let dt = a:0 ? a:1 : ''
  let obj = {}

  func obj.init(...) dict
    let dt = a:0 ? a:1 : ''
    let rp = ''
    if type(dt) == type('')
      if dt =~# g:dotoo#time#repeatable_date_regex . '$'
        let rp = matchlist(dt, g:dotoo#time#repeatable_date_regex)[5]
      elseif dt =~# g:dotoo#time#repeatable_datetime_regex . '$'
        let rp = matchlist(dt, g:dotoo#time#repeatable_datetime_regex)[7]
      endif
    endif
    let self.datetime = s:localtime(s:to_seconds(dt), rp)
    return self
  endfunc

  func obj.to_seconds() dict
    return self.datetime.to_seconds()
  endfunc

  func obj.compare(other) dict
    let [ss1, ss2] = [self.to_seconds(), a:other.to_seconds()]
    return ss1 == ss2 ? 0 : (ss1 > ss2) ? 1 : -1
  endfunc

  func obj.eq(other) dict
    return self.compare(a:other) == 0
  endfunc

  func obj.before(other) dict
    return self.compare(a:other) == -1
  endfunc

  func obj.after(other) dict
    return self.compare(a:other) == 1
  endfunc

  func obj.between(start, end) dict
    return self.after(a:start) && self.before(a:end)
  endfunc

  func obj.diff(other) dict
    return self.to_seconds() - a:other.to_seconds()
  endfunc

  func obj.diff_in_words(other) dict
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

    if years | call add(diffs, years.'y') | endif
    if days | call add(diffs, days.'d') | endif
    if hours | call add(diffs, hours.'h') | endif
    if mins | call add(diffs, mins.'m') | endif
    if secs | call add(diffs, secs.'s') | endif

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
  endfunc

  func obj.time_ago() dict
    return self.diff_in_words(s:localtime())
  endfunc

  func obj.to_string(...) dict
    let format = a:0 ? a:1 : g:dotoo#time#date_day_format
    return strftime(format, self.to_seconds())
  endfunc

  func obj.add(other) dict
    let datetime = s:localtime(self.datetime.to_seconds()
          \ + s:to_seconds(a:other))
    return dotoo#time#new(datetime)
  endfunc

  func obj.sub(other) dict
    let datetime = s:localtime(self.datetime.to_seconds()
          \ - s:to_seconds(a:other))
    return dotoo#time#new(datetime)
  endfunc

  func obj.adjust(amount) dict
    let amount = a:amount
    let adjusted = 0
    if type(amount) == type('')
      " space separated entries
      " e.g.   1y 2m -3d 4h +5M 6s
      " NOTE: 'm' and 'M' are case sensitive, but the others are not
      let seconds = 0
      let [y, m, d, H, M, S] = [self.datetime.year, self.datetime.month, self.datetime.day, self.datetime.hour, self.datetime.minute, self.datetime.second]
      for amt in split(amount, '\s\+')
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
      let seconds += S
      let seconds += s:minutes_to_seconds(M)
      let seconds += s:hours_to_seconds(H)
      let seconds += s:days_to_seconds(s:jd(y, m, d) - s:epoch_jd)
      let datetime = s:localtime(seconds)
      let adjusted = 1
    else
      let seconds = s:to_seconds(amount)
    endif
    if ! adjusted
      let datetime = s:localtime(self.datetime.to_seconds() + seconds)
    endif
    return dotoo#time#new(datetime)
  endfunction

  func obj.repeat() dict
    if !empty(self.datetime.repeat)
      return self.adjust(self.datetime.repeat)
    endif
  endfunc

  func obj.nearest_repeat(end) dict
    if empty(self.datetime.repeat)
      return self
    else
      let now = dotoo#time#new()
      if has_key(self, 'repeated_until') && self.repeated_until.before(now)
        return self.repeated_until
      endif
      let [time, u_time] = [self, self]
      " TODO: Optimize this.
      while time.before(a:end)
        let u_time = time
        let time = time.adjust(self.datetime.repeat)
      endwhile
      let self.repeated_until = u_time
      return self.repeated_until
    endif
  endfunc

  return obj.init(dt)
endfunction
