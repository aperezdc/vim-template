"
" Template system for Vim
"
" Copyright (C) 2012 Adrian Perez de Castro <aperez@igalia.com>
" Copyright (C) 2005 Adrian Perez de Castro <the.lightman@gmail.com>
"
" Distributed under terms of the MIT license.
"

if exists("g:templates_plugin_loaded")
	finish
endif
let g:templates_plugin_loaded = 1

if !exists('g:templates_name_prefix')
	let g:templates_name_prefix = ".vim-template:"
endif

if !exists('g:templates_global_name_prefix')
	let g:templates_global_name_prefix = "=template="
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

if !exists('g:templates_use_licensee')
	let g:templates_use_licensee = 1
endif

if !exists('g:templates_detect_git')
	let g:templates_detect_git = 0
endif

" Put template system autocommands in their own group. {{{1
if !exists('g:templates_no_autocmd')
	let g:templates_no_autocmd = 0
endif

if !g:templates_no_autocmd
	augroup Templating
		autocmd!
		autocmd BufNewFile * call <SID>TLoad(2, '')
	augroup END
endif

function <SID>Debug(mesg)
	if g:templates_debug
		echom(a:mesg)
	endif
endfunction

" normalize the path
" replace the windows path sep \ with /
function <SID>NormalizePath(path)
	return substitute(a:path, "\\", "/", "g")
endfunction

" Template searching. {{{1
" Returns a string containing the path of the parent directory of the given
" path. Works like dirname(3). It also simplifies the given path.
function <SID>DirName(path)
	let l:tmp = <SID>NormalizePath(a:path)
	return substitute(l:tmp, "[^/][^/]*/*$", "", "")
endfunction

" Default templates directory
let s:default_template_dir = <SID>DirName(<SID>DirName(expand("<sfile>"))) . "templates"

" Find the target template in windows
"
" In windows while we clone the symbol link from github
" it will turn to normal file, so we use this function
" to figure out the destination file
function <SID>TFindLink(path, template)
	if !filereadable(a:path . a:template)
		return a:template
	endif

	let l:content = readfile(a:path . a:template, "b")
	if len(l:content) != 1
		return a:template
	endif

	if filereadable(a:path . l:content[0])
		return <SID>TFindLink(a:path, l:content[0])
	else
		return a:template
	endif
endfunction

" Translate a template file name into a regular expression to test for matching
" against a given filename. As of writing this behavior is something like this:
" (with a g:templates_name_prefix set as 'template.')
"
" template.py -> ^.*py$
"
" template.test.py -> ^.*test.py$
"
function <SID>TemplateToRegex(template, prefix)
	let l:template_base_name = fnamemodify(a:template,":t")
	let l:template_glob = strpart(l:template_base_name, len(a:prefix))

	" Translate the template's glob into a normal regular expression
	let l:in_escape_mode = 0
	let l:template_regex = ""
	for l:c in split(l:template_glob, '\zs')
		if l:in_escape_mode == 1
			if l:c == '\'
				let l:template_regex = l:template_regex . '\\'
			else
				let l:template_regex = l:template_regex . l:c
			endif

			let l:in_escape_mode = 0
		else
			if l:c == '\'
				let l:in_escape_mode = 1
			else
				let l:tr_index = index(g:templates_tr_in, l:c)
				if l:tr_index != -1
					let l:template_regex = l:template_regex . g:templates_tr_out[l:tr_index]
				else
					let l:template_regex = l:template_regex . l:c
				endif
			endif
		endif
	endfor

	if g:templates_fuzzy_start
		return l:template_regex . '$'
	else
		return '^' . l:template_regex . '$'
	endif

endfunction

" Given a template and filename, return a score on how well the template matches
" the given filename.  If the template does not match the file name at all,
" return 0
function <SID>TemplateBaseNameTest(template, prefix, filename)
	let l:tregex = <SID>TemplateToRegex(a:template, a:prefix)

	" Ensure that we got a valid regex
	if l:tregex == ""
		return 0
	endif

	" For now only use the base of the filename.. this may change later
	" *Note* we also have to be careful because a:filename may also be the passed
	" in text from TLoad...
	let l:filename_chopped = fnamemodify(a:filename,":t")

	" Check for a match
	let l:regex_result = match(l:filename_chopped,l:tregex)
	if l:regex_result != -1
		" For a match return a score based on the regex length
		return len(l:tregex)
	else
		" No match
		return 0
	endif

