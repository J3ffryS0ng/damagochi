param([string]$Godot = 'C:/Godot/Godot_console.exe')
$ErrorActionPreference = 'Stop'
$s25root = (Resolve-Path "$PSScriptRoot/../..").Path
$s25id = 'damagochi-step22-resume-step23-step24-step25-dev-' + [guid]::NewGuid().ToString('N')
$s25copy = Join-Path $env:TEMP $s25id
$s25logs = Join-Path $s25root "docs/reports/step_25/$s25id"
New-Item -ItemType Directory $s25copy,$s25logs | Out-Null
Copy-Item "$s25root/project.godot","$s25root/icon.svg","$s25root/scripts","$s25root/scenes","$s25root/assets" -Destination $s25copy -Recurse
$s25config = Get-Content "$s25copy/project.godot" -Raw
$s25config = $s25config.Replace('config/name="damagochi"', 'config/name="damagochi"' + "`nconfig/use_custom_user_dir=true`nconfig/custom_user_dir_name=" + '"' + $s25id + '"')
Set-Content "$s25copy/project.godot" $s25config
Copy-Item "$PSScriptRoot/dev_verify.gd" $s25copy
Copy-Item "$s25root/tests/step_24/dev_verify.gd" "$s25copy/button_verify.gd"
Copy-Item "$s25root/tests/step_23/dev_verify.gd" "$s25copy/movement_verify.gd"
Copy-Item "$s25root/tests/step_22/resume_verify.gd" $s25copy
@{project=$s25copy;evidence=$s25logs;user_dir=(Join-Path $env:APPDATA $s25id);original_save_accessed=$false} | ConvertTo-Json | Set-Content "$s25root/docs/reports/step_25/dev_paths.json"
$s25results = @()
function Run([string]$Script,[string]$Label,[string]$Mode='',[switch]$Render) {
    $s25args = @('--path',$s25copy,'--script',"res://$Script",'--log-file',"$s25logs/$Label.log")
    if (-not $Render) { $s25args += '--headless' }
    if ($Mode) { $s25args += @('--',$Mode) }
    & $Godot @s25args
    $s25exit = $LASTEXITCODE
    $script:s25results += @{label=$Label;exit=$s25exit;passes=@(Select-String -Path "$s25logs/$Label.log" -Pattern '^PASS ').Count}
    $script:s25results | ConvertTo-Json | Set-Content "$s25logs/results.json"
    if ($s25exit -ne 0 -or (Select-String -Path "$s25logs/$Label.log" -Pattern 'SCRIPT ERROR:|^FAIL ' -Quiet)) { throw "Failed $Label exit=$s25exit" }
}
& $Godot --version | Set-Content "$s25logs/version.txt"
& $Godot --headless --path $s25copy --editor --import --quit --log-file "$s25logs/import.log"
if ($LASTEXITCODE -ne 0) { throw 'Import failed' }
Run 'dev_verify.gd' 'dev'
Run 'dev_verify.gd' 'restore' 'restore'
Run 'button_verify.gd' 'button_regression'
Run 'movement_verify.gd' 'movement_regression'
Run 'resume_verify.gd' 'menu_regression' 'suite'
foreach ($s25stage in @('egg','baby','hatch')) {
    Run 'resume_verify.gd' "seed_$s25stage" "seed_$s25stage"
    Run 'resume_verify.gd' "resume_$s25stage" "resume_$s25stage"
}
Run 'dev_verify.gd' 'render' -Render
Get-ChildItem $s25copy -Filter 'dev_*.png' | Copy-Item -Destination $s25logs
Write-Output "Evidence: $s25logs"
