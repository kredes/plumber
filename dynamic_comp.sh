antlr -gt dynamic_plumber.g
dlg -ci parser.dlg scan.c
g++ -o dynamic_plumber dynamic_plumber.c scan.c err.c -I/usr/include/pccts -Wno-write-strings