endfunction

" Returns the most specific / highest scored template file found in the given
" path.  Template files are found by using a glob operation on the current path
" and the setting of g:templates_name_prefix. If no template is found in the
" given directory, return an empty string
function <SID>TDirectorySearch(path, template_prefix, file_name)
	let l:picked_template = ""
	let l:picked_template_score = 0

	" Use find if possible as it will also get hidden files on nix systems. Use
	" builtin glob as a fallback
	if executable("find") && !has("win32") && !has("win64")
		let l:find_cmd = '`find -L ' . shellescape(a:path) . ' -maxdepth 1 -type f -name ' . shellescape(a:template_prefix . '*' ) . '`'
		call <SID>Debug("Executing " . l:find_cmd)
		let l:glob_results = glob(l:find_cmd)
		if v:shell_error != 0
			call <SID>Debug("Could not execute find command")
			unlet l:glob_results
		endif
	endif
	if !exists("l:glob_results")
		call <SID>Debug("Using fallback glob")
		let l:glob_results = glob(a:path . a:template_prefix . "*")
	endif
	let l:templates = split(l:glob_results, "\n")
	for template in l:templates
		" Make sure the template is readable
		if filereadable(template)
			let l:current_score =
						\<SID>TemplateBaseNameTest(template, a:template_prefix, a:file_name)
			call <SID>Debug("template: " . template . " got scored: " . l:current_score)

			" Pick that template only if it beats the currently picked template
			" (here we make the assumption that template name length ~= template
			" specifity / score)
			if l:current_score > l:picked_template_score
				let l:picked_template = template
				let l:picked_template_score = l:current_score
			endif
		endif
	endfor

	if l:picked_template != ""
		call <SID>Debug("Picked template: " . l:picked_template)
	else
		call <SID>Debug("No template found")
	endif

	return l:picked_template
endfunction

" Searches for a [template] in a given [path].
"
" If [height] is [-1] the template is searched for in the given directory and
" all parents in its directory structure
"
" If [height] is [0] no searching is done in the given directory or any
" parents
"
" If [height] is [1] only the given directory is searched
"
" If [height] is greater than one, n parents and the given directory will be
" searched where n is equal to height - 1
"
" If no template is found an empty string is returned.
"
function <SID>TSearch(path, template_prefix, file_name, height)
	if (a:height != 0)

		" pick a template from the current path
		let l:picked_template = <SID>TDirectorySearch(a:path, a:template_prefix, a:file_name)
		if l:picked_template != ""
			return l:picked_template
		else
			let l:pathUp = <SID>DirName(a:path)
			if l:pathUp != a:path
				let l:new_height = a:height >= 0 ? a:height - 1 : a:height
				return <SID>TSearch(l:pathUp, a:template_prefix, a:file_name, l:new_height)
			endif
		endif
	endif

	" Ooops, either we cannot go up in the path or [height] reached 0
	return ""
endfunction


" Tries to find valid templates using the global g:templates_name_prefix as a glob
" matcher for template files. The search is done as follows:
"   1. The [path] passed to the function, [upwards] times up.
"   2. The g:templates_directory directory, if it exists.
"   3. Built-in templates from s:default_template_dir.
" Returns an empty string if no template is found.
"
function <SID>TFind(path, name, up)
	let l:tmpl = <SID>TSearch(a:path, g:templates_name_prefix, a:name, a:up)
	if l:tmpl != ''
		return l:tmpl
	endif

	for l:directory in g:templates_directory
		let l:directory = <SID>NormalizePath(expand(l:directory) . '/')
		if isdirectory(l:directory)
			let l:tmpl = <SID>TSearch(l:directory, g:templates_global_name_prefix, a:name, 1)
			if l:tmpl != ''
				return l:tmpl
			endif
		endif
	endfor

	if g:templates_no_builtin_templates
		return ''
	endif

	return <SID>TSearch(<SID>NormalizePath(expand(s:default_template_dir) . '/'), g:templates_global_name_prefix, a:name, 1)
endfunction

