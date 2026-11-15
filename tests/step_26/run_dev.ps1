param([string]$Godot = 'C:/Godot/Godot_console.exe')
$ErrorActionPreference = 'Stop'
$s26root = (Resolve-Path "$PSScriptRoot/../..").Path
$s26id = 'damagochi-step22-resume-step23-step24-step26-dev-' + [guid]::NewGuid().ToString('N')
$s26copy = Join-Path $env:TEMP $s26id
$s26logs = Join-Path $s26root "docs/reports/step_26/$s26id"
New-Item -ItemType Directory $s26copy,$s26logs | Out-Null
Copy-Item "$s26root/project.godot","$s26root/icon.svg","$s26root/scripts","$s26root/scenes","$s26root/assets" -Destination $s26copy -Recurse
$s26config = Get-Content "$s26copy/project.godot" -Raw
$s26config = $s26config.Replace('config/name="damagochi"', 'config/name="damagochi"' + "`nconfig/use_custom_user_dir=true`nconfig/custom_user_dir_name=" + '"' + $s26id + '"')
Set-Content "$s26copy/project.godot" $s26config
Copy-Item "$PSScriptRoot/dev_verify.gd" $s26copy
Copy-Item "$s26root/tests/step_24/dev_verify.gd" "$s26copy/button_verify.gd"
Copy-Item "$s26root/tests/step_23/dev_verify.gd" "$s26copy/movement_verify.gd"
Copy-Item "$s26root/tests/step_22/resume_verify.gd" $s26copy
@{project=$s26copy;evidence=$s26logs;user_dir=(Join-Path $env:APPDATA $s26id);original_save_accessed=$false} | ConvertTo-Json | Set-Content "$s26root/docs/reports/step_26/dev_paths.json"
$s26results = @()
function Run([string]$Script,[string]$Label,[string]$Mode='',[switch]$Render) {
    $s26args = @('--path',$s26copy,'--script',"res://$Script",'--log-file',"$s26logs/$Label.log")
    if (-not $Render) { $s26args += '--headless' }
    if ($Mode) { $s26args += @('--',$Mode) }
    & $Godot @s26args
    $s26exit = $LASTEXITCODE
    $script:s26results += @{label=$Label;exit=$s26exit;passes=@(Select-String -Path "$s26logs/$Label.log" -Pattern '^PASS ').Count}
    $script:s26results | ConvertTo-Json | Set-Content "$s26logs/results.json"
    if ($s26exit -ne 0 -or (Select-String -Path "$s26logs/$Label.log" -Pattern 'SCRIPT ERROR:|^FAIL ' -Quiet)) { throw "Failed $Label exit=$s26exit" }
}
& $Godot --version | Set-Content "$s26logs/version.txt"
& $Godot --headless --path $s26copy --editor --import --quit --log-file "$s26logs/import.log"
if ($LASTEXITCODE -ne 0) { throw 'Import failed' }
Run 'dev_verify.gd' 'dev'
Run 'dev_verify.gd' 'restore' 'restore'

Run 'movement_verify.gd' 'movement_regression'
Run 'resume_verify.gd' 'menu_regression' 'suite'
foreach ($s26stage in @('egg','baby','hatch')) {
    Run 'resume_verify.gd' "seed_$s26stage" "seed_$s26stage"
    Run 'resume_verify.gd' "resume_$s26stage" "resume_$s26stage"
}
Run 'dev_verify.gd' 'render' -Render
Get-ChildItem $s26copy -Filter 'dev_*.png' | Copy-Item -Destination $s26logs
Write-Output "Evidence: $s26logs"

