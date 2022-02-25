<#
  ╓──────────────────────────────────────────────────────────────────────────────────────
  ║   PowerShell.ModuleBuilder      
  ╙──────────────────────────────────────────────────────────────────────────────────────
 #>
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


#===============================================================================
# Profile Functions
#===============================================================================

function Compare-ModulePathAgainstPermission{

    $VarModPath=$env:PSModulePath
    $Paths=$VarModPath.Split(';')

    # 1 -> Retrieve my appartenance (My Groups)
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $groups = $id.Groups | foreach-object {$_.Translate([Security.Principal.NTAccount])}
    $GroupList = @() ; ForEach( $g in $groups){  $GroupList += $g ; }
    Sleep -Milliseconds 500
    # Create Filter (Modify a folder) based on those groups
    $filteracl = {$GroupList.Contains($_.IdentityReference) -and ($_.FileSystemRights.ToString() -match 'Modify')}
    $PathPermissions = @()
    ForEach($dir in $Paths){
        if(-not(Test-Path $dir)){ continue;}
        $i = (Get-Item $dir);
        $PathPermissions += (Get-Acl $i).Access | Where $filteracl  | Select `
                                 @{n="Path";e={$i.fullname}},
                                 @{n="Permission";e={$_.FileSystemRights}}
    }
    return $PathPermissions
}

function Get-UserModulesPath{
    $VarModPath=$env:PSModulePath
    $Paths=$VarModPath.Split(';')
    $PathList = @() ; ForEach( $p in $Paths){  $PathList += $p ; }
    $P1 = Join-Path (Get-Item $Profile).DirectoryName 'Modules'
    if($PathList.Contains($P1) -eq $True){
        return $P1
    }
    $PossiblePaths = Compare-ModulePathAgainstPermission
    if($PossiblePaths.Count -gt 0){
        return $PossiblePaths[0].Path
    }
    return $null
}

