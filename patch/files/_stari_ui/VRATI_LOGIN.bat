@echo off
rem Vraca login prozor kakav je bio prije starog okvira
copy /Y "%~dp0..\data\HyperText\nui\script_prije_starog_logina.pk" "%~dp0..\data\HyperText\nui\script.pk"
echo.
echo Login je vracen na prethodni izgled.
pause
