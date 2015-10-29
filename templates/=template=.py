#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © %YEAR% %USER% <%MAIL%>
#
# Distributed under terms of the %LICENSE% license.

"""
Usage:
 %FILE% [options]

Options:
    -h --help       Show this help.
    -v --version    Show the version
"""
from docopt import docopt

def main(args):
    print args
    %HERE%

if __name__ == '__main__':
  main(docopt(__doc__, version='%CAMELCLASS% v1.0'))

