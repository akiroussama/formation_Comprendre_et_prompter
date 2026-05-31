# Assemble a deck jour-N.html: template shell + fragments _build/jN/*.html.
# Deterministic concatenation (no LLM, no truncation) + per-day cover/title.
# ASCII-only script body; accents in day metadata are written as HTML entities.
# Reads/writes UTF-8 (no BOM) via .NET so non-ASCII content is never corrupted.
# Usage: powershell -File assemble-deck.ps1 -Day 1
param(
  [Parameter(Mandatory = $true)][int]$Day
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot   # .../presentations-html
$tplPath = Join-Path $PSScriptRoot 'gen-ai-template.html'
$buildDir = Join-Path $root ("_build/j{0}" -f $Day)
$outPath = Join-Path $root ("jour-{0}.html" -f $Day)

if (-not (Test-Path $tplPath)) { throw "Template not found: $tplPath" }
if (-not (Test-Path $buildDir)) { throw "Build dir not found: $buildDir" }

# Per-day metadata (accents as HTML entities so this .ps1 stays pure ASCII).
$meta = @{
  1 = @{ deckTitle = 'Jour 1 &mdash; Comprendre &amp; prompter'; coverAccent = 'Comprendre &amp; prompter'; coverSub = "Comprendre ce qu'est un LLM, mesurer son point de d&eacute;part, et prompter sans jamais exposer une donn&eacute;e." }
  2 = @{ deckTitle = 'Jour 2 &mdash; Qualit&eacute; &amp; Copilot'; coverAccent = 'Qualit&eacute; &amp; Copilot'; coverSub = "Faire produire du code de qualit&eacute; par l'IA, valider ce qu'elle &eacute;crit, et ma&icirc;triser Copilot dans VS Code." }
  3 = @{ deckTitle = 'Jour 3 &mdash; Cr&eacute;er &amp; cl&ocirc;turer'; coverAccent = 'Cr&eacute;er en autonomie'; coverSub = "Construire un livrable sur le POC CA Titres, mesurer le gain r&eacute;el, et repartir avec un plan d'action." }
}
if (-not $meta.ContainsKey($Day)) { throw "No metadata for day $Day" }
$m = $meta[$Day]

$tpl = [System.IO.File]::ReadAllText($tplPath, [System.Text.Encoding]::UTF8)

# Fragments sorted by name (01-..., 02-..., etc.)
$fragFiles = Get-ChildItem (Join-Path $buildDir '*.html') | Sort-Object Name
if ($fragFiles.Count -eq 0) { throw "No fragment in $buildDir" }
$parts = foreach ($f in $fragFiles) { [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8) }
$script:slides = ($parts -join "`n`n")

# 1) Inject fragments: replace demo block (EXEMPLES comment .. just before </main>).
$pattern = '(?s)<!-- =+ EXEMPLES DE TYPES DE SLIDE.*?(?=</main>)'
$evaluator = [System.Text.RegularExpressions.MatchEvaluator] { param($x) $script:slides + "`n`n        " }
$out = [System.Text.RegularExpressions.Regex]::Replace($tpl, $pattern, $evaluator)
if ($out -eq $tpl) { throw "Demo block not found/replaced - check template anchor." }

# 2) Per-day header + cover (literal String.Replace, safe with special chars).
$out = $out.Replace('Formation IA generative', $m.deckTitle)
$out = $out.Replace('Credit Agricole Titres &mdash; pour les developpeurs', 'GEN AI &mdash; Cr&eacute;dit Agricole Titres')
$out = $out.Replace('Formation <span class="accent">GEN AI</span><br>', ('Jour ' + $Day + ' <span class="accent">' + $m.coverAccent + '</span><br>'))
$out = $out.Replace('pour les developpeurs &mdash; Credit Agricole Titres', 'GEN AI &mdash; Cr&eacute;dit Agricole Titres &mdash; Oussama AKIR')
$out = $out.Replace("Trois jours pour comprendre, prompter, controler et creer avec l'IA generative &mdash; sans jamais exposer une donnee.", $m.coverSub)
$out = [System.Text.RegularExpressions.Regex]::Replace($out, '<title>.*?</title>', ('<title>GEN AI - Jour ' + $Day + '</title>'))

$utf8 = New-Object System.Text.UTF8Encoding($false)  # UTF-8 without BOM
[System.IO.File]::WriteAllText($outPath, $out, $utf8)

$slideCount = ([regex]::Matches($out, 'class="slide"')).Count
Write-Output ("OK -> {0}" -f $outPath)
Write-Output ("Day {0} | fragments: {1} | total slides: {2}" -f $Day, $fragFiles.Count, $slideCount)
