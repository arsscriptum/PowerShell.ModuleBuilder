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
    [Parameter(Mandatory=$false,ValueFromPipeline=$true, 
        HelpMessage="Path of the module to compile, is not specified, takind current path") ]
    [String]$Path,
    [Parameter(Mandatory=$false,ValueFromPipeline=$true, 
        HelpMessage="Module Identifier, if not specified, the directory name is used") ]
    [String]$ModuleIdentifier,
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
        HelpMessage="Skip DependencyCheck") ]
    [Alias('nodep')]
    [switch]$SkipDependencyCheck,
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

#===============================================================================
# Root Path
#===============================================================================
$Global:ConsoleOutEnabled              = $true
$Global:CurrentRunningScript           = Get-Script basename
$Script:CurrPath                       = $ScriptPath
$Script:RootPath                       = (Get-Location).Path
If( $PSBoundParameters.ContainsKey('Path') -eq $True ){
    $Script:RootPath = $Path
}
If( $PSBoundParameters.ContainsKey('ModuleIdentifier') -eq $True ){
    $Global:ModuleIdentifier = $ModuleIdentifier
}else{
    $Global:ModuleIdentifier = (Get-Item $Script:RootPath).Name
}
#===============================================================================
# Script Variables
#===============================================================================
$Global:CurrentRunningScript           = Get-Script basename
$Script:Time                           = Get-Date
$Script:Date                           = $Time.GetDateTimeFormats()[19]
$Script:IncPath                        = Join-Path $Script:CurrPath "include"
$Script:Header                         = Join-Path $Script:IncPath  "Header.ps1"
$Script:BuilderConfig                  = Join-Path $Script:CurrPath "Config.ps1"
$Script:SourcePath                     = Join-Path $Script:RootPath "src"
$Script:BinariesPath                   = Join-Path $Script:RootPath "bin"
$Script:OutPath                        = Join-Path $Script:RootPath "out"
$Script:AssembliesPath                 = Join-Path $Script:RootPath "assemblies"
$Script:DocPath                        = Join-Path $Script:RootPath "doc"
$Script:OutputSourcePath               = Join-Path $Script:OutPath  "src"
$Script:OutputBinariesPath             = Join-Path $Script:OutPath  "bin"
$Script:DebugMode                      = $False
$Script:Compression                    = $True
$Script:Obfuscation                    = $False

If( $PSBoundParameters.ContainsKey('Debug') -eq $True ){
    $Script:DebugMode = $True 
    $Script:Compression = $False
    $Script:Obfuscation = $False
}

#===============================================================================
# Generated Manifest: Template from BUILDER directory. If present in module path
# use that one instead. This is to keep values, like GUID etc...
#===============================================================================
if(Test-Path -Path (Join-Path $Script:RootPath "templates") -PathType Container){
    $Script:TemplatePath = Join-Path $Script:RootPath "templates"
}else{
    $Script:TemplatePath = Join-Path $Script:CurrPath "templates"
}

$Script:ErrorsCount                    = 0
$Script:StepNumber                     = 0
$Script:TotalSteps                     = 100
$Script:ModuleManifestExtension        = '.psd1'
$Script:ModuleScriptExtension          = '.psm1'
$Script:ManifestFilename               = $Global:ModuleIdentifier + $Script:ModuleManifestExtension
$Script:ModuleScriptFilename           = $Global:ModuleIdentifier + $Script:ModuleScriptExtension
$Script:BuildConfigPath                = Join-Path $Script:RootPath "Config.ps1"
$Script:ModuleManifest                 = Join-Path $Script:CurrPath  $Script:ManifestFilename
$Script:ModuleScript                   = Join-Path $Script:CurrPath  $Script:ModuleScriptFilename
$Script:GeneratedModuleScript          = Join-Path $Script:OutPath  $Script:ModuleScriptFilename
$Script:GeneratedModuleManifest        = Join-Path $Script:OutPath  $Script:ManifestFilename
$Script:TemplateManifestPath           = Join-Path $Script:TemplatePath  'template-manifest.psd1'
$Script:FileContent                    = (Get-Content -Path $Script:Header -Encoding "windows-1251" -Raw)
$Script:FileContent                    = $FileContent -replace "___BUILDDATE___", $Script:Date
$Script:ScriptList                     = New-Object System.Collections.ArrayList
$Script:Psm1Content                    = "$FileContent`n`n#Requires -Version 5`nSet-StrictMode -Version 'Latest'`n"
$Script:VersionFile                    = Join-Path $Script:RootPath 'Version.nfo'

