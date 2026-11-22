@echo off
rem Postavlja engine.exe koji na izboru lika ucitava dvoranu sa zmajevima. Igra mora biti ugasena.
copy /Y "%~dp0..\engine_zmajevi.exe" "%~dp0..\engine.exe"
if errorlevel 1 (echo. & echo NIJE USPJELO - ugasi igru pa pokreni ponovo.) else (echo. & echo Postavljeno. Upali igru i dodji do izbora lika.)
pause
