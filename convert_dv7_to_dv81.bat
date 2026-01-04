@echo off
chcp 65001 >nul

set "INPUT_DIR=input"
set "OUTPUT_DIR=output"
set "TOOLS_DIR=tools"
set "TEMP_DIR=temp"
set "LOG_FILE=logs\log_dv_conversion.txt"

if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
if not exist "logs" mkdir "logs"

echo. >> "%LOG_FILE%"
echo ================================================== >> "%LOG_FILE%"
echo Session : %date% %time% >> "%LOG_FILE%"
echo ================================================== >> "%LOG_FILE%"

for %%F in ("%INPUT_DIR%\*.mkv") do call :process_file "%%F"

echo.
echo ================================================== >> "%LOG_FILE%"
echo Fin session : %date% %time% >> "%LOG_FILE%"
echo ================================================== >> "%LOG_FILE%"
echo.
echo Traitement termine - Verifier dossier output
pause
exit /b

:process_file
setlocal enabledelayedexpansion
set "INPUT_FILE=%~1"
set "BASENAME=%~n1"
set "FILENAME=%~nx1"

echo.
echo ==================================================
echo Fichier : %FILENAME%
echo ==================================================
echo Fichier : %FILENAME% >> "%LOG_FILE%"

set "HEVC_FILE=%TEMP_DIR%\%BASENAME%.hevc"
set "HEVC_INJECT=%TEMP_DIR%\%BASENAME%_dv81.hevc"

echo Analyse Dolby Vision...
"%TOOLS_DIR%\MediaInfo.exe" --Inform="Video;%%HDR_Format%%" "%INPUT_FILE%" > "%TEMP_DIR%\dv_check.txt"

findstr /C:"Dolby Vision" "%TEMP_DIR%\dv_check.txt" >nul
if errorlevel 1 goto :no_dv

"%TOOLS_DIR%\MediaInfo.exe" --Inform="Video;%%HDR_Format_Profile%%" "%INPUT_FILE%" > "%TEMP_DIR%\profile_check.txt"

findstr "dvhe.07" "%TEMP_DIR%\profile_check.txt" >nul
if errorlevel 1 goto :no_dv7

echo DV profil 7.x detecte
echo DV profil 7.x detecte >> "%LOG_FILE%"

:: Detection MEL/FEL - extraction ligne complete HDR format
%TOOLS_DIR%\MediaInfo.exe --Output=Text "%INPUT_FILE%" | findstr /C:"HDR format" > "%TEMP_DIR%\profile_detail.txt"

echo Profil complet :
for /f "usebackq tokens=1* delims=:" %%a in ("%TEMP_DIR%\profile_detail.txt") do (
    if "%%a"=="HDR format                               " (
        echo %%b
        echo HDR format :%%b >> "%LOG_FILE%"
        goto :parse_profile
    )
)

:parse_profile
:: Detection type EL
findstr "dvhe.07.06" "%TEMP_DIR%\profile_detail.txt" >nul
if not errorlevel 1 (
    set "EL_TYPE=MEL"
    set "DOVI_MODE=2"
    echo Type : MEL - Minimum Enhancement Layer - Profile 7.6
    echo Type : MEL - Profile 7.6 >> "%LOG_FILE%"
    goto :continue_conversion
)

findstr "dvhe.07.09" "%TEMP_DIR%\profile_detail.txt" >nul
if not errorlevel 1 (
    set "EL_TYPE=FEL"
    echo.
    echo ================================================== 
    echo ATTENTION : FEL - Full Enhancement Layer detecte
    echo Profile 7.9 - Full Enhancement Layer
    echo ================================================== 
    echo La suppression de l'EL peut entrainer une perte
    echo de qualite visible dans certaines scenes.
    echo.
    echo Choix du mode de conversion :
    echo   [2] Mode 2 - Compatibilite maximale (supprime mapping)
    echo   [5] Mode 5 - Preserve qualite (conserve mapping)
    echo.
    echo Type : FEL - Profile 7.9 >> "%LOG_FILE%"
    set /p "CONFIRM=Continuer ? (2/5/N pour annuler) : "
    if /i "!CONFIRM!"=="N" (
        echo Conversion annulee par l'utilisateur
        echo Conversion annulee - FEL >> "%LOG_FILE%"
        goto :cleanup
    )
    if "!CONFIRM!"=="2" (
        set "DOVI_MODE=2"
        echo Mode 2 selectionne - Compatibilite
        echo Mode 2 selectionne >> "%LOG_FILE%"
        goto :continue_conversion
    )
    if "!CONFIRM!"=="5" (
        set "DOVI_MODE=5"
        echo Mode 5 selectionne - Qualite preservee
        echo Mode 5 selectionne >> "%LOG_FILE%"
        goto :continue_conversion
    )
    echo Choix invalide, annulation
    echo Annule - Choix invalide >> "%LOG_FILE%"
    goto :cleanup
)

