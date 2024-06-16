# FuNP
Fusion of Neuroimaging Preprocessing Pipeline: A multimodal MRI data preprocessing pipeline

## Paper
> *B.-y. Park, K. Byeon, and H. Park.* FuNP (Fusion of Neuroimaging Preprocessing) pipelines: A fully automated preprocessing software for functional magnetic resonance imaging. *Frontiers in Neuroinformatics* 13:5 (2019). \
https://www.frontiersin.org/articles/10.3389/fninf.2019.00005/full

## Required software :eyes:
> [!IMPORTANT] 
>  
> ### The current version of FuNP was tested under the following versions
> **AFNI** v22.0.17 (https://afni.nimh.nih.gov/download) \
> **FSL** v6.0 (https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation) \
> **FreeSurfer** v7.1.1 (http://freesurfer.net/fswiki/DownloadAndInstall) \
> **ANTs** v2.3.5 (https://github.com/ANTsX/ANTs) \
> **MRtrix3** v3.0.2 (https://www.mrtrix.org/download) \
> **Workbench** v1.5.0 (https://www.humanconnectome.org/software/get-connectome-workbench) \
> **R** v3.6.3 (https://cran.r-project.org/bin/linux/ubuntu/fullREADME.html) \
> **python** v3.8.5 (https://www.python.org/downloads) \
> **FIX** v1.06.15 (https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FIX)
> 
> :triangular_flag_on_post: **FIX has several requirements** 
> * FSL
> * MATLAB with official toolboxes:
>   * Statistics
>   * Signal Processing 
> * R (version >=3.3.0), with the following packages:
>   * 'kernlab' version 0.9.24 
>   * 'ROCR' version 1.0.7 
>   * 'class' version 7.3.14 
>   * 'party' version 1.0.25 
>   * 'e1071' version 1.6.7 
>   * 'randomForest' version 4.6.12
> 
> :triangular_flag_on_post: **GAN-MAT requirements** \
> Download the trained model (model.pth) at https://www.dropbox.com/home/GAN-MAT?di=left_nav_browse \
> Locate model.pth into the *~/FuNP/functions/GANMAT* folder
