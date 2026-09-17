param(
    [Parameter(Mandatory = $true)]
    [string] $ProjectPath,
    [Parameter(Mandatory = $true)]
    [string] $StampPath
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$projectPath = [System.IO.Path]::GetFullPath($ProjectPath)
$stampPath = [System.IO.Path]::GetFullPath($StampPath)
$lockPath = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($projectPath), "obj", "display-version-bump.lock")
$lockDir = [System.IO.Path]::GetDirectoryName($lockPath)
if (-not [System.IO.Directory]::Exists($lockDir)) {
    [System.IO.Directory]::CreateDirectory($lockDir) | Out-Null
}

function Read-DisplayVersion([string] $text) {
    $match = [regex]::Match($text, '<ApplicationDisplayVersion>\s*([^<]+?)\s*</ApplicationDisplayVersion>')
    if (-not $match.Success) {
        throw "ApplicationDisplayVersion was not found in $projectPath"
    }
    return $match.Groups[1].Value.Trim()
}

function Write-Stamp([string] $version) {
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($stampPath, $version, $utf8)
    [Console]::Out.WriteLine($version)
}

$mutex = New-Object System.Threading.Mutex($false, "Global\BaguettepicDisplayVersionBump")
try {
    $mutex.WaitOne() | Out-Null

    $text = [System.IO.File]::ReadAllText($projectPath)
    $current = Read-DisplayVersion $text

    if ([System.IO.File]::Exists($lockPath)) {
        $age = [DateTime]::UtcNow - [System.IO.File]::GetLastWriteTimeUtc($lockPath)
        if ($age.TotalSeconds -lt 90) {
            Write-Stamp $current
            return
        }
    }

    $parts = $current.Split('.')
    $last = $parts[$parts.Length - 1]
    if ($last -notmatch '^\d+$') {
        throw "Cannot increment ApplicationDisplayVersion '$current'"
    }
    $parts[$parts.Length - 1] = [string](([int]$last) + 1)
    $next = [string]::Join('.', $parts)
    $updated = [regex]::Replace(
        $text,
        '<ApplicationDisplayVersion>\s*[^<]+?\s*</ApplicationDisplayVersion>',
        "<ApplicationDisplayVersion>$next</ApplicationDisplayVersion>",
        1)

    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($projectPath, $updated, $utf8)
    [System.IO.File]::WriteAllText($lockPath, $next, $utf8)
    Write-Stamp $next
}
finally {
    if ($mutex) {
        $mutex.ReleaseMutex() | Out-Null
        $mutex.Dispose()
    }
}
