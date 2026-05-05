perceive_gui_startup Executable

Quick start
-----------
1) Run the launcher:
   - Windows: run_perceive_gui_startup.bat
   - macOS/Linux: ./run_perceive_gui_startup.sh
2) If Runtime is missing, install MATLAB Runtime R2023a or newer.
3) Run the same launcher again.

1. Prerequisites

End users do not need a MATLAB license.
They need MATLAB Runtime R2023a or newer.

Verify that MATLAB Runtime (R2023a or newer) is installed.
If not, you can run the MATLAB Runtime installer.
To find its location, enter
  
    >>mcrinstaller
      
at the MATLAB prompt.
NOTE: You will need administrator rights to run the MATLAB Runtime installer. 

Alternatively, download and install MATLAB Runtime (R2023a or newer)
from the following link on the MathWorks website:

    https://www.mathworks.com/products/compiler/matlab-runtime.html
   
For more information about the MATLAB Runtime and the MATLAB Runtime installer, see 
"Distribute Applications" in the MATLAB Compiler documentation  
in the MathWorks Documentation Center.

2. Files to Deploy and Package (Windows)

Files to Package for Standalone 
================================
-perceive_gui_startup.exe
-run_perceive_gui_startup.bat
-MCRInstaller.exe 
    Note: if end users are unable to download the MATLAB Runtime using the
    instructions in the previous section, include it when building your 
    component by clicking the "Runtime included in package" link in the
    Deployment Tool.
-This readme file 

3. Cross-platform note

MATLAB Compiler output is OS-specific.
To support macOS and Linux, build on each target OS and package the resulting artifacts:
- Windows -> perceive_gui_startup.exe
- macOS   -> perceive_gui_startup.app
- Linux   -> perceive_gui_startup (ELF binary)

4. Definitions

For information on deployment terminology, go to
https://www.mathworks.com/help and select MATLAB Compiler >
Getting Started > About Application Deployment >
Deployment Product Terms in the MathWorks Documentation
Center.

5. Clean Windows release folder (for maintainers)

In MATLAB, run:

    >> prepare_windows_release_folder

This creates/updates:

    release/windows/perceive_gui_startup




