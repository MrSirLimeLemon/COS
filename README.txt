currently does NOTHING only says "hello" from boot
Libs just has non important code that'll be resued



Run.bat wont work nor BuildRun.bat if you have a VM that uses .imgs you could easily alter the Run.bat to work
it takes a value and uses /Floppys/floppy%1.img, if no arg it takes the largest value in floppys floppy#.img

Build.bat needs NASM to make .objs, needs WATCOM to compile, needs wsl to make .img, if you dont have NASM nothing will happen, if you dont have WATCOM only NASM will work, if you dont have wsl only NASM/WATCOM will work


License: NONE, do as you please
idk if I could coptright it as im following a tutorial
