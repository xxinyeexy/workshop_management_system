@echo off
echo Adding .gitkeep files to all subfolders...

setlocal enabledelayedexpansion

REM Loop through all subdirectories under lib
for /d /r lib %%d in (*) do (
    REM Skip files, only operate on folders
    if exist "%%d" (
        REM Create .gitkeep if it doesn't exist
        if not exist "%%d\.gitkeep" (
            echo Creating .gitkeep in %%d
            echo. > "%%d\.gitkeep"
        )
    )
)

echo All done.
pause
