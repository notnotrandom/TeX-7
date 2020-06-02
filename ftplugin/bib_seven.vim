" LaTeX filetype plugin
" Languages:    LaTeX
" Maintainer:   Óscar Pereira
" Version:      0.1
" License:      GPL

"************************************************************************
"
"                     TeX-7 library: Vim script
"
"    This program is free software: you can redistribute it and/or modify
"    it under the terms of the GNU General Public License as published by
"    the Free Software Foundation, either version 3 of the License, or
"    (at your option) any later version.
"
"    This program is distributed in the hope that it will be useful,
"    but WITHOUT ANY WARRANTY; without even the implied warranty of
"    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"    GNU General Public License for more details.
"
"    You should have received a copy of the GNU General Public License
"    along with this program. If not, see <http://www.gnu.org/licenses/>.
"                    
"    Copyright Elias Toivanen, 2011-2014
"    Copyright Óscar Pereira, 2020
"
"************************************************************************

if !has('python') 
    echoerr "TeX-7: a Vim installation with +python is required"
    finish
endif

" Let the user have the last word
if exists('g:tex_seven_config') && has_key(g:tex_seven_config, 'disable') 
    if g:tex_seven_config.disable 
        redraw
        echomsg("TeX-7: Disabled by user.")
        finish
    endif
endif

" Load Vimscript only once per buffer
if exists('b:init_tex_seven')
    finish
endif
let b:init_tex_seven = 1

"***********************************************************************

runtime ftplugin/tex_seven/tex_seven_common.vim
call tex_seven#InstantiateOmni()

"***********************************************************************

" Save old leader
if exists('g:maplocalleader')
    let s:maplocalleader_saved = g:maplocalleader
endif
let g:maplocalleader = b:tex_seven_config.leader

if exists('s:maplocalleader_saved')
    let g:maplocalleader = s:maplocalleader_saved
else
    unlet g:maplocalleader
endif
