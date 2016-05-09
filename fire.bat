
:: Fast Incident Response Extractor
:: Date: 12/7/2007
:: Additional tools needed:
::  lsgrab        (screenshots) 
::  psinfo        (host information)
::  psloggedon    (login information)
::  USBDeview     (USB information)
::  psloglist     (application log)
::  pslist        (process information)
::  listdlls      (DLL information)
::  psexec        (remote commands)

:BEGIN
cls
@echo off

IF [%1]==[] echo Usage:fire [IP Address] [Application Log Date: MM/DD/YY]
IF [%1]==[] echo. && GOTO END
IF [%2]==[] echo Usage:fire [IP Address] [Application Log Date: MM/DD/YY]
IF [%2]==[] echo. && GOTO END

echo [+] Verifying if host is alive
ping -n 2 %1 
IF ERRORLEVEL 1 echo Host is down && GOTO END
IF ERRORLEVEL 0 echo Host is alive && echo.

:: echo [+] Verifying host name
:: wmic /node:'%1' COMPUTERSYSTEM get name | find "%1"
:: IF ERRORLEVEL 1 echo Host name is incorrect && GOTO END
:: IF ERRORLEVEL 0 echo Host name is correct && GOTO FIRE

:FIRE

echo. > %1.txt
echo Fire performed on: >> %1.txt
echo Date:%date% >> %1.txt
echo Time:%time% >> %1.txt
echo. >> %1.txt

echo [+] Taking a screen shot for host %1
lsgrab /c:%1 /p:"C:\Tools\Fire\"

echo Host Info: >> %1.txt
echo ----------- >> %1.txt
echo [+] Gathering host general information
@psinfo -accepteula -s -d \\%1 >> %1.txt
echo. >> %1.txt

echo User logged on: >> %1.txt
echo ---------------- >> %1.txt
echo [+] Verifying which user is logged on
@psloggedon -accepteula \\%1 >> %1.txt
echo. >> %1.txt
@for /F "tokens=2 delims=\" %%i in ('"psloggedon \\%1 | find "[Use Your Domain]" | findstr /v "[Remove Your User]""') do wmic useraccount where name="%%i" list full | findstr "Description Fullname Name" >> %1.txt
echo. >> %1.txt

echo USB Devices: >> %1.txt
echo ------------ >> %1.txt
echo [+] Gathering USB devices information
USBDeview.exe /stext %1-usbview.txt /remote \\%1
type %1-usbview.txt >> %1.txt
del %1-usbview.txt
echo. >> %1.txt

echo Startup Programs: >> %1.txt
echo ------------------ >> %1.txt
echo [+] Looking for startup programs

wmic /node:"%1" startup list brief > %1-startup-programs.txt
IF ERRORLEVEL NEQ 0 msinfo32 /computer %1 /report %1-startup-programs.txt /categories +SWEnvStartupPrograms
type %1-startup-programs.txt >> %1.txt
del %1-startup-programs.txt 
echo. >> %1.txt

echo Application log: >> %1.txt
echo ----------------- >> %1.txt
echo [+] Gathering application log from %2 until today 
@psloglist -accepteula \\%1 -a %2 application >> %1.txt
echo. >> %1.txt

echo Processes: >> %1.txt
echo ----------- >> %1.txt
echo [+] Looking for current processes
@pslist -accepteula \\%1 >> %1.txt
echo. >> %1.txt

echo DLLs: >> %1.txt
echo ------ >> %1.txt
echo [+] Looking for DLLs associated with current processes
@listdlls -accepteula \\%1 >> %1.txt
echo. >> %1.txt

:: The netstat command is shown on screen !!!

echo Netstat: >> %1.txt
echo --------- >> %1.txt
echo [+] Gathering TCP and UDP connections
@psexec -accepteula -e \\%1 netstat -nao >> %1.txt

@echo.
echo Fire finished on: Date:%date% Time:%time% >> %1.txt
@echo.
echo [+] Making Directory for host %1

:: Taking time stamp

set datevar=%date%
set datevar=%datevar:/=_%

set timevar=%time%
set timevar=%timevar: =%
set timevar=%timevar::=_%
set timevar=%timevar:.=_%

FOR /F "tokens=2 delims= " %%x in ('echo %datevar%_%timevar%') do set timestamp=%%x
:: echo %timestamp%

@mkdir "C:\Tools\Fire\%1_%timestamp%"

@echo.
echo [+] Moving files to appropiate directory
@move %1.txt "C:\Tools\Fire\%1_%timestamp%\"
@move %1.jpg "C:\Tools\Fire\%1_%timestamp%\"
::@move out.ogg "C:\Tools\Fire\%1_%timestamp%\"
cd "C:\Tools\Fire\%1_%timestamp%\"

@echo.
echo [+] Opening report
start /MAX wordpad "C:\Tools\Fire\%1_%timestamp%\%1.txt"

:END


