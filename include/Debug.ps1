<#
  ╓──────────────────────────────────────────────────────────────────────────────────────
  ║   PowerShell.ModuleBuilder      
  ╙──────────────────────────────────────────────────────────────────────────────────────
 #>

$global:FullLogs = new-object System.String("")
$global:LogFilePath = new-object System.String("")
$global:LogFileName = new-object System.String("")
if((Get-Variable -Name "LogEnabled" -Scope Global -ValueOnly -ErrorAction Ignore) -eq $null){
    Set-Variable -Name "LogEnabled" -Scope Global -Value $True
}
if((Get-Variable -Name "ConsoleOutEnabled" -Scope Global -ValueOnly -ErrorAction Ignore) -eq $null){
    Set-Variable -Name "ConsoleOutEnabled" -Scope Global -Value ($env:computername -like 'maverick')
}
if((Get-Variable -Name "LogEventEnabled" -Scope Global -ValueOnly -ErrorAction Ignore) -eq $null){
    Set-Variable -Name "LogEventEnabled" -Scope Global -Value $false
}
$global:LogFileName = (new-guid).Guid
$global:LogFileName = $global:LogFileName -replace '-'
$global:LogFileName = $global:LogFileName + '.log'
[string]$TempDir=(new-guid).Guid
$TmpFilePath="$env:Temp\$TempDir"
$null=New-Item -Path $TmpFilePath -ItemType Directory -Force
$global:LogFileName = Join-Path $TmpFilePath $global:LogFileName

Enum LogLevel
{
    Verbose         =   0        
    Info            =   1
    Warning         =   2
    Error           =   3
}

Function Get-EnumValues{
    Param([string]$enum)
    # get-enumValues -enum "System.Diagnostics.Eventing.Reader.StandardEventLevel"
    
    $enumValues = @{}
    [enum]::getvalues([type]$enum) |
    ForEach-Object { 
        $enumValues.add($_, $_.value__)
    }
    $enumValues
}

function Get-TimeStamp{
    return [System.DateTime]::Now.ToString("yyyy.MM.dd hh:mm:ss");
}

Function Log-String {
  [CmdletBinding()]
  param(
    [Parameter(Position=0,ValueFromPipeline,ParameterSetName='Default')]
    [string]$Msg,
    [Parameter(Position=1,ValueFromPipeline,ParameterSetName='Default')] 
    [switch]$IsError,
    [Parameter(Position=2,ValueFromPipeline,ParameterSetName='Default')] 
    [ValidateSet('Verbose','Info','Warning','Error')]
    [string]$Level = 'Info'
    )

    if($Msg -eq "" -Or -not $global:LogEnabled){return}
    $global:FullLogs = $global:FullLogs + $Msg 
    if($global:ConsoleOutEnabled){
        if(-not $IsError){
            [string]$t=Get-TimeStamp
            write-host "[$Global:CurrentRunningScript] " -f DarkYellow -NoNewLine
            write-host $Msg -f DarkGray
        }
        else {
            write-host "[$Global:CurrentRunningScript] " -f DarkRed -NoNewLine
            write-host $Msg -f DarkYellow
        }
    }
    if(-not $IsError){
        [pscustomobject]@{
            Time = Get-TimeStamp
            Level = $Level
            Message = "[$Global:CurrentRunningScript] $Msg"
        } | Export-Csv -Path $global:LogFileName -Append -NoTypeInformation
    } else {
        [pscustomobject]@{
            Time = Get-TimeStamp
            Level = $Level
            Message = "[ERROR] [$Global:CurrentRunningScript] $Msg"
        } | Export-Csv -Path $global:LogFileName -Append -NoTypeInformation    
    }

}

