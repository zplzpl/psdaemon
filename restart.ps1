# # An example of parameters handle:
# param (
#    [string]$server = "http://defaultserver",
#    [Parameter(Mandatory=$true)][string]$username, # Username is not necessary
#    [string]$password = $( Read-Host "Input password, please" )
# )

# But we will work with arguments

$env:PSModulePath += ';' + $PSScriptRoot

$name = $args[0]
PsDaemonRestart $name