param(
    [Parameter(Mandatory=$true)] [string]$SourceDir,
    [Parameter(Mandatory=$true)] [string]$OutputFile
)
$ErrorActionPreference = 'Stop'
$sourceFull = (Resolve-Path $SourceDir).Path
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('<?xml version="1.0" encoding="utf-8"?>')
[void]$sb.AppendLine('<Wix xmlns="http://wixtoolset.org/schemas/v4/wxs">')
[void]$sb.AppendLine('  <Fragment>')
[void]$sb.AppendLine('    <ComponentGroup Id="AppFiles" Directory="INSTALLFOLDER">')
$script:cid = 0
$script:fid = 0
$script:did = 0

function Esc([string]$s) { return [System.Security.SecurityElement]::Escape($s) }

function Write-Dir([string]$dirPath, [string]$parentRef, [int]$level) {
    $indent = ' ' * (8 + $level * 2)
    $files = @(Get-ChildItem -LiteralPath $dirPath -File -Force -ErrorAction SilentlyContinue)
    $subdirs = @(Get-ChildItem -LiteralPath $dirPath -Directory -Force -ErrorAction SilentlyContinue)
    foreach ($f in $files) {
        $script:cid++
        $script:fid++
        $cmpId = "Cmp$($script:cid)"
        $filId = "Fil$($script:fid)"
        $src = Esc $f.FullName
        [void]$sb.AppendLine("$indent<Component Id=`"$cmpId`" Guid=`"*`" Directory=`"$parentRef`">")
        [void]$sb.AppendLine("$indent  <File Id=`"$filId`" KeyPath=`"yes`" Source=`"$src`" />")
        [void]$sb.AppendLine("$indent</Component>")
    }
    foreach ($sd in $subdirs) {
        $script:did++
        $dirId = "Dir$($script:did)"
        $dirName = Esc (Split-Path -Leaf $sd.FullName)
        [void]$sb.AppendLine("$indent<Directory Id=`"$dirId`" Name=`"$dirName`">")
        Write-Dir $sd.FullName $dirId ($level + 1)
        [void]$sb.AppendLine("$indent</Directory>")
    }
}

Write-Dir $sourceFull "INSTALLFOLDER" 0
[void]$sb.AppendLine('    </ComponentGroup>')
[void]$sb.AppendLine('  </Fragment>')
[void]$sb.AppendLine('</Wix>')
[System.IO.File]::WriteAllText($OutputFile, $sb.ToString(), (New-Object System.Text.UTF8Encoding $false))
Write-Host "Generated $OutputFile with $($script:cid) files"
