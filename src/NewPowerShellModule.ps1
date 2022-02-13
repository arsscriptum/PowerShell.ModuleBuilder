<#
  ╓──────────────────────────────────────────────────────────────────────────────────────
  ║   PowerShell.ModuleBuilder      
  ╙──────────────────────────────────────────────────────────────────────────────────────
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

#Requires -Version 5

function New-PowerShellModule{

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
}


# SIG # Begin signature block
# MIIFxAYJKoZIhvcNAQcCoIIFtTCCBbECAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUtxjxQCKgNvfktr4RHWHIY/MX
# HDugggNNMIIDSTCCAjWgAwIBAgIQmkSKRKW8Cb1IhBWj4NDm0TAJBgUrDgMCHQUA
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
# MQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUonflpR21eZeZAelDGMCm
# AsF23HkwDQYJKoZIhvcNAQEBBQAEggEA1gf42LE/cLgTEogQi1hps1PU/AEz/n2X
# DhKnKVcX74oP/5Lw9zISU/o/7fo6JtKiDa+2Wi4yRe/HyUpAs41CcC5SSp7gkzXa
# DY3ZpcKeUZgbvWfjKNxoiHgLCRoxRk5t4a7I0UFIFOLVwQ7IovaEik8lEaS/FeED
# 2y9qX2NUeJEg8VLEZgAnO3AH+1rfY7uCh+2LhWFhz67au5dnbdrSFJOSrtFcB28+
# Hg8HVnAdAUBLWueN39YzxADmX3Sg3YuQSLspA11PB5m5yHybg/o6dCPMVXcATMzz
# SkFB7wt+DUiYP907EhNRgCJbJlZHYod5MRFyshZmF7AZ/yV53Fb/bg==
# SIG # End signature block
