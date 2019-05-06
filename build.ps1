Push-Location $PSScriptRoot

# Prepare
$build = "$PSScriptRoot\build"
$dist = "$PSScriptRoot\dist"
$src = "$PSScriptRoot\src"
New-Item -ItemType Directory -Path $build -ErrorAction SilentlyContinue | Out-Null
New-Item -ItemType Directory -Path $dist -ErrorAction SilentlyContinue | Out-Null
Remove-Item "$build\*" -Recurse -Force | Out-Null
Remove-Item "$dist\*" -Recurse -Force | Out-Null

# Build
Copy-Item "$PSScriptRoot\packages\Newtonsoft.Json\lib\net45\Newtonsoft.Json.dll" $build
Copy-Item "$PSScriptRoot\packages\Newtonsoft.Json.Schema\lib\net45\Newtonsoft.Json.Schema.dll" $build
Write-Output 'Compiling Scoop.Validator.cs ...'
& "$PSScriptRoot\packages\Microsoft.Net.Compilers\tools\csc.exe" /deterministic /platform:anycpu /nologo /optimize /target:library /reference:"$build\Newtonsoft.Json.dll","$build\Newtonsoft.Json.Schema.dll" /out:"$build\Scoop.Validator.dll" "$src\Scoop.Validator.cs"
Write-Output 'Compiling validator.cs ...'
& "$PSScriptRoot\packages\Microsoft.Net.Compilers\tools\csc.exe" /deterministic /platform:anycpu /nologo /optimize /target:exe /reference:"$build\Scoop.Validator.dll","$build\Newtonsoft.Json.dll","$build\Newtonsoft.Json.Schema.dll" /out:"$build\validator.exe" "$src\validator.cs"

# Checksums
Write-Output 'Computing checksums ...'
Get-ChildItem "$build\*" -Include *.exe,*.dll -Recurse | ForEach-Object {
    $checksum = (Get-FileHash -Path $_.FullName -Algorithm SHA256).Hash.ToLower()
    "$checksum *$($_.FullName.Replace($build, '').TrimStart('\'))" | Tee-Object -FilePath "$build\checksums.sha256" -Append
}

# Package
7z a "$dist\validator.zip" "$build\*"
Get-ChildItem "$dist\*" | ForEach-Object {
    $checksum = (Get-FileHash -Path $_.FullName -Algorithm SHA256).Hash.ToLower()
    "$checksum *$($_.Name)" | Tee-Object -FilePath "$dist\$($_.Name).sha256" -Append
}
Pop-Location
