$env:PSModulePath += ';' + $PSScriptRoot

function script:run () {
    $private:command = $script:args[0]

    if (!$command) {
        throw "Command is required!"
    }
    switch ($command) {
        "start" { return PsDaemonRun(getDaemonName) }
        "stop" { return PsDaemonKill(getDaemonName) }
        "restart" { return PsDaemonRestart(getDaemonName) }
        "running" { return PsDaemonRunning }
        Default { throw "Unknown command" }
    }
}

function script:getDaemonName () {
    $private:name = $script:args[1]
    if (!$name) {
        throw "Name of the daemon is required!"
    } else {
        return $name
    }
}

run