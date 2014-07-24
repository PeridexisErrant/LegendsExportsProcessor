@ECHO OFF
SETLOCAL
rem  This script is released under the GPL3, which can be found at can be found at https://www.gnu.org/licenses/gpl.html
rem  Updates are published at https://github.com/PeridexisErrant/LegendsExportsProcessor

echo.
echo This is a script to process files exported from Dwarf Fortress's Legends Mode.  
echo. 
echo It scans the Dwarf Fortress folder for exported files and applies only to the latest region, uses GIMP (if installed) to make photo-style extra maps, calls optiPNG for lossless compression of bitmaps images, calls 7zip to create a legends archive for Legends viewer (or simply compress the legends xml), and moves the processed files to a region-specific User Content folder
echo.
echo Please wait paitently - the process may take several minutes, or even more for very large or long worlds.
echo.
echo -----------------------------
echo.

rem  find DF, which is always in the folder exports go to, in %CD% or as if from LNP utilities folder, and set working location there
IF EXIST "Dwarf Fortress.exe" (
    echo Found exports folder, script is already in folder
) else (
    CD "..\..\..\Dwarf Fortress 0.40.*"
    IF NOT EXIST "Dwarf Fortress.exe" (
        echo Error: Dwarf Fortress Folder not found!
        goto finish
    )
    echo Found exports folder, from utilities folder
)

REM set region ID, to use in rest of script, works for 1-99 inclusive, if site maps only sets "unknown region"
set region#=none
FOR /L %%G IN (99,-1,1) DO (
    IF EXIST "*region%%G*.txt"  (
        set "region#=region%%G"
        echo Script now processing legends exports from !region#!.
    )
)
if "%region#%" == "none" (
    If exist "site_map-*.bmp"  (
        set "region#=unknown region"
        echo Only found site maps from unknown region
    ) else (
        echo.
        Echo Error:  Legends Exports not found!
        echo.
        echo For all parts of this script to work, you need to export the 'p' general information, 'x'ml legends file, and all 'd'etailed maps.  Site maps may also be exported.  
        goto finish
    )
)

rem convert bitmaps to .png
if not exist "%~dp0optipng.exe" (
    echo OptiPNG is missing!  Images not compressed.
) else (
    echo Compressing maps with OptiPNG...
    rem - The "compress-bitmaps" part, which I edited to bypass the source files used by the map maker above
    if exist "*%region#%*.bmp" (
        "%~dp0optipng.exe" -zc9 -zm9 -zs0 -f0 -quiet *%region#%*.bmp
        if %ERRORLEVEL% == 0 (
            del *%region#%*.bmp
            echo Region maps compressed.  
        )
    ) else ( echo No region maps found. )
    rem addition to handle site maps: 
    if exist "site_map-*.bmp" (
        "%~dp0optipng.exe" -zc9 -zm9 -zs0 -f0 -quiet site_map-*.bmp
        if %ERRORLEVEL% == 0 (
            del site_map-*.bmp
            echo Site maps compressed.
        )
    ) else ( echo No site maps found. )
)

rem Compress legends with 7z, because the xml is massive and Legends/World Viewer take these files in a zip
echo Creating compressed legends archive...
set world_map=none
if exist "world_graphic-%region#%*.*" (
    set world_map="world_graphic-%region#%*.*"
) else ( 
    if exist "world_map-%region#%*.*" (
        set world map="world_map-%region#%*.*"
    )
)
if not "world_map" == "none" (
    echo "%region#%-legends.xml">listlegends.txt
    echo "%region#%-world_history.txt">>listlegends.txt
    echo "%region#%-world_sites_and_pops.txt">>listlegends.txt
    echo %world_map%>>listlegends.txt
    "%~dp07z.exe" a "%region#%-legends_archive.zip" @listlegends.txt
    DEL "listlegends.txt"
    DEL "%region#%-world_sites_and_pops.txt"
    DEL "%region#%-world_history.txt"
    DEL "%region#%-legends.xml"
    echo Compressed legends archive created.
)

rem moving all the exports to the User Content folder
if not exist "..\User Generated Content" MD "..\User Generated Content"

rem create a region-specific folder
SET "legendsfolder=..\User Generated Content\%region#% legends and data"
IF NOT EXIST "%legendsfolder%" MD "%legendsfolder%"

rem world maps to a 'world maps' subfolder
for /f %%G in ("png bmp") do (
    if exist "*%region#%*.%%G"  (
        if not exist "%legendsfolder%\world maps" MD "%legendsfolder%\world maps"
        MOVE "*%region#%*.%%G" "%legendsfolder%\world maps"
    )
)
rem move legends to the region folder
if exist "%region#%-legends_archive.zip" move "%region#%-legends-archive.zip" "%legendsfolder%"
if exist "%region#%-world_gen_param.txt" move "%region#%-world_gen_param.txt" "%legendsfolder%"

rem move site maps to a 'site maps' subfolder
if exist "site_map-*.*"  (
    if not exist "%legendsfolder%\site maps" MD "%legendsfolder%\site maps"
    MOVE "site_map-*.*" "%legendsfolder%\site maps"
)

rem delete color keys
if exist "*_color_key.txt" DEL "*_color_key.txt"

echo.
echo.
echo Files moved to User Generated Content folder.
echo.
echo Script complete!
echo.
:finish
timeout /t 60
