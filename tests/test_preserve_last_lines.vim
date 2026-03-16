let g:templates_no_autocmd = 1
let g:templates_directory = []

execute 'set rtp^=' . fnameescape(fnamemodify(expand('<sfile>:p'), ':h:h'))
runtime plugin/templates.vim

function! s:RunCase(file_name, template_lines, expected_lines) abort
	let l:root = tempname()
	let l:templates_dir = l:root . '/templates'
	call mkdir(l:templates_dir, 'p')
	call writefile(a:template_lines, l:templates_dir . '/=template=.' . fnamemodify(a:file_name, ':e'))
	let g:templates_directory = [l:templates_dir]

	silent execute 'edit ' . fnameescape(l:root . '/' . a:file_name)
	silent Template

	call assert_equal(a:expected_lines, getline(1, '$'))
	bwipe!
endfunction

function! s:RunFoldExprCase(file_name, template_lines, expected_lines) abort
	let l:root = tempname()
	let l:templates_dir = l:root . '/templates'
	call mkdir(l:templates_dir, 'p')
	call writefile(a:template_lines, l:templates_dir . '/=template=.' . fnamemodify(a:file_name, ':e'))
	let g:templates_directory = [l:templates_dir]

	silent enew
	execute 'file ' . fnameescape(l:root . '/' . a:file_name)
	setlocal foldmethod=expr foldexpr=1
	silent Template

	call assert_equal(a:expected_lines, getline(1, '$'))
	bwipe!
endfunction

call s:RunCase('keep.txt', ['alpha', 'beta', 'gamma'], ['alpha', 'beta', 'gamma'])
call s:RunCase('cursor.md', ['alpha', 'omega', '%HERE%', ''], ['alpha', 'omega', '', ''])
call s:RunFoldExprCase('keep.md', ['alpha', 'beta', 'gamma'], ['alpha', 'beta', 'gamma'])

if empty(v:errors)
	quit
endif

for s:error in v:errors
	echom s:error
endfor
cquit 1
