setlocal ENABLEDELAYEDEXPANSION
::copy paste of bulid.bat for local folder
::local path \\
set RAW=%~dp0..\..
for %%A in ("%RAW%") do set "SRC=%%~fA"
::for unix path //
set SRC_TMP=%SRC%
set SRC_TMP=%SRC_TMP:C:=/c%
set SRC_TMP=%SRC_TMP:\=/%
set SRC_UNIX=%SRC_TMP%/COS/BuildFiles
::my VM is run with this
set UCRT=C:\MyLibs\_Other\ucrt64.exe
set FileLoc=%SRC%\COS\BuildFiles\Floppys

if EXIST "%UCRT%" (

    if "%~1"=="" (
        rem No argument given - find highest numbered floppy file
        set "highest=0"

        for %%f in ("%FileLoc%\floppy*.img") do (
            set "filename=%%~nxf"
            rem Extract number after "floppy" and before ".img"
            set "num=!filename:floppy=!"
            set "num=!num:.img=!"
    
            rem Check if num is numeric
            for /f "delims=0123456789" %%a in ("!num!") do set "num="

            if defined num (
                if !num! gtr !highest! (
                    set "highest=!num!"
                )
            )
        )

        if defined highest (
            echo Highest number: !highest!
            echo File: floppy!highest!.img
            "%UCRT%" bash -i -c "echo timestamp:!highest!;qemu-system-i386 -drive file=%SRC_UNIX%/Floppys/floppy!highest!.img,format=raw,if=floppy"
        ) else (
            echo No matching floppy*.img files found.
        )
    ) else (
        if EXIST "%FileLoc%\floppy%1.img" (
        "%UCRT%" bash -i -c "echo timestamp-used%1;qemu-system-i386 -drive file=%SRC_UNIX%/Floppys/floppy%1.img,format=raw,if=floppy"
        ) else (
            echo could not find "floppy%1.img"
        )
    )
) else (
echo This is for me to run a img using a VM get your own .bat
)
endlocal
