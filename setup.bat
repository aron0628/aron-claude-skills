@echo off
REM aron-claude-skills setup script (Windows)
REM Usage: git clone https://github.com/aron0628/aron-claude-skills.git %USERPROFILE%\aron-claude-skills && %USERPROFILE%\aron-claude-skills\setup.bat

setlocal enabledelayedexpansion

set "SKILLS_DIR=%USERPROFILE%\.claude\skills"
set "REPO_DIR=%~dp0"
REM Remove trailing backslash
if "%REPO_DIR:~-1%"=="\" set "REPO_DIR=%REPO_DIR:~0,-1%"

if not exist "%SKILLS_DIR%" mkdir "%SKILLS_DIR%"

set count=0
for /d %%D in ("%REPO_DIR%\*") do (
    set "name=%%~nxD"

    REM Skip hidden dirs (starting with .)
    if "!name:~0,1!"=="." (
        REM skip
    ) else if "!name!"==".git" (
        REM skip
    ) else (
        if exist "%SKILLS_DIR%\!name!" (
            echo   skip: !name! ^(already exists^)
        ) else (
            mklink /J "%SKILLS_DIR%\!name!" "%%D" >nul 2>&1
            if !errorlevel! equ 0 (
                echo   linked: !name!
                set /a count+=1
            ) else (
                echo   error: !name! ^(mklink failed - try running as Administrator^)
            )
        )
    )
)

echo.
echo Done. %count% skill(s) linked to %SKILLS_DIR%

endlocal
pause
