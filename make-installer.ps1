# Makes Kairo's Windows installer, for sharing: a release build with no
# folder names of this computer in it, the licenses and notices the GPL and
# Kairo's dependencies ask for, and Inno Setup's installer around them.
# Double-click "Make Installer.cmd" to run it. The installer ends up in
# target\dist\kairo, which opens when it's done.
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
Set-Location $root

# The build's tools: Visual Studio's C++ tools, LLVM and NASM.
. (Join-Path $root 'kairo.ps1') -SetupOnly

# Inno Setup, which makes the installer; installed for this user if missing.
function Find-Iscc {
    @(
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
        "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
        "${env:ProgramFiles(x86)}\Inno Setup 7\ISCC.exe",
        "$env:ProgramFiles\Inno Setup 7\ISCC.exe",
        "$env:LOCALAPPDATA\Programs\Inno Setup 7\ISCC.exe"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
}
$iscc = Find-Iscc
if (-not $iscc) {
    Write-Host 'Installing Inno Setup, which makes the installer...'
    winget install --id JRSoftware.InnoSetup -e --scope user --accept-source-agreements --accept-package-agreements
    $iscc = Find-Iscc
    if (-not $iscc) { throw "Inno Setup didn't install. Install it from https://jrsoftware.org/isdl.php and run this again." }
}

# The release build. Rust names source folders in its error messages; these
# map this computer's (its home folder among them) to neutral names, as
# scripts/release-env does for Yapfast's releases. They replace
# .cargo/config.toml's rustflags, so its static runtime comes along.
$cargoHome = if ($env:CARGO_HOME) { $env:CARGO_HOME } else { Join-Path $HOME '.cargo' }
$flags = @(
    '-Ctarget-feature=+crt-static',
    "--remap-path-prefix=$HOME=/home",
    "--remap-path-prefix=$cargoHome=/cargo",
    "--remap-path-prefix=$root=/kairo"
)
$env:CARGO_ENCODED_RUSTFLAGS = $flags -join [char]0x1f
Write-Host 'Building Kairo for release. The first time takes a while.'
cargo build --locked --release
if ($LASTEXITCODE -ne 0) { throw 'The build failed; see the errors above.' }
Remove-Item Env:\CARGO_ENCODED_RUSTFLAGS
$exe = Join-Path $root 'target\release\yapfast.exe'

# What the installer installs.
$version = (Select-String -Path (Join-Path $root 'Cargo.toml') -Pattern '^version = "(.*)"$' |
    Select-Object -First 1).Matches[0].Groups[1].Value
$commit = (git -C $root rev-parse --short HEAD).Trim()
$dist = Join-Path $root 'target\dist\kairo'
$package = Join-Path $dist 'package'
if (Test-Path $package) { Remove-Item $package -Recurse -Force }
New-Item -ItemType Directory -Path $package | Out-Null
Copy-Item $exe (Join-Path $package 'yapfast.exe')
Copy-Item (Join-Path $root 'LICENSE') (Join-Path $package 'LICENSE.txt')
@"
Kairo $version, built from commit $commit.

Kairo is Yapfast with extra features, and free software under the GNU
General Public License, version 3 or later, in LICENSE.txt. Its source code
is at https://github.com/Nobakrec/Kairo, and Yapfast's at
https://github.com/yapfast/yapfast. The licenses folder holds every
dependency's own license and notices; THIRD-PARTY.json lists them.
"@ | Set-Content -Path (Join-Path $package 'SOURCE.txt') -Encoding utf8

# The dependencies' licenses, with the repository's own helper, as Yapfast's
# releases carry them. libwebrtc's comes from the copy the build downloaded.
$webrtc = @('release', 'fast') | ForEach-Object { Join-Path $root "target\$_\build\scratch" } |
    Where-Object { Test-Path $_ } |
    ForEach-Object { Get-ChildItem $_ -Recurse -Filter 'LICENSE.md' -ErrorAction SilentlyContinue } |
    Where-Object { Test-Path (Join-Path $_.DirectoryName 'include') } | Select-Object -First 1
if (-not $webrtc) { throw "Couldn't find libwebrtc's license in the build." }
$notices = @"
import json, subprocess, sys
from pathlib import Path
sys.path.insert(0, r'$root\scripts')
from release_package import dependency_notices
metadata = json.loads(subprocess.check_output(
    ['cargo', 'metadata', '--locked', '--format-version', '1',
     '--filter-platform', 'x86_64-pc-windows-msvc', '--no-default-features', '--features', 'desktop,discord'],
    cwd=r'$root'))
package = Path(r'$package')
found = dependency_notices(metadata, package, package / 'licenses', Path(r'$($webrtc.DirectoryName)'))
(package / 'THIRD-PARTY.json').write_text(json.dumps(found, indent=2) + '\n', encoding='utf-8')
"@
python -c $notices
if ($LASTEXITCODE -ne 0) { throw "Couldn't gather the licenses; see the errors above." }

# The installer.
$numeric = ($version -split '-')[0] + '.0'
& $iscc /Q "/DAppVersion=$version" "/DVersionNumber=$numeric" "/DSourceDir=$package" `
    "/DLicenseFile=$root\LICENSE" "/O$dist" (Join-Path $root 'packaging\windows\kairo.iss')
if ($LASTEXITCODE -ne 0) { throw "Inno Setup couldn't make the installer; see the errors above." }
$setup = Join-Path $dist "Kairo-$version-windows-x64-setup.exe"

# SHA256SUMS.txt + a minisign signature, so installed copies can auto-update
# from your GitHub releases. The signing key lives in packaging\keys\kairo.key
# (gitignored). Without it, the installer is still produced; it just won't be
# signed for auto-update.
$sums = Join-Path $dist 'SHA256SUMS.txt'
$hash = (Get-FileHash -Algorithm SHA256 $setup).Hash.ToLower()
"$hash  $(Split-Path $setup -Leaf)" | Set-Content -Path $sums -Encoding ascii -NoNewline
Add-Content -Path $sums -Value "`n" -NoNewline
$key = Join-Path $root 'packaging\keys\kairo.key'
if (Test-Path $key) {
    function Find-Minisign {
        $c = Get-Command minisign -ErrorAction SilentlyContinue
        if ($c) { return $c.Source }
        @("$env:LOCALAPPDATA\Microsoft\WinGet\Links\minisign.exe",
          "$env:ProgramFiles\minisign\minisign.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
    }
    $minisign = Find-Minisign
    if (-not $minisign) {
        Write-Host 'Installing minisign, which signs the release...'
        winget install --id jedisct1.minisign -e --scope user --accept-source-agreements --accept-package-agreements | Out-Null
        $minisign = Find-Minisign
    }
    if ($minisign) {
        # The trusted comment must be exactly this for Kairo's updater to accept it.
        & $minisign -S -W -s $key -m $sums -t "yapfast v$version SHA256SUMS.txt" -c "Kairo v$version"
        if ($LASTEXITCODE -eq 0) { Write-Host 'Signed SHA256SUMS.txt for auto-update.' }
        else { Write-Warning 'Signing failed; the installer is fine, but auto-update needs a valid signature.' }
    } else {
        Write-Warning 'minisign not found; skipped signing. Install it and re-run to enable auto-update.'
    }
} else {
    Write-Host 'No signing key at packaging\keys\kairo.key; skipping the auto-update signature.'
    Write-Host 'Friends can still install the .exe; auto-update just needs the key.'
}
Write-Host ''
Write-Host "Done. Upload everything in this folder to a GitHub Release:"
Write-Host "  $dist"
explorer.exe $dist
