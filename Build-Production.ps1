<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜 
#̷𝓍   
#̷𝓍   PowerShell.ModuleBuilder
#̷𝓍 
#̷𝓍   <guillaumeplante.qc@gmail.com>
#̷𝓍   https://arsscriptum.github.io/
#>


<#
.SYNOPSIS
    A simple Powershell script build the module files.

.DESCRIPTION
    Build a module completely for production

.PARAMETER Path
    Path of the module to compile, is not specified, takind current path

.EXAMPLE
    -
    Runs without any parameters. Uses all the default values/settings
    >> ./Build.ps1
    -

    -
#>


#===============================================================================
# Commandlet Binding
#===============================================================================
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true, HelpMessage="Module name")]
    [Alias('n','m','id')] [string] $Name,
    [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
    [switch]$Test
    )
#Requires -Version 5


function Get-Script([string]$prop){
    $ThisFile = $script:MyInvocation.MyCommand.Path
    return ((Get-Item $ThisFile)|select $prop).$prop
}

$ScriptPath = split-path $script:MyInvocation.MyCommand.Path
$ScriptFullName =(Get-Item -Path $script:MyInvocation.MyCommand.Path).DirectoryName

$ModuleBuilder = Join-Path $ScriptPath "Build-Module.ps1"
if(-not(Test-Path $ModuleBuilder)) { Write-Error "Missing Module Builder at $ModuleBuilder" }
$CurrentPath = (Get-Location).Path
If( $PSBoundParameters.ContainsKey('Name') -eq $False ){
    $Name = (Get-Item $CurrentPath).Name
}

Clear-Host
Write-Host "`n`n`n"
Write-Host "========================================================================================================================" -f DarkGreen
Write-Host "                                           ===  BUILD MODULE PRODUCTION  ===                                            " -f DarkCyan;
Write-Host "========================================================================================================================" -f DarkGreen

if($Test){
    Write-Host "-------------------------------------------------------------------------------" -f DarkYellow
    Write-Host " Will Run " -f Red
    Write-Host ". `"$ModuleBuilder`"  $Name  -Import -Documentation -Publish" -f DarkRed
    Write-Host "-------------------------------------------------------------------------------" -f DarkYellow
}else{
    . "$ModuleBuilder" $Name -Import -Documentation -Publish
}


