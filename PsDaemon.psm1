function PsDaemonRun ($loName) {
  runSpecificDaemon (findDaemonByName $loName)
}

function PsDaemonKill ($loName) {
  killSpecificDaemon (findDaemonByName $loName)
}

function PsDaemonRestart ($loName) {
  $daemon = findDaemonByName $loName
  killSpecificDaemon $daemon
  Start-Sleep -s 3
  runSpecificDaemon $daemon
}

function PsDaemonRunning {
  getRunningDaemons
}

function script:runSpecificDaemon ($loDaemon, $loThrowOnExists = $true) {
  if (checkIfDaemonRunning $loDaemon) {
    if ($loThrowOnExists) {
      throw "Daemon " + $loDaemon.name + " is already running."
    } else {
      return
    }
  }

  checkDaemonBeforePerform $loDaemon
  if ($loDaemon.depends) {
    runDependantDaemons $loDaemon
  }
  
  runDaemonScript $loDaemon 'before'
  
  if (!$loDaemon.exe) {
    return
  }

  $private:log = $PSScriptRoot + '\logs\' + $loDaemon.name + '.log.txt'
  $private:errorLog = $PSScriptRoot + '\logs\' + $loDaemon.name + '.error.txt'

  if (!$loDaemon.args) {
    Start-Process -FilePath $loDaemon.exe -WindowStyle Hidden -RedirectStandardOutput $log -RedirectStandardError $errorLog
  } else {
    $private:transformedArgs = replaceTildaWithUserPath $loDaemon.args
    Start-Process -FilePath $loDaemon.exe -WindowStyle Hidden -RedirectStandardOutput $log -RedirectStandardError $errorLog -ArgumentList $transformedArgs
  }
}

function script:killSpecificDaemon ($loDaemon) {
  if (!$loDaemon.depends -and !(checkIfDaemonRunning $loDaemon)) {
    throw "Daemon " + $loDaemon.name + " is not running."
  }
  
  checkDaemonBeforePerform $loDaemon
  if ($loDaemon.depends) {
    killDependantDaemons $loDaemon
  }

  runDaemonScript $loDaemon 'after'
  
  if (!$loDaemon.exe) {
    return
  }

  taskkill.exe /im $loDaemon.exe 2>&1 | Out-Null

  if (checkIfDaemonRunning $loDaemon) {
    taskkill.exe /f /im $loDaemon.exe 2>&1 | Out-Null
  }
}

function runDependantDaemons ($loDaemon) {
  foreach ($private:daemonName in $loDaemon.depends) {
    runSpecificDaemon (findDaemonByName $daemonName) $false
  }
}

function killDependantDaemons ($loDaemon) {
  foreach ($private:daemonName in $loDaemon.depends) {
    killSpecificDaemon (findDaemonByName $daemonName)
  }
}

function script:findDaemonByName ($loName) {
  if (!$loName) {
    throw "Name of the daemon is required!"
  }

  foreach ($private:daemon in loadDaemonList) {
    if ($loName.equals($daemon.name)) {
      return $daemon
    }
  }

  throw "Unknown daemon " + $loName + " provided."
}

function getRunningDaemons {
  $private:daemons = loadDaemonList
  return $daemons | Where { checkIfDaemonRunning $_ }
}

function script:checkDaemonBeforePerform ($loDaemon) {
  if (!$loDaemon.depends -and !$loDaemon.exe) {
    throw "Daemon " + $loDaemon.name + " doesn't have 'depends' or 'exe' key."
  }
}

function script:checkIfDaemonRunning ($loDaemon) {
  if (!$loDaemon.exe) {
    return $false
  }
  
  $private:filter = "IMAGENAME eq " + $loDaemon.exe
  $private:list = tasklist.exe /fi $filter
  return ("$list".Contains($loDaemon.exe))
}

function script:runDaemonScript ($loDaemon, $loDirectory) {
  $private:beforeRunScript = $PSScriptRoot + '\' + $loDirectory + '\' + $loDaemon.name + '.ps1'
  if (Test-Path $beforeRunScript) {
    & $beforeRunScript
  }
}

function script:loadDaemonList {
  $private:jsonLines = Get-Content -Path $PSScriptRoot\daemons.json
  $private:list = ConvertFrom-Json -InputObject "$jsonLines"
  return $list
}

function script:replaceTildaWithUserPath ($loPath) {
  return $loPath.Replace("~", $env:UserProfile)
}