#===============================================================================
# Check Folders
#===============================================================================
if(-not(Test-Path -Path $Script:SourcePath -PathType Container)){
    Write-Host -f DarkRed "[ERROR] " -NoNewline
    Write-Host " + Missing SOURCE '$Script:SourcePath' (are you in a Module directory)" -f DarkGray
    return
}
if(-not(Test-Path -Path $Script:VersionFile -PathType Leaf)){
    Write-Host -f DarkRed "[ERROR] " -NoNewline
    Write-Host " + Missing Version File '$Script:VersionFile' (are you in a Module directory)" -f DarkGray
    return
}


#===============================================================================
# ExceptionDetails
#===============================================================================
function Show-ExceptionDetails{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.ErrorRecord]$Record,
        [Parameter(Mandatory=$false)]
        [switch]$ShowStack
    )       
    $formatstring = "{0}`n{1}"
    $fields = $Record.FullyQualifiedErrorId,$Record.Exception.ToString()
    $ExceptMsg=($formatstring -f $fields)
    $Stack=$Record.ScriptStackTrace
    Write-Host "`n[ERROR] -> " -NoNewLine -ForegroundColor DarkRed; 
    Write-Host "$ExceptMsg`n`n" -ForegroundColor DarkYellow
    if($ShowStack){
        Write-Host "--stack begin--" -ForegroundColor DarkGreen
        Write-Host "$Stack" -ForegroundColor Gray  
        Write-Host "--stack end--`n" -ForegroundColor DarkGreen       
    }
}  


#===============================================================================
# Check Config
#===============================================================================
if(Test-Path -Path $Script:BuildConfigPath){
    Write-Host -f DarkRed "[CONFIG] " -NoNewline
    Write-Host "Loading build config '$Script:BuildConfigPath'" -f DarkGray
    . "$Script:BuildConfigPath"
    Write-Host -f DarkGreen "[CONFIG] " -NoNewline
    Write-Host "Config Loaded!" -f DarkGray
}

Write-Host "===============================================================================" -f DarkRed
Write-Host "BUILDING  MODULE `t" -NoNewLine -f DarkYellow ; Write-Host "$Global:ModuleIdentifier" -f Gray 
Write-Host "MODULE DEVELOPER `t" -NoNewLine -f DarkYellow;  Write-Host "$ENV:Username" -f Gray 
#Write-Host "BUILD SCRIPT PATH`t" -NoNewLine -f DarkYellow;  Write-Host "$Script:CurrPath" -f Gray 
#Write-Host "MODUL SOURCE PATH`t" -NoNewLine -f DarkYellow;  Write-Host "$Script:RootPath" -f Gray 
#Write-Host "TEMPLATE MANIFEST`t" -NoNewLine -f DarkYellow;  Write-Host "$Script:TemplateManifestPath" -f Gray 
Write-Host "BUILD DATE       `t" -NoNewLine -f DarkYellow;  Write-Host "$Script:Date" -f Gray 
#Write-Host "OUTPUT MANIFEST  `t" -NoNewLine -f DarkYellow;  Write-Host "$Script:GeneratedModuleScript" -f Gray 
#Write-Host "OUTPUT SCRIPT    `t" -NoNewLine -f DarkYellow;  Write-Host "$Script:GeneratedModuleManifest" -f Gray 

if($Script:DebugMode){
    Write-Host "`t`t`t`t>>>>>> DEBUG MODE <<<<<<" -f DarkRed;
}
Write-Host "Compression       `t" -NoNewLine -f DarkYellow;  Write-Host "$Script:Compression" -f Gray 
Write-Host "Obfuscation       `t" -NoNewLine -f DarkYellow;  Write-Host "$Script:Obfuscation" -f Gray  
Write-Host "===============================================================================" -f DarkRed     

