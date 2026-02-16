# Start Rails and Sidekiq together
# Run this in PowerShell: .\start_dev.ps1

Write-Host "Starting Rails server and Sidekiq..." -ForegroundColor Green

# Start Sidekiq in a background job
$sidekiq = Start-Job -ScriptBlock {
    Set-Location "C:\evm1"
    bundle exec sidekiq
}

Write-Host "Sidekiq started (Job ID: $($sidekiq.Id))" -ForegroundColor Yellow

# Start Rails server in the foreground
Write-Host "Starting Rails server..." -ForegroundColor Green
rails server

# When Rails server stops (Ctrl+C), clean up Sidekiq
Write-Host "`nStopping Sidekiq..." -ForegroundColor Yellow
Stop-Job $sidekiq
Remove-Job $sidekiq
Write-Host "All services stopped." -ForegroundColor Green
