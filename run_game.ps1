# Run Hole Rush without using the Godot editor Play button.
# Usage: right-click -> Run with PowerShell, or: .\run_game.ps1

$ErrorActionPreference = "Stop"
$projectRoot = $PSScriptRoot

function Find-Godot {
    $names = @("godot", "godot4", "Godot_v4.6.2-stable_win64.exe", "Godot.exe")
    foreach ($name in $names) {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }
    $common = @(
        "$env:LOCALAPPDATA\Godot\Godot_v4.6.2-stable_win64.exe",
        "$env:ProgramFiles\Godot\Godot.exe",
        "C:\Program Files\Godot\Godot_v4.6.2-stable_win64.exe"
    )
    foreach ($path in $common) {
        if (Test-Path $path) { return $path }
    }
    return $null
}

$godot = Find-Godot
if (-not $godot) {
    Write-Host "Godot not found in PATH. Install Godot 4.6+ or add it to PATH, then run again."
    exit 1
}

Write-Host "Running Hole Rush from res://scenes/main.tscn ..."
& $godot --path $projectRoot res://scenes/main.tscn
