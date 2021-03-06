# -*- coding: utf-8 -*-

# LaTeX filetype plugin
# Languages:    LaTeX
# Maintainer:   Óscar Pereira
# Version:      0.1
# License:      GPL

#************************************************************************
#
#                     TeX-7 library: Vim script
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program. If not, see <http://www.gnu.org/licenses/>.
#                    
#    Copyright Elias Toivanen, 2011-2014
#    Copyright Óscar Pereira, 2020
#
#************************************************************************

# Short summary of the module:
#
# Defines two main objects TeXSevenDocument and TeXSevenOmni that are
# meant to handle editing and completion tasks. Both of these classes
# are singletons. 

# System modules
import vim
import sys
import re
import subprocess
import os
import os.path as path
import logging

from getpass import getuser
from time import strftime
from itertools import groupby
from string import Template

#Local modules
# config = vim.bindeval('b:tex_seven_config')
# TODO: Remove vim.eval() in favor of vim.bindeval() 
# TODO: Separate python module from b:tex_seven_config
# Older Vim's do not have bindeval
config = vim.eval('b:tex_seven_config')
config['disable'] = int(config['disable'])
config['debug'] = int(config['debug'])
config['verbose'] = int(config['verbose'])

sys.path.extend([config['_pypath']])
from tex_seven_symbols import tex_seven_maths_cache
from tex_seven_utils import *

# Control debugging
if config['debug']:
  logging.basicConfig(level=logging.DEBUG, stream=sys.stdout)
else:
  logging.basicConfig(level=logging.ERROR)

# Start of the main module
logging.debug("TeX-7: Entering the Python module.")

messages = {
    'NO_BIBTEX': 'No BibTeX databases present...',
    'INVALID_BIBFILE': 'Invalid BibTeX file: `{0}\'',
    'INVALID_BIBENTRY_TYPE': 'No such BibTeX entry type: `{0}\'',
    'INVALID_BIBENTRY': 'Following BibTeX entry is invalid: {0}', 
    'INVALID_MODELINE': 'Cannot find master file `{0}\'',
    'NO_MODELINE':  'Cannot find master file: no modeline or \documentclass statement',
    'MASTER_NOT_ACTIVE': 'Please have the master file `{0}\' open in Vim.',
    'NO_OUTPUT':  'Output file `{0}\' does not exist.',
    'NO_BIBSTYLE': r'No valid bibliography style found in the document.',
}

