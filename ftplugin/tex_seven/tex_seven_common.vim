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

let s:path = fnameescape(expand('<sfile>:h'))
let &dictionary = fnameescape(s:path.'/tex_dictionary.txt')

" Defaults
let b:tex_seven_config = { 
      \    'debug'        : 0,
      \    'disable'      : 0,
      \    'leader'       : '',
      \    'diamond_tex'  : '0',
      \    'verbose'      : 0,
      \    'viewer'       : {'app': 'xdg-open', 'target': 'pdf'},
      \}

" Override values with user preferences
if exists('g:tex_seven_config')
  call extend(b:tex_seven_config, g:tex_seven_config)
endif

" Configure the leader
if b:tex_seven_config.leader == ''
  if exists('g:maplocalleader')
    let b:tex_seven_config.leader = g:maplocalleader
  else
    let b:tex_seven_config.leader = ':'
  endif
endif

" Define Python environment once per Vim session
if !exists('g:tex_seven_did_python') 
  let g:tex_seven_did_python = 1
  let b:tex_seven_config._pypath = s:path
  exe "py3file" fnameescape(b:tex_seven_config._pypath.'/TeXSeven.py')
endif
