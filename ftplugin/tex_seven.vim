" LaTeX filetype plugin
" Languages:    LaTeX
" Maintainer:   Elias Toivanen
" Version:      1.3.13
" Last Change:  
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
"
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
ru ftplugin/tex_seven/tex_seven_common.vim

setlocal completeopt=longest,menuone
setlocal fo=tcq
setlocal omnifunc=tex_seven#OmniCompletion
setlocal completefunc=tex_seven#MathCompletion

call tex_seven#AddBuffer(b:tex_seven_config)
call tex_seven#SetAutoCmds(b:tex_seven_config)

"***********************************************************************

" Mappings

" Leader

" Save old leader
if exists('g:maplocalleader')
    let s:maplocalleader_saved = g:maplocalleader
endif

let g:maplocalleader = b:tex_seven_config.leader 

" Templates
noremap <buffer><silent> <F1> :call tex_seven#InsertSkeleton(b:tex_seven_skeleton.'.xelatex')<CR>
noremap <buffer><silent> <F2> :call tex_seven#InsertSkeleton(b:tex_seven_skeleton.'.pdflatex')<CR>
noremap <buffer><silent> <F3> :call tex_seven#InsertSkeleton(b:tex_seven_skeleton.'.latex')<CR>
noremap <buffer><silent> <F4> :call tex_seven#InsertSkeleton(b:tex_seven_skeleton.'.make')<CR>

" Viewing
noremap <buffer><silent> <LocalLeader>V :call tex_seven#ViewDocument()<CR>

" Compilation
noremap <buffer><silent> <LocalLeader>k :call tex_seven#Compile(0, b:tex_seven_config)<CR>
noremap <buffer><silent> <LocalLeader>K :call tex_seven#Compile(1, b:tex_seven_config)<CR>

" Misc
noremap <buffer><silent> <LocalLeader>U :call tex_seven#Reconfigure(b:tex_seven_config)<CR>
noremap <buffer><silent> <LocalLeader>Q :copen<CR>
noremap <buffer><silent> gd yiB/\\label{<C-R>0}<CR>
noremap <buffer><silent> gb :call tex_seven#Bibquery(expand('<cword>'))<CR>

" Insert mode mappings
inoremap <buffer> <LocalLeader><LocalLeader> <LocalLeader>
inoremap <buffer> <LocalLeader>K 
inoremap <buffer> <LocalLeader>M \
inoremap <buffer><expr> <LocalLeader>B tex_seven#InsertSnippet()
imap <buffer><expr> <LocalLeader>C tex_seven#SmartInsert('\cite{', '\[cC]ite')
imap <buffer><expr> <LocalLeader>E tex_seven#SmartInsert('\eqref{')
imap <buffer><expr> <LocalLeader>R tex_seven#SmartInsert('\ref{')
imap <buffer><expr> <LocalLeader>Z tex_seven#SmartInsert('\includeonly{')

" SyncTeX
if b:tex_seven_config.synctex
    noremap <buffer><silent> <C-LeftMouse> :call tex_seven#ForwardSearch()<CR>
endif

" Greek
inoremap <buffer> <LocalLeader>a \alpha
inoremap <buffer> <LocalLeader>b \beta
inoremap <buffer> <LocalLeader>c \chi
inoremap <buffer> <LocalLeader>d \delta
inoremap <buffer> <LocalLeader>e \epsilon
inoremap <buffer> <LocalLeader>f \phi
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
inoremap <buffer> <LocalLeader>S \sum_{}^{}<Esc>F}i
inoremap <buffer> <LocalLeader>V \vec{}<Left>
inoremap <buffer> <LocalLeader>I \int\limits_{}^{}<Esc>F}i
inoremap <buffer> <LocalLeader>0 \emptyset
inoremap <buffer> <LocalLeader>6 \partial
inoremap <buffer> <LocalLeader>i \infty
inoremap <buffer> <LocalLeader>/ \frac{}{}<Esc>F}i
inoremap <buffer> <LocalLeader>v \vee
inoremap <buffer> <LocalLeader>& \wedge
inoremap <buffer> <LocalLeader>@ \circ
inoremap <buffer> <LocalLeader>* \cdot
inoremap <buffer> <LocalLeader>= \equiv
inoremap <buffer> <LocalLeader>- \bigcap
inoremap <buffer> <LocalLeader>+ \bigcup
inoremap <buffer> <LocalLeader>< \leq
inoremap <buffer> <LocalLeader>> \geq
inoremap <buffer> <LocalLeader>~ \tilde{}<Left>
inoremap <buffer> <LocalLeader>^ \hat{}<Left>
inoremap <buffer> <LocalLeader>_ \bar{}<Left>
inoremap <buffer> <LocalLeader>. \dot{}<Left>
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

" These are problematic when you want to type << or >> (C bitshift, C++ operators) 
inoremap <buffer><expr> < tex_seven#IsLeft('<') ? '<BS>\ll' : '<'
inoremap <buffer><expr> > tex_seven#IsLeft('>') ? '<BS>\gg' : '>'

" Robust inner/outer environment operators
vmap <buffer><expr> ae tex_seven#EnvironmentOperator('outer')
omap <buffer><silent> ae :normal vae<CR>
vmap <buffer><expr> ie tex_seven#EnvironmentOperator('inner')
omap <buffer><silent> ie :normal vie<CR>

if exists('s:maplocalleader_saved')
    let g:maplocalleader = s:maplocalleader_saved
else
    unlet g:maplocalleader
endif