set "EL_TYPE=INCONNU"
echo Type EL inconnu, poursuite
echo Type : INCONNU >> "%LOG_FILE%"

:continue_conversion
:: Informations HDR
echo.
echo Collecte informations HDR...
%TOOLS_DIR%\MediaInfo.exe --Inform="Video;%%BitRate/String%%" "%INPUT_FILE%" > "%TEMP_DIR%\bitrate.txt"
%TOOLS_DIR%\MediaInfo.exe --Inform="General;%%FileSize/String%%" "%INPUT_FILE%" > "%TEMP_DIR%\filesize.txt"
%TOOLS_DIR%\MediaInfo.exe --Inform="Video;%%MaxCLL%%" "%INPUT_FILE%" > "%TEMP_DIR%\maxcll.txt"
%TOOLS_DIR%\MediaInfo.exe --Inform="Video;%%MaxFALL%%" "%INPUT_FILE%" > "%TEMP_DIR%\maxfall.txt"
%TOOLS_DIR%\MediaInfo.exe --Inform="Video;%%MasteringDisplay_ColorPrimaries%%" "%INPUT_FILE%" > "%TEMP_DIR%\primaries.txt"

set /p BITRATE_ORIG=<"%TEMP_DIR%\bitrate.txt"
set /p SIZE_ORIG=<"%TEMP_DIR%\filesize.txt"
set /p MAXCLL=<"%TEMP_DIR%\maxcll.txt"
set /p MAXFALL=<"%TEMP_DIR%\maxfall.txt"
set /p PRIMARIES=<"%TEMP_DIR%\primaries.txt"

echo Debit original : !BITRATE_ORIG!
echo Taille originale : !SIZE_ORIG!
echo MaxCLL : !MAXCLL! / MaxFALL : !MAXFALL!
echo Primaires : !PRIMARIES!

echo Debit original : !BITRATE_ORIG! >> "%LOG_FILE%"
echo Taille originale : !SIZE_ORIG! >> "%LOG_FILE%"
echo MaxCLL : !MAXCLL! / MaxFALL : !MAXFALL! >> "%LOG_FILE%"
echo Primaires : !PRIMARIES! >> "%LOG_FILE%"

:: Verifier HDR10+
findstr "HDR10+" "%TEMP_DIR%\dv_check.txt" >nul
if not errorlevel 1 (
    echo HDR10+ : Present
    echo HDR10+ : Present >> "%LOG_FILE%"
) else (
    echo HDR10+ : Absent
    echo HDR10+ : Absent >> "%LOG_FILE%"
)

echo Comptage frames original...
set "TIME_START=%TIME%"
%TOOLS_DIR%\MediaInfo.exe --Inform="Video;%%FrameCount%%" "%INPUT_FILE%" > "%TEMP_DIR%\framecount.txt"
set /p FRAME_ORIG=<"%TEMP_DIR%\framecount.txt"
echo Frames originaux : !FRAME_ORIG!
echo Frames originaux : !FRAME_ORIG! >> "%LOG_FILE%"
echo.

echo Extraction piste video HEVC...
echo Heure debut extraction : %TIME% >> "%LOG_FILE%"
"%TOOLS_DIR%\mkvextract.exe" tracks "%INPUT_FILE%" 0:"%HEVC_FILE%"
if errorlevel 1 goto :error_extract
echo Heure fin extraction : %TIME% >> "%LOG_FILE%"

echo Conversion DV7 vers DV8.1 directement dans le flux HEVC...
echo Mode dovi_tool : !DOVI_MODE! >> "%LOG_FILE%"
echo Heure debut conversion : %TIME% >> "%LOG_FILE%"
"%TOOLS_DIR%\dovi_tool.exe" --mode !DOVI_MODE! convert --discard "%HEVC_FILE%" -o "%HEVC_INJECT%"
if errorlevel 1 goto :error_convert
echo Heure fin conversion : %TIME% >> "%LOG_FILE%"

