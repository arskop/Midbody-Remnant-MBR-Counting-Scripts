//Written by Dantong Zhu December 31 2023
run("Clear Results");  
close("*");
run("Set Measurements...", "area mean standard display redirect=None decimal=2");
setBatchMode("show");
suffix = ".tiff";
dir1 = getDirectory("Choose Source Directory ");
list = getFileList(dir1);

function processImage(imageTitle) {
    selectImage(imageTitle);
    setAutoThreshold("Moments dark");
    setOption("BlackBackground", true);
    run("Convert to Mask", "method=Moments background=Dark calculate black");
    run("Watershed", "stack");
    run("Analyze Particles...", "size=0.8-Infinity circularity=0.20-1.00 show=Nothing exclude summarize stack");
}

//only works with folders with only .tiff files. 
for (i = 0; i < list.length - 1; i++) {
    if (endsWith(list[i], suffix) && endsWith(list[i + 1], suffix)) { 
        showProgress(i + 1, list.length); 
        open(dir1 + list[i]); 
        print("Opened 1 : " + list[i]); 

        open(dir1 + list[i + 1]); 
        print("Opened 2 : " + list[i + 1]); 
        i++; 

        fitc = ""; 
        CY5 = "";
        MBR = "";

        openedImages = getList("image.titles");
        for (j = 0; j < openedImages.length; j++) {
            if (indexOf(openedImages[j], "fitc") >= 0) { 
                print("Image containing 'fitc': " + openedImages[j]);
                fitc = openedImages[j];
            }
            if (indexOf(openedImages[j], "cy5") >= 0) { 
                print("Image containing 'cy5': " + openedImages[j]);
                CY5 = openedImages[j];
            }
        }

        if (fitc != "" && CY5 != "") {
            print("processing " + fitc + ", " + CY5);

//actual processing
//Processing each image individually
processImage(fitc);	
processImage(CY5);

//Overlap particles in fitc and CY5
run("Image Calculator...","image1=&fitc operation=AND image2=&CY5 create");
MBR = getTitle();
setAutoThreshold("Moments dark");
setOption("BlackBackground", true);
run("Convert to Mask", "method=Moments background=Dark calculate black");
run("Watershed"); //seperate particles sticking together
run("Analyze Particles...", "size=0.8-Infinity circularity=0.20-1.00 show=Nothing exclude summarize add"); 

//substracting MKLP from CD9 results
selectImage(MBR);
run("Make Binary");
run("Dilate");
run("Dilate"); //Reduced the "crust" from thresholding
run("Calculator Plus", "i1=[CY5] i2=[MBR] operation=[Subtract: i2 = (i1-i2) x k1 + k2] k1=1 k2=0 create");
wait(5);
run("Set Scale...", "distance=2448 known=434.64 unit=micron global");
selectImage("Result");
run("Analyze Particles...", "size=0.0-0.2 circularity=0.0-1.00 show=Nothing summarize stack"); //Count particles smaller than 0.2 500nm-
run("Analyze Particles...", "size=0.2-0.8 circularity=0.0-1.00 show=Nothing summarize stack");   //Count particles between 0.2-0.8 500nm-1um
run("Analyze Particles...", "size=0.8-5 circularity=0.0-1.00 show=Nothing summarize stack");   //Count particles larger than 0.8 1um+ 

close("*");
        }
    }
}
