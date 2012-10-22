Animals
=======

This is Cat's Eye Technologies' distribution of the classic computer
game of Animals, which demonstrates an "expert system".  This version
is written in Erlang.

Description
-----------

This game stores a 'knowledge tree' about the animals it knows in a
nested tuple structure.  This is mainly to demonstrate how one can work
with binary trees as Erlang terms.  A more serious implementation would
probably use a real database system, such as Mnesia.

License
-------

This work is in the public domain.  See the file `UNLICENSE` for more
information.

Running
-------

To build the `animals` module, run the script `make.sh` from the root
directory of the distribution.

After the module has been built, the game can be played by running the
script `animals` in the `bin` directory.  This script can be run from
anywhere; it knows to locate the module and the data files in the
distribution directory.
