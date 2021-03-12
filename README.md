# gcode-splicer
Used for merging multiple Cura-generated Gcode files for Marlin firmware.

Written in MATLAB for now but it's very slow to run on the GNU Octave implementation.

The only fully functional code at this time is gcode_merger.m which is entirely self-contained. It will perform a simple merge operation on the individual layers and correct the E steps. The code before ;LAYER:0 and after the last layer is discarded on all except the first file selected for merge.
