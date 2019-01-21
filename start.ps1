# # An example of parameters handle:
# param (
#    [string]$server = "http://defaultserver",
#    [Parameter(Mandatory=$true)][string]$username, # Username is not necessary
#    [string]$password = $( Read-Host "Input password, please" )
# )

# But we will work with arguments

Import-Module .\PsDaemon.psm1 -Force

$name = $args[0]
PsDaemonRun $name