class TeXSevenBase(object):
  """Singleton base class for TeX-7."""

  _instance = None
  buffers = {}
  regexp_modeline = re.compile(r'^\s*%\s*mainfile:\s*(\S+)')

  def __new__(self, *args, **kwargs):
    if self._instance is None:
      self._instance = object.__new__(self)
    return self._instance

  def add_buffer(self, vimbuffer):
    """Add vimbuffer to buffers.
    
    Does not override existing entries."""

    logging.debug("TeX-7: Adding `{0}\' to buffer dict.".format(vimbuffer.name))
    bufinfo = {
        'ft' : vim.eval('&ft'),
        'master': "",
        'buffer': vimbuffer,
    }

    # Note that vimbuffer.name contains the full path!
    self.buffers.setdefault(vimbuffer.name, bufinfo)
    return

  def find_master_file(self, vimbuffer, nlines=3):
    """Finds (and returns) the filename (full path) of the master file in a
    LaTeX project.

    Checks if `vimbuffer' contains a \documentclass statement and sets
    the master file to `vimbuffer.name'. Otherwise checks the
    `nlines' first and `nlines' last lines for modeline of the form

    % mainfile: <master_file>

    where <master_file> is the path of the master file relative to
    the current file, e.g. ../main.tex.

    Raises `TeXSevenError' if master cannot be found."""

    # Most often this is the case
    for line in vimbuffer:
      if line.startswith('\\documentclass'):
        return vimbuffer.name

    # Look for modeline
    for line in vimbuffer[:nlines]+vimbuffer[-nlines:]:
      match = TeXSevenBase.regexp_modeline.search(line)
      if match:
        master_file = path.join(path.dirname(vimbuffer.name),
                                match.group(1))
        master_file = path.abspath(master_file)

        if path.exists(master_file):
          return master_file
        else:
          e = messages['INVALID_MODELINE'].format(match.group(1)) 
          raise TeXSevenError(e)

    # Empty buffer, no match or no read access to master 
    raise TeXSevenError(messages['NO_MODELINE'])

  def get_master_file(self, vimbuffer):
    """Returns the filename of the master file."""

    if not self.buffers[vimbuffer.name]['master']:
      master = self.find_master_file(vimbuffer)
      self.buffers[vimbuffer.name]['master'] = master

      # Make sure master knows it's the master
      masterinfo = self.buffers.get(master)
      if masterinfo is not None:
          # masterinfo['master'] = "myself"
          masterinfo['master'] = master

    return self.buffers[vimbuffer.name]['master']

  @staticmethod
  def multi_file(f):
    """Decorates methods that need to know the actual master file in
    a multi-file project.
    
    The decorator swaps passed vim.buffer object to the vim.buffer object
    of the master file.

    When calling a decorated method, `TeXSevenError' has to be caught.

    """
    def new_f(self, vimbuffer, *args, **kwargs):

      master = self.get_master_file(vimbuffer)
      masterbuffer = self.buffers.get(master)
      if masterbuffer is None:
        # Master is not loaded yet
        # NB: badd does not make the master buffer active so 
        # decorated methods are not guaranteed to get read access to
        # the master buffer.
        vim.command('badd {0}'.format(master.replace(' ', '\ ')))
        for b in vim.buffers:
          if b.name == master:
            break
        self.add_buffer(b) 
        self.buffers[master]['master'] = master
        masterbuffer = self.buffers[master]

      return f(self, masterbuffer['buffer'], *args, **kwargs)

    return new_f
# End class TeXSevenBase

class TeXSevenBibTeX(TeXSevenBase):
    """A class to gather BibTeX entries in a list.

    After instantiation, this object tries to figure out
    all BibTeX files in a project by looking at the master file
    containing the \\bibliography{...} statement.

    Alternatively, this behavior may be overridden by providing
    a list of absolute paths to the BibTeX files:

    # Let the object figure out everything
    omni = TeXSevenBibTeX()
    entries = omni.bibentries

    # DIY
    omni = TeXSevenBibTeX()
    omni.bibpaths = [path1, path2,...]
    entries = omni.bibentries

    # Update entries
    omni.update() #or omni.update(my_new_paths)
    
    """

    _bibentries = []
    _bibpaths = set([])

    def _bibparser(self, fname):
      """Opens a file and extracts all BibTeX entries in it."""
      try:
        with open(fname) as f:
            logging.debug("TeX-7: Reading BibTeX entries from `{0}'".format(path.basename(fname)))
            return re.findall('^@\w+ *{\s*([^, ]+) *,', f.read(), re.M)

      except IOError:
        echoerr(messages["INVALID_BIBFILE"].format(fname))
        return []

    @property
    def bibpaths(self):
      return self.get_bibpaths(vim.current.buffer)

    @property
    def bibentries(self):
      return self.get_bibentries()

    # Lazy load
    @TeXSevenBase.multi_file
    def get_bibpaths(self, vimbuffer, update=False):
      """Returns the BibTeX files in a LaTeX project.

      Reads the master file to find out the names of BibTeX files.
      Files in the compilation folder take precedence over files
      located in a TDS tree[1].

      * Requires the program ``kpsewhich''
      that is shipped with the standard TeXLive distribution.

      [1] http://www.tug.org/tds/tds.html#BibTeX
      """

      if not self._bibpaths or update:
        # Find out the bibfiles in use
        master = vimbuffer.name 
        masterbuffer = "\n".join(vimbuffer[:])
        if not masterbuffer:
            e = messages['MASTER_NOT_ACTIVE'].format(path.basename(master))
            raise TeXSevenError(e)
        else:
          match = re.search(r'\\(?:bibliography|addbibresource){([^}]+)}',
                            masterbuffer)
          if not match:
            return [] # The user might not use BiBTeX...

          bibfiles = match.group(1).split(',')
          dirname = path.dirname(master)
          # Find the absolute paths of the bibfiles
          for b in bibfiles:
            if not b.endswith('.bib'):
                b += '.bib'

            # Check if the .bib file is in the compilation folder.
            bibtemp = path.join(dirname, b)
            b = ( bibtemp if path.exists(bibtemp) else b )
            # Get the full path with kspewhich.
            proc = subprocess.Popen(['kpsewhich','-must-exist', b],
                                    stdout=subprocess.PIPE)
            bibpath = proc.communicate()[0].strip(b'\n').decode("utf-8")

            # kpsewhich returns either the full path or an empty string.
            if bibpath:
              self._bibpaths.add(bibpath)
            else:
              raise TeXSevenError(messages["INVALID_BIBFILE"].format(b))

      return list(self._bibpaths)

    def get_bibentries(self):
      """Returns a list of BibTeX entries found in the BibTeX files."""
      if not self._bibentries:
        bibpaths = self.get_bibpaths(vim.current.buffer)
        for b in bibpaths:
          self._bibentries += self._bibparser(b)
      return self._bibentries

    def update(self):
      self._bibentries = []
      self._bibpaths.clear()

      self.get_bibpaths(vim.current.buffer, update=True)