" Escapes a string for use in a regex expression where the regex uses / as the
" delimiter. Must be used with Magic Mode off /V
"
function <SID>EscapeRegex(raw)
	return escape(a:raw, '/')
endfunction

" Template variable expansion. {{{1

" Makes a single [variable] expansion, using [value] as replacement.
"
function <SID>TExpand(variable, value)
	silent! execute "%s/\\V%" . <SID>EscapeRegex(a:variable) . "%/" .  <SID>EscapeRegex(a:value) . "/g"
endfunction

" Performs variable expansion in a template once it was loaded {{{2
"
function <SID>TExpandVars()
	" Date/time values
	let l:day        = strftime("%d")
	let l:year       = strftime("%Y")
	let l:month      = strftime("%m")
	let l:monshort   = strftime("%b")
	let l:monfull    = strftime("%B")
	let l:time       = strftime("%H:%M")
	let l:date       = exists("g:dateformat") ? strftime(g:dateformat) :
				     \ (l:year . "-" . l:month . "-" . l:day)
	let l:fdate      = l:date . " " . l:time
	let l:filen      = expand("%:t:r:r:r")
	let l:filex      = expand("%:e")
	let l:filec      = expand("%:t")
	let l:fdir       = expand("%:p:h:t")
	let l:hostn      = hostname()
	let l:user       = exists("g:username") ? g:username :
				     \ (exists("g:user") ? g:user : $USER)
	let l:email      = exists("g:email") ? g:email : (l:user . "@" . l:hostn)
	let l:guard      = toupper(substitute(l:filec, "[^a-zA-Z0-9]", "_", "g"))
	let l:class      = substitute(l:filen, "\\([a-zA-Z]\\+\\)", "\\u\\1\\e", "g")
	let l:macroclass = toupper(l:class)
	let l:camelclass = substitute(l:class, "_", "", "g")

	" Define license variable
	if executable('licensee') && g:templates_use_licensee
        let l:projectpath = shellescape(expand("%:p:h"))
        if executable('git') && g:templates_detect_git
            silent "!git rev-parse --is-inside-work-tree > /dev/null"
            if v:shell_error == 0
                let l:projectpath = system("git rev-parse --show-toplevel")
            endif
        endif
		" Returns 'None' if the project does not have a license.
		let l:license = matchstr(system("licensee detect " . l:projectpath), '^License:\s*\zs\S\+\ze\%x00')
	endif
	if !exists("l:license") || l:license == "None" || l:license == ""
		if exists("g:license")
			let l:license = g:license
		else
			let l:license = "MIT"
		endif
	endif

	" Finally, perform expansions
	call <SID>TExpand("DAY",   l:day)
	call <SID>TExpand("YEAR",  l:year)
	call <SID>TExpand("DATE",  l:date)
	call <SID>TExpand("TIME",  l:time)
	call <SID>TExpand("USER",  l:user)
	call <SID>TExpand("FDATE", l:fdate)
	call <SID>TExpand("MONTH", l:month)
	call <SID>TExpand("MONTHSHORT", l:monshort)
	call <SID>TExpand("MONTHFULL",  l:monfull)
	call <SID>TExpand("FILE",  l:filen)
	call <SID>TExpand("FFILE", l:filec)
	call <SID>TExpand("FDIR",  l:fdir)
	call <SID>TExpand("EXT",   l:filex)
	call <SID>TExpand("MAIL",  l:email)
	call <SID>TExpand("HOST",  l:hostn)
	call <SID>TExpand("GUARD", l:guard)
	call <SID>TExpand("CLASS", l:class)
	call <SID>TExpand("MACROCLASS", l:macroclass)
	call <SID>TExpand("CAMELCLASS", l:camelclass)
	call <SID>TExpand("LICENSE", l:license)

	" Perform expansions for user-defined variables
	for [l:varname, l:funcname] in g:templates_user_variables
		let l:value = function(funcname)()
		call <SID>TExpand(l:varname, l:value)
	endfor
endfunction

" }}}2

" Puts the cursor either at the first line of the file or in the place of
" the template where the %HERE% string is found, removing %HERE% from the
" template.
"
function <SID>TPutCursor()
	0  " Go to first line before searching
	if search("%HERE%", "W")
		let l:column = col(".")
		let l:lineno = line(".")
		s/%HERE%//
		call cursor(l:lineno, l:column)
	endif
