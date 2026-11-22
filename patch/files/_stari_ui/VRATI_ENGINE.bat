@echo off
rem Vraca engine.exe kakav je bio prije dvorane sa zmajevima na izboru lika
copy /Y "%~dp0..\engine_prije_zmajeva.exe" "%~dp0..\engine.exe"
echo.
echo engine.exe je vracen.
pause