# End class TeXSevenBibTeX

class TeXSevenOmni(TeXSevenBibTeX):
  """Vim's omni completion for a LaTeX document.

  findstart() finds the position where completion should start and
  stores the relevant `keyword'. An appropiate list is then returned
  based on the keyword.
  
  Following items are completed via omni completion

  *   BibTeX entries
  *   Labels for cross-references
  *   Paths of \include'd files, so you can jump from \\ref to \\label, even across files
  *   Font names when using `fontspec' or 'unicode-math'
  *   Picture names when using `graphicx' (EPS, PNG, JPG, PDF)
  
  """
  _incpaths = set([])

  @property
  def incpaths(self):
    return self.get_incpaths(vim.current.buffer)

  def __init__(self):
    self.keyword = None

  # Lazy load
  @TeXSevenBase.multi_file
  def get_incpaths(self, vimbuffer, update=False):
    """Returns the .tex files \included in a LaTeX project.

    Reads the master file to find out the names of .tex files.

    """

    if not self._incpaths or update:
      # Find out the \include'd files
      master = vimbuffer.name
      masterbuffer = "\n".join(vimbuffer[:])
      if not masterbuffer:
          e = messages['MASTER_NOT_ACTIVE'].format(path.basename(master))
          raise TeXSevenError(e)
      else:
        # incfiles will be a list of strings, each containing the string inside
        # the curly brackets: \include{...}
        p = re.compile(r'^\s*\\include{([^}]+)}', re.MULTILINE)
        incfiles = p.findall(masterbuffer)

        # There might not be any \include'd files.
        if len(incfiles) == 0:
          return self._incpaths

        # Find the relative paths of the incfiles, and add them to the _incpaths
        # array. NB: these have to be relative paths, otherwise completion for
        # say, \includeonly, will yield absolute path, which is not what we want.
        for b in incfiles:
          if b.endswith('.tex'):
            raise TeXSevenError("\include'd files cannot contain .tex extension: %s!" % b)

          # To check if the file actually exists, we need to add its extension.
          if path.exists(b + '.tex'):
            self._incpaths.add(b)
          else:
            raise TeXSevenError("Invalid include path: %s!" % b)

    return list(self._incpaths)

  @TeXSevenBase.multi_file
  def _labels(self, vimbuffer,
            pat=re.compile(r'\\label{(?P<label>[^,}]+)}|\\in(?:clude\*?|put){(?P<fname>[^}]+)}')):
    """Labels for references.

    Searches \label{} statements in the master file and in
    \include'd and \input'd files. 
    
    * Thanks to TeX's clunky design, included files cannot contain
    "special" characters such as whitespace.
    """

    # This fails, but replacing 'update' with 'write' works. But commenting it
    # out does not seem to hurt anything...
    # vim.command('update')

    labels = []
    masterbuffer = "\n".join(vimbuffer[:])
    master_folder, basename  = path.split(vimbuffer.name)
    match = pat.findall(masterbuffer)

    if not match:
      if not masterbuffer:
        e = messages['MASTER_NOT_ACTIVE'].format(basename)
        raise TeXSevenError(e)
      logging.debug('TeX-7: Found {0} labels'.format(len(labels)))
      return labels

    labels, included = zip(*match)
    labels = filter(None, labels)
    included = filter(None, included)

    labels = [dict(word=i, menu=basename) for i in labels]
    for fname in included:

      logging.debug("TeX-7: Reading from included file `{0}'...".format(fname))

      if not fname.endswith('.tex'):
        fname += '.tex'

      try:
        with open(path.join(master_folder, fname), 'r') as f:
          inc_labels = re.findall(r'\\label{(?P<label>[^,}]+)}', f.read())
          inc_labels = [dict(word=i, menu=fname) for i in inc_labels]
          labels += inc_labels
      except IOError as e:
        # Do not raise an error because the \include statement might
        # be commented
        logging.debug(str(e).decode('string_escape'))

    logging.debug('TeX-7: Found {0} labels'.format(len(labels)))
    return labels

  def _fonts(self):
    """Installed fonts.

    WARNING: Requires fontconfig.
    """
    proc = subprocess.Popen(['fc-list', ':', 'family'],
                            stdout=subprocess.PIPE)
    output = proc.communicate()[0].splitlines()
    output.sort()
    output = [ i for i,j in groupby(output, lambda x: re.split('[:,]', x)[0]) ]
    return output

  def _pics(self):
    """Picture completion."

    Checks the compilation directory and its subdirectories.
    """
    extensions = [ '.PDF', '.PNG', '.JPG', '.JPEG', '.EPS', 
                  '.pdf', '.png', '.jpg', '.jpeg', '.eps' ]

    p, subdirs, files = next(os.walk(path.dirname(vim.current.buffer.name)))
    pics = [ pic for pic in files if pic[pic.rfind('.'):] in extensions ]
    for d in subdirs:
      files = os.listdir(path.join(p, d))
      pics += [ path.join(d, pic) for pic in files if pic[pic.rfind('.'):] in extensions ] 

    return pics

  # def findstart(self, pat):
  def findstart(self, pat=re.compile(r'\\(\w+)(?:[(].+[)])?(?:[\[].+[]])?{?')):
    """Finds the cursor position where completion starts."""

    row, col = vim.current.window.cursor
    line = vim.current.line[:col]
    start = max((line.rfind('{'),
                 line.rfind(','),
                 line.rfind('\\')))
    try:
      # Starting at a backslash and there is no keyword.
      if '\\' in line[col - 1:col]: 
        self.keyword = ""
      else:
        # There can be a keyword: grab it! 
        self.keyword = pat.findall(line)[-1]
    except IndexError:
      self.keyword = None

    finally:
      if start == -1:
        pass
      elif '}' in line[start:]:
        # Let's not move the cursor too aggresively.
        start = -1
        self.keyword = None
      else:
        start += 1

      return start 

  def completions(self):
    """Selects what type of omni completion should occur."""

    compl = []

    try:
      # Select completion based on keyword
      if self.keyword is not None:
        # Natbib has \Cite.* type of of commands
        if 'cite' in self.keyword or 'Cite' in self.keyword: 
          compl = self.bibentries
        elif 'ref' in self.keyword:
          compl = self._labels(vim.current.buffer)
        elif 'font' in self.keyword or 'setmath' in self.keyword:
          compl = self._fonts()
        elif 'includegraphics' in self.keyword:
          compl = self._pics()
        elif 'includeonly' in self.keyword:
          compl = self.incpaths

    except TeXSevenError as e:
      echoerr("Omni completion failed: "+str(e))
      compl = []

    return compl

  def update(self):
    super(TeXSevenOmni, self).update()

    self.get_incpaths(vim.current.buffer, update=True)

