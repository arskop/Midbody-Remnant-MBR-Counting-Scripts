macro "MKLP-Ch1_V4" {
        //last edited 3/25/2023 by Liily Dantong Zhu       
       //open a folder with .nd files it will only read .nd files
       
       //define necessary constants----------------------------------------------------------------------
       run("Clear Results");
       setBatchMode(true);
       input = getDirectory("Input directory");
       suffix = ".nd2";
       run("Set Measurements...", "area mean standard display redirect=None decimal=2");
       
       // function to scan folders/subfolders/files
       processFolder(input);
       function processFolder(input) {
       list = getFileList(input);
       list = Array.sort(list);
               for (i = 0; i < list.length; i++) {
       if(File.isDirectory(input + File.separator + list[i]))
       processFolder(input + File.separator + list[i]);
       if(endsWith(list[i], suffix))
       processFile(input, list[i]);}}
       
       //actual processing------------------------------------------------------------------------------        
       function processFile(input, file) {
            path = input + file;  
       run("Bio-Formats Importer", "open=path open_all_series windowless=true");
       //run("Bio-Formats Importer", "open=path open_all_series");
       //importing all.nd using Bioformat 	
       run("Z Project...", "projection=[Max Intensity]");
       img0 = getTitle();
       setAutoThreshold("Moments dark");
       setOption("BlackBackground", true);
       run("Convert to Mask", "method=Moments background=Dark calculate black");
       //clean the image
       run("Despeckle","stack");
       run("Gaussian Blur...", "sigma=1.5 stack");
       //get rid of backgrund noise
       setAutoThreshold("Moments dark");
       setOption("BlackBackground", true);
       run("Convert to Mask", "method=Moments background=Dark calculate black");
       run("Watershed","stack");
       //seperate particles sticking together
       run("Analyze Particles...", "size=0.80-Infinity circularity=0.20-1.00 show=Outlines exclude summarize stack");
       
       //make a summary of result tables----------------------------------------------------------------
       {tableTitle = Table.title;
        Table.rename(tableTitle, "Results"); //rename all [summary of] to results 
        headings = Table.headings;
        headingsArray = split(headings, "\t"); //split headings to different fields 
        if (isOpen("Ch1")==false) {
                Table.create("Ch1");}//create Ch1 if it's not present
        if (isOpen("MKLP")==false) {
                Table.create("MKLP");}//create MKLP if it's not present  
        selectWindow("Ch1");
        size = Table.size;
        
        for (i=0; i<headingsArray.length; i++){ //i=2 make count the first column, I spent two days fixing this function right here. Turns out it's a version bug. Upgraded to Fiji and everything is fixed smh.
                Ch1 = getResultString(headingsArray[i], 0); //get heading array from the heading in line 0, Slice 1
                MKLP = getResultString(headingsArray[i], 1); //get heading array from the heading in line 1, Slice 2
                //print(data);
                selectWindow("Ch1");
                Table.set(headingsArray[i], size, Ch1);
                Table.set("Slice", size, tableTitle);
                Table.update; //Ch1 count for each image in Ch1 table
                
                selectWindow("MKLP");
                Table.set(headingsArray[i], size, MKLP);
                Table.set("Silce", size, tableTitle);
                Table.update; //MKLP count for each image in MKLP table
        }}
       //OVERLAP----------------------------------------------------------------------------------
       selectWindow(img0);
       run("Split Channels");
       img1 = getTitle();
       img2 = getTitle();
       run("Image Calculator...","image1=&img1 operation=AND image2=&img2 create");
       run("Gaussian Blur...", "sigma=2 stack");
       setAutoThreshold("Moments dark");
        setOption("BlackBackground", true);
       run("Convert to Mask", "method=Moments background=Dark calculate black");
       //run("Analyze Particles...", "size=0.80-Infinity circularity=0.10-1.00 show=[Overlay Masks] summarize");
       run("Watershed");
       //seperate particles sticking together
       run("Analyze Particles...", "size=0.9-Infinity circularity=0.20-1.00 show=Outlines exclude summarize overlay stack");
       close("*");
       }
       //end of analysis--------------------------------------------------------------------------
	   close("Results"); //close the last results window 
	   //This code below is for easy processing
       selectWindow("Ch1");
       Table.deleteColumn("Total Area");
       Table.deleteColumn("Average Size");
       Table.deleteColumn("%Area");
       Table.deleteColumn("Mean");
       Table.update;
       Table.setLocationAndSize(0, 0, 1000, 500);
       wait(10);
       selectWindow("MKLP");
       Table.setLocationAndSize(1000,0, 1000,500);
       Table.deleteColumn("Total Area");
       Table.deleteColumn("Average Size");
       Table.deleteColumn("%Area");
       Table.deleteColumn("Mean");
       Table.deleteColumn("Slice");
       Table.update;
       wait(10);
       selectWindow("Summary");
       Table.deleteColumn("Total Area");
       Table.deleteColumn("Average Size");
       Table.deleteColumn("%Area");
       Table.deleteColumn("Mean");
       Table.update;
       Table.setLocationAndSize(0,500, 1000, 500);
       
       print("Done!");
}