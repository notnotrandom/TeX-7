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

if !has('python3')
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

setlocal completeopt=longest,menuone
setlocal fo=tcq
setlocal omnifunc=tex_seven#OmniCompletion
setlocal completefunc=tex_seven#MathCompletion

call tex_seven#AddBuffer()

"***********************************************************************

" Mappings

" Leader

" Save old leader
if exists('g:maplocalleader')
  let s:maplocalleader_saved = g:maplocalleader
endif

let g:maplocalleader = b:tex_seven_config.leader 

" Viewing
noremap <buffer><silent> <LocalLeader>V :call tex_seven#ViewDocument()<CR>

" Misc
noremap <buffer><silent> <LocalLeader>U :call tex_seven#Reconfigure(b:tex_seven_config)<CR>
noremap <buffer><silent> <LocalLeader>Q :copen<CR>

" Go from \ref to \label, or from \cite bib entry preview.
noremap <buffer><silent> gd :call tex_seven#QueryMap()<CR>

" Insert mode mappings
inoremap <buffer> <LocalLeader><LocalLeader> <LocalLeader>
inoremap <buffer> <LocalLeader>M \
inoremap <buffer> <LocalLeader>" ``''<Left><Left>
inoremap <buffer><expr> <LocalLeader>C tex_seven#SmartInsert('\cite{', '\[cC]ite')
inoremap <buffer><expr> <LocalLeader>E tex_seven#SmartInsert('\eqref{')
inoremap <buffer><expr> <LocalLeader>R tex_seven#SmartInsert('\ref{')
inoremap <buffer><expr> <LocalLeader>Z tex_seven#SmartInsert('\includeonly{')

" Greek
inoremap <buffer> <LocalLeader>a \alpha
inoremap <buffer> <LocalLeader>b \beta
inoremap <buffer> <LocalLeader>c \chi
inoremap <buffer> <LocalLeader>d \delta
inoremap <buffer> <LocalLeader>e \varepsilon
inoremap <buffer> <LocalLeader>/e \epsilon
inoremap <buffer> <LocalLeader>f \varphi
inoremap <buffer> <LocalLeader>/f \phi
inoremap <buffer> <LocalLeader>g \gamma
inoremap <buffer> <LocalLeader>h \eta
inoremap <buffer> <LocalLeader>k \kappa
inoremap <buffer> <LocalLeader>l \lambda
inoremap <buffer> <LocalLeader>m \mu
inoremap <buffer> <LocalLeader>n \nu
inoremap <buffer> <LocalLeader>o \omega
inoremap <buffer> <LocalLeader>p \pi
inoremap <buffer> <LocalLeader>q \theta
inoremap <buffer> <LocalLeader>r \rho
inoremap <buffer> <LocalLeader>s \sigma
inoremap <buffer> <LocalLeader>t \tau
inoremap <buffer> <LocalLeader>u \upsilon
inoremap <buffer> <LocalLeader>w \varpi
inoremap <buffer> <LocalLeader>x \xi
inoremap <buffer> <LocalLeader>y \psi
inoremap <buffer> <LocalLeader>z \zeta
inoremap <buffer> <LocalLeader>D \Delta
inoremap <buffer> <LocalLeader>F \Phi
inoremap <buffer> <LocalLeader>G \Gamma
inoremap <buffer> <LocalLeader>L \Lambda
inoremap <buffer> <LocalLeader>O \Omega
inoremap <buffer> <LocalLeader>P \Pi
inoremap <buffer> <LocalLeader>Q \Theta
inoremap <buffer> <LocalLeader>U \Upsilon
inoremap <buffer> <LocalLeader>X \Xi
inoremap <buffer> <LocalLeader>Y \Psi

" Math

