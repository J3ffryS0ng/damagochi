param([string]$Godot='C:/Godot/Godot_console.exe',[string]$RetryLabel='')
$ErrorActionPreference='Stop'
$root=(Resolve-Path "$PSScriptRoot/../..").Path
$registry="$root/docs/reports/step_46/dev_paths.json"
if($RetryLabel) {
 $paths=Get-Content $registry -Raw | ConvertFrom-Json
 $copy=$paths.project; $logs=$paths.evidence
 if(-not $copy.StartsWith([IO.Path]::GetFullPath($env:TEMP),[StringComparison]::OrdinalIgnoreCase) -or -not $copy.Contains('step46-dev-')) {throw 'Unsafe retry path'}
 if(Test-Path "$logs/${RetryLabel}_retry.log") {throw 'Single retry already used'}
} else {
 $id='damagochi-step22-resume-step23-step27-step30-step32-35-dev-step46-dev-'+[guid]::NewGuid().ToString('N')
 $copy=Join-Path $env:TEMP $id
 $logs="$root/docs/reports/step_46/$id"
 New-Item -ItemType Directory $copy,$logs | Out-Null
 Copy-Item "$root/project.godot","$root/icon.svg","$root/scripts","$root/scenes","$root/assets","$root/data" -Destination $copy -Recurse
 $config=Get-Content "$copy/project.godot" -Raw
 $config=$config.Replace('config/name="damagochi"','config/name="damagochi"'+"`nconfig/use_custom_user_dir=true`nconfig/custom_user_dir_name="+'"'+$id+'"')
 Set-Content "$copy/project.godot" $config
 Copy-Item "$PSScriptRoot/dev_verify.gd" $copy
 Copy-Item "$root/tests/step_32_35/dev_failure.gd" "$copy/dev_failure.gd"
 Copy-Item "$root/tests/step_30/play_failure.gd" $copy
 Copy-Item "$root/tests/step_27/dev_failure.gd" "$copy/feed_failure.gd"
 $regressions=@{'clean_verify.gd'='step_32_35';'play_verify.gd'='step_30';'feed_verify.gd'='step_27'}
 foreach($name in $regressions.Keys) {
  $source=Get-Content "$root/tests/$($regressions[$name])/dev_verify.gd" -Raw
  if($name -eq 'feed_verify.gd') {$source=$source.Replace('res://dev_failure.gd','res://feed_failure.gd')}
  $source=[regex]::Replace($source,'(?m)^(\s*)gm\.create_new_game\(([^\r\n]*)\)','$1gm.game_data = GameDataFactory.create_new_game($2)')
  Set-Content "$copy/$name" $source
 }
 Copy-Item "$root/tests/step_22/resume_verify.gd" $copy
 @{project=$copy;evidence=$logs;user_dir=(Join-Path $env:APPDATA $id);original_save_accessed=$false} | ConvertTo-Json | Set-Content $registry
 Get-ChildItem "$root/scripts","$root/data","$root/assets" -Recurse -File | Where-Object {$_.Extension -ne '.import'} | Get-FileHash -Algorithm SHA256 | Select-Object Path,Hash | ConvertTo-Json | Set-Content "$logs/product_hashes.json"
}
$results=@()
if(Test-Path "$logs/results.json") {$results=@(Get-Content "$logs/results.json" -Raw | ConvertFrom-Json)}
function Run([string]$Script,[string]$Label,[string]$Mode='') {
 $arguments=@('--headless','--path',$copy,'--script',"res://$Script",'--log-file',"$logs/$Label.log")
 if($Mode) {$arguments+=@('--',$Mode)}
 $quoted=$arguments | ForEach-Object {'"'+$_+'"'}
 $process=Start-Process -FilePath $Godot -ArgumentList $quoted -WindowStyle Hidden -PassThru
 $timeout=-not $process.WaitForExit(180000)
 if($timeout) {$process.Kill()}
 $process.WaitForExit()
 $code=$process.ExitCode
 $script:results+=@{label=$Label;script=$Script;mode=$Mode;exit=$code;timeout=$timeout;passes=@(Select-String "$logs/$Label.log" -Pattern '^PASS ').Count}
 $script:results | ConvertTo-Json | Set-Content "$logs/results.json"
 if($timeout -or $code -ne 0 -or (Select-String "$logs/$Label.log" -Pattern 'SCRIPT ERROR:|^FAIL ' -Quiet)) {throw "$Label failed exit=$code; first evidence preserved"}
}
if($RetryLabel) {
 $previous=@($results | Where-Object {$_.label -eq $RetryLabel})
 if($previous.Count -ne 1 -or $previous[0].exit -ne -1073741819) {throw 'Retry only for one recorded native crash'}
 Run $previous[0].script "${RetryLabel}_retry" $previous[0].mode
 exit 0
}
& $Godot --version | Set-Content "$logs/version.txt"
& $Godot --headless --path $copy --editor --import --quit --log-file "$logs/import.log"
if($LASTEXITCODE -ne 0 -or (Select-String "$logs/import.log" -Pattern 'SCRIPT ERROR:' -Quiet)) {throw 'Import failed'}
Run 'dev_verify.gd' 'core'
Run 'dev_verify.gd' 'seed' 'seed'
Run 'dev_verify.gd' 'restore' 'restore'
Run 'clean_verify.gd' 'clean_regression'
Run 'play_verify.gd' 'play_regression'
Run 'feed_verify.gd' 'feed_regression'
Run 'resume_verify.gd' 'menu_regression' 'suite'
Write-Output "Evidence: $logs"
