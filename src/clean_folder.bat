call :CLEANUP
goto :EOF

:CLEANUP
del /F /Q *.dcu *.identcache *.local
rem del /F /Q /A:H  
rmdir /S /Q __history
