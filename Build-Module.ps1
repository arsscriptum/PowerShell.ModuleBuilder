<#
  ╓──────────────────────────────────────────────────────────────────────────────────────
  ║   PowerShell.ModuleBuilder      
  ╙──────────────────────────────────────────────────────────────────────────────────────
 #>

<#
.SYNOPSIS
    A simple Powershell script build the module files.

.DESCRIPTION
    The script will gather relevant files, functions, aliases. Then it will generate the manifest
    file (.psd1) and script file (.psm1). If compression and/or obfuscation is requested, it will
    apply the appropriate operations. After this, it will optionally generate documentation,
    import the module, and commit in the github repository.
.PARAMETER Path
    Path of the module to compile, is not specified, takind current path
.PARAMETER ModuleIdentifier
    Module Identifier, if not specified, the directory name is used
.PARAMETER Documentation
    FLAG: Build documentation
.PARAMETER Import
    FLAG: Import after build
.PARAMETER Deploy
    FLAG: Deploy after build
.PARAMETER Debug
    FLAG: For Debug purposes. Output the scripts with no compression
.PARAMETER Verbose
    FLAG: For Debug purposes. Output LOTS of logs

.EXAMPLE
    -
    Runs without any parameters. Uses all the default values/settings
    >> ./Build.ps1
    -
    Build the module located in 'c:\ModuleToBuild', with verbose output
    >> ./Build.ps1 -Path 'c:\ModuleToBuild' -Verbose -Debug
    -
    Runs Build, import and deploy
    >> ./Build.ps1 -Import -Deploy
    -
#>


#===============================================================================
# Commandlet Binding
#===============================================================================
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true, HelpMessage="Module name")]
    [Alias('n','m','id')] [string] $Name,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true, 
        HelpMessage="Build the module documentation") ]
    [Alias('doc')]
    [switch]$Documentation,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true, 
        HelpMessage="Import after build") ]
    [Alias('i')]
    [switch]$Import,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true, 
        HelpMessage="Deploy after build") ]
    [Alias('d')]
    [switch]$Deploy,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true, 
        HelpMessage="Validate function names") ]
    [switch]$Strict,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true, 
        HelpMessage="Push after build") ]
    [Alias('p')]
    [switch]$Push,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true, 
        HelpMessage="Sign after build") ]
    [Alias('s')]
    [switch]$Sign,      
    [Parameter(Mandatory=$false,ValueFromPipeline=$true, 
        HelpMessage="Edit after build") ]
    [Alias('e')]
    [switch]$Edit,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true, 
        HelpMessage="Publish after build (deploy + official steps)") ]
    [switch]$Publish,          
    [Parameter(Mandatory=$false,ValueFromPipeline=$true, 
        HelpMessage="Skip DependencyCheck") ]
    [Alias('nodep')]
    [switch]$SkipDependencyCheck,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true, 
        HelpMessage="Validate function names") ]
    [switch]$ValidateNames    
)


#Requires -Version 5



function Get-Script([string]$prop){
    $ThisFile = $script:MyInvocation.MyCommand.Path
    return ((Get-Item $ThisFile)|select $prop).$prop
}

$ScriptPath = split-path $script:MyInvocation.MyCommand.Path
$ScriptFullName =(Get-Item -Path $script:MyInvocation.MyCommand.Path).DirectoryName

# C:\DOCUMENTS\PowerShell\Projects\PowerShell.ModuleBuilder
# $ENV:PSModuleBuilder
try{
    $ErrorOccured = $False
    [int]$ModulesBuilt = 0
    $CurrentPath = (Get-Location).Path
    $ModuleBuilderName = 'PowerShell.ModuleBuilder'
    $RegistryPath = "$ENV:OrganizationHKCU\$ModuleBuilderName"
    $BuildScriptPath = (Get-ItemProperty $RegistryPath -Name 'BuildScriptPath' -ErrorAction Stop).BuildScriptPath
    $ModuleBuilderPath = (Get-ItemProperty $RegistryPath -Name 'ModuleBuilderPath' -ErrorAction Stop).ModuleBuilderPath
    $ModuleDevelopmentPath = (Get-ItemProperty $RegistryPath -Name 'ModuleDevelopmentPath' -ErrorAction Stop).ModuleDevelopmentPath
    if(-not(Test-Path -Path $ModuleBuilderPath -PathType Container)){ throw "Could not locate ModuleBuilder Path" }
    if(-not(Test-Path -Path $ModuleDevelopmentPath -PathType Container)){ throw "Could not locate Module Development Path" }
    if(-not(Test-Path -Path $BuildScriptPath -PathType Leaf)){ throw "Could not locate Build Script Path" }

    Write-Host "===============================================================================" -f DarkRed
    Write-Host " Build Script       Path `t" -NoNewLine -f DarkYellow ; Write-Host "$BuildScriptPath" -f Gray 
    Write-Host " Module Builder     Path `t" -NoNewLine -f DarkYellow;  Write-Host "$ModuleBuilderPath" -f Gray 
    Write-Host " Module Development Path `t" -NoNewLine -f DarkYellow;  Write-Host "$ModuleDevelopmentPath" -f Gray 
    Write-Host "===============================================================================" -f DarkRed   
    If( $PSBoundParameters.ContainsKey('Name') -eq $False ){
        $Name = (Get-Item $CurrentPath).Name
    }
        pushd $ModuleDevelopmentPath
        $FilteredDir = (gci . -Directory | where Name -match $Name)
        $FilteredDirCount = $FilteredDir.Count
        Write-Host "[$ModuleBuilderName] " -f DarkRed -NonewLine
        Write-Host "Module Id $Name is refering to $FilteredDirCount modules." -f DarkYellow  
        if($FilteredDirCount -eq 0){  throw "not in module directory" ;  }
        ForEach($mdir in $FilteredDir){
            $fullname = $mdir.Fullname
            $mname = $mdir.Name
            Write-Host "Directory Fullname `t" -NoNewLine -f DarkYellow;  Write-Host "$fullname" -f Gray 
            Write-Host "Directory     name `t" -NoNewLine -f DarkYellow;  Write-Host "$mname" -f Gray 
            Write-Log "Switching to $fullname"
            pushd $fullname
            $gitstr = Get-GitRevision -r
            [string]$verstr = Get-Content "./Version.nfo"
           
            Write-Log " Building $mname"
            Write-Log "  Module Version ==> $verstr"
            Write-Log "  GIT Revision   ==> $gitstr"
            Write-Log "BuildScriptPath $BuildScriptPath"
            Read-Host 'Press any key...'
            #. "$BuildScriptPath" -Path "$fullname" -Documentation:$Documentation -Import:$Import -Deploy:$Deploy -Strict:$Strict
            . "$BuildScriptPath" -Path "$fullname" -Documentation:$Documentation -Import:$True -Deploy:$True -Strict:$Strict -Push:$Push -Edit:$Edit -SkipDependencyCheck:$SkipDependencyCheck -ValidateNames:$ValidateNames -Sign:$Sign
            
            $ModulesBuilt++
        }
     
    
}catch{
    $ErrorOccured = $True
    Write-Host "❗❗❗ Build Error" -f DarkYellow ;
    Show-ExceptionDetails($_)
}
finally{
    popd
    if($ErrorOccured -eq $False){
        Write-Host "`n`n===============================================================================" -f DarkRed
        Write-Host " BUILD RESULTS" -f DarkYellow;
        Write-Host "===============================================================================" -f DarkRed

        Write-Host "[SUCCESS] " -f DarkGreen -n
        Write-Host "$ModulesBuilt Modules compiled" -f Gray 
    }
    
    popd
}
