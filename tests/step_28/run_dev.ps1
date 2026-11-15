param([string]$Godot = 'C:/Godot/Godot_console.exe')
$ErrorActionPreference = 'Stop'
$s28root = (Resolve-Path "$PSScriptRoot/../..").Path
$s28id = 'damagochi-step22-resume-step23-step24-step27-step28-dev-' + [guid]::NewGuid().ToString('N')
$s28copy = Join-Path $env:TEMP $s28id
$s28logs = Join-Path $s28root "docs/reports/step_28/$s28id"
New-Item -ItemType Directory $s28copy,$s28logs | Out-Null
Copy-Item "$s28root/project.godot","$s28root/icon.svg","$s28root/scripts","$s28root/scenes","$s28root/assets" -Destination $s28copy -Recurse
$s28config = Get-Content "$s28copy/project.godot" -Raw
$s28config = $s28config.Replace('config/name="damagochi"', 'config/name="damagochi"' + "`nconfig/use_custom_user_dir=true`nconfig/custom_user_dir_name=" + '"' + $s28id + '"')
Set-Content "$s28copy/project.godot" $s28config
Copy-Item "$PSScriptRoot/dev_verify.gd" $s28copy
Copy-Item "$s28root/tests/step_27/dev_failure.gd" $s28copy
Copy-Item "$s28root/tests/step_27/dev_verify.gd" "$s28copy/feed_verify.gd"
Copy-Item "$s28root/tests/step_24/dev_verify.gd" "$s28copy/button_verify.gd"
Copy-Item "$s28root/tests/step_23/dev_verify.gd" "$s28copy/movement_verify.gd"
Copy-Item "$s28root/tests/step_22/resume_verify.gd" $s28copy
@{project=$s28copy;evidence=$s28logs;user_dir=(Join-Path $env:APPDATA $s28id);original_save_accessed=$false} | ConvertTo-Json | Set-Content "$s28root/docs/reports/step_28/dev_paths.json"
$s28results = @()
function Run([string]$Script,[string]$Label,[string]$Mode='',[switch]$Render) {
    $s28args = @('--path',$s28copy,'--script',"res://$Script",'--log-file',"$s28logs/$Label.log")
    if (-not $Render) { $s28args += '--headless' }
    if ($Mode) { $s28args += @('--',$Mode) }
    & $Godot @s28args
    $s28exit = $LASTEXITCODE
    $script:s28results += @{label=$Label;exit=$s28exit;passes=@(Select-String -Path "$s28logs/$Label.log" -Pattern '^PASS ').Count}
    $script:s28results | ConvertTo-Json | Set-Content "$s28logs/results.json"
    if ($s28exit -ne 0 -or (Select-String -Path "$s28logs/$Label.log" -Pattern 'SCRIPT ERROR:|^FAIL ' -Quiet)) { throw "Failed $Label exit=$s28exit" }
}
& $Godot --version | Set-Content "$s28logs/version.txt"
& $Godot --headless --path $s28copy --editor --import --quit --log-file "$s28logs/import.log"
if ($LASTEXITCODE -ne 0) { throw 'Import failed' }
Run 'dev_verify.gd' 'dev'
Run 'feed_verify.gd' 'feed_regression'
Run 'feed_verify.gd' 'restore' 'restore'

Run 'movement_verify.gd' 'movement_regression'
Run 'resume_verify.gd' 'menu_regression' 'suite'
foreach ($s28stage in @('egg','baby','hatch')) {
    Run 'resume_verify.gd' "seed_$s28stage" "seed_$s28stage"
    Run 'resume_verify.gd' "resume_$s28stage" "resume_$s28stage"
}
Run 'dev_verify.gd' 'render' -Render
Get-ChildItem $s28copy -Filter 'dev_*.png' | Copy-Item -Destination $s28logs
Write-Output "Evidence: $s28logs"



