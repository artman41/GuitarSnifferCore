$mix=(Get-Command mix | Select-Object -ExpandProperty Path)
$iex="$($mix)/../iex.bat"
mix deps.clean --all
mix deps.get
$env:MIX_ENV="prod"
mix release