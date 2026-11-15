param([string]$Godot = 'C:/Godot/Godot_console.exe', [switch]$CoreOnly, [switch]$RenderOnly)
$ErrorActionPreference = 'Stop'
if ($RenderOnly) {
    $retryPaths = Get-Content "$PSScriptRoot/../../docs/reports/step_32_35/dev_paths.json" -Raw | ConvertFrom-Json
    $retryCopy = $retryPaths.project
    $retryLogs = $retryPaths.evidence
    if (-not $retryCopy.StartsWith([IO.Path]::GetFullPath($env:TEMP),[StringComparison]::OrdinalIgnoreCase) -or -not $retryCopy.Contains('step32-35-dev-')) { throw 'Unexpected retry path' }
    if (Test-Path "$retryLogs/render_retry.log") { throw 'Retry evidence already exists; preserve previous evidence' }
    & $Godot --path $retryCopy --script res://dev_verify.gd --log-file "$retryLogs/render_retry.log"
    $retryExit = $LASTEXITCODE
    $retryResults = @(Get-Content "$retryLogs/results.json" -Raw | ConvertFrom-Json)
    $retryResults += @{label='render_retry';exit=$retryExit;passes=@(Select-String -Path "$retryLogs/render_retry.log" -Pattern '^PASS ').Count}
    $retryResults | ConvertTo-Json | Set-Content "$retryLogs/results.json"
    Get-ChildItem $retryCopy -Filter 'dev_*.png' | Copy-Item -Destination $retryLogs
    if ($retryExit -ne 0 -or (Select-String -Path "$retryLogs/render_retry.log" -Pattern 'SCRIPT ERROR:|^FAIL ' -Quiet)) { throw "Render retry exit=$retryExit" }
    Write-Output "Evidence: $retryLogs"
    exit 0
}
$s35root = (Resolve-Path "$PSScriptRoot/../..").Path
$s35id = 'damagochi-step22-resume-step23-step24-step27-step28-step29-step30-step32-35-dev-' + [guid]::NewGuid().ToString('N')
$s35copy = Join-Path $env:TEMP $s35id
$s35logs = Join-Path $s35root "docs/reports/step_32_35/$s35id"
New-Item -ItemType Directory $s35copy,$s35logs | Out-Null
Copy-Item "$s35root/project.godot","$s35root/icon.svg","$s35root/scripts","$s35root/scenes","$s35root/assets" -Destination $s35copy -Recurse
$s35config = Get-Content "$s35copy/project.godot" -Raw
$s35config = $s35config.Replace('config/name="damagochi"', 'config/name="damagochi"' + "`nconfig/use_custom_user_dir=true`nconfig/custom_user_dir_name=" + '"' + $s35id + '"')
Set-Content "$s35copy/project.godot" $s35config
Copy-Item "$PSScriptRoot/dev_verify.gd","$PSScriptRoot/dev_failure.gd" $s35copy
Copy-Item "$s35root/tests/step_30/play_failure.gd" $s35copy
Copy-Item "$s35root/tests/step_30/dev_verify.gd" "$s35copy/play_verify.gd"
Copy-Item "$s35root/tests/step_27/dev_failure.gd" "$s35copy/feed_failure.gd"
(Get-Content "$s35root/tests/step_27/dev_verify.gd" -Raw).Replace("res://dev_failure.gd","res://feed_failure.gd") | Set-Content "$s35copy/feed_verify.gd"

Copy-Item "$s35root/tests/step_24/dev_verify.gd" "$s35copy/button_verify.gd"
Copy-Item "$s35root/tests/step_23/dev_verify.gd" "$s35copy/movement_verify.gd"
Copy-Item "$s35root/tests/step_22/resume_verify.gd" $s35copy
@{project=$s35copy;evidence=$s35logs;user_dir=(Join-Path $env:APPDATA $s35id);original_save_accessed=$false} | ConvertTo-Json | Set-Content "$s35root/docs/reports/step_32_35/dev_paths.json"
$s35results = @()
function Run([string]$Script,[string]$Label,[string]$Mode='',[switch]$Render) {
    $s35args = @('--path',$s35copy,'--script',"res://$Script",'--log-file',"$s35logs/$Label.log")
    if (-not $Render) { $s35args += '--headless' }
    if ($Mode) { $s35args += @('--',$Mode) }
    & $Godot @s35args
    $s35exit = $LASTEXITCODE
    $script:s35results += @{label=$Label;exit=$s35exit;passes=@(Select-String -Path "$s35logs/$Label.log" -Pattern '^PASS ').Count}
    $script:s35results | ConvertTo-Json | Set-Content "$s35logs/results.json"
    if ($s35exit -ne 0 -or (Select-String -Path "$s35logs/$Label.log" -Pattern 'SCRIPT ERROR:|^FAIL ' -Quiet)) { throw "Failed $Label exit=$s35exit" }
}
& $Godot --version | Set-Content "$s35logs/version.txt"
& $Godot --headless --path $s35copy --editor --import --quit --log-file "$s35logs/import.log"
if ($LASTEXITCODE -ne 0) { throw 'Import failed' }
Run 'dev_verify.gd' 'dev'
Run 'dev_verify.gd' 'clean_restore' 'restore'
if (-not $CoreOnly) {
Run 'dev_verify.gd' 'real_interval' 'real'
Run 'play_verify.gd' 'play_regression'
Run 'play_verify.gd' 'play_restore' 'restore'
Run 'feed_verify.gd' 'feed_regression'
Run 'feed_verify.gd' 'restore' 'restore'

Run 'movement_verify.gd' 'movement_regression'
Run 'resume_verify.gd' 'menu_regression' 'suite'
foreach ($s35stage in @('egg','baby','hatch')) {
    Run 'resume_verify.gd' "seed_$s35stage" "seed_$s35stage"
    Run 'resume_verify.gd' "resume_$s35stage" "resume_$s35stage"
}
}
Run 'dev_verify.gd' 'render' -Render
Get-ChildItem $s35copy -Filter 'dev_*.png' | Copy-Item -Destination $s35logs
Write-Output "Evidence: $s35logs"









