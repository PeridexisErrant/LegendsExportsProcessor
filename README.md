LegendsExportsProcessor
=======================

A set of tools to process the files exported from Dwarf Fortress's Legends mode, and a script to call all of them.  Windows-only for now, as it's a .bat file.  I did make some progress on a Python port, but it's nowhere near feature parity.  

I'm just teaching myself git (along with everything else...) so hopefully this first project won't go too badly wrong.  A stable version is available at http://dffd.wimbli.com/file.php?id=7989.  For the newest version - which *should* be stable, and is definitley enhanced - you can use the 'download as a zip' option on the right, and place the whole unzipped folder in the LNP/utilities folder of the DF Starter pack or in the same folder as the Dwarf Fortress executable.  

This script is released under the GPL3, or as CC-BY-SA-NC at your option.  The GPL3 licence can be found at https://www.gnu.org/licenses/gpl.html

It incorporates code written by Parker147 to call his DwarfMapMaker (a GIMP script), CharonM72 for SatelliteMapMaker (derived from the before), and /u/YukiHyou in general cleanup and assistance.  Thanks!  

----------------------------

General overview of functions:  

1. Establish which region's exports we're working with, by iterating back from 99 and looking from a match.  Display message explaining function of the script if nothing is found.  

2. If GIMP has ever been opened and is installed, call the two map-maker scripts.  The script will find the install location, and if they're not already in place copy the mapmaker scripts to the user's GIMP folder.

3. Call OptiPNG to compress the bitmaps to PNG format.  

4. Call 7zip to compress the legends XML in .zip format.  If all required files are available, an archive compatible with "Legends Viewer" will be created (includes other text history files and a map); otherwise it will just compress the legends XML as they can be 4GB+ and usually get better than 95% compression.

5. Move all output files to a "User Generated Content" folder next to the Dwarf Fortress folder, and delete uninteresting text files.  