# End class TeXSevenOmni

class TeXSevenDocument(TeXSevenBase):
  """A class to manipulate LaTeX documents in Vim.
  
  TeXSevenDocument can:

  * Compile a LaTeX document updating the BibTeX references as well
  * Launch a viewer application
  * Preview the definition of a BibTeX entry based on its keyword

  Methods that are decorated with TeXSevenBase.multi_file are designed
  to also work in multi-file LaTeX projects."""

  # To match things like \ref{foo} or \eqref{bar}.
  regexp_incqueries = re.compile(r'\\(\S+){(\S+)}')

  # To match things like \cite[ibid.]{foo} or \nocite{bar} or \cite{baz}.
  regexp_bibqueries = re.compile(r'\\(no)?cite.?(\[.+\])?{(\S+)}')

  def __init__(self, vimbuffer):
    TeXSevenBase.add_buffer(self, vimbuffer)
    self.biberrors = []

  @TeXSevenBase.multi_file
  def get_master_output(self, vimbuffer):
    """Get the output file (PDF or DVI) of the LaTeX project"""
    output = vimbuffer.name
    fmt = config['viewer']['target']
    output = "{0}.{1}".format(output[:-len('.tex')], fmt)
    if path.exists(output):
      return output
    else:
      raise TeXSevenError(messages['NO_OUTPUT'].format(output))


  def view(self, vimbuffer):
    """Launches the viewer application.

    The process is started in the background by the system shell.

    WARNING: Requires a *NIX type shell"""

    try:
      output = self.get_master_output(vimbuffer)
      cmd = '{0} "{1}" &> /dev/null &'.format(config['viewer']['app'], output)
      subprocess.call(cmd, shell=True)
    except TeXSevenError as e:
      echoerr("Cannot determine the output file: "+str(e))

  def bibquery(self, cword, paths):
    """Displays the BibTeX entry under cursor in a preview window."""

    try:
      match = TeXSevenDocument.regexp_bibqueries.search(cword)
      if match:
        key = match.group(3)
        echomsg(key)
      else:
        echomsg('Malformed command: {}'.format(cword))
        return

      for fname in paths:
          with open(fname, 'r') as f:
            txt = f.read()
            fname = fname.replace(' ', '\ ')
          # First match wins.
          if re.search("^@\S+"+key, txt, re.M):
            cword = "^@\\\S\\\+"+key
            vim.command("pedit +/{0} {1}".format(key, fname))
            vim.command('windo if &pvw|normal zR|endif') # Unfold
            vim.command("redraw") # Needed after opening a preview window.
            return

    except IOError:
      e = messages["INVALID_BIBFILE"].format(bibfile)
      echoerr("Cannot lookup `{}': {}".format(key, e))

    # No matches and paths was not the empty list
    if paths:
      echomsg(messages["INVALID_BIBENTRY"].format(cword))

  def incquery(self, cword, paths):
    """Goes, in a preview window, to the \\label entry corresponding to the
    \\ref or \\eqref entry under cursor."""

    ref_command = None
    match = TeXSevenDocument.regexp_incqueries.search(cword)
    if match:
      ref_command = match.group(1)
      key = match.group(2)
    else:
      echomsg('Malformed command: \\{}'.format(cword))
      return

    if not (ref_command == 'ref' or ref_command == 'eqref'):
      echomsg("Functionality not available with command \\{}".format(ref_command))
      return

    # Label not found in current file, so search \include'd files.
    for fname in [vim.current.buffer.name] + paths:
      try:
        with open(fname, 'r') as f:
          txt = f.read()
          fname = fname.replace(' ', '\ ')
      except IOError as io:
        echoerr("Cannot lookup label `{}': {}".format(key, str(io)))
        return

      # First match wins (labels are suppose to be unique).
      if re.search("\\label\{"+key+"\}", txt, re.M):
        try:
          vim.command("pedit +/{0} {1}".format(key, fname))
          vim.command('windo if &pvw|normal zR|endif') # Unfold
          vim.command("redraw") # Needed after opening a preview window.
        except vim.error as v:
          echomsg("Vim error {}".format(str(v)))

        return

    # If control reaches here, then no matches were found, either on the
    # current file, or in the \include'd ones.
    echomsg("Could not find label for key: {0}".format(key))

logging.debug("TeX-7: Done with the Python module.")
