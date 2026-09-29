# ============================================================
#  Momentum - one-shot deploy to YOUR PERSONAL GitHub Pages
#  Run this file AFTER you have logged in with your personal
#  GitHub account (see step 1 below).
# ============================================================
#
#  STEP 1 (only once): log in to your PERSONAL GitHub
#     gh auth login
#     -> GitHub.com  ->  HTTPS  ->  Login with a web browser
#     -> make sure the browser is signed into your PERSONAL account
#
#  STEP 2: run this script
#     cd C:\Users\rjee\Documents\My_Life_Plan\GitHubPages
#     ./deploy.ps1
# ============================================================

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

Write-Host "Checking GitHub login..." -ForegroundColor Cyan
gh auth status

# Who am I logged in as?
$me = (gh api user --jq '.login').Trim()
if (-not $me) { Write-Host "Not logged in. Run: gh auth login" -ForegroundColor Red; exit 1 }
Write-Host "Deploying as PERSONAL account: $me" -ForegroundColor Green

# Make sure the newest app is bundled in
Copy-Item '..\tracker.html' '.\index.html' -Force
git add -A
git commit -m "Update Momentum" 2>$null

# Create the repo on your account (if it already exists this is skipped) and push
$exists = $false
try { gh repo view "$me/momentum" *> $null; $exists = $true } catch { $exists = $false }
if (-not $exists) {
    gh repo create momentum --public --source=. --push
} else {
    git remote remove origin 2>$null
    git remote add origin "https://github.com/$me/momentum.git"
    git branch -M main
    git push -u origin main
}

# Turn on GitHub Pages (main branch, root folder)
Write-Host "Enabling GitHub Pages..." -ForegroundColor Cyan
try {
    '{"source":{"branch":"main","path":"/"}}' | gh api -X POST "repos/$me/momentum/pages" --input - | Out-Null
    Write-Host "GitHub Pages enabled." -ForegroundColor Green
} catch {
    Write-Host "Could not auto-enable Pages. Do it once in the browser:" -ForegroundColor Yellow
    Write-Host "   https://github.com/$me/momentum/settings/pages" -ForegroundColor Yellow
    Write-Host "   -> Branch: main  -> / (root)  -> Save" -ForegroundColor Yellow
}

$url = "https://" + $me.ToLower() + ".github.io/momentum/"
Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host " DONE! Your app will be live in ~1 minute at:" -ForegroundColor Green
Write-Host "   $url" -ForegroundColor White
Write-Host " Open it on your phone -> menu -> 'Add to Home Screen'." -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
