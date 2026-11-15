param([string]$Godot = 'C:/Godot/Godot_console.exe')
$ErrorActionPreference = 'Stop'
$s31root = (Resolve-Path "$PSScriptRoot/../..").Path
$s31id = 'damagochi-step22-resume-step23-step24-step27-step28-step29-step30-step31-dev-' + [guid]::NewGuid().ToString('N')
$s31copy = Join-Path $env:TEMP $s31id
$s31logs = Join-Path $s31root "docs/reports/step_31/$s31id"
New-Item -ItemType Directory $s31copy,$s31logs | Out-Null
Copy-Item "$s31root/project.godot","$s31root/icon.svg","$s31root/scripts","$s31root/scenes","$s31root/assets" -Destination $s31copy -Recurse
$s31config = Get-Content "$s31copy/project.godot" -Raw
$s31config = $s31config.Replace('config/name="damagochi"', 'config/name="damagochi"' + "`nconfig/use_custom_user_dir=true`nconfig/custom_user_dir_name=" + '"' + $s31id + '"')
Set-Content "$s31copy/project.godot" $s31config
Copy-Item "$PSScriptRoot/dev_verify.gd" $s31copy
Copy-Item "$s31root/tests/step_30/play_failure.gd" $s31copy
Copy-Item "$s31root/tests/step_30/dev_verify.gd" "$s31copy/play_verify.gd"
Copy-Item "$s31root/tests/step_27/dev_failure.gd" $s31copy
Copy-Item "$s31root/tests/step_27/dev_verify.gd" "$s31copy/feed_verify.gd"
Copy-Item "$s31root/tests/step_24/dev_verify.gd" "$s31copy/button_verify.gd"
Copy-Item "$s31root/tests/step_23/dev_verify.gd" "$s31copy/movement_verify.gd"
Copy-Item "$s31root/tests/step_22/resume_verify.gd" $s31copy
@{project=$s31copy;evidence=$s31logs;user_dir=(Join-Path $env:APPDATA $s31id);original_save_accessed=$false} | ConvertTo-Json | Set-Content "$s31root/docs/reports/step_31/dev_paths.json"
$s31results = @()
function Run([string]$Script,[string]$Label,[string]$Mode='',[switch]$Render) {
    $s31args = @('--path',$s31copy,'--script',"res://$Script",'--log-file',"$s31logs/$Label.log")
    if (-not $Render) { $s31args += '--headless' }
    if ($Mode) { $s31args += @('--',$Mode) }
    & $Godot @s31args
    $s31exit = $LASTEXITCODE
    $script:s31results += @{label=$Label;exit=$s31exit;passes=@(Select-String -Path "$s31logs/$Label.log" -Pattern '^PASS ').Count}
    $script:s31results | ConvertTo-Json | Set-Content "$s31logs/results.json"
    if ($s31exit -ne 0 -or (Select-String -Path "$s31logs/$Label.log" -Pattern 'SCRIPT ERROR:|^FAIL ' -Quiet)) { throw "Failed $Label exit=$s31exit" }
}
& $Godot --version | Set-Content "$s31logs/version.txt"
& $Godot --headless --path $s31copy --editor --import --quit --log-file "$s31logs/import.log"
if ($LASTEXITCODE -ne 0) { throw 'Import failed' }
Run 'dev_verify.gd' 'dev'
Run 'dev_verify.gd' 'real_interval' 'real'
Run 'play_verify.gd' 'play_regression'
Run 'play_verify.gd' 'play_restore' 'restore'
Run 'feed_verify.gd' 'feed_regression'
Run 'feed_verify.gd' 'restore' 'restore'

Run 'movement_verify.gd' 'movement_regression'
Run 'resume_verify.gd' 'menu_regression' 'suite'
foreach ($s31stage in @('egg','baby','hatch')) {
    Run 'resume_verify.gd' "seed_$s31stage" "seed_$s31stage"
    Run 'resume_verify.gd' "resume_$s31stage" "resume_$s31stage"
}
Run 'dev_verify.gd' 'render' -Render
Get-ChildItem $s31copy -Filter 'dev_*.png' | Copy-Item -Destination $s31logs
Write-Output "Evidence: $s31logs"






