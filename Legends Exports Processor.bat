@ECHO OFF
SETLOCAL
:: This script is released under the GPL3, which can be found at can be found at https://www.gnu.org/licenses/gpl.html
:: Updates are published at https://github.com/PeridexisErrant/LegendsExportsProcessor

echo.
echo This is a script to process files exported from Dwarf Fortress's Legends Mode.  
echo. 
echo It scans the Dwarf Fortress folder for exported files and applies only to the latest region, uses GIMP (if installed) to make photo-style extra maps, calls optiPNG for lossless compression of bitmaps images, calls 7zip to create a legends archive for Legends viewer (or simply compress the legends xml), and moves the processed files to a region-specific User Content folder
echo.
echo Please wait paitently - the process may take several minutes, or even more for very large or long worlds.
echo.
echo -----------------------------
echo.

:: find DF, which is always in the folder exports go to, in %CD% or as if from LNP utilities folder, and set working location there
cd /D "%~dp0" rem set working directory to script location

IF EXIST "%CD%\Dwarf Fortress.exe" (
    echo Found exports folder (script is already in folder)
) else (
    for %%v in (1,1,9) do (
        IF EXIST "%CD%\..\..\..\Dwarf Fortress 0.40.0%%v\Dwarf Fortress.exe" (
            CD "..\..\..\Dwarf Fortress 0.40.0%%v"
            IF NOT EXIST "Dwarf Fortress.exe" (
                echo Error: Dwarf Fortress Folder not found!
                goto finish
            )
            echo Found exports folder (from utilities folder)
        )
    )
)

