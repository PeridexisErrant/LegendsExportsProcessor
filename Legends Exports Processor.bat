@ECHO OFF
SETLOCAL EnableDelayedExpansion
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
cd /D "%~dp0" rem set working directory to script location

IF EXIST "Dwarf Fortress.exe" (
    echo Found exports folder (script is already in folder)
) else (
    for %%v in (1,1,9) do (
        IF EXIST "..\..\..\Dwarf Fortress 0.40.0%%v\Dwarf Fortress.exe" (
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
    IF EXIST "*region%%G*.txt"  (
        set "region#=region%%G"
        echo Script now processing legends exports from %region#%.
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


REM GIMP Map Makers section

rem  check if the maps used by the GIMP script are present, and if not skip the whole bit
for /l %%G in (-elw -el- -veg- -vol- -tmp- -bm-) do (
    if not exist "*%%G*.bmp" goto skip_gimp_script
)

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

rem  Now to call the GIMP scripts...
rem  shared maps and names
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

rem  base images for fantasy map
set "fantasymapName=FantasyMapmaker-%region#%.bmp"
for %%i in ("%~dp0mountains.bmp")  do set mountains=%%~fi
for %%i in ("%~dp0trees.bmp")  do set trees=%%~fi
for %%i in ("%~dp0dirt.bmp")  do set dirt=%%~fi
set trees=%trees:\=\\%
set dirt=%dirt:\=\\%
set mountains=%mountains:\=\\%

rem  base images for satelite map
set atmosphere=0 rem [0|1|2]; intensity of blue shade added to image
set "satellitemapName=SatelliteMapmaker_%atmosphere%atmo-%region#%.bmp"
for %%i in ("%~dp0sat_mountains.bmp")  do set sat_mountains=%%~fi
for %%i in ("%~dp0sat_trees.bmp")  do set sat_trees=%%~fi
for %%i in ("%~dp0sat_dirt.bmp")  do set sat_dirt=%%~fi
set sat_trees=%sat_trees:\=\\%
set sat_dirt=%sat_dirt:\=\\%
set sat_mountains=%sat_mountains:\=\\%
set outputFile=%outputFile:\=\\%

start /wait "Fantasy Map Maker" %gimpLocation% -d -f -i -b "(create-save \"%water%\" \"%elevation%\" \"%vegetation%\" \"%volcanism%\" \"%temperature%\" \"%biome%\" \"%trees%\" \"%dirt%\" \"%mountains%\" \"%fantasymapName%\")"

start /wait "Satellite Map Maker" %gimpLocation% -d -f -i -b "(create-save-satellite \"%water%\" \"%elevation%\" \"%vegetation%\" \"%volcanism%\" \"%temperature%\" \"%biome%\" \"%sat_trees%\" \"%sat_dirt%\" \"%sat_mountains%\" %atmosphere% \"%satellitemapName%\")"

:skip_gimp_script


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
    )
    rem addition to handle site maps: 
    if exist "site_map-*.bmp" (
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
                rem  can use either world map, but prefer biome+elevation over tileset
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
                    echo !world_map!>>listlegends.txt
                    "%~dp07z.exe" a "Legends Archive for %region#%.zip" @listlegends.txt
                    DEL "listlegends.txt"
                    DEL "*-world_sites_and_pops.txt"
                    DEL "*-world_history.txt"
                    DEL "%region#%-legends*.xml"
                    echo Compressed legends archive created.
                )
            )
        ) else (
            "%~dp07z.exe" a "%region#%-legends-xml.zip" "%region#%*-legends.xml"
            DEL "%region#%-legends*.xml"
            echo Legends xml compressed seperately.
        )
    )
)

rem moving all the exports to the User Content folder
if not exist "..\User Generated Content" MD "..\User Generated Content"

rem create a region-specific folder
SET "legendsfolder=..\User Generated Content\%region#% legends and data"
IF NOT EXIST "%legendsfolder%" MD "%legendsfolder%"

rem world maps to a 'world maps' subfolder
for /l %%G in (png bmp) do (
    if exist "*%region#%*.%%G"  (
        if not exist "%legendsfolder%\world maps" MD "%legendsfolder%\world maps"
        MOVE "*%region#%*.%%G" "%legendsfolder%\world maps"
    )
)
rem move legends to the region folder
for /l %%G in ("Legends Archive for %region#%.zip" "%region#%*-world_gen_param.txt" "%region#%-legends-xml.zip" "%region#%-legends.xml" "*-world_sites_and_pops.txt" "*-world_history.txt") do (
    if exist %%G move %%G "%legendsfolder%"
)
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
