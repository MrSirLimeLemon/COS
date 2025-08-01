::local path \\
set "RAW=%~dp0..\.."
for %%A in ("%RAW%") do set "SRC=%%~fA"
::for unix path //
set "SRC_TMP=%SRC%"
set "SRC_TMP=%SRC_TMP:C:=/c%"
set "SRC_TMP=%SRC_TMP:\=/%"
set "SRC_UNIX=%SRC_TMP%/COS/BuildFiles"
::outputs (not .img)
set BUILD=%SRC%\COS\BuildFiles\build
::save name is based on time for floppy
for /f %%t in ('powershell -NoProfile -Command "[int][double]::Parse((Get-Date).ToUniversalTime().Subtract([datetime]'1970-01-01').TotalSeconds)"') do set "unixtime=%%t"
::build requirments
set CFLAGS16=-s -wx -ms -zl -zq
set ASM_FLAGS16=-f obj
::remove old files
del /Q "%BUILD%\*"
for /D %%i in ("%BUILD%\*") do rd /S /Q "%%i"
rem no NASM check due the fact if there isnt nasm than it is pointless to run this bat
::Assemble
nasm -f bin "%SRC%\COS\boot.asm" -o "%BUILD%\boot.bin"
nasm -f obj "%SRC%\COS\kernel.asm" -o "%BUILD%\boot.obj"
::nasm -f bin "%SRC%\kernel.asm" %ASM_FLAGS16% -o "%SRC%\build\kernel.obj"
nasm %ASM_FLAGS16% "%SRC%\Libs\print.asm" -o "%BUILD%\print.obj"
nasm %ASM_FLAGS16% "%SRC%\COS\kernel.asm" -o "%BUILD%\kernel.obj"

IF EXIST "C:\WATCOM\owsetenv.bat" (
CALL C:\WATCOM\owsetenv.bat
:: Compile
wcc "%SRC%\COS\main.c" %CFLAGS16% -fo="%BUILD%\main.obj"
wcc "%SRC%\Libs\stdio.c" %CFLAGS16% -fo="%BUILD%\stdio.obj"

::Link with WLINK
wlink @%SRC%\COS\BuildFiles\linker.lnk

::checks if wsl is installed, due to this having commands that are useful (idk if windows has correct commands Im no expert)
wsl echo "WSL is available" >nul 2>&1
if %errorlevel%==0 (

:: reate a blank floppy image
wsl dd if=/dev/zero of=/mnt%SRC_UNIX%/Floppys/floppy%unixtime%.img bs=512 count=2880
::Format it as FAT12
wsl mkfs.fat -F 12 /mnt%SRC_UNIX%/Floppys/floppy%unixtime%.img
::Write bootloader to sector 0
wsl dd if=/mnt%SRC_UNIX%/build/boot.bin of=/mnt%SRC_UNIX%/Floppys/floppy%unixtime%.img conv=notrunc bs=512 count=1
::Copy kernel.bin as KERNEL.BIN into floppy image
wsl mcopy -i /mnt%SRC_UNIX%/Floppys/floppy%unixtime%.img -m /mnt%SRC_UNIX%/build/kernel.bin ::KERNEL.BIN

:: Show contents (for debugging)
wsl mdir -i /mnt%SRC_UNIX%/Floppys/floppy%unixtime%.img ::
)
)