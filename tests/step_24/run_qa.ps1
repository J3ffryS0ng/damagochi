param([string]$Godot = 'C:/Godot/Godot_console.exe', [switch]$RenderOnly)
$ErrorActionPreference = 'Stop'
$qaRoot = (Resolve-Path "$PSScriptRoot/../..").Path
if ($RenderOnly) {
    $qaPaths = Get-Content "$qaRoot/docs/reports/step_24/qa_paths.json" -Raw | ConvertFrom-Json
    $qaOriginal = Join-Path $env:APPDATA 'Godot/app_userdata/damagochi/savegame.json'
    $qaBeforeRetry = (Get-FileHash -LiteralPath $qaOriginal).Hash
    & $Godot --path $qaPaths.project --script res://qa_verify.gd --log-file "$($qaPaths.evidence)/qa_render_retry.log"
    $qaNativeExit = $LASTEXITCODE
    Get-ChildItem $qaPaths.project -Filter 'qa_*.png' | Copy-Item -Destination $qaPaths.evidence
    $qaAfterRetry = (Get-FileHash -LiteralPath $qaOriginal).Hash
    @{native_exit=$qaNativeExit;original_before=$qaBeforeRetry;original_after=$qaAfterRetry;original_preserved=($qaBeforeRetry -eq $qaAfterRetry)} | ConvertTo-Json | Set-Content "$qaRoot/docs/reports/step_24/qa_render_retry_status.json"
    if ($qaNativeExit -ne 0 -or $qaBeforeRetry -ne $qaAfterRetry -or (Select-String -Path "$($qaPaths.evidence)/qa_render_retry.log" -Pattern 'SCRIPT ERROR:|^FAIL ' -Quiet)) { throw "Render retry native exit $qaNativeExit" }
    return
}
$qaId = 'damagochi-step22-resume-step23-step24-qa-' + [guid]::NewGuid().ToString('N')
$qaCopy = Join-Path $env:TEMP $qaId
$qaLogs = Join-Path $qaRoot "docs/reports/step_24/$qaId"
New-Item -ItemType Directory $qaCopy,$qaLogs | Out-Null
$qaOriginal = Join-Path $env:APPDATA 'Godot/app_userdata/damagochi/savegame.json'
function SaveHash { if (Test-Path -LiteralPath $qaOriginal) { (Get-FileHash -LiteralPath $qaOriginal).Hash } else { 'ABSENT' } }
$qaBefore = SaveHash
$qaBefore | Set-Content "$qaLogs/original_before.txt"
Copy-Item "$qaRoot/project.godot","$qaRoot/icon.svg","$qaRoot/scripts","$qaRoot/scenes","$qaRoot/assets" -Destination $qaCopy -Recurse
$qaConfig = Get-Content "$qaCopy/project.godot" -Raw
$qaConfig = $qaConfig.Replace('config/name="damagochi"', 'config/name="damagochi"' + "`nconfig/use_custom_user_dir=true`nconfig/custom_user_dir_name=" + '"' + $qaId + '"')
Set-Content "$qaCopy/project.godot" $qaConfig
Copy-Item "$PSScriptRoot/qa_verify.gd" $qaCopy
Copy-Item "$qaRoot/tests/step_23/dev_verify.gd" "$qaCopy/movement_verify.gd"
Copy-Item "$qaRoot/tests/step_22/resume_verify.gd" $qaCopy
@{project=$qaCopy;evidence=$qaLogs;user_dir=(Join-Path $env:APPDATA $qaId)} | ConvertTo-Json | Set-Content "$qaRoot/docs/reports/step_24/qa_paths.json"
function Run([string]$Script,[string]$Label,[string]$Mode='',[switch]$Render) {
    $qaArgs = @('--path',$qaCopy,'--script',"res://$Script",'--log-file',"$qaLogs/$Label.log")
    if (-not $Render) { $qaArgs += '--headless' }
    if ($Mode) { $qaArgs += @('--',$Mode) }
    & $Godot @qaArgs
    if ($LASTEXITCODE -ne 0 -or (Select-String -Path "$qaLogs/$Label.log" -Pattern 'SCRIPT ERROR:|^FAIL ' -Quiet)) { throw "Failed $Label" }
}
try {
    & $Godot --version | Set-Content "$qaLogs/version.txt"
    & $Godot --headless --path $qaCopy --editor --import --quit --log-file "$qaLogs/import.log"
    if ($LASTEXITCODE -ne 0) { throw 'Import failed' }
    Run 'qa_verify.gd' 'qa'
    Run 'movement_verify.gd' 'qa_movement'
    Run 'resume_verify.gd' 'qa_menu' 'suite'
    foreach ($qaStage in @('egg','baby','hatch')) {
        Run 'resume_verify.gd' "qa_seed_$qaStage" "seed_$qaStage"
        Run 'resume_verify.gd' "qa_resume_$qaStage" "resume_$qaStage"
    }
    Run 'qa_verify.gd' 'qa_render' -Render
    Get-ChildItem $qaCopy -Filter 'qa_*.png' | Copy-Item -Destination $qaLogs
} finally {
    $qaAfter = SaveHash
    $qaAfter | Set-Content "$qaLogs/original_after.txt"
    if ($qaBefore -ne $qaAfter) { throw 'Original save changed' }
    Write-Output "Evidence: $qaLogs"
}
