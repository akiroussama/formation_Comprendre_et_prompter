# Garde "accents seulement" : prouve mecaniquement que la passe d'accents n'a
# change QUE des accents. Fold(avant) == Fold(apres) ou Fold = decode les
# entites d'accent + plie les diacritiques (e accent -> e) + collapse espaces.
# Si egal -> seuls les accents ont change (aucune balise/mot/structure touchee).
# ASCII-only ; lecture UTF-8 via .NET. -Promote copie les fragments OK vers _build.
# Usage: powershell -File check-accents-guard.ps1 [-Promote]
param([switch]$Promote)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$before = Join-Path $root '_build'
$after = Join-Path $root '_build_fixed'

function Fold([string]$s) {
  # Decode TOUTES les entites (accents, &amp;, &mdash;, &nbsp;, pictos...) -> vrais
  # caracteres. Applique avant ET apres, donc les entites non-accent s'annulent.
  $s = [System.Net.WebUtility]::HtmlDecode($s)
  $d = $s.Normalize([System.Text.NormalizationForm]::FormD)
  $sb = New-Object System.Text.StringBuilder
  foreach ($ch in $d.ToCharArray()) {
    if ([System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch) -ne [System.Globalization.UnicodeCategory]::NonSpacingMark) { [void]$sb.Append($ch) }
  }
  $s = $sb.ToString().Normalize([System.Text.NormalizationForm]::FormC)
  $s = [System.Text.RegularExpressions.Regex]::Replace($s, '\s+', ' ')
  return $s.Trim()
}

$pass = @(); $fail = @(); $missingOrig = @()
foreach ($day in 1,2,3) {
  $afterDir = Join-Path $after ("j{0}" -f $day)
  if (-not (Test-Path $afterDir)) { continue }
  Get-ChildItem (Join-Path $afterDir '*.html') | Sort-Object Name | ForEach-Object {
    $rel = "j$day/$($_.Name)"
    $borig = Join-Path $before ("j{0}\{1}" -f $day, $_.Name)
    if (-not (Test-Path $borig)) { $missingOrig += $rel; return }
    $fb = Fold([System.IO.File]::ReadAllText($borig, [System.Text.Encoding]::UTF8))
    $fa = Fold([System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8))
    if ($fb -ceq $fa) {
      $pass += $rel
      if ($Promote) { Copy-Item -Path $_.FullName -Destination $borig -Force }
    } else {
      $fail += $rel
    }
  }
}

Write-Output ("Fragments corriges presents : {0}" -f ($pass.Count + $fail.Count))
Write-Output ("PASS (accents seulement) : {0}" -f $pass.Count)
Write-Output ("FAIL (autre chose a change) : {0}" -f $fail.Count)
if ($fail.Count -gt 0) { $fail | ForEach-Object { Write-Output ("   FAIL -> {0}" -f $_) } }
if ($missingOrig.Count -gt 0) { Write-Output ("Sans original : {0}" -f ($missingOrig -join ', ')) }
if ($Promote) { Write-Output ("Promus vers _build : {0}" -f $pass.Count) }

if ($fail.Count -gt 0) { exit 1 } else { exit 0 }
