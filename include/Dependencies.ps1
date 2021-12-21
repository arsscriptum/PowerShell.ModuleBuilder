<#̷#̷\
#̷\ 
#̷\   ⼕龱ᗪ㠪⼕闩丂ㄒ龱尺 ᗪ㠪ᐯ㠪㇄龱尸爪㠪𝓝ㄒ
#̷\    
#̷\   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇨​​​​​🇴​​​​​🇩​​​​​🇪​​​​​🇨​​​​​🇦​​​​​🇸​​​​​🇹​​​​​🇴​​​​​🇷​​​​​@🇮​​​​​🇨​​​​​🇱​​​​​🇴​​​​​🇺​​​​​🇩​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#̷\ 
#̷##>

function Global:Invoke-LoadModule{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Name,
        [Parameter(Mandatory=$true, Position=1)]
        [ValidateScript({
            if(-Not ($_ | Test-Path) ){
                throw "File or folder does not exist"
            }
            if(-Not ($_ | Test-Path -PathType Container) ){
                throw "Not a folder"
            }
            return $true 
        })]
        [string]$SourcePath,
        [Parameter(Mandatory=$false)]
        [switch]$Global
    )   
    try{
        Write-Host '[ LOADER ] ' -f DarkRed -NoNewLine
        Write-Host " =====>> LOADING $Name" -f DarkGray
        if($Global){
            Import-Module $Name -Scope Global -Force -ErrorAction Stop #-Verbose
        }else{
            Import-Module $Name -Force -ErrorAction Stop #-Verbose
        } 
        
    }catch [Exception]{
        Write-Host '[ LOADER ] ' -f DarkRed -NoNewLine
        Write-Host "ERROR LOADING $Global:ModuleManifest" -f Yellow
        Show-ExceptionDetails($_) -ShowStack
    }
}

function Global:Invoke-UnloadModule{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Name,
        [Parameter(Mandatory=$true, Position=1)]
        [ValidateScript({
            if(-Not ($_ | Test-Path) ){
                throw "File or folder does not exist"
            }
            if(-Not ($_ | Test-Path -PathType Container) ){
                throw "Not a folder"
            }
            return $true 
        })]
        [string]$SourcePath
    )     
    try{
        Write-Host '[ LOADER ] ' -f DarkRed -NoNewLine
        Write-Host " <<===== UNLOADING '$Name' == $SourcePath" -f DarkGray    
        Remove-Module $Name -Force -ErrorAction Ignore
        $UnloadedAliasesCount = 0
        $ModuleAliases = (Get-Alias | where Source -match "$Name" | select Name).Name
        $RegisteredAliases = ( Get-AliasList $SourcePath -EA Ignore | select Name).Name
        $ModuleAliasesCount = 0
        $RegisteredAliasCount = 0
        if($RegisteredAliases -ne $null){
            $RegisteredAliasCount = $RegisteredAliases.Count
            ForEach($alias in $RegisteredAliases){  if(get-alias $alias -EA Ignore){ $UnloadedAliasesCountRemove++ } Remove-Alias $alias -Force -EA Ignore  ;}
        }        
        if($ModuleAliases -ne $null){
            $ModuleAliasesCount = $ModuleAliases.Count
            ForEach($alias in $ModuleAliases){  if(get-alias $alias -EA Ignore){ $UnloadedAliasesCountRemove++ } Remove-Alias $alias -Force -EA Ignore ;} 
        }

        Write-Host '[ LOADER ] ' -f DarkRed -NoNewLine
        Write-Host " <<===== UNLOADING ALIASES Aliases removed $UnloadedAliasesCountRemove" -f DarkGray  
        
    }catch [Exception]{
        Write-Host '[ LOADER ] ' -f DarkRed -NoNewLine
        Write-Host "ERROR UNLOADING $Global:ModuleIdentifier" -f DarkYellow
        Show-ExceptionDetails($_) -ShowStack
    }
}