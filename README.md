# Automagic

## 1. Setup

### 1.1. System Requirements
You need MATLAB installed and activated on your system to use *Automagic*. *Automagic* was developed and tested in MATLAB R2015b and newer releases.

### 1.2. Installation
1. Download the *Automagic EEG Toolbox* to a folder of your choosing. 
2. Within that folder, navigate to \Automagic_EEG_Toolbox\ppp
3. Double click the file named *automagic* or *automagic.mlappinstall*. Wait until MATLAB displays a dialogue box.
4. Please select Install. You will be notified as soon as the installation is complete.

### 1.3. How to Run Automagic
1. Start MATLAB. 
2. Select the APPS tab. 
3. Click on the Automagic icon. You might have to expand the APPS tab to see the *Automagic* icon by clicking the small triangle pointing down on the far right of the APPS tab.

## 2. Basic Workflow
In this section of the manual, only the basic functionality of Automagic will be explained. This covers the basic workflow from selecting a project to rating the data. Please refer to chapters 3 to 6 for detailed information all functions within the main GUI.

1. Create a new project or load an existing project.
2. Make sure that all the data you want to work with has been pre-processed before proceeding.
3. Rate the data manually.
4. Interpolate all manually selected channels.
5. Repeat steps 3 and 4 until all data is rated.
6. Close Automagic or switch to another project: All data is saved automatically.

* Important:	Since synchronisation is rather basic, people should never work on the same project simultaneously.

## 3. The Project Panel

### 3.1. Creating a New Project
1. Navigate to the drop-down list labelled *Select Project*.
2. Select *Create New Project…*
3. Name your project.
4. Choose the file extension that corresponds to your data’s file format. *Automagic* currently supports the following file formats: raw image files (.raw), fractal image files (.fif) and generic data files (.dat).
5. Specify the path of your data folder. *Automagic* will scan all folders in your data folder for data files. Files and folders in the data folder will not be altered by *Automagic*.
 * Important: 	The data folder must contain a folder for each subject (subject folders). Your data folder should not contain any other kinds of folders since this will lead to a wrong number of subjects. 
 * Important:	A subject folder must contain data files. A subject folder should not contain any folders. Automagic can only load data saved in subject folders. Since subject folders are defined as folders in the data folder, no specific naming is required.
6. Specify the path of your project folder. If the specified folder does not yet exist, *Automagic* will create it for you. *Automagic* will save all processed data to your project folder. By default, *Automagic* opts for your data folder’s path and adds *_results* to your data folder’s name, e.g. *\PathDataFolder\MyDataFolder_results\*
7. Please choose the required filtering on the pre-processing panel. Chose US if your data was recorded in adherence to US standards. Chose EU if your data was recorded in adherence to EU standards.
8. Set the downsampling rate on the manual rating panel. The downsampling only affects the visual representation of your data. A higher downsampling rate will shorten loading times. In general, a downsampling rate of 2 is a good choice. 
 * Important:	You cannot alter paths, the filtering, or the downsampling rate after creating your project.
9. Click on Create New in the lower right corner of the project panel to create your new project. If the specified data and project folders do not yet exist, *Automagic* will now create them for you.

### 3.2. Loading an Existing Project
There are two options to load an existing project. The first option can only be used to open projects that have been created on your system or that have been loaded before:

1. Navigate to the drop-down list labelled *Select Project*.
2. Select the project you want to load.

The second option can be used to load any *Automagic* project:

1. Navigate to the drop-down list labelled *Select Project*.
2. Select *Load an existing project…*
3. A browser window will open. Navigate to the existing project’s project folder.
4. Select and open the file named *project_state.mat*

### 3.3. Merging Projects
To merge any number of existing projects without losing the individual projects, please follow these steps:

1. Create a new data folder using Finder (Mac), Explorer (Windows) or your Linux equivalent.
2. Create a new project folder using Finder (Mac), Explorer (Windows) or your Linux equivalent.
3. For all the projects that you want to merge: Copy the contents from the data and project folders to the new data and project folders.
 * Important: 	Each of your existing projects’ project folders contains a file named project_state.mat. Do not copy these files to your new project folder.
