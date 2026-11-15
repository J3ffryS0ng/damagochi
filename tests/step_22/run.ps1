param([string]$Godot = 'C:/Godot/Godot_console.exe')
$ErrorActionPreference = 'Stop'
$s22root = (Resolve-Path "$PSScriptRoot/../..").Path
$s22id = 'damagochi-step22-' + [guid]::NewGuid().ToString('N')
$s22copy = Join-Path $env:TEMP $s22id
$s22logs = Join-Path $s22root "docs/reports/step_22/$s22id"
New-Item -ItemType Directory $s22copy,$s22logs | Out-Null
Copy-Item "$s22root/project.godot","$s22root/icon.svg","$s22root/scripts","$s22root/scenes","$s22root/assets" -Destination $s22copy -Recurse
$s22config = Get-Content "$s22copy/project.godot" -Raw
$s22config = $s22config.Replace('config/name="damagochi"', 'config/name="damagochi"' + "`nconfig/use_custom_user_dir=true`nconfig/custom_user_dir_name=" + '"' + $s22id + '"')
Set-Content "$s22copy/project.godot" $s22config
Copy-Item "$PSScriptRoot/verify.gd" "$s22copy/verify.gd"
& $Godot --headless --path $s22root --script "$PSScriptRoot/probe.gd" --log-file "$s22logs/original_probe.log"
if ($LASTEXITCODE -ne 0) { throw 'Original path probe failed' }
& $Godot --headless --path $s22copy --editor --import --quit --log-file "$s22logs/import.log"
if ($LASTEXITCODE -ne 0) { throw 'Import failed' }
& $Godot --headless --path $s22copy --script res://verify.gd --log-file "$s22logs/verify.log"
if ($LASTEXITCODE -ne 0) { throw 'Verification failed; inspect log' }
& $Godot --path $s22copy --script res://verify.gd --log-file "$s22logs/restore_render.log" -- restore
if ($LASTEXITCODE -ne 0) { throw 'Fresh-process restore failed' }
Copy-Item "$s22copy/restored_baby.png" "$s22logs/restored_baby.png"
Write-Output "Test project: $s22copy"
Write-Output "Evidence: $s22logs"
