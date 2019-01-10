$mix=(Get-Command mix | Select-Object -ExpandProperty Path)
$env:MIX_ENV="prod"
mix release