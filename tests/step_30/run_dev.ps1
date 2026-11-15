param([string]$Godot = 'C:/Godot/Godot_console.exe')
$ErrorActionPreference = 'Stop'
$s30root = (Resolve-Path "$PSScriptRoot/../..").Path
$s30id = 'damagochi-step22-resume-step23-step24-step27-step28-step29-step30-dev-' + [guid]::NewGuid().ToString('N')
$s30copy = Join-Path $env:TEMP $s30id
$s30logs = Join-Path $s30root "docs/reports/step_30/$s30id"
New-Item -ItemType Directory $s30copy,$s30logs | Out-Null
Copy-Item "$s30root/project.godot","$s30root/icon.svg","$s30root/scripts","$s30root/scenes","$s30root/assets" -Destination $s30copy -Recurse
$s30config = Get-Content "$s30copy/project.godot" -Raw
$s30config = $s30config.Replace('config/name="damagochi"', 'config/name="damagochi"' + "`nconfig/use_custom_user_dir=true`nconfig/custom_user_dir_name=" + '"' + $s30id + '"')
Set-Content "$s30copy/project.godot" $s30config
Copy-Item "$PSScriptRoot/dev_verify.gd","$PSScriptRoot/play_failure.gd" $s30copy
Copy-Item "$s30root/tests/step_27/dev_failure.gd" $s30copy
Copy-Item "$s30root/tests/step_27/dev_verify.gd" "$s30copy/feed_verify.gd"
Copy-Item "$s30root/tests/step_24/dev_verify.gd" "$s30copy/button_verify.gd"
Copy-Item "$s30root/tests/step_23/dev_verify.gd" "$s30copy/movement_verify.gd"
Copy-Item "$s30root/tests/step_22/resume_verify.gd" $s30copy
@{project=$s30copy;evidence=$s30logs;user_dir=(Join-Path $env:APPDATA $s30id);original_save_accessed=$false} | ConvertTo-Json | Set-Content "$s30root/docs/reports/step_30/dev_paths.json"
$s30results = @()
function Run([string]$Script,[string]$Label,[string]$Mode='',[switch]$Render) {
    $s30args = @('--path',$s30copy,'--script',"res://$Script",'--log-file',"$s30logs/$Label.log")
    if (-not $Render) { $s30args += '--headless' }
    if ($Mode) { $s30args += @('--',$Mode) }
    & $Godot @s30args
    $s30exit = $LASTEXITCODE
    $script:s30results += @{label=$Label;exit=$s30exit;passes=@(Select-String -Path "$s30logs/$Label.log" -Pattern '^PASS ').Count}
    $script:s30results | ConvertTo-Json | Set-Content "$s30logs/results.json"
    if ($s30exit -ne 0 -or (Select-String -Path "$s30logs/$Label.log" -Pattern 'SCRIPT ERROR:|^FAIL ' -Quiet)) { throw "Failed $Label exit=$s30exit" }
}
& $Godot --version | Set-Content "$s30logs/version.txt"
& $Godot --headless --path $s30copy --editor --import --quit --log-file "$s30logs/import.log"
if ($LASTEXITCODE -ne 0) { throw 'Import failed' }
Run 'dev_verify.gd' 'dev'
Run 'dev_verify.gd' 'play_restore' 'restore'
Run 'feed_verify.gd' 'feed_regression'
Run 'feed_verify.gd' 'restore' 'restore'

Run 'movement_verify.gd' 'movement_regression'
Run 'resume_verify.gd' 'menu_regression' 'suite'
foreach ($s30stage in @('egg','baby','hatch')) {
    Run 'resume_verify.gd' "seed_$s30stage" "seed_$s30stage"
    Run 'resume_verify.gd' "resume_$s30stage" "resume_$s30stage"
}
Run 'dev_verify.gd' 'render' -Render
Get-ChildItem $s30copy -Filter 'dev_*.png' | Copy-Item -Destination $s30logs
Write-Output "Evidence: $s30logs"





