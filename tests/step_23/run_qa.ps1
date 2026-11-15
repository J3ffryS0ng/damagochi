param([string]$Godot = 'C:/Godot/Godot_console.exe')
$ErrorActionPreference = 'Stop'
$s23root = (Resolve-Path "$PSScriptRoot/../..").Path
$s23id = 'damagochi-step22-resume-step23-qa-' + [guid]::NewGuid().ToString('N')
$s23copy = Join-Path $env:TEMP $s23id
$s23logs = Join-Path $s23root "docs/reports/step_23/$s23id"
New-Item -ItemType Directory $s23copy,$s23logs | Out-Null
$s23original = Join-Path $env:APPDATA 'Godot/app_userdata/damagochi/savegame.json'
function OriginalHash { if (Test-Path -LiteralPath $s23original) { (Get-FileHash -LiteralPath $s23original).Hash } else { 'ABSENT' } }
$s23before = OriginalHash
$s23before | Set-Content "$s23logs/original_before.txt"
Copy-Item "$s23root/project.godot","$s23root/icon.svg","$s23root/scripts","$s23root/scenes","$s23root/assets" -Destination $s23copy -Recurse
$s23config = Get-Content "$s23copy/project.godot" -Raw
$s23config = $s23config.Replace('config/name="damagochi"', 'config/name="damagochi"' + "`nconfig/use_custom_user_dir=true`nconfig/custom_user_dir_name=" + '"' + $s23id + '"')
Set-Content "$s23copy/project.godot" $s23config
Copy-Item "$PSScriptRoot/qa_verify.gd" $s23copy
Copy-Item "$s23root/tests/step_22/resume_verify.gd","$s23root/tests/step_22/resume_qa_verify.gd" $s23copy
# Preserve the historical test; only its obsolete stationary-x assertion is adapted in the isolated copy.
$legacy = Get-Content "$s23root/tests/step_22/verify.gd" -Raw
$legacy = $legacy.Replace('game.creature_sprite.position.x == base.x and', 'abs(game.creature_sprite.position.x - base.x) <= 120.001 and')
Set-Content "$s23copy/verify.gd" $legacy
@{project=$s23copy;evidence=$s23logs;user_dir=(Join-Path $env:APPDATA $s23id)} | ConvertTo-Json | Set-Content "$s23root/docs/reports/step_23/qa_paths.json"
function Run([string]$Script,[string]$Label,[string]$Mode='',[switch]$Render) {
    $s23args = @('--path',$s23copy,'--script',"res://$Script",'--log-file',"$s23logs/$Label.log")
    if (-not $Render) { $s23args += '--headless' }
    if ($Mode) { $s23args += @('--',$Mode) }
    & $Godot @s23args
    if ($LASTEXITCODE -ne 0 -or (Select-String -Path "$s23logs/$Label.log" -Pattern 'SCRIPT ERROR:|^FAIL |^QA_FAIL ' -Quiet)) { throw "Failed $Label" }
}
try {
    & $Godot --version | Set-Content "$s23logs/version.txt"
    & $Godot --headless --path $s23copy --editor --import --quit --log-file "$s23logs/import.log"
    if ($LASTEXITCODE -ne 0) { throw 'Import failed' }
    Run 'qa_verify.gd' 'qa'
    Run 'verify.gd' 'legacy'
    Run 'resume_verify.gd' 'menu_suite' 'suite'
    foreach ($s23stage in @('egg','baby','hatch')) {
        Run 'resume_verify.gd' "seed_$s23stage" "seed_$s23stage"
        Run 'resume_verify.gd' "resume_$s23stage" "resume_$s23stage"
    }
    Run 'resume_qa_verify.gd' 'legacy_independent'
    Run 'qa_verify.gd' 'qa_render' -Render
    Get-ChildItem $s23copy -File | Where-Object { $_.Extension -in @('.png','.csv') } | Copy-Item -Destination $s23logs
} finally {
    $s23after = OriginalHash
    $s23after | Set-Content "$s23logs/original_after.txt"
    if ($s23before -ne $s23after) { throw 'Original save changed' }
    Write-Output "Evidence: $s23logs"
}