" Start mathmode completion
inoremap <buffer> <LocalLeader>\ \setminus
inoremap <buffer> <LocalLeader>½ \sqrt{}<Left>
inoremap <buffer> <LocalLeader>N \nabla
inoremap <buffer> <LocalLeader>S \sum_{}^{}<Esc>2F{a
inoremap <buffer> <LocalLeader>/S \prod_{}^{}<Esc>2F{a
inoremap <buffer> <LocalLeader>V \vec{}<Left>
inoremap <buffer> <LocalLeader>I \int\limits_{}^{}<Esc>2F{a
inoremap <buffer> <LocalLeader>0 \varnothing
inoremap <buffer> <LocalLeader>/0 \emptyset
inoremap <buffer> <LocalLeader>6 \partial
inoremap <buffer> <LocalLeader>i \infty
inoremap <buffer> <LocalLeader>/ \frac{}{}<Esc>2F{a
inoremap <buffer> <LocalLeader>v \vee
inoremap <buffer> <LocalLeader>& \wedge
inoremap <buffer> <LocalLeader>/v \bigvee
inoremap <buffer> <LocalLeader>/& \bigwedge
inoremap <buffer> <LocalLeader>@ \circ
inoremap <buffer> <LocalLeader>* \not
inoremap <buffer> <LocalLeader>! \neq
inoremap <buffer> <LocalLeader>~ \neg
inoremap <buffer> <LocalLeader>= \equiv
inoremap <buffer> <LocalLeader>- \cap
inoremap <buffer> <LocalLeader>+ \cup
inoremap <buffer> <LocalLeader>/- \bigcap
inoremap <buffer> <LocalLeader>/+ \bigcup
if exists('g:tex_seven_config')
      \ && has_key(g:tex_seven_config, 'diamond_tex')
      \ && g:tex_seven_config['diamond_tex'] == '1'
  inoremap <buffer> <LocalLeader>< \leq
  inoremap <buffer> <LocalLeader>> \geq
else
  inoremap <buffer> <LocalLeader>> <><Left>
endif
inoremap <buffer> <LocalLeader>~ \widetilde{}<Left>
inoremap <buffer> <LocalLeader>^ \widehat{}<Left>
inoremap <buffer> <LocalLeader>_ \overline{}<Left>
inoremap <buffer> <LocalLeader>. \cdot<Space>
inoremap <buffer> <LocalLeader><CR> \nonumber\\<CR>

" Enlarged delimiters
inoremap <buffer> <LocalLeader>( \left(\right)<Esc>F(a
inoremap <buffer> <LocalLeader>[ \left[\right]<Esc>F[a
inoremap <buffer> <LocalLeader>{ \left\{ \right\}<Esc>F a

" Neat insertion of various LaTeX constructs by tapping keys
inoremap <buffer><expr> _ tex_seven#IsLeft('_') ? '{}<Left>' : '_'
inoremap <buffer><expr> ^ tex_seven#IsLeft('^') ? '{}<Left>' : '^'
inoremap <buffer><expr> = tex_seven#IsLeft('=') ? '<BS>&=' : '='
inoremap <buffer><expr> ~ tex_seven#IsLeft('~') ? '<BS>\approx' : '~'

" For angle brackets
inoremap <buffer> <LocalLeader>« \langle
inoremap <buffer> <LocalLeader>» \rangle

" Robust inner/outer environment operators
vmap <buffer><expr> ae tex_seven#EnvironmentOperator('outer')
omap <buffer><silent> ae :normal vae<CR>
vmap <buffer><expr> ie tex_seven#EnvironmentOperator('inner')
omap <buffer><silent> ie :normal vie<CR>

" As these are visual mode mappings, they interfere with other usages of
" visual mode, notoriously the snippets plugin. Hence each mapping starts with
" a <Space>: because having a visually selected piece of text, I almost never
" want to enter a space...
" (I don't use <LocalLeader> here because the mappings have two keys. I
" generally avoid the leader for mapping with more than one key (other than
" said leader, of course).)
vmap <buffer><expr> <Space>bf tex_seven#ChangeFontStyle('bf')
vmap <buffer><expr> <Space>it tex_seven#ChangeFontStyle('it')
vmap <buffer><expr> <Space>rm tex_seven#ChangeFontStyle('rm')
vmap <buffer><expr> <Space>sf tex_seven#ChangeFontStyle('sf')
vmap <buffer><expr> <Space>tt tex_seven#ChangeFontStyle('tt')
vmap <buffer>       <Space>up di\text{}<Left><C-R>"

if exists('s:maplocalleader_saved')
  let g:maplocalleader = s:maplocalleader_saved
else
  unlet g:maplocalleader
endif
