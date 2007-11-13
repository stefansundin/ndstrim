@echo off
windres -o resources.o resources.rc
gcc -o ndstrim ndstrim.c resources.o
strip ndstrim.exe