echo Remux final avec mkvmerge...
echo Heure debut remux : %TIME% >> "%LOG_FILE%"
set "OUTPUT_NAME=%BASENAME%_dv81.mkv"
"%TOOLS_DIR%\mkvmerge.exe" -o "%OUTPUT_DIR%\!OUTPUT_NAME!" "%HEVC_INJECT%" --no-video "%INPUT_FILE%"
if errorlevel 1 goto :error_remux
echo Heure fin remux : %TIME% >> "%LOG_FILE%"

echo Verification framecount...
%TOOLS_DIR%\MediaInfo.exe --Inform="Video;%%FrameCount%%" "%OUTPUT_DIR%\!OUTPUT_NAME!" > "%TEMP_DIR%\framecount_new.txt"
set /p FRAME_NEW=<"%TEMP_DIR%\framecount_new.txt"

%TOOLS_DIR%\MediaInfo.exe --Inform="Video;%%BitRate/String%%" "%OUTPUT_DIR%\!OUTPUT_NAME!" > "%TEMP_DIR%\bitrate_new.txt"
%TOOLS_DIR%\MediaInfo.exe --Inform="General;%%FileSize/String%%" "%OUTPUT_DIR%\!OUTPUT_NAME!" > "%TEMP_DIR%\filesize_new.txt"

set /p BITRATE_NEW=<"%TEMP_DIR%\bitrate_new.txt"
set /p SIZE_NEW=<"%TEMP_DIR%\filesize_new.txt"

echo.
echo Debit final : !BITRATE_NEW!
echo Taille finale : !SIZE_NEW!
echo Debit final : !BITRATE_NEW! >> "%LOG_FILE%"
echo Taille finale : !SIZE_NEW! >> "%LOG_FILE%"

set "TIME_END=%TIME%"
echo Heure debut traitement : !TIME_START! >> "%LOG_FILE%"
echo Heure fin traitement : !TIME_END! >> "%LOG_FILE%"

if "!FRAME_ORIG!"=="!FRAME_NEW!" (
    echo.
    echo ================================================== 
    echo Conversion reussie : !FRAME_ORIG! frames
    echo Fichier de sortie : !OUTPUT_NAME!
    echo ================================================== 
    echo Conversion OK : !FRAME_ORIG! frames >> "%LOG_FILE%"
    echo Fichier de sortie : !OUTPUT_NAME! >> "%LOG_FILE%"
) else (
    echo.
    echo ================================================== 
    echo ERREUR framecount : original=!FRAME_ORIG! nouveau=!FRAME_NEW!
    echo ================================================== 
    echo ERREUR framecount : original=!FRAME_ORIG! nouveau=!FRAME_NEW! >> "%LOG_FILE%"
)
goto :cleanup

:no_dv
echo Pas de Dolby Vision detecte, fichier ignore
echo Ignore : pas de DV >> "%LOG_FILE%"
goto :cleanup

:no_dv7
echo Pas de profil 7.x detecte, fichier ignore
echo Ignore : pas DV profil 7 >> "%LOG_FILE%"
goto :cleanup

:error_extract
echo ERREUR extraction HEVC
echo ERREUR extraction HEVC >> "%LOG_FILE%"
goto :cleanup

:error_convert
echo ERREUR conversion DV7 vers DV8.1
echo ERREUR conversion DV7 vers DV8.1 >> "%LOG_FILE%"
goto :cleanup

:error_remux
echo ERREUR remux final
echo ERREUR remux final >> "%LOG_FILE%"
goto :cleanup

:cleanup
del "%TEMP_DIR%\%BASENAME%.hevc" "%TEMP_DIR%\%BASENAME%_dv81.hevc" >nul 2>&1
del "%TEMP_DIR%\dv_check.txt" "%TEMP_DIR%\profile_check.txt" "%TEMP_DIR%\profile_detail.txt" >nul 2>&1
del "%TEMP_DIR%\bitrate.txt" "%TEMP_DIR%\filesize.txt" "%TEMP_DIR%\maxcll.txt" "%TEMP_DIR%\maxfall.txt" "%TEMP_DIR%\primaries.txt" >nul 2>&1
del "%TEMP_DIR%\framecount.txt" "%TEMP_DIR%\framecount_new.txt" "%TEMP_DIR%\bitrate_new.txt" "%TEMP_DIR%\filesize_new.txt" >nul 2>&1
endlocal
exit /b
