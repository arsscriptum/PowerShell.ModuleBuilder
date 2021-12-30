<#
#̷\   ⼕龱ᗪ㠪⼕闩丂ㄒ龱尺 ᗪ㠪ᐯ㠪㇄龱尸爪㠪𝓝ㄒ
#̷\   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇨​​​​​🇴​​​​​🇩​​​​​🇪​​​​​🇨​​​​​🇦​​​​​🇸​​​​​🇹​​​​​🇴​​​​​🇷​​​​​@🇮​​​​​🇨​​​​​🇱​​​​​🇴​​​​​🇺​​​​​🇩​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>
[CmdletBinding(SupportsShouldProcess)]
Param
(
    [Parameter(Mandatory = $false)]
    [switch]$Alias,
    [Parameter(Mandatory = $false)]
    [switch]$Quiet    
)



function Get-ModuleBuilderRoot{

    if($ENV:PSModuleBuilder -ne $Null){
        if(Test-Path $ENV:PSModuleBuilder -PathType Container){
            $PsProfileDevRoot = $ENV:PSModuleBuilder
            return $ModuleBuilder
        }
    }else{
        $TmpPath = (Get-Item $Profile).DirectoryName
        $TmpPath = Join-Path $TmpPath 'Projects\PowerShell.ModuleBuilder'
        if(Test-Path $TmpPath -PathType Container){
            $ModuleBuilder = $TmpPath
            return $ModuleBuilder
        }

    }
    $mydocuments = [environment]::getfolderpath("mydocuments") 
    $ModuleBuilder = Join-Path $mydocuments 'PowerShell\Projects\PowerShell.ModuleBuilder'
    return $ModuleBuilder
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



$Name = (Get-Item $PSScriptRoot).Name
$DisplayName = 'PowerShell.ModuleBuilder'
$RegistryPath = "$ENV:OrganizationHKCU\$Name"
 Write-Host "[$DisplayName] " -f Blue -NonewLin
 Write-Host " $RegistryPath" -f White

$ModuleBuilderPath = Get-ModuleBuilderRoot
$ModuleDevelopmentPath =  Get-PSModuleDevelopmentRoot
$BuildScript = Join-Path $ModuleBuilderPath 'Build.ps1'
$BuildModuleScript = Join-Path $ModuleBuilderPath 'Build-Module.ps1'

try{
    if($Quiet -eq $False){
        Write-Host "[$DisplayName] " -f Blue -NonewLine
        Write-Host "configuring registry values" -f White
    }

    Remove-Item $RegistryPath -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
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
    Remove-Alias -Name make -Force | Out-null
    if(Test-Path -Path $BuildScript -PathType Leaf){
        if($Quiet -eq $False){
            Write-Host "[$DisplayName] " -f DarkRed -NonewLine
            Write-Host "`tmake`t`t==>`t$BuildScript" -f DarkYellow
        }
        New-Alias -Name make -Value "$BuildScript" -Description 'Build a module' -Scope Global
    }
    Remove-Alias -Name makeall -Force | Out-null
    if(Test-Path -Path $BuildModuleScript -PathType Leaf){
        if($Quiet -eq $False){
            Write-Host "[$DisplayName] " -f DarkRed -NonewLine
            Write-Host "`tmakeall`t`t==>`t$BuildModuleScript" -f DarkYellow
        }
        New-Alias -Name makeall -Value "$BuildModuleScript" -Description 'Build a module' -Scope Global
    }
    if($Quiet -eq $False){
        Write-Host "`n`n[$DisplayName] " -f DarkRed -NonewLine
        Write-Host " To build a module, type 'make' or 'makeall'. Optionally Use -Import -Deploy" -f DarkYellow 
    }
}