<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜 
#̷𝓍   
#̷𝓍   PowerShell.ModuleBuilder
#̷𝓍 
#̷𝓍   <guillaumeplante.qc@gmail.com>
#̷𝓍   https://arsscriptum.github.io/
#>


[CmdletBinding(SupportsShouldProcess)]
param (
      [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
      [switch]$Quiet,
      [Parameter(Mandatory=$false,ValueFromPipeline=$true)]
      [switch]$Alias
    )



function write-slog {

    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(Mandatory=$true,Position=0)]     
        [string]$Message
    )
    Write-Host -n -f DarkCyan "[i] "
    Write-Host -f Cyan "$Message"  
}

function Get-ModuleBuilderRoot{
    [CmdletBinding(SupportsShouldProcess)] param()

    $TmpPath = (Get-Item $Profile).DirectoryName
    $TmpPath = Join-Path $TmpPath 'Projects\PowerShell.ModuleBuilder'
    if(Test-Path $TmpPath -PathType Container){
        $ModuleBuilder = $TmpPath
        Write-Verbose "[GetModuleBuilderRoot] Get-Item Profile, DirectoryName"
        Write-Verbose "[GetModuleBuilderRoot] $ModuleBuilder"
        return $ModuleBuilder
    }
    
    $mydocuments = [environment]::getfolderpath("mydocuments") 
    $ModuleBuilder = Join-Path $mydocuments 'PowerShell\Projects\PowerShell.ModuleBuilder'
    if(Test-Path $ModuleBuilder -PathType Container){
        Write-Verbose "[GetModuleBuilderRoot] getfolderpath, mydocuments"
        Write-Verbose "[GetModuleBuilderRoot] $ModuleBuilder"        
        return $ModuleBuilder
    }
    Write-Verbose "[GetModuleBuilderRoot] ENV:PSModuleBuilder"      
    return $ENV:PSModuleBuilder
}


function Get-PSModuleDevelopmentRoot{

    if($ENV:PSModuleDevelopmentRoot -ne $Null){
        if(Test-Path $ENV:PSModuleDevelopmentRoot -PathType Container){
            $PSModuleDevelopmentRoot = $ENV:PSModuleDevelopmentRoot
            return $PSModuleDevelopmentRoot
        }
    }else{
        $TmpPath = (Get-Item $Profile).DirectoryName
        $TmpPath = Join-Path $TmpPath 'Module-Development'
        if(Test-Path $TmpPath -PathType Container){
            $PSModuleDevelopmentRoot = $TmpPath
            return $PSModuleDevelopmentRoot
        }

    }
    $mydocuments = [environment]::getfolderpath("mydocuments") 
    $PSModuleDevelopmentRoot = Join-Path $mydocuments 'PowerShell\Module-Development'
    return $PSModuleDevelopmentRoot
}


#===============================================================================
# OrganizationHKCU
#===============================================================================
if( ($ENV:OrganizationHKCU -eq $null) -Or ($ENV:OrganizationHKCU -eq '') )
{
    Write-Host "===============================================================================" -f DarkRed    
    Write-Host "A required environment variable needs to be setup (user scope)     `t" -NoNewLine -f DarkYellow ; Write-Host "$Script:OrganizationHKCU" -f Gray 
    $OrgIdentifier = "Development-" + "$ENV:USERNAME"
    $OrganizationHKCU = "HKCU:\Software\" + "$OrgIdentifier"

    [Environment]::SetEnvironmentVariable('OrganizationHKCU',$OrganizationHKCU,"User")

    Write-Host "Setting OrganizationHKCU --> $OrganizationHKCU [User]"  -ForegroundColor Yellow
    $Null = New-Item -Path "$OrganizationHKCU" -Force -ErrorAction Ignore

    $Cmd = Get-Command "RefreshEnv.cmd"
    if($Cmd){
        $RefreshEnv = $Cmd.Source
        &"$RefreshEnv"
    }

    $ENV:OrganizationHKCU = "$OrganizationHKCU"

}

$Name = $script:MyInvocation.MyCommand.Name
$i = $Name.IndexOf('.')
$Script:CurrentScript = $Name.SubString(0, $i)
$Script:CurrPath=$PSScriptRoot #Split-Path $script:MyInvocation.MyCommand.Path


#===============================================================================
# Script Variables
#===============================================================================
$Script:CurrentRunningScript           = $Script:CurrentScript
$Script:Time                           = Get-Date
$Script:Date                           = $Time.GetDateTimeFormats()[19]

Write-Host "===============================================================================" -f DarkRed
Write-Host "CONFIGURATION of DEVELOPMENT ENVIRONMENT for MODULE BUILDER" -f DarkYellow;
Write-Host "===============================================================================" -f DarkRed    
Write-Host "Current Path     `t" -NoNewLine -f DarkYellow ; Write-Host "$Script:CurrPath" -f Gray 
Write-Host "Current Script   `t" -NoNewLine -f DarkYellow;  Write-Host "$Script:CurrentScript" -f Gray 

Write-Host "Setting PSModuleBuilder to `t" -NoNewLine -f DarkYellow;  Write-Host "$Script:CurrPath" -f Gray 
[Environment]::SetEnvironmentVariable('PSModuleBuilder',$Script:CurrPath,"User")


#===============================================================================
# ModuleBuilderRoot Variable
#===============================================================================





$DisplayName = 'PowerShell.ModuleBuilder'
$RegistryPath = "$ENV:OrganizationHKCU\$DisplayName"
 Write-Host "[$DisplayName] " -f Blue -NonewLin
 Write-Host " $RegistryPath" -f White

