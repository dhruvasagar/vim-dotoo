function! s:ParseFileTest1()
  let dotoos = dotoo#parser#parsefile({'file': 't/fixtures/sample.dotoo'})

  call testify#assert#equals(dotoos.file, 't/fixtures/sample.dotoo')
  call testify#assert#equals(len(dotoos.headlines), 17)
endfunction
call testify#it('dotoo#parser#parsefile should parse headlines', function('s:ParseFileTest1'))

function! s:ParseFileTest2()
  let dotoos = dotoo#parser#parsefile({'file': 't/fixtures/sample.dotoo'})

  call testify#assert#equals(dotoos.directives['TITLE'], 'Dotoo Tasks')
  call testify#assert#equals(dotoos.directives['EMAIL'], 'dhruva.sagar@gmail.com')
  call testify#assert#equals(dotoos.directives['AUTHOR'], 'Dhruva Saga')
endfunction
call testify#it('dotoo#parser#parsefile should have right directives', function('s:ParseFileTest2'))
