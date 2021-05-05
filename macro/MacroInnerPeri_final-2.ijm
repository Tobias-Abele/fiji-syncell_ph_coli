//////////////////
// This script is designed to evaluate .czi files exported from a Zeiss LSM800.
// The whole code is divided into two main parts: 1. Selection of the region of interest (ROI), 2. Analysis of the ROI
//////
// Part I: In the first part, after the file was saved as .tif file in the same folder of the opened image, the ROI(s) - one(several) spherical spherical object(s) - will be detected automatically, based on the functions "Threshold", "Fill Holes", "Analyze Particles".
// This part was optimized manually, as the success of automatically getting the desired threshold is highly sensitive to image quality.
// If the proposed ROIs are not okay, one then has the opportunity to delete them and/or add new ones. Hence, it is also possible to just draw the ROIs. The ROIs will be saved in a .zip file then, after pressing the OK button.
// After the selection of the ROIs for all(!) open images, the script either transitions to the second part or will be stopped.
//////
// Part II: In the second part, the ROIs will be evaluated. Therefor, either the already opened tif file(s) will be evaluated or the script will open the files automatically, in case the subsequent analysis after ROI detection was was selected in the beginning.
// Now, for every ROI, its area will be saved, as well as the mean intensity of a circle with a radius r_{circle}=0.5*r_{ROI} and the corresponding standard deviation. Afterwards, the center of the ROI will be determined, in order to select (in this case) 20 lines, that are crossing the boundary orthogonally.
// For every line, the maximum intensity will be determined. Per ROI, the averaged maximum and th corresponding standard deviation will be saved. In the end, all results will be saved in a .csv file like this: <filename>.csv.


run("Clear Results");
imagenumber=nImages;
filearray=newArray();

// Building up GUI
Dialog.create("Welcome");
Dialog.addMessage("Please select whether you would like to select the ROIs and or analyze them.\nTick the corresponding box");
Dialog.addCheckbox("ROI Selection", false);
Dialog.addCheckbox("Analysis", false);
Dialog.show()
selection = Dialog.getCheckbox();
analysis = Dialog.getCheckbox();

//////////////////
// PART I: Selection of the ROIs for every image
if (selection==true) {
for (i = 0; i < imagenumber; i++) { //loop over all images currently open
// Save image as .tif file at location of the opened image
title=getTitle();
dir=getDirectory("image");
saveAs("Tiff", dir+replace(title, ".czi", "")+".tif");

// The channel used for the detection of the ROIs was the first one (hence "Stack.setChannel(1);) in our case and might change, if the macro is used for other types of images.
Stack.setChannel(1);
title=getTitle();
dir=getDirectory("image");
filearray=Array.concat(filearray,dir+title);
selectWindow(title);
// The first channel will be used to create a binary mask for the detection of the ROI as required by the "Analyze Particles" function.
run("Duplicate...", "title=ImageForMaskForROISelection duplicate channels=1");
selectWindow("ImageForMaskForROISelection");
// The following part highly depends on the images to be analyzed, in our experience this needs to be adjusted for other types of images. Helpful was the recording function of FIJI, while playing around with different filters and thresholding algorithms!
setAutoThreshold("Moments dark");
run("Convert to Mask");
run("Fill Holes");
run("Watershed");
run("Outline");
run("Fill Holes");
run("Watershed");
// The particles will be analyzed now and converted into a cirular ROI. The size range and circularity were chosen according to manual evaluation of a sample image and probably need to be adjusted for the evaluation of different objects to be analyzed.
run("Analyze Particles...", "size=600-Infinity circularity=0.70-1.00 display exclude clear include add in_situ");
roiManager("deselect");
count=roiManager("count");
for (a = 0; a < count; a++) {
	roiManager("select", 0);
	run("Fit Circle");
	roiManager("add");
	roiManager("select", 0);
	roiManager("delete");
	roiManager("show none");
}

// Now, the ROIs will be shown and can be adjusted, deleted or new ones can be added now. Important: Do not close the window, just put it at the side, adjust/create/delete the ROIs and press OK then.
// Afterwards, the ROIs will be saved like this: <filename>ROI.zip.
selectWindow(title);
Stack.setChannel(1);
run("Enhance Contrast", "saturated=0.35");
roiManager("show all");
selectWindow("ROI Manager");
waitForUser("Are those ROIS fine? Otherwise delete them or add new ones in the ROI Manager now. \n \nPress the OK button afterwards");
roiManager("deselect");
roiManager("Save", dir+replace(title, ".tif", "") + "ROI.zip" );

//Closing everything again, in order to maybe continue with the next image
selectWindow(title);
run("Close");
selectWindow("ImageForMaskForROISelection");
run("Close");
selectWindow("ROI Manager");
run("Close");
};
};
// End of part I, depending on the decision in the beginning the script will continue now with the analysis or stop or start with the analysis
//////////////////


