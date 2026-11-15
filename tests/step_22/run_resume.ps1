param([string]$Godot = 'C:/Godot/Godot_console.exe')
$ErrorActionPreference = 'Stop'
$s22root = (Resolve-Path "$PSScriptRoot/../..").Path
$s22id = 'damagochi-step22-resume-' + [guid]::NewGuid().ToString('N')
$s22copy = Join-Path $env:TEMP $s22id
$s22logs = Join-Path $s22root "docs/reports/step_22_resume/$s22id"
New-Item -ItemType Directory $s22copy,$s22logs | Out-Null
$s22original = Join-Path $env:APPDATA 'Godot/app_userdata/damagochi/savegame.json'
function Save-OriginalHash([string]$Label) {
    if (Test-Path -LiteralPath $s22original) {
        (Get-FileHash -LiteralPath $s22original).Hash | Set-Content "$s22logs/original_$Label.txt"
    } else { 'ABSENT' | Set-Content "$s22logs/original_$Label.txt" }
}
Save-OriginalHash 'before'
Copy-Item "$s22root/project.godot","$s22root/icon.svg","$s22root/scripts","$s22root/scenes","$s22root/assets" -Destination $s22copy -Recurse
$s22config = Get-Content "$s22copy/project.godot" -Raw
$s22config = $s22config.Replace('config/name="damagochi"', 'config/name="damagochi"' + "`nconfig/use_custom_user_dir=true`nconfig/custom_user_dir_name=" + '"' + $s22id + '"')
Set-Content "$s22copy/project.godot" $s22config
Copy-Item "$PSScriptRoot/resume_verify.gd","$PSScriptRoot/verify.gd" $s22copy
@{project=$s22copy; evidence=$s22logs; user_dir=(Join-Path $env:APPDATA $s22id)} | ConvertTo-Json | Set-Content "$s22root/docs/reports/step_22_resume/latest_run.json"
function Invoke-Check([string]$Mode, [switch]$Render) {
    $s22args = @('--path', $s22copy, '--script', 'res://resume_verify.gd', '--log-file', "$s22logs/$Mode.log")
    if (-not $Render) { $s22args += '--headless' }
    & $Godot @s22args -- $Mode
    if ($LASTEXITCODE -ne 0) { throw "Failed $Mode" }
    if (Select-String -Path "$s22logs/$Mode.log" -Pattern 'SCRIPT ERROR:|^FAIL ' -Quiet) { throw "Script/assertion failure in $Mode" }
}
try {
    & $Godot --headless --path $s22root --script "$PSScriptRoot/probe.gd" --log-file "$s22logs/original_probe.log"
    if ($LASTEXITCODE -ne 0) { throw 'Original probe failed' }
    & $Godot --headless --path $s22copy --editor --import --quit --log-file "$s22logs/import.log"
    if ($LASTEXITCODE -ne 0) { throw 'Import failed' }
    Invoke-Check 'suite' -Render
    foreach ($s22stage in @('egg','baby','hatch')) {
        Invoke-Check "seed_$s22stage"
        Invoke-Check "resume_$s22stage" -Render
    }
    foreach ($s22fault in @('continue_scene_failure','name_scene_failure','read_locked','write_locked')) {
        Invoke-Check 'seed_baby'
        $s22save = Join-Path (Join-Path $env:APPDATA $s22id) 'savegame.json'
        $s22hash = (Get-FileHash -LiteralPath $s22save).Hash
        $s22lock = $null
        try {
            if ($s22fault -eq 'read_locked') {
                $s22lock = [System.IO.File]::Open($s22save, 'Open', 'ReadWrite', 'None')
            } elseif ($s22fault -eq 'write_locked') {
                $s22lock = [System.IO.File]::Open($s22save, 'Open', 'Read', 'Read')
            }
            Invoke-Check $s22fault
        } finally { if ($null -ne $s22lock) { $s22lock.Dispose() } }
        if ($s22fault -in @('read_locked','write_locked')) {
            if ((Get-FileHash -LiteralPath $s22save).Hash -ne $s22hash) { throw "Save changed in $s22fault" }
            "PASS $s22fault SHA256 unchanged $s22hash" | Add-Content "$s22logs/locked_hashes.txt"
        }
    }
    & $Godot --headless --path $s22copy --script res://verify.gd --log-file "$s22logs/legacy_regression.log"
    if ($LASTEXITCODE -ne 0) { throw 'Existing Idle/egg/save regression failed' }
    & $Godot --headless --path $s22copy --quit-after 10 --log-file "$s22logs/default_start.log"
    if ($LASTEXITCODE -ne 0) { throw 'Default start failed' }
    Get-ChildItem $s22copy -Filter 'resume_*.png' | Copy-Item -Destination $s22logs
} finally {
    Save-OriginalHash 'after'
    if ((Get-Content "$s22logs/original_before.txt") -ne (Get-Content "$s22logs/original_after.txt")) { throw 'Original save hash changed' }
    Write-Output "Evidence: $s22logs"
}
