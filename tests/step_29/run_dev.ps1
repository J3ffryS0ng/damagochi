param([string]$Godot = 'C:/Godot/Godot_console.exe')
$ErrorActionPreference = 'Stop'
$s29root = (Resolve-Path "$PSScriptRoot/../..").Path
$s29id = 'damagochi-step22-resume-step23-step24-step27-step28-step29-dev-' + [guid]::NewGuid().ToString('N')
$s29copy = Join-Path $env:TEMP $s29id
$s29logs = Join-Path $s29root "docs/reports/step_29/$s29id"
New-Item -ItemType Directory $s29copy,$s29logs | Out-Null
Copy-Item "$s29root/project.godot","$s29root/icon.svg","$s29root/scripts","$s29root/scenes","$s29root/assets" -Destination $s29copy -Recurse
$s29config = Get-Content "$s29copy/project.godot" -Raw
$s29config = $s29config.Replace('config/name="damagochi"', 'config/name="damagochi"' + "`nconfig/use_custom_user_dir=true`nconfig/custom_user_dir_name=" + '"' + $s29id + '"')
Set-Content "$s29copy/project.godot" $s29config
Copy-Item "$PSScriptRoot/dev_verify.gd" $s29copy
Copy-Item "$s29root/tests/step_27/dev_failure.gd" $s29copy
Copy-Item "$s29root/tests/step_27/dev_verify.gd" "$s29copy/feed_verify.gd"
Copy-Item "$s29root/tests/step_24/dev_verify.gd" "$s29copy/button_verify.gd"
Copy-Item "$s29root/tests/step_23/dev_verify.gd" "$s29copy/movement_verify.gd"
Copy-Item "$s29root/tests/step_22/resume_verify.gd" $s29copy
@{project=$s29copy;evidence=$s29logs;user_dir=(Join-Path $env:APPDATA $s29id);original_save_accessed=$false} | ConvertTo-Json | Set-Content "$s29root/docs/reports/step_29/dev_paths.json"
$s29results = @()
function Run([string]$Script,[string]$Label,[string]$Mode='',[switch]$Render) {
    $s29args = @('--path',$s29copy,'--script',"res://$Script",'--log-file',"$s29logs/$Label.log")
    if (-not $Render) { $s29args += '--headless' }
    if ($Mode) { $s29args += @('--',$Mode) }
    & $Godot @s29args
    $s29exit = $LASTEXITCODE
    $script:s29results += @{label=$Label;exit=$s29exit;passes=@(Select-String -Path "$s29logs/$Label.log" -Pattern '^PASS ').Count}
    $script:s29results | ConvertTo-Json | Set-Content "$s29logs/results.json"
    if ($s29exit -ne 0 -or (Select-String -Path "$s29logs/$Label.log" -Pattern 'SCRIPT ERROR:|^FAIL ' -Quiet)) { throw "Failed $Label exit=$s29exit" }
}
& $Godot --version | Set-Content "$s29logs/version.txt"
& $Godot --headless --path $s29copy --editor --import --quit --log-file "$s29logs/import.log"
if ($LASTEXITCODE -ne 0) { throw 'Import failed' }
Run 'dev_verify.gd' 'dev'
Run 'feed_verify.gd' 'feed_regression'
Run 'feed_verify.gd' 'restore' 'restore'

Run 'movement_verify.gd' 'movement_regression'
Run 'resume_verify.gd' 'menu_regression' 'suite'
foreach ($s29stage in @('egg','baby','hatch')) {
    Run 'resume_verify.gd' "seed_$s29stage" "seed_$s29stage"
    Run 'resume_verify.gd' "resume_$s29stage" "resume_$s29stage"
}
Run 'dev_verify.gd' 'render' -Render
Get-ChildItem $s29copy -Filter 'dev_*.png' | Copy-Item -Destination $s29logs
Write-Output "Evidence: $s29logs"




