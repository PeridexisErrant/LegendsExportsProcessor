@ECHO OFF
SETLOCAL

REM - This script is released under the GPL3 to the extent that I (PeridexisErrant) can do so.  It incorporates code written by Parker147 to call his DwarfMapMaker, a script for GIMP.  The GPL3 licence can be found at https://www.gnu.org/licenses/gpl.html
REM "__Process Legends Exports" version 2.4

rem	Changelog:  v2 	initial standalone release, previously as part of PeridexisErrant's Lazy Newb Pack
rem				v2.1	loads of bugfixes
rem				v2.2	few typos, added a module to remove workflow contamination of legends.xml for Legends Viewer.  
rem				v2.3	fixed the loop at start to count down (set region1 as a match for region11 before...) and expanded the range to regions 999:1 inclusive just because
rem				v2.4	moved DwarfMapMaker to the same folder as Dwarf Fortress.exe, so that that dependancy is easy to include in the standalone distribution, standalone now includes said dependancies (trees.bmp, dirt.bmp, mountains.bmp, and DwarfMapMaker.scm)
rem				v2.5	added RealisticMapMaker, a second map processing script; enabled it to be placed in a LNP\Utilities\legendsprocessor folder

ECHO Please wait paitently - this script may take several minutes, or even more for very large or long worlds!

rem If placed as a utility in the LNP, run from the DF folder
IF NOT EXIST "%CD%\Dwarf Fortress.exe" (
	IF EXIST "%CD%\..\..\..\Dwarf Fortress 0.34.11\optipng.exe" 
		CD "..\..\..\Dwarf Fortress 0.34.11"
	)
)

REM set region ID, to use in rest of script, works for 1-99 inclusive, if site maps only sets "unknown region"
FOR /L %%G IN (999,-1,1) DO (
	IF EXIST "%CD%\*region%%G*"  (
		set "region#=region%%G"
		goto got_region
		)
	)
If exist "%CD%\site_map-*.bmp"  (
	set "region#=unknown region"
	goto got_region
	)

:Error
Echo Legends Exports not found
echo.
echo For all parts of this script to work, you need to export the 'p' general information, 'x'ml legends file, and all 'd'etailed maps (hotkey 'a' for all).
echo.
echo This will create .png maps for Isoworld, a compresed archive for Legends Viewer, and if applicable use the Fantasty Map Maker too (see the extras folder)
pause
goto end

:got_region


REM GIMP Map Makers section

rem check if the maps used by the GIMP script are present, and if not skip the whole bit
if not exist "%CD%\*-elw-*.bmp" goto skip_gimp_script
if not exist "%CD%\*-el-*.bmp" goto skip_gimp_script
if not exist "%CD%\*-veg-*.bmp" goto skip_gimp_script
if not exist "%CD%\*-vol-*.bmp" goto skip_gimp_script
if not exist "%CD%\*-tmp-*.bmp" goto skip_gimp_script
if not exist "%CD%\*-bm-*.bmp" goto skip_gimp_script

:: check whether GIMP in installed via the user folder - requires user to have run GIMP before; set script folder
IF NOT EXIST "%userprofile%\.gimp-*" goto skip_gimp_script
for /f "usebackq tokens=*" %%f in (`dir /s /b "%userprofile%\.gimp-*"`) do (
	SET scriptFolder="%%f"
)
rem check for GIMP install location (calls external .cmd file)
for /f "usebackq tokens=*" %%d in (`"GetGimpInstallLocation.cmd" AUTOMODE`) do (
	SET gimpLocation="%%d"
)

:: ensure that the Scheme files are in place; doing this without checks ensures that it's not an earlier version
xcopy "%CD%\SatMapMaker.scm" "%scriptFolder%\scripts\SatMapMaker.scm" /y /q
xcopy "%CD%\DwarfMapMaker.scm" "%scriptFolder%\scripts\DwarfMapMaker.scm" /y /q

rem The following is taken from the DwarfMapMaker script, by Parker147.  It relies on the GIMP script he wrote.  
set "mapName=FantasyMapmaker-%region#%.bmp"

for %%i in (*-elw-*) do set water=%%~fi
for %%i in (*-el-*)  do set elevation=%%~fi
for %%i in (*-veg-*) do set vegetation=%%~fi
for %%i in (*-vol-*) do set volcanism=%%~fi
for %%i in (*-tmp-*) do set temperature=%%~fi
for %%i in (*-bm-*)  do set biome=%%~fi
for %%i in (mountains.bmp)  do set mountains=%%~fi
for %%i in (trees.bmp)  do set trees=%%~fi
for %%i in (dirt.bmp)  do set dirt=%%~fi

set water=%water:\=\\%
set elevation=%elevation:\=\\%
set vegetation=%vegetation:\=\\%
set volcanism=%volcanism:\=\\%
set temperature=%temperature:\=\\%
set biome=%biome:\=\\%
set trees=%trees:\=\\%
set dirt=%dirt:\=\\%
set mountains=%mountains:\=\\%
set outputFile=%outputFile:\=\\%

