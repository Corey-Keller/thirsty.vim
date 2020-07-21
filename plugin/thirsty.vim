" =========================================================================
" File: thirsty.vim
" Author: Corey Keller
" Description: Regularly prompt the user to drink some water. Inspired by
" (and designed to be fully backwardly compatible with)
" https://github.com/kalbhor/thirsty
" Repository: https://github.com/Corey-Keller/thirsty.vim
" Last Modified: 2020-03-03
" License: Mozilla Public License 2.0
" This Source Code Form is subject to the terms of the Mozilla Public
" License, v. 2.0. If a copy of the MPL was not distributed with this file,
" You can obtain one at http://mozilla.org/MPL/2.0/.
" =========================================================================

if get(g:, 'loaded_thirsty')
	finish
endif

let g:loaded_thirsty = 1

if !has('timers')
	echoerr 'thirsty.vim won''t work without timers'
	finish
endif

command! Notthirsty call thirsty#_not_thirsty()
command! Drank call thirsty#_drank()

" vim:set filetype=vim:
