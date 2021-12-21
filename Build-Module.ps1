<#
#̷\   ⼕龱ᗪ㠪⼕闩丂ㄒ龱尺 ᗪ㠪ᐯ㠪㇄龱尸爪㠪𝓝ㄒ
#̷\   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇨​​​​​🇴​​​​​🇩​​​​​🇪​​​​​🇨​​​​​🇦​​​​​🇸​​​​​🇹​​​​​🇴​​​​​🇷​​​​​@🇮​​​​​🇨​​​​​🇱​​​​​🇴​​​​​🇺​​​​​🇩​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
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
    [switch]$Strict
)


#Requires -Version 5



function Get-Script([string]$prop){
    $ThisFile = $script:MyInvocation.MyCommand.Path
    return ((Get-Item $ThisFile)|select $prop).$prop
}

$ScriptPath = split-path $script:MyInvocation.MyCommand.Path
$ScriptFullName =(Get-Item -Path $script:MyInvocation.MyCommand.Path).DirectoryName



try{
    $CurrentPath = (Get-Location).Path
    $ModuleBuilderName = 'CodeCastor.PowerShell.ModuleBuilder'
    $RegistryPath = "$ENV:OrganizationHKCU\$ModuleBuilderName"
    $BuildScriptPath = (Get-ItemProperty $RegistryPath -Name 'BuildScriptPath' -ErrorAction Stop).BuildScriptPath
    $ModuleBuilderPath = (Get-ItemProperty $RegistryPath -Name 'ModuleBuilderPath' -ErrorAction Stop).ModuleBuilderPath
    $ModuleDevelopmentPath = (Get-ItemProperty $RegistryPath -Name 'ModuleDevelopmentPath' -ErrorAction Stop).ModuleDevelopmentPath
    if(-not(Test-Path -Path $ModuleBuilderPath -PathType Container)){ throw "Could not locate ModuleBuilder Path" }
    if(-not(Test-Path -Path $ModuleDevelopmentPath -PathType Container)){ throw "Could not locate Module Development Path" }
    if(-not(Test-Path -Path $BuildScriptPath -PathType Leaf)){ throw "Could not locate Build Script Path" }

    If( $PSBoundParameters.ContainsKey('Name') -eq $False ){
        $Name = (Get-Item $CurrentPath).Name
    }
        pushd $ModuleDevelopmentPath
        $FilteredDir = (gci . -Directory | where Name -match $Name)
        $FilteredDirCount = $FilteredDir.Count
        Write-Host "[$ModuleBuilderName] " -f DarkRed -NonewLine
        Write-Host "Module Id $Name is refering to $FilteredDirCount modules." -f DarkYellow  
        if($FilteredDirCount -eq 0){ return }
        ForEach($mdir in $FilteredDir){
            $fullname = $mdir.Fullname
            $mname = $mdir.Name
    
            Write-ChannelMessage "Switching to $fullname"
            pushd $fullname
            $gitstr = Get-GitRevision -r
            [string]$verstr = Get-Content "./Version.nfo"
           
            Write-ChannelMessage " Building $mname"
            Write-ChannelMessage "  Module Version ==> $verstr"
            Write-ChannelMessage "  GIT Revision   ==> $gitstr"
            #. "$BuildScriptPath" -Path "$fullname" -Documentation:$Documentation -Import:$Import -Deploy:$Deploy -Strict:$Strict
            . "$BuildScriptPath" -Path "$fullname" -Documentation:$Documentation -Import:$True -Deploy:$True -Strict:$Strict
            popd
        }
        popd
    
}catch{
    Write-Error $_
}
