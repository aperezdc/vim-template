let s:dict = [
			\ 'DAY',
			\ 'YEAR',
			\ 'MONTH',
			\ 'DATE',
			\ 'TIME',
			\ 'FDATE',
			\ 'FILE',
			\ 'EXT',
			\ 'FFILE',
			\ 'MAIL',
			\ 'USER',
			\ 'LICENSE',
			\ 'HOST',
			\ 'GUARD',
			\ 'CLASS',
			\ 'MACROCLASS',
			\ 'CAMELCLASS',
			\ 'HERE',
			\ ]

function! coc#source#template#init() abort
	return {
				\ 'priority': 9,
				\ 'shortcut': 'vim-template',
				\ 'filetypes': ['vim-template'],
				\ 'triggerCharacters': ['%'],
				\ }
endfunction

function! coc#source#template#complete(opt, cb) abort
	let l:templates_user_variables = get(g:, 'templates_user_variables', [])
	for l:item in l:templates_user_variables
		let s:dict += [l:item[1]]
	endfor
	let l:classes = []
	for l:item in s:dict
		call add(l:classes, {'word': l:item . '%'})
	endfor
	call a:cb(l:classes)
endfunction