REM set region ID, to use in rest of script, works for 1-99 inclusive, if site maps only sets "unknown region"
set region#=none
FOR /L %%G IN (99,-1,1) DO (
    IF EXIST "%CD%\*region%%G*.txt"  (
        set "region#=region%%G"
        echo Script now processing legends exports from %region#%.
    )
)
if "%region#%" == "none" (
    If exist "%CD%\site_map-*.bmp"  (
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


REM GIMP Map Makers section

:: check if the maps used by the GIMP script are present, and if not skip the whole bit
if not exist "%CD%\*-elw-*.bmp" goto skip_gimp_script
if not exist "%CD%\*-el-*.bmp" goto skip_gimp_script
if not exist "%CD%\*-veg-*.bmp" goto skip_gimp_script
if not exist "%CD%\*-vol-*.bmp" goto skip_gimp_script
if not exist "%CD%\*-tmp-*.bmp" goto skip_gimp_script
if not exist "%CD%\*-bm-*.bmp" goto skip_gimp_script

rem check whether GIMP in installed via the user folder - requires user to have run GIMP before; set script folder
IF NOT EXIST "%userprofile%\.gimp-*" goto skip_gimp_script
for /f "usebackq tokens=*" %%f in (`dir /s /b "%userprofile%\.gimp-*"`) do (
    SET scriptFolder="%%f"
)
rem check for GIMP install location (calls external .cmd file)
for /f "usebackq tokens=*" %%d in (`"%~dp0GetGimpInstallLocation.cmd" AUTOMODE`) do (
    SET gimpLocation="%%d"
)

rem ensure that the Scheme files are in place, the switches: overwrite without notice, quiet mode, only overwrite if more recent
xcopy "%~dp0*.scm" "%scriptFolder%\scripts\" /y /q /d

:: Now to call the GIMP scripts...
:: shared maps and names
for %%i in (*-elw-*) do set water=%%~fi
for %%i in (*-el-*)  do set elevation=%%~fi
for %%i in (*-veg-*) do set vegetation=%%~fi
for %%i in (*-vol-*) do set volcanism=%%~fi
for %%i in (*-tmp-*) do set temperature=%%~fi
for %%i in (*-bm-*)  do set biome=%%~fi
set water=%water:\=\\%
set elevation=%elevation:\=\\%
set vegetation=%vegetation:\=\\%
set volcanism=%volcanism:\=\\%
set temperature=%temperature:\=\\%
set biome=%biome:\=\\%
set outputFile=%outputFile:\=\\%

:: base images for fantasy map
set "fantasymapName=FantasyMapmaker-%region#%.bmp"
for %%i in ("%~dp0mountains.bmp")  do set mountains=%%~fi
for %%i in ("%~dp0trees.bmp")  do set trees=%%~fi
for %%i in ("%~dp0dirt.bmp")  do set dirt=%%~fi
set trees=%trees:\=\\%
set dirt=%dirt:\=\\%
set mountains=%mountains:\=\\%

:: base images for satelite map
set "satellitemapName=SatelliteMapmaker_%atmosphere%atmo-%region#%.bmp"
for %%i in ("%~dp0sat_mountains.bmp")  do set sat_mountains=%%~fi
for %%i in ("%~dp0sat_trees.bmp")  do set sat_trees=%%~fi
for %%i in ("%~dp0sat_dirt.bmp")  do set sat_dirt=%%~fi
set sat_trees=%sat_trees:\=\\%
set sat_dirt=%sat_dirt:\=\\%
set sat_mountains=%sat_mountains:\=\\%
set outputFile=%outputFile:\=\\%
set atmosphere=0 rem [0|1|2]; intensity of blue shade added to image

start /wait "Fantasy Map Maker" %gimpLocation% -d -f -i -b "(create-save \"%water%\" \"%elevation%\" \"%vegetation%\" \"%volcanism%\" \"%temperature%\" \"%biome%\" \"%trees%\" \"%dirt%\" \"%mountains%\" \"%fantasymapName%\")"

start /wait "Satellite Map Maker" %gimpLocation% -d -f -i -b "(create-save-satellite \"%water%\" \"%elevation%\" \"%vegetation%\" \"%volcanism%\" \"%temperature%\" \"%biome%\" \"%sat_trees%\" \"%sat_dirt%\" \"%sat_mountains%\" %atmosphere% \"%satellitemapName%\")"

:skip_gimp_script


rem convert bitmaps to .png
if not exist "%~dp0optipng.exe" (
    echo OptiPNG is missing!  Images not compressed.
) else (
    echo Compressing maps with OptiPNG...
    rem - The "compress-bitmaps" part, which I edited to bypass the source files used by the map maker above
    if exist "%CD%\*%region#%*.bmp" (
        "%~dp0optipng.exe" -zc9 -zm9 -zs0 -f0 -quiet *%region#%*.bmp
        if %ERRORLEVEL% == 0 (
            del *%region#%*.bmp
            echo Region maps compressed.  
        )
    )
    rem addition to handle site maps: 
    if exist "%CD%\site_map-*.bmp" (
        "%~dp0optipng.exe" -zc9 -zm9 -zs0 -f0 -quiet site_map-*.bmp
        if %ERRORLEVEL% == 0 (
            del site_map-*.bmp
            echo Site maps compressed.
        )
    )
)

rem Compress legends with 7z, because the xml is massive
if not exist "%~dp07z.exe" (
    echo 7zip is missing!  Legends not compressed.
) else (
    echo Creating compressed legends archive...
    rem - prefer an archive compatible with "Legends Viewer.exe" ...
    If exist "%region#%*-legends.xml" (
        if exist "%region#%*-world_history.txt" (
            if exist "%region#%*-world_sites_and_pops.txt" (
                :: can use either world map, but prefer biome+elevation over tileset
                set world_map=none
                if exist "world_graphic-%region#%*.*" (
                    set world_map="world_graphic-%region#%*.*"
                ) else (
                if exist "world_map-%region#%*.*" (
                    set world map="world_map-%region#%*.*"
                )
                if not "world_map" == "none" (
                    echo "%region#%-legends.xml">listlegends.txt
                    echo "%region#%-world_history.txt">>listlegends.txt
                    echo "%region#%-world_sites_and_pops.txt">>listlegends.txt
                    echo %world_map%>>listlegends.txt
                    "%~dp07z.exe" a "Legends Archive for %region#%.zip" @listlegends.txt
                    DEL "%CD%\listlegends.txt"
                    DEL "%CD%\*-world_sites_and_pops.txt"
                    DEL "%CD%\*-world_history.txt"
                    DEL "%CD%\%region#%-legends*.xml"
                    echo Compressed legends archive created.
                    goto legends_compressed
                )
            )
        ) else (
            "%~dp07z.exe" a "%region#%-legends-xml.zip" "%region#%*-legends.xml"
            DEL "%CD%\%region#%-legends*.xml"
            echo Legends xml compressed seperately.
        )
    )
)

:legends_compressed

rem moving all the exports to the User Content folder

if not exist "%CD%\..\User Generated Content" MD "%CD%\..\User Generated Content"

rem create a region-specific folder
SET "legendsfolder=%CD%\..\User Generated Content\%region#% legends and data"
IF NOT EXIST "%legendsfolder%" MD "%legendsfolder%"

rem world maps to a 'world maps' subfolder
if exist "%CD%\*%region#%*.png"  (
    if not exist "%legendsfolder%\world maps" MD "%legendsfolder%\world maps"
    MOVE "%CD%\*%region#%*.png" "%legendsfolder%\world maps"
)
if exist "%CD%\*%region#%*.bmp"  (
    if not exist "%legendsfolder%\world maps" MD "%legendsfolder%\world maps"
    MOVE "%CD%\*%region#%*.bmp" "%legendsfolder%\world maps"
)

rem move legends to the region folder
if exist "%CD%\Legends Archive for %region#%.zip" MOVE "%CD%\Legends Archive for %region#%.zip" "%legendsfolder%"
if exist "%CD%\%region#%*-world_gen_param.txt" MOVE "%CD%\%region#%*-world_gen_param.txt" "%legendsfolder%"
rem ... and if a previous part of the script didn't work properly:
if exist "%CD%\%region#%-legends-xml.zip" MOVE "%CD%\%region#%-legends-xml.zip" "%legendsfolder%"
if exist "%CD%\%region#%-legends.xml" MOVE "%CD%\%region#%-legends.xml" "%legendsfolder%"
if exist "%CD%\*-world_sites_and_pops.txt" MOVE "%CD%\*-world_sites_and_pops.txt" "%legendsfolder%"
if exist "%CD%\*-world_history.txt" MOVE "%CD%\*-world_history.txt" "%legendsfolder%"

rem move site maps to a 'site maps' subfolder
if exist "%CD%\site_map-*.*"  (
    if not exist "%legendsfolder%\site maps" MD "%legendsfolder%\site maps"
    MOVE "%CD%\site_map-*.*" "%legendsfolder%\site maps"
    )

rem delete color keys
if exist "%CD%\*_color_key.txt" DEL "%CD%\*_color_key.txt"

rem reporting completion - 'move' output is not particularly legible (change to xcopy/echo/del?)
echo.
echo.
echo Files moved to User Generated Content folder.
echo.
echo Script complete!

:finish
timeout /t 60
