function PsDaemonRun ($loName) {
  
  $private:pf = $pf = Get-Item $loName
  if(!$pf){
    echo "Please " + $loName " confirm that the process exists!"
    return
  }

  echo "Daemon Process:"
  echo $loName

  echo "Run History:"
  for ($i=1;;){
    $private:rs = runSpecificDaemon ($loName)
    if($rs){
      Get-Date
      $i = $i + 1
    }
    Start-Sleep -s 3
  }

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

function script:runSpecificDaemon ($loName, $loThrowOnExists = $true) {

  if (checkIfProcessRunning $loName) {
    if ($loThrowOnExists) {
      return $false
    } else {
      return $false
    }
  }

  Start-Process -FilePath $loName

  return $true
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


function script:checkIfProcessRunning ($loName) {

  $private:pf = $pf = Get-Item $loName
  if(!$pf){
    return $false
  }

  $private:lpath = $pf.Directory.FullName + '*'
  $private:pp = Get-Process -Name $pf.Basename | Where-Object { $_.Path -like $lpath}

  if($pp){
    return $true
  }

  return $false
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