try{
    #===============================================================================
    # Paths
    #===============================================================================

    if(Test-Path -Path $Script:OutPath){
        Write-Host "[$Global:CurrentRunningScript] " -NoNewLine -f DarkYellow ;Write-Host "Deleting output path..." -f DarkGray;
        $null=Remove-Item -Path $Script:OutPath -Recurse -Force -ErrorAction Stop
    }
    $null=New-Item -Path $Script:OutPath -ItemType Directory -Force -ErrorAction Ignore
    Write-Host "[$Global:CurrentRunningScript] " -NoNewLine -f Yellow ;Write-Host "Create output path" -f DarkGray;


   
    #===============================================================================
    # Dependencies
    #===============================================================================
    $Script:BuildDependencies = @( Get-ChildItem -Path $Script:IncPath -Filter '*.ps1' )
    $Script:DependencyCount = $Script:BuildDependencies.Count

    Write-Host "[$Global:CurrentRunningScript] " -NoNewLine -f DarkYellow ;Write-Host "Importing build script dependencies from $Script:IncPath ($Script:DependencyCount)..." -f DarkYellow;

    #Dot source the files
    Foreach ($file in $Script:BuildDependencies) {
        Try {
            $Depname = (Get-Item -Path $file).Name

            . "$file"
            Write-Host -f Green "[OK] " -NoNewline
            Write-Host " + $Depname imported" -f DarkGray
        }  
        Catch {
            Write-Error -Message "Failed to import file $file $_"
        }
    }
    $ModuleName='CodeCastor.PowerShell.Core'
    Import-Module "$ModuleName" -ErrorAction Ignore 
    $ModPtr = Get-Module "$ModuleName" -ErrorAction Ignore    
    if(($ModPtr -eq $null) -Or ($Global:ModuleIdentifier -eq $ModuleName)){    
        . "$ENV:pwshtools\src\Exception.ps1"   
        . "$ENV:pwshtools\src\Module.ps1"
        . "$ENV:pwshtools\src\Miscellaneous.ps1"
        . "$ENV:pwshtools\src\Script.ps1"
        . "$ENV:pwshtools\src\Process.ps1"   
        . "$ENV:pwshtools\src\Parser.ps1"   
        . "$ENV:pwshtools\src\Directory.ps1"   
        . "$ENV:pwshtools\src\Converter.ps1"   
    }
    If( $PSBoundParameters.ContainsKey('SkipDependencyCheck') -eq $False ){
        Write-Host "===============================================================================" -f DarkRed
        Write-Host "CHECKING DEPENDENCIES" -f DarkYellow;
         Write-Host "$Script:BuilderConfig" -f DarkYellow;
        Write-Host "===============================================================================" -f DarkRed    
        $NumErrors = &"$Script:BuilderConfig"

        if($NumErrors -gt 0){
            throw "Dependency errors : $NumErrors"
        }
    }

    #$Script:EssentialFunctions = (Get-FunctionList $Script:IncPath).Name
    #$Script:EssentialFunctionCount = $Script:EssentialFunctions.Count
    #$DepCheckOk=Invoke-ValidateDependencies $Script:EssentialFunctions


    Invoke-UnloadModule $Global:ModuleIdentifier $Script:SourcePath

    Write-Host "===============================================================================" -f DarkRed
    Write-Host "GETTING MODULE VERSION" -f DarkYellow;
    Write-Host "===============================================================================" -f DarkRed    
    
    [string]$VersionString = '99.99.98'
    if(Test-Path $Script:VersionFile){
        [string]$VersionString = (Get-Content -Path $VersionFile -Raw)
    }else{
        throw "Missing Version File $Script:VersionFile"
    }
    [Version]$CurrentVersion = $VersionString
    [Version]$NewVersion = $VersionString
    $NewVersionBuild = $NewVersion.Build
    $NewVersionBuild++
    $NewVersion = New-Object -TypeName System.Version -ArgumentList $NewVersion.Major,$NewVersion.Minor,$NewVersionBuild
    [string]$NewVersionString = $NewVersion.ToString()
    Write-Host "Current`t$(($CurrentVersion).Major).$(($CurrentVersion).Minor).$(($CurrentVersion).Build)" -f Gray;
    Write-Host "NEW VER`t$NewVersionString" -f Gray;
 
    # We're going to add 1 to the revision value since a new commit has been merged to Master
    # This means that the major / minor / build values will be consistent across GitHub and the Gallery


    # This is where the module manifest lives
    if($Strict){
        Write-Host "===============================================================================" -f DarkRed
        Write-Host "VALIDATING FUNCTION NAMES" -f DarkYellow;
        Write-Host "===============================================================================" -f DarkRed  
        $NumErrors = CheckFunctionVerbs $SourcePath  
        if(($StrictNames= $true) -And ($NumErrors -ne 0)){
            throw "INVALID FUNCTION NAMES: $NumErrors"
        }   
    }

    Write-Host "===============================================================================" -f DarkRed
    Write-Host "UPDATING MANIFEST" -f DarkYellow;
    Write-Host "===============================================================================" -f DarkRed       
    Log-String "Updating Module Manifest"
    Log-String "$TemplateManifestPath ==> $GeneratedModuleManifest"
    Remove-Item -Path $GeneratedModuleManifest -Force -ErrorAction Ignore | Out-null
    Copy-Item $TemplateManifestPath $GeneratedModuleManifest
    # Start by importing the manifest to determine the version, then add 1 to the revision
    (Get-Content -Path $GeneratedModuleManifest) -replace '___SCRIPT_MODULE_FILENAME___', $Global:ModuleIdentifier | Set-Content -Path $GeneratedModuleManifest -Force

    (Get-Content -Path $GeneratedModuleManifest) -replace '___DATE___', $Date | Set-Content -Path $GeneratedModuleManifest -Force
    $ExportedFunctionDecl = Get-ExportedFunctionsDecl $SourcePath
    if(($ExportedFunctionDecl -eq $null) -Or ($ExportedFunctionDecl.Count -eq 0)){
        throw "NO FUNCTIONS TO EXPORT"
    }

    Log-String "Updating Exported Functions List from [$SourcePath]"
    (Get-Content -Path $GeneratedModuleManifest) -replace '___FUNCTION_TO_EXPORT_ANCHOR___', "$ExportedFunctionDecl" | Set-Content -Path $GeneratedModuleManifest -Force

    $ExportedFilesDecl = Get-ExportedFilesDecl $SourcePath
    Log-String "Updating Exported Files List from [$SourcePath]"
    #(Get-Content -Path $GeneratedModuleManifest) -replace '___FILE_LIST_ANCHOR___', "$ExportedFilesDecl" | Set-Content -Path $GeneratedModuleManifest -Force
    (Get-Content -Path $GeneratedModuleManifest) -replace '___FILE_LIST_ANCHOR___', "FileList = @()" | Set-Content -Path $GeneratedModuleManifest -Force

    $ExportedAliasesDecl = Get-ExportedAliassDecl $SourcePath
    Log-String "Updating Exported Aliases List from [$SourcePath]"
    (Get-Content -Path $GeneratedModuleManifest) -replace '___ALIASES_TO_EXPORT_ANCHOR___', "$ExportedAliasesDecl" | Set-Content -Path $GeneratedModuleManifest -Force

    [string]$NewGuid = (New-Guid).Guid
    Log-String "Updating GUID [$NewGuid]"
    (Get-Content -Path $GeneratedModuleManifest) -replace '___MODULE_GUID___', "$NewGuid" | Set-Content -Path $GeneratedModuleManifest -Force
   
    [string]$NewDescription = $Info.Description
    Log-String "Updating Description [$NewDescription]"
    (Get-Content -Path $GeneratedModuleManifest) -replace '___MODULE_DESCRIPTION___', "$NewDescription" | Set-Content -Path $GeneratedModuleManifest -Force

    Log-String "Updating Version [$NewVersionString]"
    (Get-Content -Path $GeneratedModuleManifest) -replace '___MODULE_VERSION___', "$NewVersionString" | Set-Content -Path $GeneratedModuleManifest -Force

    if(Test-Path -Path $Script:AssembliesPath -PathType Container){
        $RequiredAssemblies =  Get-AssembliesDecl $Script:AssembliesPath  
        Log-String "Updating REQUIRED ASSEMBLIES"
        (Get-Content -Path $GeneratedModuleManifest) -replace '___REQUIRED_ASSEMBLIES_ANCHOR___', "$RequiredAssemblies" | Set-Content -Path $GeneratedModuleManifest -Force
    }else{
        (Get-Content -Path $GeneratedModuleManifest) -replace '___REQUIRED_ASSEMBLIES_ANCHOR___', "RequiredAssemblies = @()" | Set-Content -Path $GeneratedModuleManifest -Force   
    }

    Log-String "Updating Module Identifier [$Global:ModuleIdentifier]"
    (Get-Content -Path $GeneratedModuleManifest) -replace '___MODULE_IDENTIFIER___', "$Global:ModuleIdentifier" | Set-Content -Path $GeneratedModuleManifest -Force
   

    $Script:HeadRev =  git rev-parse HEAD
    Log-String "Updating GIT REVISION [$Script:HeadRev]"
    (Get-Content -Path $GeneratedModuleManifest) -replace '___GIT_REV_PARSE___', "$Script:HeadRev" | Set-Content -Path $GeneratedModuleManifest -Force
   

Invoke-UnloadModule $Global:ModuleIdentifier $Script:SourcePath
Write-Host "===============================================================================" -f DarkRed
Write-Host "COMPILING SCRIPT FILE" -f DarkYellow;
Write-Host "===============================================================================" -f DarkRed

$Script:CompilationErrorsCount = 0
$Script:CompilationLoadTest = $True

Get-ChildItem -Path "$Script:SourcePath" -File -Filter '*.ps1' | ForEach-Object {
    $Path = $_.fullname
    $Filename = $_.Name
    $Basename = (Get-Item -Path $Path).Basename
    $ScriptName = $Basename

    $BadCharsStr = '-'
    $BadChars = $BadCharsStr.ToCharArray()
    $BadChars | % {
        if($ScriptName -match "$_"){ throw "File name '$ScriptName' contains an invalid character '$_'" }
    }

    try {
        if($Script:CompilationLoadTest){
            try{
                . $Path
                Write-Host -ForegroundColor DarkGreen "[OK] " -NoNewline
                Write-Host "script $Filename is OK"    
            }catch [Exception]{
                Show-ExceptionDetails($_) -ShowStack
                Write-Host -ForegroundColor DarkRed "[ERROR] " -NoNewline
                $a=Read-Host -Prompt "script $Filename has an error. Continue building (y/N)?" ; if($a -notmatch "y") {return;}
            }
        
        }

        [void] $ScriptList.Add($Basename)

        # Read script block from module file
        [string]$ScriptBlock = Get-Content -Path $Path -Raw

        # Strip out comments
        $ScriptBlock = Remove-CommentsFromScriptBlock -ScriptBlock $ScriptBlock

        # Compress and Base64 encode script block
        $ScriptBlockBase64 = Convert-ToBase64CompressedScriptBlock -ScriptBlock $ScriptBlock

        $Psm1Content += "# ------------------------------------`n"
        $Psm1Content += "# Script file - $ScriptName - `n"
        $Psm1Content += "# ------------------------------------`n"
        $Psm1Content += "`$ScriptBlock$($ScriptName) = `"$($ScriptBlockBase64)`"`n`n"
    }catch { 
        Show-ExceptionDetails($_) -ShowStack
        $Script:CompilationErrorsCount += 1
    }
}

# if no error, write the loader
if ($Script:CompilationErrorsCount -ne 0){
    Write-Host '[COMPILATION] ' -f DarkRed -NoNewLine
    Write-Host "$Script:CompilationErrorsCount errors" -f Yellow  
    throw "$Script:CompilationErrorsCount errors"
    return 
}

$LoaderBlock = ''
if ($Script:DebugMode -ne $True) {
    $LoaderBlock = @"
# ------------------------------------`
# Loader
# ------------------------------------
function ConvertFrom-Base64CompressedScriptBlock {

    [CmdletBinding()] param(
        [String]
        `$ScriptBlock
    )

    # Take my B64 string and do a Base64 to Byte array conversion of compressed data
    `$ScriptBlockCompressed = [System.Convert]::FromBase64String(`$ScriptBlock)

    # Then decompress script's data
    `$InputStream = New-Object System.IO.MemoryStream(, `$ScriptBlockCompressed)
    `$GzipStream = New-Object System.IO.Compression.GzipStream `$InputStream, ([System.IO.Compression.CompressionMode]::Decompress)
    `$StreamReader = New-Object System.IO.StreamReader(`$GzipStream)
    `$ScriptBlockDecompressed = `$StreamReader.ReadToEnd()
    # And close the streams
    `$GzipStream.Close()
    `$InputStream.Close()

    `$ScriptBlockDecompressed
}

# For each scripts in the module, decompress and load it.

`$ScriptList = @($( ($ScriptList | ForEach-Object { "'$_'" }) -join ','))
`$ScriptList | ForEach-Object {
    `$ScriptId = `$_
     `$ScriptBlock = `"```$ScriptBlock`$(`$ScriptId)`" | Invoke-Expression
    `$ClearScript = ConvertFrom-Base64CompressedScriptBlock -ScriptBlock `$ScriptBlock
    try{
        `$ClearScript | Invoke-Expression
    }catch{
        Write-Host `"===============================`" -f DarkGray
        Write-Host `"`$ClearScript`" -f DarkGray
        Write-Host `"===============================`" -f DarkGray
        Write-Error `"ERROR IN script `$ScriptId . Details `$_`"
    }
}


"@

    $Psm1Content += "`n`n$($LoaderBlock)`n`n"
}else{
    $LoaderBlock = @"
# ------------------------------------`
# DEBUG MODE : SOURCE ARE CLEAR 
# NOT COMPRESSED
# ------------------------------------

# ------------------------------------`
# Source paths
# ------------------------------------
[array]`$paths = @(
    'src',
    'public'
)
# ------------------------------------`
# DOT SOURCE the scripts paths
# ------------------------------------
foreach (`$path in `$paths) {
    if(-not (Test-Path `$path)){ continue }
    "`$(Split-Path -Path `$MyInvocation.MyCommand.Path)\`$path\*.ps1" |
    Resolve-Path |
    ForEach-Object  { . `$_.ProviderPath }
}


"@

    $Psm1Content = "`n`n$($LoaderBlock)`n`n"
}

# If no error, write the script to the file
if ($Script:CompilationErrorsCount -eq 0) {

    Write-Host -ForegroundColor DarkGreen "[OK] " -NoNewline
    Write-Host "Build complete!"

    $Psm1Content | Out-File -FilePath $Script:GeneratedModuleScript -Encoding "windows-1251"
    Write-Host -ForegroundColor DarkGreen "[OK] " -NoNewline
    Write-Host "Script written to file $Script:GeneratedModuleScript"
}

if($Script:DebugMode){
    New-Item -Path $Script:OutputSourcePath -Force -ItemType Directory -ErrorAction Ignore | Out-null
    Sync-Directories $SourcePath $Script:OutputSourcePath -SyncType 'MIRROR' -Log $Logfile
    Write-Host -ForegroundColor DarkGreen "[OK] " -NoNewline
    Write-Host "DEBUG MODE! Source copied to $Script:OutputSourcePath"
}
if($Deploy){
    Sleep 1
    $RegistryPath = "$ENV:OrganizationHKCU\powershell"
    $DefaultModulePath = Get-RegistryValue $RegistryPath "DefaultModulePath"

    if ($PSBoundParameters.ContainsKey('DeployPath')) { 
        Log-String "USER-SPECIFIED DEPLOY PATH [$DeployPath]"
        $DefaultModulePath = $DeployPath
    }

    if(-not(Test-Path $DefaultModulePath -PathType Container)){ throw "DefaultModulePath ERROR" }
    $ExportedModulePath = Join-Path $DefaultModulePath $Global:ModuleIdentifier
    Write-Host "===============================================================================" -f DarkRed
    Write-Host "DEPLOYING MODULE to $ExportedModulePath" -f DarkYellow;
    Write-Host "===============================================================================" -f DarkRed    
    $Logfile = (New-TemporaryFile).Fullname
    $null=Remove-Item -Path $Logfile -Force -ErrorAction Ignore

    $null=Remove-Item -Path $ExportedModulePath -Recurse -Force -ErrorAction Ignore
    $null=New-Item -Path $ExportedModulePath -ItemType Directory -Force -ErrorAction Ignore
    Copy-Item $GeneratedModuleManifest $ExportedModulePath
    Copy-Item $GeneratedModuleScript $ExportedModulePath
    if(-not(Test-Path $ExportedModulePath -PathType Container)){ throw "DEPLOY ERROR" }
    if(-not(Test-Path $GeneratedModuleManifest -PathType Leaf)){ throw "DEPLOY ERROR" }
    if(-not(Test-Path $GeneratedModuleScript -PathType Leaf)){ throw "DEPLOY ERROR" }

    ForEach($file in (gci $ExportedModulePath -File)){
        Write-Host '[OK] ' -f DarkGreen -NoNewLine
        Write-Host "deploy file ==> $file" -f Gray
    }
    if(Test-Path -Path $Script:BinariesPath -PathType Container){
        $ExportedBinariesPath = Join-Path $ExportedModulePath 'bin'
        New-Item -Path $ExportedBinariesPath -Force -ItemType Directory -ErrorAction Ignore | Out-null
        Sync-Directories $BinariesPath $ExportedBinariesPath -SyncType 'MIRROR' -Log $Logfile
        Write-Host -ForegroundColor Cyan "[SYNC] " -NoNewline
        Write-Host "BINARIES ==> $ExportedBinariesPath"
        $Exported = (gci -Path $ExportedBinariesPath -File -ErrorAction Ignore)
        if($Exported -ne $Null){$Exported.ForEach({ $f = ''; Write-Host -n -f DarkGreen "[OK] ";Write-Host "$f"; })}
    }
    if(Test-Path -Path $Script:AssembliesPath -PathType Container){
        $ExportedAssembliesPath = Join-Path $ExportedModulePath 'assemblies'
        New-Item -Path $ExportedAssembliesPath -Force -ItemType Directory -ErrorAction Ignore | Out-null
        Sync-Directories $AssembliesPath $ExportedAssembliesPath -SyncType 'MIRROR' -Log $Logfile
        Write-Host -ForegroundColor Cyan "[SYNC] " -NoNewline
        Write-Host "ASSEMBLIES ==> $Script:AssembliesPath"
        $Exported = (gci -Path $ExportedAssembliesPath -File -ErrorAction Ignore)
        if($Exported -ne $Null){$Exported.ForEach({ $f = ''; Write-Host -n -f DarkGreen "[OK] ";Write-Host "$f"; })}
    }
}



if($Documentation){
    
    Write-Host "===============================================================================" -f DarkRed
    Write-Host "BUILDING DOCUMENTATION" -f DarkYellow;
    Write-Host "===============================================================================" -f DarkRed
    $CmdPtr = get-command -Name 'New-MarkdownHelp'
    $ModPtr = Get-Module -Name 'platyPS'
    if(($CmdPtr -eq $null) -Or ($ModPtr -eq $null)){
        Log-String "" -IsNotification
    }
    Log-String "LOAD MODULE BEFORE Building new function documentation"
    Invoke-LoadModule $Global:ModuleIdentifier $Script:SourcePath -Global
    Log-String "Building new function documentation"
    
    Write-Host '[GENERATE DOCUMENTATION] ' -f DarkCyan -NoNewLine
    Write-Host "Markdown Documentation for $Global:ModuleIdentifier ==> $Script:DocPath" -f Gray

    New-MarkdownHelp -Module $Global:ModuleIdentifier -OutputFolder "$Script:DocPath" -Force | Out-null
    # $xplorer=(Get-command explorer.exe).Source
    # &$xplorer $Script:DocPath
    New-ExternalHelp -Path $Script:DocPath -OutputPath "$Script:DocPath\help\en-US\" -Force
    if(Test-Path -Path '.\docs.ps1'){
        . .\docs.ps1
    }    

    Invoke-UnloadModule $Global:ModuleIdentifier $Script:SourcePath
}       

if($Import){
    Write-Host "===============================================================================" -f DarkRed
    Write-Host "IMPORTING MODULE" -f DarkYellow;
    Write-Host "===============================================================================" -f DarkRed
    #Invoke-UnloadModule $Global:ModuleIdentifier $Script:SourcePath
    Remove-Module $Global:ModuleIdentifier -force  -ErrorAction Ignore
    Import-Module $Global:ModuleIdentifier  -Force -ErrorAction Ignore
    return
    Write-Host "SourcePath ==> $Script:SourcePath"
    $FuncList=(Get-FunctionList $Script:SourcePath)
    if($FuncList){
        $FuncListCount=$FuncList.Count
        if($FuncListCount -gt 0){
            $FuncNameList = $FuncList
            $DepCheckOk=Invoke-ValidateDependencies $FuncNameList      
        }
        
    }
    
}

}Catch {
    Write-Error -Message "Build Failure"
    Show-ExceptionDetails($_) -ShowStack
    return
}