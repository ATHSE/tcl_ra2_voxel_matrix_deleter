# tcl_ra2_voxel_matrix_deleter

RA2 voxel (internal) transform matrix deletion tool

C&C Red Alert 2 uses a voxel format distinct from other games, which includes normals (per-pixel UV map) and transformation matrix, along with an unused palette section. The transformation matrix is included in the tailer of each voxel section, and is ignored by RA2, but not by every utility or emulator engine. This tool replaces any matrix with deviations from the default values, with the default values stored in included binary.

TCL seems to have a hard time formatting the correct type of float values, so it was easier to save a "good" one for use as the replacement.

Usage of this script is simple, simply drag-n-drop the voxel onto the batchfile, which will run the script on it. It is recommended that the script package be in the same directory as the voxels. 

There's no plan to add batch operation, as the target market was ChronoDivide, a web-based RA2 remake of sorts, which had rendered voxels with these transformations, often making them appear to float above the ground. In RA2, transforms and animations are stored/loaded within an accompanying .hva file, and none of the voxel tools made for RA2 exposed the internal matrix for editing, even when they incorrectly included them in the final render position. 