endfunction

" File name utils
"
" Ensures that the given file name is safe to be opened and will not be shell
" expanded
function <SID>NeuterFileName(filename)
	let l:neutered = fnameescape(a:filename)
	call <SID>Debug("Neutered " . a:filename . " to " . l:neutered)
	return l:neutered
endfunction


" Template application. {{{1

" Expand a template in the current buffer, substituting variables and
" putting the cursor at %HERE%.
"
" The a:position parameter determines the mode of operation:
"
"    -1   The template is to be expanded in a new file/buffer.
"     0   The template is to be expanded at the top of the buffer.
"     1   The template is to be expanded at the cursor position.
"
" An empty a:template will use the file name for the current buffer in
" order to determine which template to use. A non-empty string can be
" either be a filename (which gets loaded as a template) or a template
" suffix (i.e. '.c') which will use the template search algorithm.
"
function <SID>TLoad(position, template)
	" A new file is being created.
	if a:position == -1
		if !line2byte(line('$') + 1) == -1
			return
		endif
		let a:position = 0
	endif

	if a:template !=# '' && filereadable(a:template)
	    let l:tFile = a:template
    else
	    let l:height = g:templates_search_height
		let l:file_name = expand('%:p')
	    let l:file_dir = <SID>DirName(l:file_name)
		if a:template !=# ''
			let l:file_name = a:template
		endif
	    let l:tFile = <SID>TFind(l:file_dir, l:file_name, l:height)
    endif
    call <SID>TLoadTemplate(l:tFile, a:position)
endfunction

" Load the given file as a template
function <SID>TLoadTemplate(template, position)
	if a:template != ""
		let l:deleteLastLine = 0
		if line('$') == 1 && getline(1) == ''
			let l:deleteLastLine = 1
		endif

		" Read template file and expand variables in it.
		let l:safeFileName = <SID>NeuterFileName(a:template)
		if a:position == 0 || l:deleteLastLine == 1
			execute "keepalt 0r " . l:safeFileName
		else
			execute "keepalt r " . l:safeFileName
		endif
		call <SID>TExpandVars()

		if l:deleteLastLine == 1
			" Loading a template into an empty buffer leaves an extra blank line at the bottom, delete it
			execute line('$') . "d _"
		endif

		call <SID>TPutCursor()
		setlocal nomodified
	endif
endfunction

" Commands {{{1

" Just calls the above function, pass either a filename or a template
" suffix, as explained before =)
"
fun ListTemplateSuffixes(A,P,L)
  let l:templates = split(globpath(s:default_template_dir, g:templates_global_name_prefix . a:A . "*"), "\n")
  let l:res = []
  for t in templates
    let l:suffix = substitute(t, ".*\\.", "", "")
    call add(l:res, l:suffix)
  endfor

  return l:res
endfun

command -nargs=? -complete=customlist,ListTemplateSuffixes Template call <SID>TLoad(0, "<args>")
command -nargs=? -complete=customlist,ListTemplateSuffixes TemplateHere call <SID>TLoad(1, "<args>")

" Syntax autocommands {{{1
"
" Enable the vim-template syntax for template files
" Usually we'd put this in the ftdetect folder, but because
" g:templates_name_prefix doesn't get defined early enough we have to add the
" template detection from the plugin itself
execute "au BufNewFile,BufRead " . g:templates_name_prefix . "* "
			\. "let b:vim_template_subtype = &filetype | "
			\. "set ft=vim-template"

if !g:templates_no_builtin_templates
	execute "au BufNewFile,BufRead "
				\. s:default_template_dir . "/" . g:templates_global_name_prefix . "* "
				\. "let b:vim_template_subtype = &filetype | "
				\. "set ft=vim-template"
endif

for s:directory in g:templates_directory
	let s:directory = <SID>NormalizePath(expand(s:directory) . '/')
	if isdirectory(s:directory)
		execute "au BufNewFile,BufRead "
					\. s:directory . "/" . g:templates_global_name_prefix . "* "
					\. "let b:vim_template_subtype = &filetype | "
					\. "set ft=vim-template"
	endif
	unlet s:directory
endfor

" vim: fdm=marker