$ModuleBuilderPath = Get-ModuleBuilderRoot
$ModuleDevelopmentPath =  Get-PSModuleDevelopmentRoot
$BuildScript = Join-Path $ModuleBuilderPath 'Build.ps1'
$BuildModuleScript = Join-Path $ModuleBuilderPath 'Build-Module.ps1'
$BuildProductionScript = Join-Path $ModuleBuilderPath 'Build-Production.ps1'
$BuildTestScript = Join-Path $ModuleBuilderPath 'Build-Test.ps1'
try{
    if($Quiet -eq $False){
        Write-Host "[$DisplayName] " -f Blue -NonewLine
        Write-Host "configuring registry values" -f White
    }

    write-slog "Remove-Item $RegistryPath"
    Remove-Item $RegistryPath -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
    write-slog "New-Item $RegistryPath"
    New-Item $RegistryPath -Force  -ErrorAction SilentlyContinue | Out-Null
    $Added_BuildScriptPath =(New-ItemProperty $RegistryPath -Name 'BuildScriptPath' -Value  "$BuildScript"  -ErrorAction SilentlyContinue).BuildScriptPath
    #if($Added_BuildScriptPath -ne $BuildScriptPath) { throw "BAD REGISTRY VALUE $Added_BuildScriptPath"; }
    $Added_ModuleBuilderPath = (New-ItemProperty $RegistryPath -Name 'ModuleBuilderPath' -Value  "$ModuleBuilderPath"  -ErrorAction SilentlyContinue).ModuleBuilderPath
    #if($Added_ModuleBuilderPath -ne $ModuleBuilderPath) { throw "BAD REGISTRY VALUE $Added_ModuleBuilderPath"; }    
    $Added_BuildModuleScript = (New-ItemProperty $RegistryPath -Name 'BuildModuleScript' -Value  "$BuildModuleScript"  -ErrorAction SilentlyContinue ).BuildModuleScript
    #if($Added_BuildModuleScript -ne $BuildModuleScript) { throw "BAD REGISTRY VALUE $Added_BuildModuleScript"; }
    $Added_ModuleDevelopmentPath = (New-ItemProperty $RegistryPath -Name 'ModuleDevelopmentPath' -Value  "$ModuleDevelopmentPath"  -ErrorAction SilentlyContinue).ModuleDevelopmentPath
    #if($Added_ModuleDevelopmentPath -ne $ModuleDevelopmentPath) { throw "BAD REGISTRY VALUE $Added_ModuleDevelopmentPath"; }
}catch{
    Write-Host "[error] " -f DarkRed -NonewLine
    Write-Host "$_" -f DarkYellow    
}


if($Quiet -eq $False){
    Write-Host "[$DisplayName] " -f DarkRed -NonewLine
    Write-Host " BuildScriptPath`t==>`t$BuildScript" -f DarkYellow
    Write-Host "[$DisplayName] " -f DarkRed -NonewLine
    Write-Host "  ModuleBuilder`t==>`t$ModuleBuilderPath" -f DarkYellow
    Write-Host "[$DisplayName] " -f DarkRed -NonewLine
    Write-Host " DevelopmentPath`t==>`t$ModuleDevelopmentPath" -f DarkYellow
}


if($Alias){
    if($Quiet -eq $False){
        Write-Host "[$DisplayName] "  -f Blue -NonewLine
        Write-Host "configuring alias values" -f White    
    }

    # ========================================================================
    # make
    # ========================================================================

    Remove-Alias -Name make -Force -ErrorAction Ignore| Out-null
    if(Test-Path -Path $BuildScript -PathType Leaf){
        if($Quiet -eq $False){
            Write-Host "[$DisplayName] " -f DarkRed -NonewLine
            Write-Host "`tmake`t`t==>`t$BuildScript" -f DarkYellow
        }
        New-Alias -Name make -Value "$BuildScript" -Description 'Build a module' -Scope Global -ErrorAction Ignore -Force
    }

    
    # ========================================================================
    # makeall
    # ========================================================================

    Remove-Alias -Name makeall -Force -ErrorAction Ignore| Out-null
    if(Test-Path -Path $BuildModuleScript -PathType Leaf){
        if($Quiet -eq $False){
            Write-Host "[$DisplayName] " -f DarkRed -NonewLine
            Write-Host "`tmakeall`t`t==>`t$BuildModuleScript" -f DarkYellow
        }
        New-Alias -Name makeall -Value "$BuildModuleScript" -Description 'Build a module' -Scope Global -ErrorAction Ignore -Force
    }    

    # ========================================================================
    # maketest
    # ========================================================================

    Remove-Alias -Name maketest -Force -ErrorAction Ignore | Out-null
    if(Test-Path -Path $BuildTestScript -PathType Leaf){
        if($Quiet -eq $False){
            Write-Host "[$DisplayName] " -f DarkRed -NonewLine
            Write-Host "`maketest`t`t==>`t$BuildTestScript" -f DarkYellow
        }
        New-Alias -Name maketest -Value "$BuildTestScript" -Description 'Build a module' -Scope Global -ErrorAction Ignore -Force
    }

    # ========================================================================
    # makeprod
    # ========================================================================

    Remove-Alias -Name makeprod -Force -ErrorAction Ignore | Out-null
    if(Test-Path -Path $BuildProductionScript -PathType Leaf){
        if($Quiet -eq $False){
            Write-Host "[$DisplayName] " -f DarkRed -NonewLine
            Write-Host "`makeprod`t`t==>`t$BuildProductionScript" -f DarkYellow
        }
        New-Alias -Name makeprod -Value "$BuildProductionScript" -Description 'Build a PROD module' -Scope Global -ErrorAction Ignore -Force
    }

    if($Quiet -eq $False){
        Write-Host "`n`n[$DisplayName] " -f DarkRed -NonewLine
        Write-Host " To build a module, type 'make' or 'makeall'. Optionally Use -Import -Deploy" -f DarkYellow 
    }
}