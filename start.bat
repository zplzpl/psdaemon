@echo off
cd %~dp0
set program=%~dp0server-manager.exe
../psdaemon/psdaemon.cmd start %program%