# Builds and runs Kairo with everything its build needs, in any PowerShell
# window: Visual Studio's C++ tools, LLVM and NASM.
#
#   .\kairo.ps1               build and run
#   .\kairo.ps1 -BuildOnly    just build
#   .\kairo.ps1 -EmojiLinks   run with emoji always sent as links (to test FakeNitro)
#   . .\kairo.ps1 -SetupOnly  only set up this window's tools (make-installer.ps1 uses it)
#
# If Windows refuses to run scripts, use:
#   powershell -ExecutionPolicy Bypass -File .\kairo.ps1
param([switch]$BuildOnly, [switch]$EmojiLinks, [switch]$SetupOnly)
Set-Location $PSScriptRoot

# Visual Studio's C++ tools and the Windows SDK, unless this window
# already has them (a Developer PowerShell).
if (-not $env:VCINSTALLDIR) {
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $vs = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
        if ($vs) {
            try {
                Import-Module (Join-Path $vs 'Common7\Tools\Microsoft.VisualStudio.DevShell.dll')
                Enter-VsDevShell -VsInstallPath $vs -SkipAutomaticLocation -DevCmdArguments '-arch=x64 -host_arch=x64' | Out-Null
            } catch {
                Write-Warning "Visual Studio's developer shell reported a problem; carrying on: $_"
            }
        }
    }
    if (-not $env:VCINSTALLDIR) {
        Write-Warning "Couldn't set up Visual Studio's C++ tools. If the build fails to link, install 'Desktop development with C++' from Visual Studio Installer."
    }
}

# LLVM: clang-cl, lld-link (the linker Kairo uses) and libclang.
$llvm = 'C:\Program Files\LLVM\bin'
if (-not (Test-Path "$llvm\lld-link.exe")) {
    Write-Error "LLVM isn't installed at $llvm. Run: winget install --id LLVM.LLVM -e"
    exit 1
}
$env:Path = "$llvm;$env:Path"
$env:LIBCLANG_PATH = $llvm

# NASM, for FFmpeg's and x264's assembly.
$nasm = @(
    "$env:LOCALAPPDATA\bin\NASM\nasm.exe",
    'C:\Program Files\NASM\nasm.exe',
    'C:\Program Files (x86)\NASM\nasm.exe'
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $nasm) {
    Write-Error "NASM isn't installed. Run: winget install --id NASM.NASM -e"
    exit 1
}
$env:NASM = $nasm
$env:Path = "$(Split-Path $nasm);$env:Path"

if ($SetupOnly) { return }

if ($EmojiLinks) { $env:YAPFAST_EMOJI_LINKS = 'always' }

if ($BuildOnly) {
    cargo build --locked --profile fast
} else {
    cargo run --locked --profile fast
}
exit $LASTEXITCODE