start /wait "Fantasy Map Maker" %gimpLocation% -d -f -i -b "(create-save \"%water%\" \"%elevation%\" \"%vegetation%\" \"%volcanism%\" \"%temperature%\" \"%biome%\" \"%trees%\" \"%dirt%\" \"%mountains%\" \"%mapName%\")"

rem Now call SatMapMaker, which is built on the previous script

:: v1.2 takes an "atmosphere" variable, which adds a blue shade to the image.  Options are 0, 1, 2.  I've set this to skip user input.  
set atmosphere=0

set "mapName=SatelliteMapmaker_%atmosphere%atmo-%region#%.bmp"

for %%i in (sat_mountains.bmp)  do set mountains=%%~fi
for %%i in (sat_trees.bmp)  do set trees=%%~fi
for %%i in (sat_dirt.bmp)  do set dirt=%%~fi

set trees=%trees:\=\\%
set dirt=%dirt:\=\\%
set mountains=%mountains:\=\\%
set outputFile=%outputFile:\=\\%

start /wait "Realistic Map Maker" %gimpLocation% -d -f -i -b "(create-save-satellite \"%water%\" \"%elevation%\" \"%vegetation%\" \"%volcanism%\" \"%temperature%\" \"%biome%\" \"%trees%\" \"%dirt%\" \"%mountains%\" %atmosphere% \"%mapName%\")"

:skip_gimp_script


rem convert bitmaps to .png
if not exist "%CD%\optipng.exe" (
	echo OptiPNG is missing!  Images not compressed.
	goto no_optipng
	)
rem - The "compress-bitmaps" part, which I edited to bypass the files used by the map maker above
if exist "%CD%\*%region#%*.bmp"  optipng -zc9 -zm9 -zs0 -f0 *%region#%*.bmp
if %ERRORLEVEL% == 0 del *%region#%*.bmp
rem addition to handle site maps: 
if exist "%CD%\site_map-*.bmp"  optipng -zc9 -zm9 -zs0 -f0 site_map-*.bmp
if %ERRORLEVEL% == 0 del site_map-*.bmp

:no_optipng


rem Module to clean legends xml for Legends Viewer, because workflow jobs are stored there and mess up the copy-abandon-export-replace-view trick for midgame legends mode.  Future dfhack version (after r4 for 0.34.11) will strip these from exports, but it's still required now.

set "SOH=""" rem because findstr will take this in a variable but not directly.  There must be a way to represent it in plain text though...
FINDSTR /v /l %SOH% "%CD%\%region#%-legends.xml">"%CD%\%region#%-legends-cleaned.xml"
del "%CD%\%region#%-legends.xml"
rename "%region#%-legends-cleaned.xml" "%region#%-legends.xml"

rem Compress legends with 7z, because the xml is massive
if not exist "%CD%\7z.exe" goto legends_compressed

rem - prefer an archive compatible with "Legends Viewer.exe" ...
If exist "%region#%*-legends.xml" (
	if exist "%region#%*-world_history.txt" (
		if exist "%region#%*-world_sites_and_pops.txt" (
			if exist "world_graphic-%region#%*.*" (
				echo "%region#%-legends.xml">listlegends.txt
				echo "%region#%-world_history.txt">>listlegends.txt
				echo "%region#%-world_sites_and_pops.txt">>listlegends.txt
				echo "world_graphic-%region#%-*.*">>listlegends.txt
				7z.exe a "Legends Archive for %region#%.zip" @listlegends.txt
				DEL "%CD%\listlegends.txt"
				DEL "%CD%\*-world_sites_and_pops.txt"
				DEL "%CD%\*-world_history.txt"
				DEL "%CD%\%region#%-legends*.xml"
				goto legends_compressed
			) else (
				if exist "world_map-%region#%*.*" (
				echo "%region#%-legends.xml">listlegends.txt
				echo "%region#%-world_history.txt">>listlegends.txt
				echo "%region#%-world_sites_and_pops.txt">>listlegends.txt
				echo "world_map-%region#%*.*">>listlegends.txt
				7z.exe a "Legends Archive for %region#%.zip" @listlegends.txt
				DEL "%CD%\listlegends.txt"
				DEL "%CD%\*-world_sites_and_pops.txt"
				DEL "%CD%\*-world_history.txt"
				DEL "%CD%\%region#%-legends*.xml"
				goto legends_compressed
					)
				)
			)
		)
	)
	rem ... but just the xml if that's not possible
If exist "%region#%*-legends.xml" do (
	if not exist "Legends Archive for %region#%.zip" do (
		7z.exe a "%region#%-legends-xml.zip" "%region#%*-legends.xml"
		DEL "%CD%\%region#%-legends*.xml"
		goto legends_compressed
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

:end