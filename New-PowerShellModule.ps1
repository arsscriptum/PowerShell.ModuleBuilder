<#
#̷\   ⼕龱ᗪ㠪⼕闩丂ㄒ龱尺 ᗪ㠪ᐯ㠪㇄龱尸爪㠪𝓝ㄒ
#̷\   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇨​​​​​🇴​​​​​🇩​​​​​🇪​​​​​🇨​​​​​🇦​​​​​🇸​​​​​🇹​​​​​🇴​​​​​🇷​​​​​@🇮​​​​​🇨​​​​​🇱​​​​​🇴​​​​​🇺​​​​​🇩​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>


<#
.SYNOPSIS
    Create a PowerShell Module structure ready to receive your amazing ideas.

.DESCRIPTION
    Create a PowerShell Module structure ready to receive your amazing ideas.
    It will use the template module in the template directory.

.PARAMETER Path
    Path of the module to compile, is not specified, takind current path
.PARAMETER ModuleIdentifier
    Module Identifier, if not specified, the directory name is used
.PARAMETER NoCompile
    Do not co,pile qfter creqtion
.PARAMETER Verbose
    FLAG: For Debug purposes. Output LOTS of logs

.EXAMPLE
    -
    Create a Module in 'c:\ModPath' (note that a folder will be created in 'c:\ModPath' ==> 'c:\ModPath\MySuperModuleToRuleThemAll')
    >> ./NewPowerShellModule.ps1 -Name 'MySuperModuleToRuleThemAll' -Path 'c:\ModPath'
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
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false,ValueFromPipeline=$true, 
        HelpMessage="Module Identifier, if not specified, the directory name is used") ]
    $ModuleIdentifier,
    [switch]$NoCompile

)






#Requires -Version 5

Try {

    if(Test-Path -Path $Path -PathType Container){
        throw "Folder $Path already exists... Use a new folder name."
        return
    }
    if(-not(Test-Path -Path $Path)){
        $Null = New-Item -Path $Path -ItemType Directory -Force -ErrorAction Ignore
    }



    $Path  = (Resolve-Path $Path).Path

    ## Set the script execution policy for this process
    Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}
    
    ##*===============================================
    ##* VARIABLE DECLARATION
    ##*===============================================
    
    function Get-Script([string]$prop){
        $ThisFile = $script:MyInvocation.MyCommand.Path
        return ((Get-Item $ThisFile)|select $prop).$prop
    }

    $ScriptPath = split-path $script:MyInvocation.MyCommand.Path
    $ScriptFullName =(Get-Item -Path $script:MyInvocation.MyCommand.Path).DirectoryName

    $CreateDirectory = $True
    #===============================================================================
    # Root Path
    #===============================================================================
    $Global:ConsoleOutEnabled              = $true
    $Global:CurrentRunningScript           = Get-Script basename
    $Script:CurrPath                       = $ScriptPath
    $Script:RootPath                       = (Get-Location).Path
    $Script:ModulePath                     = $Path
    if($CreateDirectory){
        $Script:ModulePath                 = Join-Path $Path $ModuleIdentifier
    }
    
    $Script:TemplatePath                   = Join-Path $Script:RootPath "templates"
    $Script:TemplateModulePath             = Join-Path $Script:RootPath "templates\template-module"
    $Script:ModuleSource                   = Join-Path $Script:TemplateModulePath "Template_New-Function.ps1"

    if(-not(Test-Path $Script:TemplateModulePath -PathType Container)){
        throw "Folder $Script:TemplatePath not found... You need a template folder"
        return
    }
    if(Test-Path $Script:ModulePath -PathType Container){
        #throw "Folder $Script:ModulePath already exists! Make sure you remove previous work, this will not overwrite"
        write-host "WARNING" -f Red  -NoNewLine ; $a=Read-Host -Prompt " Overwriting $Script:ModulePath! Are you sure (y/N)?" ; if($a -notmatch "y") {return;}
    
        Remove-Item $Script:ModulePath -Force -Recurse
    
    }

    New-Item -Path $Script:ModulePath -ItemType Directory -Force -ErrorAction Ignore | out-null


    Write-Host "===============================================================================" -f DarkRed
    Write-Host "NEW POWERSHELL MODULE `t" -NoNewLine -f DarkYellow ; Write-Host "$Global:ModuleIdentifier" -f Gray 
    Write-Host "MODULE DEVELOPER `t" -NoNewLine -f DarkYellow;  Write-Host "$ENV:Username" -f Gray 
    Write-Host "MODULE PATH      `t" -NoNewLine -f DarkYellow;  Write-Host "$Script:ModulePath" -f Gray 
    Write-Host "BUILD DATE       `t" -NoNewLine -f DarkYellow;  Write-Host "$Script:Date" -f Gray 


    


    $ROBOCOPY = (Get-Command 'robocopy.exe').Source
    Write-Host '[COPY] ' -f DarkCyan -NoNewLine
    Write-Host "$Script:TemplateModulePath ==> $Script:ModulePath" -f Gray
    
    Copy-Item "$Script:TemplateModulePath\*" "$Script:ModulePath" -Force -Recurse

    #$Out = &"$ROBOCOPY" "`"$TemplateModulePath`"" "`"$ModulePath`"" "/MIR"

    if($NoCompile -eq $False){
        pushd "$ModulePath"
        make
        popd   
    }
    $Explorer = (Get-Command 'explorer.exe').Source
    &"$Explorer" $ModulePath


    Write-Host "`n[DONE]" -f DarkGreen -NoNewLine
    Write-Host "Module Successfully Created! ue 'make' to build" -f Gray
    
}
Catch {
    Write-Error "$_"
}

