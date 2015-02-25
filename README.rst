=============================
 Simple Vim templates plugin
=============================
:Author: Adrian Perez <aperez@igalia.com>

This is a simple plugin for Vim that will allow you to have a set of
templates for certain file types. It is useful to add boilerplate code
like guards in C/C++ headers, or license disclaimers.


Installation
============

The easiest way to install the plugin is to install it as a bundle.
For example, using Pathogen__:

1. Get and install `pathogen.vim <_Pathogen>`__. You can skip this step
   if you already have it installed.

2. ``cd ~/.vim/bundle``

3. ``git clone git://github.com/aperezdc/vim-template.git``

__ https://github.com/tpope/vim-pathogen

Bundle installs are known to work fine also when using Vundle__. Other
bundle managers are expected to work as well.

__ https://github.com/gmarik/vundle


Updating
========

Manually
--------

In order to update the plugin, go to its bundle directory and use
Git to update it:

1. ``cd ~/.vim/bundle/vim-template``

2. ``git pull``


With Vundle
-----------

Use the ``:BundleUpdate`` command provided by Vundle, for example invoking
Vim like this::

  % vim +BundleUpdate


Configuration
=============

In your vimrc you can put:

* ``let g:templates_plugin_loaded = 1`` to skip loading of this plugin.

* ``let g:templates_no_autocmd = 1`` to disable automatic insertion of
  template in new files.

* ``let g:templates_directory = '/path/to/directory'`` to specify a directory
  from where to search for additional global templates. See `template search
  order`_ below for more details. This can also be a list of paths.

* ``let g:templates_name_prefix = '.vimtemplate.'`` to change the name of the
  template files that are searched.

* ``let g:templates_global_name_prefix = 'template:'`` to change the prefix of the
  templates in the global template directory.

* ``let g:templates_debug = 1`` to have vim-template output debug information

* ``let g:templates_fuzzy_start = 1`` to be able to name templates with
  implicit fuzzy matching at the start of a template name.  For example a
  template file named ``template:.c`` would match ``test.cpp``.

* ``let g:templates_tr_in = [ '.', '_', '?' ]`` and 
  ``let g:templates_tr_out = [ '\.', '.*', '\?' ]`` would allow you to change
  how template names are interpretted as regular expressions for matching file
  names. This might be helpful if hacking on a windows box where ``*`` is not
  allowed in file names. The above configuration, for example, treates
  underscores ``_`` as the typical regex wildcard ``.*``.

* ``let g:templates_no_builtin_templates = 1`` to disable usage of the
  built-in templates. See `template search order`_ below for more details.

* ``let g:templates_user_variables = [[USERVAR, UserFunc]]`` to enable
  user-defined variable expanding. See `User-defined variable expanding`_
  below for details.


Usage
=====

There are a number of options to use a template:


* Create a new file giving it a name. The suffix will be used to determine
  which template to use. E.g::

    $ vim foo.c

* In a buffer, use ``:Template *.foo`` to load the template that would be
  loaded for file matching the pattern ``*.foo``. E.g. from within Vim::

    :Template *.c

Template search order
---------------------

The algorithm to search for templates works like this:

1. A file named ``.vim-template:<pattern>`` in the current directory. If not
   found, goto *(2)*. If there are multiple template files that match a given
   suffix in the *same* directory, the one that is most specific is used.

2. Go up a directory and goto *(1)*, if not possible, goto *(3)*.

3. Try to use the ``=template=<pattern>`` file from the directory specified
   using the ``g:templates_directory`` option (only if the option is defined
   and the directory exists).

3. Try to use the ``=template=<pattern>`` file supplied with the plugin (only
   if ``g:templates_no_builtin_templates`` was not defined).


Variables in templates
----------------------

The following variables will be expanded in templates:

``%DAY%``, ``%YEAR%``, ``%MONTH%``
    Numerical day of the month, year and month.
``%DATE%``
    Date in ``YYYY-mm-dd`` format
``%TIME%``
    Time in ``HH:MM`` format
``%FDATE%``
    Full date (date + time), in ``YYYY-mm-dd HH:MM`` format.
``%FILE%``
    File name, without extension.
``%FFILE%``
    File name, with extension.
``%EXT%``
    File extension.
``%MAIL%``
    Current user's e-mail address. May be overriden by defining ``g:email``.
``%USER%``
    Current logged-in user name. May be overriden by defining ``g:username``.
``%HOST%``
    Host name.
``%GUARD%``
    A string with alphanumeric characters and underscores, suitable for use
    in proprocessor guards for C/C++/Objective-C header files.
``%CLASS%``
    File name, without extension, and the first character of every word is
    capital
``%MACROCLASS%``
    File name, without extension, and all characters are capitals.
``%CAMELCLASS%``
    File name, without extension, the first character of every word is capital,
    and all underscores are removed.
``%HERE%``
    Expands to nothing, but ensures that the cursor will be placed in its
    position after expanding the template.

User-defined variable expanding
-------------------------------

You can set ``g:templates_user_variables`` to expand custom variables. It should
be something like ``[['USERVAR1', 'UserFunc1'], ['USERVAR2', 'UserFunc2']]``,
where ``USERVAR1`` is the variable to be expanded and ``UserFunc1`` is the name of
the function that returns the result. The function should take no arguments and
return the string after expansion.

Example:::

    let g:templates_user_variables = [['FULLPATH', 'GetFullPath']]
    function GetFullPath()
        return expand('%:p')
    endfunction

And each occurrence of ``%FULLPATH%`` in template will be replaced with the full
path of current file.

