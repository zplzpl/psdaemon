if (!$env:path.Contains('scoop\apps\php\current')) {
  $env:path += ";C:\Users\$env:UserName\scoop\apps\php\current"
}
