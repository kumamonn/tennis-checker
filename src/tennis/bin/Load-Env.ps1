param(
    [Parameter(Mandatory)]
    [string]$BaseDir
)

$envFile = Join-Path $BaseDir ".env"

if (-not (Test-Path $envFile)) {
    throw ".env file not found: $envFile"
}

Get-Content $envFile | ForEach-Object {

    # コメント行
    if ($_ -match '^\s*#') { return }

    # 空行
    if ($_ -match '^\s*$') { return }

    $name, $value = $_ -split '=', 2

    [System.Environment]::SetEnvironmentVariable($name.Trim(), $value.Trim())
}