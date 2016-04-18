" vim-template syntax file
" Language:	vim-template
" Maintainer:	Lyude Paul <thatslyude@gmail.com>
" Last Change:	2014 April 21

if exists("b:current_syntax")
	finish
endif

if b:vim_template_subtype != ""
	execute "runtime! syntax/" . b:vim_template_subtype . ".vim"
	unlet b:current_syntax
endif

syn match vimtemplateVariable "%\%(DAY\|YEAR\|MONTH\|MONTHSHORT\|MONTHFULL\|DATE\|TIME\|FILE\|FFILE\|EXT\|MAIL\|USER\|HOST\|GUARD\|CLASS\|MACROCLASS\|CAMELCLASS\|HERE\)%" containedin=ALL

let b:current_syntax = "vim-template"

hi def link vimtemplateVariable Constant
