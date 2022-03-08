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
    [switch]$Strict
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
    Write-Host "Build Script       Path `t" -NoNewLine -f DarkYellow ; Write-Host "$BuildScriptPath" -f Gray 
    Write-Host "Module Builder     Path `t" -NoNewLine -f DarkYellow;  Write-Host "$ModuleBuilderPath" -f Gray 
    Write-Host "Module Development Path `t" -NoNewLine -f DarkYellow;  Write-Host "$ModuleDevelopmentPath" -f Gray 
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
            $ModulesBuilt++
        }
     
    
}catch{
    $ErrorOccured = $True
    Write-Host "❗❗❗ Build Error" -f DarkYellow ;
    Show-ExceptionDetails($_)
}
finally{
    if($ErrorOccured -eq $False){
        Write-Host '[OK] ' -f DarkGreen -NoNewLine
        Write-Host "$ModulesBuilt Modules compiled" -f Gray 
    }
    
    popd
}

# SIG # Begin signature block
# MIIFxAYJKoZIhvcNAQcCoIIFtTCCBbECAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUGDpldhoAh+K4dRsu7cByBElb
# jKGgggNNMIIDSTCCAjWgAwIBAgIQmkSKRKW8Cb1IhBWj4NDm0TAJBgUrDgMCHQUA
# MCwxKjAoBgNVBAMTIVBvd2VyU2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdDAe
# Fw0yMjAyMDkyMzI4NDRaFw0zOTEyMzEyMzU5NTlaMCUxIzAhBgNVBAMTGkFyc1Nj
# cmlwdHVtIFBvd2VyU2hlbGwgQ1NDMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
# CgKCAQEA60ec8x1ehhllMQ4t+AX05JLoCa90P7LIqhn6Zcqr+kvLSYYp3sOJ3oVy
# hv0wUFZUIAJIahv5lS1aSY39CCNN+w47aKGI9uLTDmw22JmsanE9w4vrqKLwqp2K
# +jPn2tj5OFVilNbikqpbH5bbUINnKCDRPnBld1D+xoQs/iGKod3xhYuIdYze2Edr
# 5WWTKvTIEqcEobsuT/VlfglPxJW4MbHXRn16jS+KN3EFNHgKp4e1Px0bhVQvIb9V
# 3ODwC2drbaJ+f5PXkD1lX28VCQDhoAOjr02HUuipVedhjubfCmM33+LRoD7u6aEl
# KUUnbOnC3gVVIGcCXWsrgyvyjqM2WQIDAQABo3YwdDATBgNVHSUEDDAKBggrBgEF
# BQcDAzBdBgNVHQEEVjBUgBD8gBzCH4SdVIksYQ0DovzKoS4wLDEqMCgGA1UEAxMh
# UG93ZXJTaGVsbCBMb2NhbCBDZXJ0aWZpY2F0ZSBSb290ghABvvi0sAAYvk29NHWg
# Q1DUMAkGBSsOAwIdBQADggEBAI8+KceC8Pk+lL3s/ZY1v1ZO6jj9cKMYlMJqT0yT
# 3WEXZdb7MJ5gkDrWw1FoTg0pqz7m8l6RSWL74sFDeAUaOQEi/axV13vJ12sQm6Me
# 3QZHiiPzr/pSQ98qcDp9jR8iZorHZ5163TZue1cW8ZawZRhhtHJfD0Sy64kcmNN/
# 56TCroA75XdrSGjjg+gGevg0LoZg2jpYYhLipOFpWzAJqk/zt0K9xHRuoBUpvCze
# yrR9MljczZV0NWl3oVDu+pNQx1ALBt9h8YpikYHYrl8R5xt3rh9BuonabUZsTaw+
# xzzT9U9JMxNv05QeJHCgdCN3lobObv0IA6e/xTHkdlXTsdgxggHhMIIB3QIBATBA
# MCwxKjAoBgNVBAMTIVBvd2VyU2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdAIQ
# mkSKRKW8Cb1IhBWj4NDm0TAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAig
# AoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgEL
# MQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUOgFyC6rJfm9McX/y12tr
# hAu54FMwDQYJKoZIhvcNAQEBBQAEggEAhGuMBkJ1esILtTD2OnyDTiJZFRidOrGC
# Mi+dJHmmKto0Zq5mWuBDqOMcZ7I1wVEGjdlOYPk7OdaSpT/Et7ivsZ47r/m/vLBl
# 2ys/wgnygXH2tLVMcQbf96jk9wig/iHeKFvdaSNS1UxuFFQsoYOUBKiB3bF73q9t
# lFgPY2GDxNOxggSIPDYCYCYTk4h2cLHE9n+OB/wpwSh8iXnMbgbQZTq7v4mrw7h0
# HqmOWWfU5RopmnhMSHFDfU8qkc6+84qjA0XlmXNRhStCvbXOzZJw9Jxm5P0QwQjV
# Bl7QPOmTRQLk2nx88Qfoi4Ac9TJIfoky6l+kEj4ImQ69qVIfyh6nKA==
# SIG # End signature block
