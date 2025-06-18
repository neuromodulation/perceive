[![GitHub top language](https://img.shields.io/github/languages/top/neuromodulation/perceive)](https://matlab.mathworks.com/)  [![Perceive CI/CD](https://github.com/neuromodulation/perceive/actions/workflows/main.yml/badge.svg)](https://github.com/neuromodulation/perceive/actions/workflows/main.yml) [![GitHub issues by-label](https://img.shields.io/github/issues-raw/neuromodulation/perceive/bug)](https://github.com/neuromodulation/perceive/issues?q=is%3Aissue+is%3Aopen+label%3Abug) ![GitHub Repo stars](https://img.shields.io/github/stars/neuromodulation/perceive?style=social)

[![Codecov](https://img.shields.io/codecov/c/github/neuromodulation/perceive)](https://app.codecov.io/gh/neuromodulation/perceive) ![MATLAB Code Issues](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fneuromodulation%2Fperceive%2Fmain%2Freports%2Fbadge%2Fcode_issues.json) ![MATLAB Versions Tested](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fneuromodulation%2Fperceive%2Fmain%2Freports%2Fbadge%2Ftested_with.json) 


# Perceive (MATLAB)

TUTORIAL:
addpath C:\code\perceive
perceive
testJK

https://github.com/neuromodulation/perceive 
v0.2 Contributors Tomas Sieger, Wolf-Julian Neumann, Gerd Tinkhauser
v0.3 Contributor Jojo Vanhoecke
This is an open research tool that is not intended for clinical purposes. 

## What's new?

Interactive GUI provides the possibility to convert percept.json files into BIDS-like structures,
including taks, acquistion, run and other handles.

# INPUT

perceive(files, sub, ses, extended)

## files:
All input is optional, you can specify files as cell or character array
(e.g. files = 'Report_Json_Session_Report_20200115T123657.json') 
if files isn't specified or remains empty, it will automatically include
all files in the current working directory
if no files in the current working directory are found, a you can choose
files via the MATLAB uigetdir window.

## sub:
SubjectID: you can specify a subject ID for each file in case you want to follow an IRB approved naming scheme for file export

e.g. run perceive('Report_Json_Session_Report_20200115T123657.json',80) -> creates sub-080

e.g. run perceive('Report_Json_Session_Report_20200115T123657.json','080') -> also creates sub-080

e.g. run perceive('Report_Json_Session_Report_20200115T123657.json','Charite001') -> creates sub-Charite001

if unspecified or left empy, the subjectID will be created from
ImplantDate, first letter of disease type and target (e.g. sub-2020110DGpi)

## extended:
'Yes' or ''
If 'Yes': saves all created files in between and in different formats
default: ''


# OUTPUT

The script generates BIDS bids.neuroimaging.io/ inspired subject and session folders with the
ieeg format specifier. 
All time series data are being exported as FieldTrip '.mat' files, as these require no additional dependencies for creation.
You can reformat with FieldTrip and SPM to MNE python and other formats (e.g. using fieldtrip2fiff([fullname '.fif'],data))

## Recording type output naming
Each of the FieldTrip data files correspond to a specific aspect of the Recording session:

LMTD = LFP Montage Time Domain - BrainSenseSurvey

IS = Indefinite Streaming - BrainSenseStreaming

CT = Calibration Testing - Calibration Tests

BSL = BrainSense LFP (2 Hz power average + stimulation settings)

BSTD = BrainSense Time Domain (250 Hz raw data corresponding to the BSL file)

## TODO: 
ADD BATTERY DRAIN information per sesssion
ADD PATIENT SNAPSHOT EVENT READINGS
ADD CHRONIC DIAGNOSTIC READINGS
ADD Lead DBS Integration for electrode location

