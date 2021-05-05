# fiji-syncell_ph_coli

This script is part of the publication "Actuation of synthetic cells with proton gradientsgenerated by light-harvesting E. coli" by Jahnke et al.

It is designed to evaluate .czi files exported from a Zeiss LSM800.
The whole code is divided into two main parts: 1. Selection of the region of interest (ROI), 2. Analysis of the ROI

Part I: In the first part, after the file was saved as .tif file in the same folder of the opened image, the ROI(s) - one(several) spherical spherical object(s) - will be detected automatically, based on the functions "Threshold", "Fill Holes", "Analyze Particles".
This part was optimized manually, as the success of automatically getting the desired threshold is highly sensitive to image quality.
If the proposed ROIs are not okay, one then has the opportunity to delete them and/or add new ones. Hence, it is also possible to just draw the ROIs. The ROIs will be saved in a .zip file then, after pressing the OK button.
After the selection of the ROIs for all(!) open images, the script either transitions to the second part or will be stopped.

Part II: In the second part, the ROIs will be evaluated. Therefor, either the already opened tif file(s) will be evaluated or the script will open the files automatically, in case the subsequent analysis after ROI detection was was selected in the beginning.
Now, for every ROI, its area will be saved, as well as the mean intensity of a circle with a radius r_{circle}=0.5*r_{ROI} and the corresponding standard deviation. Afterwards, the center of the ROI will be determined, in order to select (in this case) 20 lines, that are crossing the boundary orthogonally.
For every line, the maximum intensity will be determined. Per ROI, the averaged maximum and th corresponding standard deviation will be saved. In the end, all results will be saved in a .csv file like this: <filename>.csv.
