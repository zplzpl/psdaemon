@echo off
echo %~dp0Host.*
for /f %%a in ('dir %~dp0Host* /b /A:D') do (if exist %%a echo Checking folder %%a
											cd /D %%a
											if exist start.bat (echo start.bat exist
																		 start start.bat) else (if exist server-manager.exe (echo server-manager.exe exist
																		 start server-manager.exe
																		 timeout 5) else (echo server-manager.exe doesnt exist && if exist acc-server-manager.exe (echo acc-server-manager.exe exist
																											 													start acc-server-manager.exe
																											 												   timeout 5) else (echo acc-server-manager.exe doesnt exist)))
											cd ..
											)
