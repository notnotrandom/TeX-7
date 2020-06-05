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

"***********************************************************************
" General purpose routines
"***********************************************************************

function tex_seven#GetMaster()
python << EOF
try:
  master_file = document.get_master_file(vim.current.buffer)
except TeXSevenError, e:
  echoerr(e)
  master_file = ""
EOF
return pyeval('master_file')
endfunction

function tex_seven#GetOutputFile()
python << EOF
master_output = ""
try:
  master_output = document.get_master_output(vim.current.buffer)
except TeXSevenError, e:
  echoerr(e)
  master_output = ""
EOF
return pyeval('master_output')
endfunction

"***********************************************************************
" Viewing
"***********************************************************************

function tex_seven#ViewDocument()
  echo "Viewing the document...\r"
  python document.view(vim.current.buffer)
endfunction

"***********************************************************************
" Miscellaneous (Omni completion, snippets, headers, bibqueries)
"***********************************************************************

function tex_seven#UpdateHeader()
  python document.update_header(vim.current.buffer)
endfunction

function tex_seven#OmniCompletion(findstart, base)
  if a:findstart
    let pos = pyeval('omni.findstart()')
    return pos
  else
    let compl = pyeval('omni.completions()')
    return compl
  endif
endfunction

function tex_seven#MathCompletion(findstart, base)
  if a:findstart
    let line = getline('.')
    let start = col('.') - 1
    while start > 0 && line[start - 1] != '\'
      if line[start] == ' ' | return -2 | endif
      let start -= 1
    endwhile
    return start
  else
    let compl = pyeval('tex_seven_maths_cache')
    call filter(compl, 'v:val.word =~ "^'.a:base.'"')
    "let res = []
    "for m in compl
    "    if m.word =~ '^'.a:base
    "        call add(res, m)
    "    endif
    "endfor
    return compl
  endif
endfunction

function tex_seven#Bibquery(cword)
python << EOF
try:
  document.bibquery(vim.eval('a:cword'), omni.bibpaths)
except TeXSevenError, e:
  echoerr(e)
EOF
return
endfunction

function tex_seven#Incquery(cword)
python << EOF
try:
  document.incquery(vim.eval('a:cword'), omni.incpaths)
except TeXSevenError, e:
  echoerr(e)
EOF
return
endfunction

function tex_seven#IsLeft(lchar)
  let left = getline('.')[col('.')-2]
  return left == a:lchar ? 1 : 0
endfunction

function tex_seven#ChangeFontStyle(style)
  let str = 'di'
  let is_math = pyeval("int(is_latex_math_environment(vim.current.window))")
  let str .= is_math ? '\math'.a:style : '\text'.a:style
  let str .= "{}\<Left>\<C-R>\""
  return str
endfunction

function tex_seven#SmartInsert(keyword, ...)
" Inserts a LaTeX statement and starts omni completion.  If the
" line already contains the statement and the statement is still
" incomplete, i.e. missing the closing delimiter, only omni
" completion is started.

  let pattern = exists('a:1') ? '\'.a:1.'{' : '\'.a:keyword
  let line = getline('.')
  let pos = col('.')

" There's a beginning of a statement on the left
  if line[:pos] =~ pattern
" Is there closing delimiter on the right and no beginning of a
" new statement

" The closing delimiter is closer than \
    let i = pos-1
    while i < col('$')
      if line[i] == '\'
        break
      elseif line[i] == '}'
        return ""
      endif
      let i = i+1
    endwhile
  endif

  return a:keyword."}\<Esc>ha"
endfunction

" Returns the list of completions to be used when asking the user for an
" environment name, in tex_seven#InsertSnippet.
function! ListEnvCompletions(A,L,P)
" Breaks if dictionary is a list but we only support one dictionary
" at the moment
  if filereadable(&dictionary)
    return join(readfile(&dictionary), "\<nl>")
  else
    return []
  endif
endfunction

" Only for .tex files!
function tex_seven#InsertSnippet()
  let s:envkey = input('Environment: ', '', 'custom,ListEnvCompletions')

  if s:envkey != ""
    python snip = document.insert_snippet(vim.eval('s:envkey'))
    return pyeval('snip')
  else
    return "\<Esc>"
  endif
endfunction

function tex_seven#EnvironmentOperator(mode)
  let pos = pyeval('get_latex_environment(vim.current.window)["range"]')
  if !pos[0] && !pos[1]
    return "\<Esc>"
  endif
  if a:mode == 'inner'
    let pos[0] += 1
    let pos[1] -= 1
  endif
  let delta = pos[1] - pos[0] > 0 ? (pos[1] - pos[0])."j" : ""
  return "\<Esc>:".pos[0]."\<Enter>V".delta."O"
endfunction


"***********************************************************************
" Settings
"***********************************************************************

function tex_seven#AddBuffer()
python << EOF
omni = TeXSevenOmni()
document = TeXSevenDocument(vim.current.buffer)
EOF
endfunction

function tex_seven#SetAutoCmds(config)
  augroup tex_seven
    au BufWritePre *.tex call tex_seven#UpdateHeader()
  augroup END
endfunction

function tex_seven#Reconfigure(config)
python << EOF
try:
  omni.update()
  paths = map(path.basename, omni.bibpaths)
  echomsg("Updated BibTeX databases...using {0}.".format(", ".join(paths)))
  paths = map(path.basename, omni.incpaths)
  echomsg("Updated \include'd files...using {0}.".format(", ".join(paths)))
except TeXSevenError, e:
# It may be not an error. The user may not use BibTeX...
  echomsg("Cannot update BibTeX databases: "+str(e))
EOF
endfunction
