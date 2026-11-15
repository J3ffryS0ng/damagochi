param([string]$Godot = 'C:/Godot/Godot_console.exe')
$ErrorActionPreference = 'Stop'
$s27root = (Resolve-Path "$PSScriptRoot/../..").Path
$s27id = 'damagochi-step22-resume-step23-step24-step27-dev-' + [guid]::NewGuid().ToString('N')
$s27copy = Join-Path $env:TEMP $s27id
$s27logs = Join-Path $s27root "docs/reports/step_27/$s27id"
New-Item -ItemType Directory $s27copy,$s27logs | Out-Null
Copy-Item "$s27root/project.godot","$s27root/icon.svg","$s27root/scripts","$s27root/scenes","$s27root/assets" -Destination $s27copy -Recurse
$s27config = Get-Content "$s27copy/project.godot" -Raw
$s27config = $s27config.Replace('config/name="damagochi"', 'config/name="damagochi"' + "`nconfig/use_custom_user_dir=true`nconfig/custom_user_dir_name=" + '"' + $s27id + '"')
Set-Content "$s27copy/project.godot" $s27config
Copy-Item "$PSScriptRoot/dev_verify.gd","$PSScriptRoot/dev_failure.gd" $s27copy
Copy-Item "$s27root/tests/step_24/dev_verify.gd" "$s27copy/button_verify.gd"
Copy-Item "$s27root/tests/step_23/dev_verify.gd" "$s27copy/movement_verify.gd"
Copy-Item "$s27root/tests/step_22/resume_verify.gd" $s27copy
@{project=$s27copy;evidence=$s27logs;user_dir=(Join-Path $env:APPDATA $s27id);original_save_accessed=$false} | ConvertTo-Json | Set-Content "$s27root/docs/reports/step_27/dev_paths.json"
$s27results = @()
function Run([string]$Script,[string]$Label,[string]$Mode='',[switch]$Render) {
    $s27args = @('--path',$s27copy,'--script',"res://$Script",'--log-file',"$s27logs/$Label.log")
    if (-not $Render) { $s27args += '--headless' }
    if ($Mode) { $s27args += @('--',$Mode) }
    & $Godot @s27args
    $s27exit = $LASTEXITCODE
    $script:s27results += @{label=$Label;exit=$s27exit;passes=@(Select-String -Path "$s27logs/$Label.log" -Pattern '^PASS ').Count}
    $script:s27results | ConvertTo-Json | Set-Content "$s27logs/results.json"
    if ($s27exit -ne 0 -or (Select-String -Path "$s27logs/$Label.log" -Pattern 'SCRIPT ERROR:|^FAIL ' -Quiet)) { throw "Failed $Label exit=$s27exit" }
}
& $Godot --version | Set-Content "$s27logs/version.txt"
& $Godot --headless --path $s27copy --editor --import --quit --log-file "$s27logs/import.log"
if ($LASTEXITCODE -ne 0) { throw 'Import failed' }
Run 'dev_verify.gd' 'dev'
Run 'dev_verify.gd' 'restore' 'restore'

Run 'movement_verify.gd' 'movement_regression'
Run 'resume_verify.gd' 'menu_regression' 'suite'
foreach ($s27stage in @('egg','baby','hatch')) {
    Run 'resume_verify.gd' "seed_$s27stage" "seed_$s27stage"
    Run 'resume_verify.gd' "resume_$s27stage" "resume_$s27stage"
}
Run 'dev_verify.gd' 'render' -Render
Get-ChildItem $s27copy -Filter 'dev_*.png' | Copy-Item -Destination $s27logs
Write-Output "Evidence: $s27logs"


