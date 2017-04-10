# Automagic

![alt tag](https://github.com/amirrezaw/automagic/blob/master/automagic_resources/automagic.jpg)

## What is Automagic ?

**Automagic** is a MATLAB based toolbox for preprocessing of EEG-datasets. First, the toolbox *automagically* removes artifacts (e.g. eye movements, noisy electrodes, etc.) from your raw EEG-data. In a second step, **Automagic** lets you check visually the entire dataset for remaining artifacts. You will be able to select and remove these manually in an efficient way. Furthermore, you can rate the quality of individual EEG-files.

![alt tag](https://github.com/amirrezaw/automagic/blob/master/automagic_resources/main_gui.png)

## 1. Setup

### 1.1. System Requirements
You need MATLAB installed and activated on your system to use **Automagic**. **Automagic** was developed and tested in MATLAB R2015b and newer releases.

### 1.2. How to start

There are four different ways of using the application.

1. The easiest and recommended way is to simply install the application from the app installer file `automagic.mlappinstall`. Please see [GUI Manual](#2-gui-manual)
2. Automagic is also available as an **EEGLab** extension and you can use it to preprocess data loaded by **EEGLab** gui. See [Automagic as EEGLab extension](#3-automagic-as-eeglab-extension)
3. You can also use the preprocessing files independent from the gui. See [Application structure](#4-application-structure) and [How to run the app from the code](#5-how-to-run-the-application-from-the-code)  
4. Or if you wish to make any modifications to any part of the application, be it the gui or the preprocessing part, you can run the application from the code instead of the installer file.  See [Application structure](#3-application-structure) and [How to run the app from the code](#5-how-to-run-the-application-from-the-code)  


## 2. GUI Manual 

### 2.1. Setup

#### 2.1.1. System Requirements
You need MATLAB installed and activated on your system to use **Automagic**. **Automagic** was developed and tested in MATLAB R2015b and newer releases.

#### 2.1.2. Installation
1. Download the **Automagic** EEG Toolbox to a folder of your choice. 
2. Navigate to `gui/` folder
3. Double click the file named `Automagic` or `Automagic.mlappinstall`. Wait until MATLAB displays a dialogue box.
4. Please select Install. You will be notified as soon as the installation is complete.

#### 2.1.3. How to Run Automagic
1. Start MATLAB. 
2. Select the APPS tab. 
3. Click on the Automagic icon. You might have to expand the APPS tab to see the **Automagic** icon by clicking the small triangle pointing down on the far right of the APPS tab.

### 2.2. Basic Workflow
In this section of the manual, only the basic functionality of **Automagic** will be explained. This covers the basic workflow from selecting a project to rating the data. Please refer to chapters 3 to 6 for detailed information all functions within the main GUI.

1. [Create a new project or load an existing project](#231-creating-a-new-project).
2. [Preprocess the data](#24-the-pre-processing-panel).
3. [Rate data and manually select bad channels if any](#25-the-manual-rating-panel).
4. [Interpolate all manually selected channels](#26-the-interpolation-panel).
5. Repeat steps 3 and 4 until all data is rated.
   * NOTE: You can not close the main gui window during the preprocessing. If you wish to stop the preprocessing at any time, you can use `CTRL-C`. In this case, or if by any other reason the preprocessing is stopped before being completely finished, all preprocessed files to that moment will be saved, and you can resume the preprocessing only for the files which are not preprocessed yet. After having used `CTRL-C`, please load your project from the main gui, by reselecting it from the list of existing projects. This will update the gui with the new preprocessed files.

* Important:	Since synchronisation is rather basic, people should never work on the same project simultaneously.

### 2.3. The Project Panel

![alt tag](https://github.com/amirrezaw/automagic/blob/master/automagic_resources/project_panel.png)

#### 2.3.1. Creating a New Project
1. Navigate to the drop-down list labelled *Select Project*.
2. Select *Create New Project...*
3. Name your project.
4. Write down the file extension that corresponds to your data???s file format. For example raw image files (`.raw` or `.RAW`), fractal image files (`.fif`) or generic data files (`.dat`).
5. Choose the EEG System in which your data is recorded. Currently only **EGI HCGSN** is fully supported for both number of channels 128 and 256 (or 129 and 257 respectively). This information is needed mainly to find channel locations. In case you choose the option *Other...* for your EEG System, you must provide a file in which channel locations are specified. The file format must be one which is also supported by EEGLab (`pop_chanedit` function). In addition, you must provide a list of indices of the EOG channels of your dataset. Note that here the list contains the indices of those channels and not their labels (You can also simply deselect the EOG regression and this step will be skipped during the preprocessing).
   * The *Channel location file* must be the full address of the channel location file.
   * The *Channel location file type* must specify the type of the file as required by `pop_chanedit`. eg. `sfp`
   * Please note that in case you choose *Other...* as your EEG system, no reduction in number of channels is supported.
   * ICA is supported for *Other...* only in case your channel labels are as it is required by processMARA. They must be of the form FPz, F3, Fz, F4, Cz, Oz, etc. Otherwise the ICA is simply skipped. If only some of your labels have the required format, only those channels are considered for ICA.
6. You can select or deselect the EOG regression (It is recommended to select it). If you choose *Other...* for your EEG system then you need to specify the list of EOG channels as well. In the case of **EGI** automagic already knows the EOG channels and you don't need to specify anything. The list of EOG channels must be integers seperated by space or comma, e.g. `1 32 8 14 17 21 25 125 126 127 128`
7. Set the downsampling rate on the manual rating panel. The downsampling only affects the visual representation of your data. A higher downsampling rate will shorten loading times. In general, a downsampling rate of 2 is a good choice. 
   * Important:	You cannot alter paths, the filtering, or the downsampling rate after creating your project.
8. Specify the path of your data folder. **Automagic** will scan all folders in your data folder for data files. Files and folders in the data folder will not be altered by **Automagic**.
   * Important: 	The data folder must contain a folder for each subject (subject folders). Your data folder should not contain any other kinds of folders since this will lead to a wrong number of subjects. 
9. Specify the path of your project folder. If the specified folder does not yet exist, **Automagic** will create it for you. **Automagic** will save all processed data to your project folder. By default, **Automagic** opts for your data folder???s path and adds `_results` to your data folder???s name, e.g. `\PathDataFolder\MyDataFolder_results\`
   * Important:	A subject folder must contain EEG files. Automagic can only load data saved in subject folders. Since subject folders are defined as folders in the data folder, no specific naming is required.
 
 ![alt tag](https://github.com/amirrezaw/automagic/blob/master/automagic_resources/folder_structure.png)
 
 
10. Choose your filtering parameters in the Filtering panel. 
    * Notch Filter: Choose `US` if your data was recorded in adherence to US standards (60 Hz). Choose `EU` if your data was recorded in adherence to EU standards (50 Hz).
    * By default a High pass filtering is performed on data. You can change the freuqency or simply uncheck the High pass filtering. You can also choose to have a Low pass filtering. By default there is no Low pass filtering.
11. [By clicking on the *Configurations...*](#237-customize-settings) button you can modify additional optional parameters of the preprocessing. This is not necessary, and you can leave it so that the default values are used.
12. Click on *Create New* in the lower right corner of the project panel to create your new project. If the specified data and project folders do not yet exist, **Automagic** will now create them for you.

#### 2.3.2. Loading an Existing Project
There are two options to load an existing project. The first option can only be used to open projects that have been created on your system or that have been loaded before:

1. Navigate to the drop-down list labelled *Select Project*.
2. Select the project you want to load.

The second option can be used to load any *Automagic* project:

1. Navigate to the drop-down list labelled *Select Project*.
2. Select *Load an existing project...*
3. A browser window will open. Navigate to the existing project...s project folder.
4. Select and open the file named `project_state.mat`

#### 2.3.3. Merging Projects
To merge any number of existing projects without losing the individual projects, please follow these steps:

1. Create a new data folder using Finder (Mac), Explorer (Windows) or your Linux equivalent.
2. Create a new project folder using Finder (Mac), Explorer (Windows) or your Linux equivalent.
3. For all the projects that you want to merge: Copy the contents from the data and project folders to the new data and project folders.
   * Important: 	Each of your existing project folders contains a file named `project_state.mat`. Do not copy these files to your new project folder.
4. In **Automagic**: Create a new project using the newly created data and project folders.

#### 2.3.4. Adding Data to an Existing Project
1. Add subject folders to your data folder using Finder (Mac), Explorer (Windows) or your Linux equivalent.
2. Refresh the **Automagic** GUI using one of these options:
 * Start or restart **Automagic**.
 * Navigate to the drop-down list labelled Select Project and load (or reload) the project containing new data by clicking on its name.
3. The number of subjects and files in both the project panel and the pre-processing panel should now be updated.

#### 2.3.5. Deleting Data from an Existing Project
1. Delete subject folders from your data folder using Finder (Mac), Explorer (Windows) or your Linux equivalent.
2. Refresh the **Automagic** GUI:
 * Navigate to the drop-down list labelled Select Project and load (or reload) the project containing new data by clicking on its name.
3. The number of subjects and files in both the project panel and the pre-processing panel should now be updated.

#### 2.3.6. Deleting a Project
1. Click on *Delete Project* in the lower right corner of the project panel. A dialog box will appear.
2. Take responsibility by clicking on Delete.
   * Important: 	This will only delete the file named `project_state.mat` in the project folder and remove the project from the Automagic GUI. Please use Finder (Mac), Explorer (Windows) or your Linux equivalent to delete your project data and/or project folder.

#### 2.3.7. Customize Settings
![alt tag](https://github.com/amirrezaw/automagic/blob/master/automagic_resources/settings.png)

After clicking on *Configurations...* button a new window is opened where you can customize preprocessing steps:

1. If *Reduce number of channels* is checked, then before preprocessing number of channgels is reduced. [Click here](https://github.com/amirrezaw/automagic/blob/master/automagic_resources/reduced_channels.txt) to see list of channels selected. In case you choose *Other* as your EEG System in the `main_gui` then this element is deactivated: No channel reduction is supported for other EEG Systems. 
2. In the *Filtering* section you can choose the order of the filtering. The default value corresponds to the default value computed by `pop_eegfiltnew.m`.
3. In the *Channel rejection criterias* you can select or deselect the three different criterias *Kurtosis*, *Probability* and *Spectrum* to reject channels (see `pop_rejchan.m`). The corresponding thresholds can also be customized.
4. *ICA* can be selected or deselected. Note that ICA and PCA can not be chosen together at the same time. The ICA uses the algorithm in MARA extension of MATLAB.
5. *PCA* can be selected or deselected. The parameters correspond to paramters of `inexact_alm_rpca.m`. The default value *lambda* is ![alt tag](https://github.com/amirrezaw/automagic/blob/master/automagic_resources/sqrt.jpg) where m is the number of channels.
6. The mode of interpolation can be determined. The default value is *spherical*.
   * Important:	The preprocessing parameters can be set only during project creation.

### 2.4. The Pre-Processing Panel

Click on Run to start the pre-processing of your data. This is the first thing you should do after creating a new project or after adding data to an existing project. Pre-processing includes filtering, detection of bad channels, EOG regression, PCA, and automatic interpolation.

Should the project folder already contain files (i.e. should some of the projects data already have been pre-processed), you will be able to choose whether existing files will be overwritten or skipped after clicking on Run.


### 2.5. The Manual Rating Panel

![alt tag](https://github.com/amirrezaw/automagic/blob/master/automagic_resources/rating_gui.png)


Click on *Start...* to open the rating GUI.
 
A visualisation of the currently selected file is displayed. Time corresponds to the x-axis, EEG channels correspond to the y-axis. You can use the tools in the top left corner to e.g. magnify an area or select a specific point of the current visualisation. Use the filters right below the tools to focus on a subset of your files based on their rating. You can navigate between files of the current subset by clicking on *Previous* and *Next* or by selecting a file from the drop-down list in the top right corner.

You can rate the quality of the visualised data on the very right. You can choose between **Good**, **OK**, and **Bad**. These ratings are subjective and relative rather than absolute: The overall quality of your data should be used as point of reference. The colouring allows you to rate the quality of your data: Ideally, everything is green. Darker colours signify lower quality, i.e. artifacts etc. As a rule of thumb, horizontal artifacts are worse than vertical artifacts of the same size and colouring. After choosing a rating, you will automatically proceed to the next file.

Should you spot bad channels (represented by horizontal lines which are darker than their surroundings), please select **Interpolate**. This will activate selection mode. Manually navigate to bad channels and select them by clicking on them. Click on *Turn off* after selecting all bad channels. Click on Next to proceed to the next file. In the next step you will start interpolationg these bad channels and finally you can come back to re-rate these files after interpolating all selected channels. 

   * Important: 	Only pre-processed files will be shown for rating.
   * Important: 	Manual rating can be interrupted anytime by closing the rating GUI. No data will be lost and you can resume rating later.

### 2.6. The Interpolation Panel
1. Click on *Interpolate All* to interpolate all channels you selected during manual rating.
2. Refresh the **Automagic** GUI:
   * Navigate to the drop-down list labelled *Select Project* and load (or reload) the project containing new data by clicking on its name.
3. Manually re-rate the files that contained bad channels. 
   * Note that you can select and interpolate bad channels as often as you want in each file.

## 3. Automagic as EEGLab extension

![alt tag](https://github.com/amirrezaw/automagic/blob/master/automagic_resources/eeglab.png)

You can also run **Automagic** as an EEGLab [extension](https://sccn.ucsd.edu/wiki/EEGLAB_Extensions_and_plug-ins). To do so, you need to simply put the `automagic/` folder in the `eeglab_[your-version]/plugins/` folder. 
After this being done, on start-up, **EEGLab** will create a new menu item for **Automagic**. This menu item will have three sub-menus, each of which corresponding to the earlier explained steps of preprocessing: 
1. *Start Processing...* which corresponds to [Preprocessing the data](#24-the-pre-processing-panel)
2. *Start Manual Rating...* which corresponds to [Manual rating of bad channels](#25-the-manual-rating-panel).
3. *Start Interpolation...* which corresponds to [Interpolation of all manually selected channels](#26-the-interpolation-panel)

The behaviour of the the second and third step is exactly as explained in previous section. The only difference happens for the first step where you can preprocess only the currently selected EEG structure instead of the list of all of your EEG structures loaded in **EEGLab**.

Also please note that, when using **EEGLab**, there is no more the notion of having projects, or creating a new project,etc. In this case, you simply load your data from within **EEGLab**, preprocess, rate and interpolate them, and all the results are given back in `ALLEEG` structure of the **EEGLab**. From there you may want to save your result yourself.

   * Important: In order to be able to start the preprocessing, you must first add the channel locations to your EEG data strucutre. For more information please see **EEGLab** documentation on this.

## 4. Application Structure

There are four main folders (in total 6 folders): 

1. **`automagic/preprocessing/`**
 This folder contains all relevant files of preprocessing step (with no GUIs). The folder is standalone and can be used independent from the entire application. The main function to be called is `preprocess.m` which needs two arguments. The first argument is the EEG data structure loaded by `pop_fileio.m` function (or a similar function) of **EEGLab** and the second argument is preprocessing parameters (see documations, ie. `preprocess.m` to learn about the second argument). The first ouput of `preprocess.m` is an EEG data structure similar to the input EEG structure, where the `EEG.data` field has the preprocessed results. This EEG data streucture has some new fields like the parameters used for preprocessing and channels that have been interpolated by automatic detection. The second output is a figure showing the effects of preprocessing. For more information on how to run the code without installer please see  [How to run the app from the code](#5-how-to-run-the-application-from-the-code).
2. **`automagic/gui/`**
 This folder contains files created by *MATLAB GUIDE*. All callback operations related to the gui are implemented here.
   1. `main\_gui.m` is the main function of the project which must be started to run the application.
   2. `rating\_gui.m` is the gui that is accessed from within the `main\_gui.m` and is used to rate subjects and files. You don't need to use this function directly.
   3. `settings.m` is the gui corresponsing to configuration button on the main gui. It allows to customize the preprocessing steps. Again you don't need to run this file directly.
   4. `Automagic.mlappinstall` which is the app installer mentionned in [Installation](#2-1-2-Installation) section.
3. **`automagic/src/`**
 This folder contains all source files regarding the entire structure of the application:
   * `Project.m`, `Subject.m` and `Block.m` are classes representing a project created in the gui, its corresponding subjects and the raw files of each subject, respectievly. `ConstantGlobalValues.m` contains constant variables used throughout the application to avoid duplications.
4. **`eeglab_plugin/`**
 This folder contains necessary files to integrate **Automagic** as an **EEGLab** extension. There are corresponding `pop_` functions and equivalent functions of `automagic/src/` for the plugin. The structure is very similar to `automagic/src/`.
 
5. `matlab_scripts/` 
    This folder (must) contain all external files from **EEGLab** and other libraries.
    
6. `automagic_resources`
    Contains few images and icons for the readme, etc.

## 5. How to run the application from the code
You can also run **Automagic** without using the installer. A clear reason to do so is to make your own modifications to the code and then run it.

For this code to be able to run, functions from [**EEGLab**](https://sccn.ucsd.edu/eeglab/) and  [**Augmented Lagrange Multiplier (ALM) Method**](http://perception.csl.illinois.edu/matrix-rank/sample_code.html) are needed to be on your path:

1. Download the [**EEGLab**](https://sccn.ucsd.edu/eeglab/downloadtoolbox.php) library and put it in the `automagic/matlab_scripts` folder.
2. Download the  **inexact ALM** ( containing the function `[A, E] = inexact_alm_rpca(D, ??)`) from [**(ALM) Method**](http://perception.csl.illinois.edu/matrix-rank/sample_code.html) and put it in the `automagic/matlab_scripts/` as well.
    * Important: If you feel too lazy to download this extension and put it in  `automagic/matlab_scripts/`, **don't**. While using **Automagic**, if you choose to use PCA in preprocessing, you will be asked if you agree to download the package, if you answer *Yes*, the package will be downloaded *Automagically* in the right folder. Note that this feature is not yet implemented for the precious step, **EEGLab**.  
3. Now you are able to run the code by running the `automagic/gui/main_gui.m`

* NOTE: If your data is with `.fif` extension, you need to download [**fieldtrip**](http://www.fieldtriptoolbox.org/download) which is an **EEGLab** extension and put it in `matlab_scripts/eeglab13_6_5b/plugins/`.

Note that you can modify anything in the code if you want and change all files and folder structures including matlab paths. 


## Contact us
You can find us [here](http://www.psychologie.uzh.ch/de/fachrichtungen/plafor.html).
If you have any questions, feedbacks please email us at amirreza [dot] bahreini [at] uzh [dot] ch
