"
" Template system for Vim
"
" Copyright (C) 2012-2016 Adrian Perez de Castro <aperez@igalia.com>
" Copyright (C) 2005 Adrian Perez de Castro <the.lightman@gmail.com>
"
" Distributed under terms of the MIT license.
"

if exists('g:templates_plugin_loaded')
	finish
endif
let g:templates_plugin_loaded = 1

if !exists('g:templates_name_prefix')
	let g:templates_name_prefix = '.vim-template:'
endif

if !exists('g:templates_global_name_prefix')
	let g:templates_global_name_prefix = '=template='
endif

if !exists('g:templates_debug')
	let g:templates_debug = 0
endif

if !exists('g:templates_tr_in')
	let g:templates_tr_in = [ '.', '*', '?' ]
endif

if !exists('g:templates_tr_out')
	let g:templates_tr_out = [ '\.', '.*', '\?' ]
endif

if !exists('g:templates_fuzzy_start')
	let g:templates_fuzzy_start = 1
endif

if !exists('g:templates_search_height')
	" First try to find the deprecated option
	if exists('g:template_max_depth')
		echom('g:template_max_depth is deprecated in favor of g:templates_search_height')
		let g:templates_search_height = g:template_max_depth != 0 ? g:template_max_depth : -1
	endif

	if(!exists('g:templates_search_height'))
		let g:templates_search_height = -1
	endif
endif

if !exists('g:templates_directory')
	let g:templates_directory = []
elseif type(g:templates_directory) == type('')
	" Convert string value to a list with one element.
	let s:tmp = g:templates_directory
	unlet g:templates_directory
	let g:templates_directory = [ s:tmp ]
	unlet s:tmp
endif

if !exists('g:templates_no_builtin_templates')
	let g:templates_no_builtin_templates = 0
endif

if !exists('g:templates_user_variables')
	let g:templates_user_variables = []
endif

" Put template system autocommands in their own group. {{{1
if !exists('g:templates_no_autocmd')
	let g:templates_no_autocmd = 0
endif

if !g:templates_no_autocmd
	augroup Templating
		autocmd!
		autocmd BufNewFile * call template#load()
	augroup END
endif


command -nargs=1 -complete=customlist,template#suffix_list Template     call template#load_command("<args>", 0)
command -nargs=1 -complete=customlist,template#suffix_list TemplateHere call template#load_command("<args>", 1)


" TODO: Remove the duplicated copy of these two functions
function! s:NormalizePath(path) abort
	return substitute(a:path, "\\", "/", "g")
endfunction
function! s:DirName(path) abort
	let l:tmp = s:NormalizePath(a:path)
	return substitute(l:tmp, "[^/][^/]*/*$", "", "")
endfunction


" Enable the vim-template syntax for template files
" Usually we'd put this in the ftdetect folder, but because
" g:templates_name_prefix doesn't get defined early enough we have to add the
" template detection from the plugin itself
execute "au BufNewFile,BufRead " . g:templates_name_prefix . "* "
			\. "let b:vim_template_subtype = &filetype | "
			\. "set ft=vim-template"

if !g:templates_no_builtin_templates
	" Default templates directory
	let s:default_template_dir = s:DirName(s:DirName(expand('<sfile>'))) . 'templates'
	execute "au BufNewFile,BufRead "
				\. s:default_template_dir . "/" . g:templates_global_name_prefix . "* "
				\. "let b:vim_template_subtype = &filetype | "
				\. "set ft=vim-template"
	unlet s:default_template_dir
endif

for s:directory in g:templates_directory
	let s:directory = s:NormalizePath(expand(s:directory) . '/')
	if isdirectory(s:directory)
		execute "au BufNewFile,BufRead "
					\. s:directory . "/" . g:templates_global_name_prefix . "* "
					\. "let b:vim_template_subtype = &filetype | "
					\. "set ft=vim-template"
	endif
	unlet s:directory
endfor

" vim: fdm=marker
