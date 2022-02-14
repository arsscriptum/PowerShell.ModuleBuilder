# PowerShell Module Builder


![MODULE BUILDER](https://raw.githubusercontent.com/arsscriptum/PowerShell.ModuleBuilder/master/data/exec.gif)

The script will gather relevant files, functions, aliases. Then it will generate the manifest
file (.psd1) and script file (.psm1). If compression and/or obfuscation is requested, it will
apply the appropriate operations. After this, it will optionally generate documentation,
import the module, and commit in the github repository.

In short:
- List all the functions and aliases to be exported from the module's source directory
- Update the module MANIFEST (.psd1) file
- Generate the module script file (.psm1)
- Deploy to local module path
- Import

## Why ?

I was getting tired of maintaining a manifest file for each of my modules, and there was a need for
added consistency between my modules

## Objectives

1. Create a new module from scratch very EASILY and QUICKLY
1. UPDATE EXISTING PowerShell Module very EASILY and QUICKLY
1. Straightforward scripts/system and stand-alone (no 1000x dependencies...)


## Parameters

1. ***Path***
    1. Path of the module to compile, is not specified, takind current path
1. ***ModuleIdentifier***
    1. Module Identifier, if not specified, the directory name is used 
1. ***Doumentation***
    1. FLAG: Build documentation 
1. ***Deploy***
    1. Deploy after build 
1. ***Debug***
    1. FLAG: For Debug purposes. Output the scripts with no compression 
1. ***Verbose***
    1. FLAG: For Debug purposes. Output LOTS of logs 


## How To Use

1. FIRSTLY, run ./Setup.ps1. To Create the aliases and other stuff.
1. Create your first MODULE using New-PowershellModule.ps1
1. Set-Location 'NewModule' ; then make!
   

	

##EXAMPLE
```
    Runs without any parameters. Uses all the default values/settings
    >> ./Build.ps1
    -
    Build the module located in 'c:\ModuleToBuild', with verbose output
    >> ./Build.ps1 -Path 'c:\ModuleToBuild' -Verbose -Debug
    -
    Runs Build, import and deploy
    >> ./Build.ps1 -Import -Deploy
    -
```



## Tasks List
-------------
龱 Automatic function list detection and update in manifest

龱 Aliases detection and update in manifest

龱 Documentation

龱 Create a EXE

龱 Create a Setup script

龱 Create a template module