//////////////////
// PART II: Analysis of the ROIs
if (analysis==true) {
if (selection==true) {
//In this case the file directories were saved in the beginning and simply can be reopened again.
//Otherwise the .tif files(!) need to be opened before the macro is started.
	for (l = 0; l < imagenumber; l++) { // Opens all images in case their ROIs were selected in the same run as this analysis
	open(filearray[l]);
	};
};
if (selection==false) {
	filearray=newArray();
}

// Beginning of the Analysis
imagenumber=nImages;
for (n = 0; n < imagenumber; n++) { //loop over all images that are open at the moment
run("Clear Results");
title=getTitle();
dir=getDirectory("image");
if (selection==false) {
	filearray=Array.concat(filearray,dir+title);
}

// The channel to be analyzed was the first channel in our case and might differ for different experiments
Stack.setChannel(1);
run("Enhance Contrast", "saturated=0.35");
Stack.getDimensions(width, height, channels, slices, frames);
scalingfactor=0.5; // This scaling factor will determine the radius of the area, where the mean intensity will be extracted from!
inverse_factor=1/scalingfactor;
roiManager("Open", dir+replace(title, ".tif", "") + "ROI.zip" );
counter2=roiManager("count");

// Now, the iterations/lines over all ROIs will be performed, after the eman intensity of the inner circle is determined.
	for (o = 0; o < counter2; o++) {	
		Stack.setChannel(1);
		selectWindow(title);
		roiManager("Open", dir+replace(title, ".tif", "") + "ROI.zip" );
		roiManager("Select", o);
		getStatistics(area, mean, min, max, std, histogram); // Extracting the area of the ROI
		area1=area;
		roiManager("Select", o);
		run("Scale... ", "x=scalingfactor y=scalingfactor centered"); // Scaling down the ROI in order to assure that the circle is inside the spherical object to be analyzed
		roiManager("update");
		getStatistics(area, mean, min, max, std, histogram); // Analysis of the mean intensity
		circlemean=mean;
		circlemeanstd=std;	
		Stack.setChannel(1);
		run("Scale... ", "x=inverse_factor y=inverse_factor centered"); // Scaling back of the ROI
		roiManager("update");
		
// Now, the boundaries of the ROI will be used to determine the center of the ROI and hance the center of the lines that will cross the ROI
		Roi.getBounds(x, y, width, height);
		middlex = x+width/2;
		middley = y+height/2;
		diameter = (width+height)/2;
		roiManager("deselect");
		roiManager("delete");
		
// The lines will be drawn now and their maximum averaged per ROI.
		lines = 20; // Number of lines to be drawn -> Mainly determines the execution time of the code
		maxivalues=newArray();
		for (p = 0; p < lines; p++) {
			run("Line Width...", "line=6"); // A bigger line helps to get a better signal-to-noise ratio for the intensity profiles across the lines
			roiManager("show all with labels");
			makeLine(middlex+1.2*0.5*diameter*cos(p/(lines*0.5)*PI), middley+1.2*0.5*diameter*sin(p/(lines*0.5)*PI), middlex+0.1*0.5*diameter*cos(p/(lines*0.5)*PI), middley+0.1*0.5*diameter*sin(p/(lines*0.5)*PI));
			roiManager("add");
			ypoints=getProfile();
			y1points=getProfile();
			xpoints=Array.getSequence(ypoints.length);
			Array.sort(y1points);
			Array.getStatistics(y1points, min, max, mean, stdDev);
			maxi=max;
			maxivalues=Array.concat(maxivalues,maxi);
			};
		Array.getStatistics(maxivalues, min, max, mean, stdDev); // Averaging the maximum values per ROI -> 1 maximum value per ROI
		maximean1=mean;
		Array.getStatistics(maxivalues, min, max, mean, stdDev);
		maxistd1=stdDev;
		
// Every measurement will be arranged/organized in the following block, starting with the area of the original ROI, followed by the averaged maximum value of the peripheral ring, the corresponding standard deviation, the mean intensity of the inner circle, the corresponding standard deviation and the ration between the maximum value and the mean intensity.
		setResult("Area", o, area);
		setResult("Max", o, maximean1);
		setResult("MaxStd", o, maxistd1);
		setResult("CircleIntensMean", o, circlemean);
		setResult("CircleIntensMeanStd", o, circlemeanstd);
		setResult("Max/Middle Ratio", o, maximean1/circlemean);
		updateResults();
		selectWindow("ROI Manager");
		run("Close");
};
updateResults();

// Now, the results wil be saved as a .csv file according to the following scheme: <filename>.csv in the same folder as the original image-file
saveAs("Results", replace(filearray[n], ".tif", ".csv"));
selectWindow(title);
run("Close");
selectWindow("Results");
run("Close");
};
waitForUser("Thank you for your cooperation, take care and goodbye! :)");
};
// End of part II. Hopefully everything did work out!!
//////////////////