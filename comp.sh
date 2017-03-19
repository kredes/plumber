antlr -gt plumber.g
dlg -ci parser.dlg scan.c
g++ -o plumber plumber.c scan.c err.c -I/usr/include/pccts -Wno-write-strings
