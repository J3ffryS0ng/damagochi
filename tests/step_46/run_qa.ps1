param([string]$Godot='C:/Godot/Godot_console.exe',[switch]$ExitSmoke)
$ErrorActionPreference='Stop'
$qaRoot=(Resolve-Path "$PSScriptRoot/../..").Path
if ($ExitSmoke) {
    $qaPaths=Get-Content "$qaRoot/docs/reports/step_46/qa_paths.json" -Raw | ConvertFrom-Json
    $qaCopy=$qaPaths.project
    $qaLogs=$qaPaths.evidence
    Copy-Item "$PSScriptRoot/qa_verify.gd" $qaCopy
    Copy-Item "$qaRoot/tests/step_30/qa_failure_game.gd" "$qaCopy/play_failure_game.gd"
} else {
    $qaId='damagochi-step22-resume-step23-step27-step30-qa-step46-qa-'+[guid]::NewGuid().ToString('N')
    $qaCopy=Join-Path $env:TEMP $qaId
    $qaLogs=Join-Path $qaRoot "docs/reports/step_46/$qaId"
    New-Item -ItemType Directory $qaCopy,$qaLogs | Out-Null
    Copy-Item "$qaRoot/project.godot","$qaRoot/icon.svg","$qaRoot/scripts","$qaRoot/scenes","$qaRoot/assets","$qaRoot/data" -Destination $qaCopy -Recurse
    $qaConfig=Get-Content "$qaCopy/project.godot" -Raw
    $qaConfig=$qaConfig.Replace('config/name="damagochi"','config/name="damagochi"'+"`nconfig/use_custom_user_dir=true`nconfig/custom_user_dir_name="+'"'+$qaId+'"')
    Set-Content "$qaCopy/project.godot" $qaConfig
    Copy-Item "$PSScriptRoot/qa_verify.gd" $qaCopy
    Copy-Item "$qaRoot/tests/step_30/qa_failure_game.gd" "$qaCopy/play_failure_game.gd"
    Copy-Item "$qaRoot/tests/step_30/qa_verify.gd" "$qaCopy/play_verify.gd"
    Copy-Item "$qaRoot/tests/step_27/qa_verify.gd" "$qaCopy/feed_verify.gd"
    Copy-Item "$qaRoot/tests/step_27/qa_failure_game.gd" $qaCopy
    (Get-Content "$qaCopy/feed_verify.gd" -Raw).Replace("step27-qa-","step27-step30-qa-step46-qa-") | Set-Content "$qaCopy/feed_verify.gd"

    Copy-Item "$qaRoot/tests/step_22/resume_verify.gd" $qaCopy
    Copy-Item "$qaRoot/tests/step_32_35/qa_verify.gd" "$qaCopy/clean_verify.gd"
    Copy-Item "$qaRoot/tests/step_32_35/qa_failure.gd" $qaCopy
    (Get-Content "$qaCopy/clean_verify.gd" -Raw).Replace("step32-35-qa-","step46-qa-") | Set-Content "$qaCopy/clean_verify.gd"
    @{project=$qaCopy;evidence=$qaLogs;user_dir=(Join-Path $env:APPDATA $qaId);original_save_accessed=$false} | ConvertTo-Json | Set-Content "$qaRoot/docs/reports/step_46/qa_paths.json"
    $qaHashes=foreach ($qaFile in @('scripts/game/game.gd','scenes/game/Game.tscn','assets/food/rice_bowl.svg','assets/images/poop.svg','scripts/managers/game_manager.gd','scripts/managers/save_manager.gd','scripts/managers/creature_catalog.gd','scripts/managers/game_data_factory.gd','data/creatures.json','project.godot','assets/creatures/001/creature_001_idle.png','assets/images/creatures/002/creature_002_idle.png','assets/images/creatures/003/creature_003_idle.png','assets/images/creatures/004/creature_004_idle.png')) { @{path=$qaFile;source=(Get-FileHash "$qaRoot/$qaFile").Hash;copy=(Get-FileHash "$qaCopy/$qaFile").Hash} }
    $qaHashes | ConvertTo-Json | Set-Content "$qaLogs/source_hashes.json"
}
function Run([string]$Script,[string]$Label,[string]$Mode='',[switch]$Render) {
    $qaArgs=@('--path',$qaCopy,'--script',"res://$Script",'--log-file',"$qaLogs/$Label.log")
    if (-not $Render) { $qaArgs+='--headless' }
    if ($Mode) { $qaArgs+=@('--',$Mode) }
    if (($Script -eq 'feed_verify.gd' -or $Script -eq 'play_verify.gd' -or $Script -eq 'clean_verify.gd') -and -not $Mode) {
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
        $qaQuoted=$qaArgs | ForEach-Object { '"'+$_+'"' }
        $qaProcess=Start-Process -FilePath $Godot -ArgumentList $qaQuoted -PassThru -WindowStyle Hidden
        if (-not $qaProcess.WaitForExit(180000)) { $qaProcess.Kill(); throw "QA timeout $Label" }
        $qaProcess.WaitForExit()
        $qaExit=$qaProcess.ExitCode
    }
    @{native_exit=$qaExit} | ConvertTo-Json | Set-Content "$qaLogs/$Label.status.json"
    if ($qaExit -ne 0 -or (Select-String -Path "$qaLogs/$Label.log" -Pattern 'SCRIPT ERROR:|^FAIL ' -Quiet)) { throw "Failed $Label exit $qaExit" }
}
if ($ExitSmoke) {
    foreach ($qaEntry in @('menu','game')) {
        $qaExitArgs=@('--path',$qaCopy,'--quit-after','120','--log-file',"$qaLogs/qa_native_${qaEntry}_exit.log")
        if($qaEntry -eq 'game') { $qaExitArgs+='res://scenes/game/Game.tscn' }
        $qaProcess=Start-Process -FilePath $Godot -ArgumentList ($qaExitArgs | ForEach-Object { '"'+$_+'"' }) -PassThru -WindowStyle Hidden
        if (-not $qaProcess.WaitForExit(60000)) { $qaProcess.Kill(); throw 'Native smoke timeout' }
        $qaProcess.WaitForExit()
        $LASTEXITCODE=$qaProcess.ExitCode
        $qaExit=$LASTEXITCODE
        @{native_exit=$qaExit} | ConvertTo-Json | Set-Content "$qaLogs/qa_native_${qaEntry}_exit.status.json"
        if($qaExit -ne 0) {
            $qaRetryArgs=$qaExitArgs.Clone()
            $qaRetryArgs[$qaRetryArgs.IndexOf('--log-file')+1]="$qaLogs/qa_native_${qaEntry}_exit_retry.log"
            $qaProcess=Start-Process -FilePath $Godot -ArgumentList ($qaRetryArgs | ForEach-Object { '"'+$_+'"' }) -PassThru -WindowStyle Hidden
            if (-not $qaProcess.WaitForExit(60000)) { $qaProcess.Kill(); throw 'Native smoke retry timeout' }
            $qaProcess.WaitForExit()
            $LASTEXITCODE=$qaProcess.ExitCode
            @{native_exit=$LASTEXITCODE;first_native_exit=$qaExit;known_issue='BUG005 observation'} | ConvertTo-Json | Set-Content "$qaLogs/qa_native_${qaEntry}_exit_retry.status.json"
            if($LASTEXITCODE -ne 0) { throw "Repeated native exit failed: $qaEntry" }
        }
        if(Select-String -Path "$qaLogs/qa_native_${qaEntry}_exit.log" -Pattern 'SCRIPT ERROR:' -Quiet) { throw "Native exit script failed: $qaEntry" }
    }
} else {
    & $Godot --version | Set-Content "$qaLogs/version.txt"
    & $Godot --headless --path $qaCopy --editor --import --quit --log-file "$qaLogs/import.log"
    if ($LASTEXITCODE -ne 0) { throw 'Import failed' }
    Run 'qa_verify.gd' 'qa'
    foreach ($qaSpecies in @('001','002','003','004')) {
        foreach ($qaLevel in @('4','5','6')) {
            Run 'qa_verify.gd' "qa_seed_${qaSpecies}_$qaLevel" "seed_${qaSpecies}_$qaLevel"
            Run 'qa_verify.gd' "qa_restore_${qaSpecies}_$qaLevel" "restore_${qaSpecies}_$qaLevel"
        }
    }
    Run 'play_verify.gd' 'qa_play'
    Run 'play_verify.gd' 'qa_play_resume' 'resume'
    Run 'feed_verify.gd' 'qa_feed'
    Run 'feed_verify.gd' 'qa_feed_resume' 'resume'


    Run 'resume_verify.gd' 'qa_menu' 'suite'
    Run 'clean_verify.gd' 'qa_clean'
    Run 'clean_verify.gd' 'qa_clean_resume' 'resume'
    foreach ($qaStage in @('egg','baby','hatch')) {
        Run 'resume_verify.gd' "qa_seed_$qaStage" "seed_$qaStage"
        Run 'resume_verify.gd' "qa_restore_$qaStage" "resume_$qaStage"
    }
}
Write-Output "Evidence: $qaLogs"



















