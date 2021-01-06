# extremely-simple-language; also known as esl #

This respository contains a compiler and an interpreter, or virtual machine, for an extremely simple language.

_esl_ is, as the name implies, a simple language. There are some things about the language, as described below, that its name does not imply.  
_esl_ was created as an educational opportunity and curiosity scratcher. In other words, you should not use this language. It has no practical purpose or unique merit.  
_esl_ is assembly-like in aesthetics. Implementation details are bound to differ, however.


## Syntax ##

This languages splits text into tokens based off whitespace alone. Semicolons are currently unused.  
Any amount of whitespace is allowed between tokens.  
_esl_ expects files to conform to this pattern:  
`[operation name] [required arguments, each one prepended by whitespace]`  
That's it! Newlines, tabs, and the regular space are all counted as whitespace, so you are free to make your programs as unreadable as you would like.

You can find a list of operations and their arguments in _src/language.zig_. You can also find a list of available registers in that file as well.

## Notes ##

The compiler and interpreter require [zig](https://ziglang.org) to build. It has been tested with zig version 0.7.1. It should work with other versions, though it might require small modifications to keep up with standard library changes.

This compiler and interpreter only work on Linux.
