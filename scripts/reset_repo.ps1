
param([string]$PackZip = "panel_clean_slate_pack.zip", [string]$Branch = "clean-slate")
$repo = Get-Location
$backup = Join-Path $repo "backup_before_clean.zip"
Write-Host "Backup: $backup"
Compress-Archive -Path (Get-ChildItem -Force | Where-Object { $_.Name -ne ".git" }) -DestinationPath $backup -Force
Expand-Archive -Path $PackZip -DestinationPath $repo -Force
git checkout -b $Branch
git add -A
git commit -m "Clean slate: known-good overlay baseline"
git push -u origin $Branch
