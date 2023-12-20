function ddc#source#vim#get_cur_text(input) abort
  let cur_text = a:input

  let line = '.'->line()
  let cnt = 0
  while cur_text =~# '^\s*\\' && line > 1 && cnt < 5
    let cur_text =
          \ (line - 1)->getline() .. cur_text->substitute('^\s*\\', '', '')
    let line -= 1
    let cnt += 1
  endwhile

  return cur_text->split('\s\+|\s\+\|<bar>', 1)[-1]
endfunction
