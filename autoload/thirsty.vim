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

" Main function. Just returns the current prompt value, and runs the
" initializations if they haven't been already
function! thirsty#run() abort "{{{
	" Run init if we haven't already
	if !get(g:, 'thirsty_ran_init')
		call thirsty#_init()
	endif
	return get(g:, 'thirsty_prompt_text', '')
endfunction "}}}

" This function is ran when the 'check' timer expires (the check timer is
" the shorter one that is used to periodically remind the user to drink
" water).
function! thirsty#_prompt_check(timer) abort "{{{
	let g:thirsty_prompt_text = g:thirsty#prompt
endfunction "}}}

" This function is ran when the 'max' timer expires (the max timer is the
" longer one that will force the user to drink to remove the prompt).
function! thirsty#_prompt_force(timer) abort "{{{
	" If the user says they aren't thirsty, don't accept it
	let g:thirsty_force_drink = 1

	" Use a more demanding prompt
	let g:thirsty_prompt_text = g:thirsty#prompt_force

	" Stop the incrimental check timer
	call timer_stop(get(g:, 'thirsty_timer_check'))
endfunction "}}}

function! thirsty#_prompt_blank() abort "{{{
	let g:thirsty_prompt_text = ''
endfunction "}}}

" Start the 'check' timer
function! thirsty#_timer_check() abort "{{{
	call timer_stop(get(g:, 'thirsty_timer_check'))
	let g:thirsty_timer_check = timer_start((g:thirsty#frequency * 1000),
	\ 'thirsty#_prompt_check', {'repeat':0})
endfunction "}}}

" Start the 'max' timer
function! thirsty#_timer_max() abort "{{{
	call timer_stop(get(g:, 'thirsty_timer_max'))

	" If we're reseting the maximum length timer, we should obviously do
	" the same on the periodic check timer
	call thirsty#_timer_check()

	let g:thirsty_force_drink = 0

	let g:thirsty_timer_max = timer_start((g:thirsty#max_time * 1000),
	\ 'thirsty#_prompt_force', {'repeat':0})
endfunction "}}}

" Run initializations. This will set any necessary variables that are
" unset, or that don't meet sanity checks. It will then set the initial
" prompt value based on how long it has been since the user last drank.
function! thirsty#_init() abort "{{{
	" Don't rerun this unless the user manually sets the variable
	" to zero (0)
	if get(g:, 'thirsty_ran_init')
		return
	endif

	" Set Variable Defaults "{{{
	" ============================================================
	" File Variables "{{{
	" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	" The file that stores the Unix epoch timestamp of the last time we
	" drank water
	let g:thirsty#file#last_drink_time = get(g:,
	\ 'thirsty#file#last_drink_time',
	\ fnameescape(resolve(expand(empty("$DRINK_WATER_CONF") ?
	\ $DRINK_WATER_CONF :'~/.water'))))
	"}}}

	" Message Variables "{{{
	" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	" The message that is displayed prompting you to get some water.
	let g:thirsty#prompt = get(g:, 'thirsty#prompt',
	\ 'Drink some water please. :)')

	" The message that is displayed when it has been too long between
	" drinks of water
	let g:thirsty#prompt_force = get(g:, 'thirsty#prompt_force',
	\ 'DRINK WATER NOW! >:(')

	" Positive affirmation displayed for drinking water.
	let g:thirsty#message#drank = get(g:,
	\ 'thirsty#message#drank', 'Thanks for staying hydrated! :)')

	" Admonishment for not drinking frequently enough
	let g:thirsty#message#drink_anyway = get(g:,
	\ 'thirsty#message#drink_anyway',
	\ 'Drink some water anyway! ಠ_ಠ It''s good for you!')

	" Message displayed if the user isn't thirsty, and it hasn't been
	" longer than g:thirsty#max_time since the last drink.
	let g:thirsty#message#not_thirsty = get(g:,
	\ 'thirsty#message#not_thirsty',
	\ 'That''s Ok. Just remember that water is essential. :)')
	"}}}

	" Numeric Variables "{{{
	" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	" Time in seconds between prompting the user to drink some water.
	let g:thirsty#frequency = get(g:, 'thirsty#frequency',
	\ str2nr($WATER_TIME) > 0 ? $WATER_TIME : 1200)

	" Time in seconds before requiring the user to drink some water.
	let g:thirsty#max_time = str2nr(get(g:, 'thirsty#max_time')) >= get(g:,
	\ 'thirsty#frequency') ? get(g:, 'thirsty#max_time') : get(g:,
	\ 'thirsty#frequency')
	"}}}
	"}}}

	if !filereadable(g:thirsty#file#last_drink_time)
		call thirsty#_write_file()
	endif

	" Store current unix time
	let l:now = str2nr(strftime("%s"))

	" Read the file storing our last drink time
	let l:last_drink_time = thirsty#_read_file()

	" The latest time it could be before we require the user to drink some
	" water
	let l:latest_drink_time = l:last_drink_time + get(g:,
	\ 'thirsty#max_time')

	" If it is after l:latest_drink_time, force the user to drink, and give
	" a more demanding message
	if l:now >= l:latest_drink_time "{{{
		call thirsty#_prompt_force(1)
	" Otherwise set g:thirsty#timer_max to the time left until
	" l:latest_drink_time
	else
		let l:time_til_latest_drink = l:latest_drink_time - l:now
		let g:thirsty_timer_max = timer_start((l:time_til_latest_drink *
		\ 1000), 'thirsty#_prompt_force', {'repeat':0})
	endif "}}}

	" If there is more than g:thirsty#frequency seconds left on the max
	" timer, set a check timer
	if get(l:, 'time_til_latest_drink') > get(g:, 'thirsty#frequency') "{{{
		call thirsty#_timer_check()
	endif "}}}

	let g:thirsty_ran_init = 1
endfunction "}}}

function! thirsty#_drank() abort "{{{
	call thirsty#_timer_max()
	call thirsty#_write_file()
	echo g:thirsty#message#drank
	call thirsty#_prompt_blank()
endfunction "}}}

function! thirsty#_not_thirsty() abort "{{{
	if !get(g:, 'thirsty_force_drink') "{{{
		call thirsty#_timer_check()
		call thirsty#_prompt_blank()
		echo g:thirsty#message#not_thirsty
	else
		echohl ErrorMsg | echo g:thirsty#message#drink_anyway | echohl None
	endif "}}}
endfunction "}}}

function! thirsty#_read_file() abort "{{{
	" Read the 'g:thirsty#file#last_drink_time' file as a binary ('b')
	" file, and only get the first line. Because readfile() returns a list
	" we have to get index [0]
	return str2nr(readfile(g:thirsty#file#last_drink_time, 'b', 1)[0])
endfunction "}}}

function! thirsty#_write_file() abort "{{{
	call writefile([strftime("%s")], g:thirsty#file#last_drink_time, "b")
endfunction "}}}

function thirsty#statusline(...) abort "{{{
	let l:end_string_list = []
	if a:0
		call extend(l:end_string_list, ['%#', a:1, '#'])
	endif

	call add(l:end_string_list, thirsty#run())

	if a:0 > 1
		call extend(l:end_string_list, ['%#', a:2, '#'])
	endif
	return join(l:end_string_list, '')
endfunction "}}}

" vim:set filetype=vim:
