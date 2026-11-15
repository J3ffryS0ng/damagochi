param([string]$Godot = 'C:/Godot/Godot_console.exe')
$ErrorActionPreference = 'Stop'
$s24root = (Resolve-Path "$PSScriptRoot/../..").Path
$s24id = 'damagochi-step22-resume-step23-dev-step24-dev-' + [guid]::NewGuid().ToString('N')
$s24copy = Join-Path $env:TEMP $s24id
$s24logs = Join-Path $s24root "docs/reports/step_24/$s24id"
New-Item -ItemType Directory $s24copy,$s24logs | Out-Null
$s24original = Join-Path $env:APPDATA 'Godot/app_userdata/damagochi/savegame.json'
function OriginalHash { if (Test-Path -LiteralPath $s24original) { (Get-FileHash -LiteralPath $s24original).Hash } else { 'ABSENT' } }
$s24before = OriginalHash
$s24before | Set-Content "$s24logs/original_before.txt"
Copy-Item "$s24root/project.godot","$s24root/icon.svg","$s24root/scripts","$s24root/scenes","$s24root/assets" -Destination $s24copy -Recurse
$s24config = Get-Content "$s24copy/project.godot" -Raw
$s24config = $s24config.Replace('config/name="damagochi"', 'config/name="damagochi"' + "`nconfig/use_custom_user_dir=true`nconfig/custom_user_dir_name=" + '"' + $s24id + '"')
Set-Content "$s24copy/project.godot" $s24config
Copy-Item "$PSScriptRoot/dev_verify.gd" $s24copy
Copy-Item "$s24root/tests/step_23/dev_verify.gd" "$s24copy/movement_verify.gd"
Copy-Item "$s24root/tests/step_22/resume_verify.gd","$s24root/tests/step_22/resume_qa_verify.gd" $s24copy
# Preserve the historical test; only its obsolete stationary-x assertion is adapted in the isolated copy.
$legacy = Get-Content "$s24root/tests/step_22/verify.gd" -Raw
$legacy = $legacy.Replace('game.creature_sprite.position.x == base.x and', 'abs(game.creature_sprite.position.x - base.x) <= 120.001 and')
Set-Content "$s24copy/verify.gd" $legacy
@{project=$s24copy;evidence=$s24logs;user_dir=(Join-Path $env:APPDATA $s24id)} | ConvertTo-Json | Set-Content "$s24root/docs/reports/step_24/dev_paths.json"
function Run([string]$Script,[string]$Label,[string]$Mode='',[switch]$Render) {
    $s24args = @('--path',$s24copy,'--script',"res://$Script",'--log-file',"$s24logs/$Label.log")
    if (-not $Render) { $s24args += '--headless' }
    if ($Mode) { $s24args += @('--',$Mode) }
    & $Godot @s24args
    if ($LASTEXITCODE -ne 0 -or (Select-String -Path "$s24logs/$Label.log" -Pattern 'SCRIPT ERROR:|^FAIL ' -Quiet)) { throw "Failed $Label" }
}
try {
    & $Godot --version | Set-Content "$s24logs/version.txt"
    & $Godot --headless --path $s24copy --editor --import --quit --log-file "$s24logs/import.log"
    if ($LASTEXITCODE -ne 0) { throw 'Import failed' }
    Run 'dev_verify.gd' 'dev'
    Run 'movement_verify.gd' 'movement_regression'
    Run 'verify.gd' 'legacy'
    Run 'resume_verify.gd' 'menu_suite' 'suite'
    foreach ($s24stage in @('egg','baby','hatch')) {
        Run 'resume_verify.gd' "seed_$s24stage" "seed_$s24stage"
        Run 'resume_verify.gd' "resume_$s24stage" "resume_$s24stage"
    }
    Run 'resume_qa_verify.gd' 'legacy_independent'
    foreach ($s24stage in @('egg','baby')) {
        Run 'dev_verify.gd' "feed_seed_$s24stage" "seed_$s24stage"
        Run 'dev_verify.gd' "feed_restore_$s24stage" "restore_$s24stage"
    }
    Run 'dev_verify.gd' 'render' -Render
    Get-ChildItem $s24copy -File | Where-Object { $_.Extension -in @('.png','.csv') } | Copy-Item -Destination $s24logs
} finally {
    $s24after = OriginalHash
    $s24after | Set-Content "$s24logs/original_after.txt"
    if ($s24before -ne $s24after) { throw 'Original save changed' }
    Write-Output "Evidence: $s24logs"
}

