param([string]$Godot='C:/Godot/Godot_console.exe',[switch]$RenderOnly,[switch]$ExitSmoke,[switch]$CompletionOnly)
$ErrorActionPreference='Stop'
$qaRoot=(Resolve-Path "$PSScriptRoot/../..").Path
if ($RenderOnly -or $ExitSmoke -or $CompletionOnly) {
    $qaPaths=Get-Content "$qaRoot/docs/reports/step_31/qa_paths.json" -Raw | ConvertFrom-Json
    $qaCopy=$qaPaths.project
    $qaLogs=$qaPaths.evidence
    Copy-Item "$PSScriptRoot/qa_verify.gd" $qaCopy
    Copy-Item "$qaRoot/tests/step_30/qa_failure_game.gd" "$qaCopy/play_failure_game.gd"
} else {
    $qaId='damagochi-step22-resume-step23-step27-step30-qa-step31-qa-'+[guid]::NewGuid().ToString('N')
    $qaCopy=Join-Path $env:TEMP $qaId
    $qaLogs=Join-Path $qaRoot "docs/reports/step_31/$qaId"
    New-Item -ItemType Directory $qaCopy,$qaLogs | Out-Null
    Copy-Item "$qaRoot/project.godot","$qaRoot/icon.svg","$qaRoot/scripts","$qaRoot/scenes","$qaRoot/assets" -Destination $qaCopy -Recurse
    $qaConfig=Get-Content "$qaCopy/project.godot" -Raw
    $qaConfig=$qaConfig.Replace('config/name="damagochi"','config/name="damagochi"'+"`nconfig/use_custom_user_dir=true`nconfig/custom_user_dir_name="+'"'+$qaId+'"')
    Set-Content "$qaCopy/project.godot" $qaConfig
    Copy-Item "$PSScriptRoot/qa_verify.gd" $qaCopy
    Copy-Item "$qaRoot/tests/step_30/qa_failure_game.gd" "$qaCopy/play_failure_game.gd"
    Copy-Item "$qaRoot/tests/step_30/qa_verify.gd" "$qaCopy/play_verify.gd"
    Copy-Item "$qaRoot/tests/step_27/qa_verify.gd" "$qaCopy/feed_verify.gd"
    Copy-Item "$qaRoot/tests/step_27/qa_failure_game.gd" $qaCopy
    (Get-Content "$qaCopy/feed_verify.gd" -Raw).Replace("step27-qa-","step27-step30-qa-step31-qa-") | Set-Content "$qaCopy/feed_verify.gd"
    Copy-Item "$qaRoot/tests/step_23/dev_verify.gd" "$qaCopy/movement_verify.gd"
    Copy-Item "$qaRoot/tests/step_22/resume_verify.gd" $qaCopy
    @{project=$qaCopy;evidence=$qaLogs;user_dir=(Join-Path $env:APPDATA $qaId);original_save_accessed=$false} | ConvertTo-Json | Set-Content "$qaRoot/docs/reports/step_31/qa_paths.json"
    $qaHashes=foreach ($qaFile in @('scripts/game/game.gd','scenes/game/Game.tscn','assets/food/rice_bowl.svg','scripts/managers/game_manager.gd','scripts/managers/save_manager.gd')) { @{path=$qaFile;source=(Get-FileHash "$qaRoot/$qaFile").Hash;copy=(Get-FileHash "$qaCopy/$qaFile").Hash} }
    $qaHashes | ConvertTo-Json | Set-Content "$qaLogs/source_hashes.json"
}
function Run([string]$Script,[string]$Label,[string]$Mode='',[switch]$Render) {
    $qaArgs=@('--path',$qaCopy,'--script',"res://$Script",'--log-file',"$qaLogs/$Label.log")
    if (-not $Render) { $qaArgs+='--headless' }
    if ($Mode) { $qaArgs+=@('--',$Mode) }
    if (($Script -eq 'feed_verify.gd' -or $Script -eq 'play_verify.gd') -and -not $Mode) {
        foreach($qaMarker in @('readonly.ready','readonly.go','readonly.done','readonly.released')) {
            $qaMarkerPath=Join-Path $qaCopy $qaMarker
            if(Test-Path -LiteralPath $qaMarkerPath) { Remove-Item -LiteralPath $qaMarkerPath }
        }
        $qaQuoted=$qaArgs | ForEach-Object { '"'+$_+'"' }
        $qaProcess=Start-Process -FilePath $Godot -ArgumentList $qaQuoted -PassThru -WindowStyle Hidden
        $qaStarted=Get-Date
        $qaReadOnlyFile=$null
        try {
            while(-not $qaProcess.HasExited) {
                if((Test-Path "$qaCopy/readonly.ready") -and -not (Test-Path "$qaCopy/readonly.go")) {
                    $qaReadOnlyFile=Get-Content "$qaCopy/readonly.ready" -Raw
                    $qaResolved=[IO.Path]::GetFullPath($qaReadOnlyFile)
                    if (-not $qaResolved.StartsWith([IO.Path]::GetFullPath((Join-Path $env:APPDATA (Split-Path $qaCopy -Leaf))))) { throw 'Unexpected save path' }
                    (Get-Item -LiteralPath $qaReadOnlyFile).IsReadOnly=$true
                    Set-Content "$qaCopy/readonly.go" 'go'
                }
                if((Test-Path "$qaCopy/readonly.done") -and -not (Test-Path "$qaCopy/readonly.released")) {
                    (Get-Item -LiteralPath $qaReadOnlyFile).IsReadOnly=$false
                    Set-Content "$qaCopy/readonly.released" 'released'
                }
                if(((Get-Date)-$qaStarted).TotalSeconds -gt 180) { $qaProcess.Kill(); throw 'QA timeout' }
                Start-Sleep -Milliseconds 50
                $qaProcess.Refresh()
            }
            $qaProcess.WaitForExit()
            $qaExit=$qaProcess.ExitCode
        } finally {
            if($qaReadOnlyFile -and (Test-Path -LiteralPath $qaReadOnlyFile)) { (Get-Item -LiteralPath $qaReadOnlyFile).IsReadOnly=$false }
        }
    } else {
        & $Godot @qaArgs
        $qaExit=$LASTEXITCODE
    }
    @{native_exit=$qaExit} | ConvertTo-Json | Set-Content "$qaLogs/$Label.status.json"
    if ($qaExit -ne 0 -or (Select-String -Path "$qaLogs/$Label.log" -Pattern 'SCRIPT ERROR:|^FAIL ' -Quiet)) { throw "Failed $Label exit $qaExit" }
}
if ($ExitSmoke) {
    foreach ($qaEntry in @('menu','game')) {
        $qaExitArgs=@('--path',$qaCopy,'--quit-after','120','--log-file',"$qaLogs/qa_native_${qaEntry}_exit.log")
        if($qaEntry -eq 'game') { $qaExitArgs+='res://scenes/game/Game.tscn' }
        & $Godot @qaExitArgs
        $qaExit=$LASTEXITCODE
        @{native_exit=$qaExit} | ConvertTo-Json | Set-Content "$qaLogs/qa_native_${qaEntry}_exit.status.json"
        if($qaExit -ne 0 -or (Select-String -Path "$qaLogs/qa_native_${qaEntry}_exit.log" -Pattern 'SCRIPT ERROR:' -Quiet)) { throw "Native exit smoke failed: $qaEntry" }
    }
} elseif ($CompletionOnly) {
    Run 'qa_verify.gd' 'qa_completion' 'completion'
} elseif ($RenderOnly) {
    Run 'qa_verify.gd' 'qa_render' 'render' -Render
    Get-ChildItem $qaCopy -Filter 'qa_*.png' | Copy-Item -Destination $qaLogs
} else {
    & $Godot --version | Set-Content "$qaLogs/version.txt"
    & $Godot --headless --path $qaCopy --editor --import --quit --log-file "$qaLogs/import.log"
    if ($LASTEXITCODE -ne 0) { throw 'Import failed' }
    Run 'qa_verify.gd' 'qa'
    Run 'qa_verify.gd' 'qa_resume' 'resume'
    Run 'play_verify.gd' 'qa_play'
    Run 'play_verify.gd' 'qa_play_resume' 'resume'
    Run 'feed_verify.gd' 'qa_feed'
    Run 'feed_verify.gd' 'qa_feed_resume' 'resume'

    Run 'movement_verify.gd' 'qa_movement'
    Run 'resume_verify.gd' 'qa_menu' 'suite'
    foreach ($qaStage in @('egg','baby','hatch')) {
        Run 'resume_verify.gd' "qa_seed_$qaStage" "seed_$qaStage"
        Run 'resume_verify.gd' "qa_restore_$qaStage" "resume_$qaStage"
    }
}
Write-Output "Evidence: $qaLogs"