4. In *Automagic*: Create a new project using the newly created data and project folders.

### 3.4. Adding Data to an Existing Project
1. Add subject folders to your data folder using Finder (Mac), Explorer (Windows) or your Linux equivalent.
2. Refresh the *Automagic* GUI using one of these options:
 * Start or restart Automagic.
 * Navigate to the drop-down list labelled Select Project and load (or reload) the project containing new data by clicking on its name.
3. The number of subjects and files in both the project panel and the pre-processing panel should now be updated.

### 3.5. Deleting Data from an Existing Project
1. Delete subject folders from your data folder using Finder (Mac), Explorer (Windows) or your Linux equivalent.
2. Refresh the *Automagic* GUI using one of these options:
 * Start or restart Automagic.
 * Navigate to the drop-down list labelled Select Project and load (or reload) the project containing new data by clicking on its name.
3. The number of subjects and files in both the project panel and the pre-processing panel should now be updated.

### 3.6. Deleting a Project
1. Click on *Delete Project* in the lower right corner of the project panel. A dialog box will appear.
2. Take responsibility by clicking on Delete.
 * Important: 	This will only delete the file named project_state.mat in the project folder and remove the project from the Automagic GUI. Please use Finder (Mac), Explorer (Windows) or your Linux equivalent to delete your project’s data and/or project folder.

## 4. The Pre-Processing Panel
 * Important:	The filtering can only be set during project creation.
Click on Run to start the pre-processing of your data. This is the first thing you should do after creating a new project or after adding data to an existing project. Pre-processing includes filtering, detection of bad channels, EOG regression, PCA, and automatic interpolation.

Should the project folder already contain files (i.e. should some of the project’s data already have been pre-processed), you’ll be able to choose whether existing files will be overwritten or skipped after clicking on Run. 
* Important:	Please wait until all files have been pre-processed before doing anything else in this instance of MATLAB.

## 5. The Manual Rating Panel
 * Important:	 The downsampling rate can only be set during project creation.
Click on *Start…* to open the rating GUI.
 * Important: 	Only pre-processed files can be rated manually.
 
### 5.1. The Rating GUI
A visualisation of the currently selected file is displayed. Time corresponds to the x-axis, EEG channels correspond to the y-axis. You can use the tools in the top left corner to e.g. magnify an area or select a specific point of the current visualisation. Use the filters right below the tools to focus on a subset of your files based on their rating. You can navigate between files of the current subset by clicking on *Previous* and *Next* or by selecting a file from the drop-down list in the top right corner.

You can rate the quality of the visualised data on the very right. You can choose between **Good**, **OK**, and **Bad**. These ratings are subjective and relative rather than absolute: The overall quality of your data should be used as point of reference. The colouring allows you to rate the quality of your data: Ideally, everything is green. Darker colours signify lower quality, i.e. artifacts etc. As a rule of thumb, horizontal artifacts are worse than vertical artifacts of the same size and colouring. After choosing a rating, you will automatically proceed to the next file.

Should you spot bad channels (represented by horizontal lines which are darker than their surroundings), please select **Interpolate**. This will activate selection mode. Manually navigate to bad channels and select them by clicking on them. Click on *Turn off* after selecting all bad channels. Click on Next to proceed to the next file. You will be able to rate these files after interpolating all selected channels. 
* Important: 	Manual rating can be interrupted anytime by closing the rating GUI. No data will be lost and you can resume rating later.

## 6. The Interpolation Panel
1. Click on *Interpolate All* to interpolate all channels you selected during manual rating.
 * Important: 	Wait until all channels have been interpolated before doing anything else in this instance of MATLAB.
2. Refresh the *Automagic* GUI using one of these options:
 * Start or restart Automagic.
 * Navigate to the drop-down list labelled *Select Project* and load (or reload) the project containing new data by clicking on its name.
3. Manually rate the files that contained bad channels. 
 * Important:	You can select and interpolate bad channels as often as you want in each file.
