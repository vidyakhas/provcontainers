@echo off
call %*
goto :EOF

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:DateToSecs %yy% %mm% %dd% %hh% %nn% %ss% secs
::
:: By:   Ritchie Lawrence, updated 2002-08-13. Version 1.1
::
:: Func: Returns number of seconds elapsed since 1st January 1970 00:00:00
::       for a given calendar date and time of day. For NT4/2000/XP/2003.
:: 
:: Args: %1 year to convert, 2 or 4 digit (by val)
::       %2 month to convert, 1/01 to 12, leading zero ok (by val)
::       %3 day of month to convert, 1/01 to 31, leading zero ok (by val)
::       %4 hours to convert, 1/01 to 12 for 12hr times (minutes must be
::          suffixed by 'a' or 'p', 0/00 to 23 for 24hr clock (by val)
::       %5 mins to convert, 00-59 only, suffixed by a/p if 12hr (by val)
::       %6 secs to convert, 0-59 or 00-59 (by val)
::       %7 var to receive number of elapsed seconds (by ref)
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
setlocal ENABLEEXTENSIONS
set yy=%1&set mm=%2&set dd=%3&set hh=%4&set nn=%5&set ss=%6
if 1%yy% LSS 200 if 1%yy% LSS 170 (set yy=20%yy%) else (set yy=19%yy%)
set /a dd=100%dd%%%100,mm=100%mm%%%100
set /a z=14-mm,z/=12,y=yy+4800-z,m=mm+12*z-3,j=153*m+2
set /a j=j/5+dd+y*365+y/4-y/100+y/400-2472633
if 1%hh% LSS 20 set hh=0%hh%
if {%nn:~2,1%} EQU {p} if "%hh%" NEQ "12" set hh=1%hh%&set/a hh-=88
if {%nn:~2,1%} EQU {a} if "%hh%" EQU "12" set hh=00
if {%nn:~2,1%} GEQ {a} set nn=%nn:~0,2%
set /a hh=100%hh%%%100,nn=100%nn%%%100,ss=100%ss%%%100
set /a j=j*86400+hh*3600+nn*60+ss
endlocal&set %7=%j%&goto :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:GetDate yy mm dd
::
:: By:   Ritchie Lawrence, 2002-06-15. Version 1.0
::
:: Func: Loads local system date components into args 1 to 3.
::       For NT4/2000/XP/2003.
:: 
:: Args: %1 var to receive year, 4 digits (by ref)
::       %2 var to receive month, 2 digits, 01 to 12 (by ref)
::       %3 Var to receive day of month, 2 digits, 01 to 31 (by ref)
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
setlocal ENABLEEXTENSIONS
set t=2&if "%date%z" LSS "A" set t=1
for /f "skip=1 tokens=2-4 delims=(-)" %%a in ('echo/^|date') do (
  for /f "tokens=%t%-4 delims=.-/ " %%d in ('date/t') do (
    set %%a=%%d&set %%b=%%e&set %%c=%%f))
endlocal&set %1=%yy%&set %2=%mm%&set %3=%dd%&goto :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::	

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:GetTime hh nn ss tt
::
:: By:   Ritchie Lawrence, updated 2007-05-12. Version 1.3
::
:: Func: Loads local system time components into args 1 to 4.
::       For NT4/2000/XP/2003
:: 
:: Args: %1 Var to receive hours, 2 digits, 00 to 23 (by ref)
::       %2 Var to receive minutes, 2 digits, 00 to 59 (by ref)
::       %3 Var to receive seconds, 2 digits, 00 to 59 (by ref)
::       %4 Var to receive centiseconds, 2 digits, 00 to 99 (by ref)
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
setlocal ENABLEEXTENSIONS
for /f "tokens=5-8 delims=:,. " %%a in ('echo/^|time') do (
  set hh=%%a&set nn=%%b&set ss=%%c&set cs=%%d)
if 1%hh% LSS 20 set hh=0%hh%
endlocal&set %1=%hh%&set %2=%nn%&set %3=%ss%&set %4=%cs%&goto :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:GetEpochTime
::
:: By:   Ritchie Lawrence, updated 2017-03-29 by Eric Dargelies.
::
:: Func: Returns the epoch time based on the current system time. Requires
:: system time to be using UTC
:: 
:: Args: %1 Var to receive epoch time in seconds
setlocal ENABLEEXTENSIONS
call :GetDate y m d
call :GetTime h n s t
call :DateToSecs %y% %m% %d% %h% %n% %s% secs
endlocal&set %1=%secs%&goto :EOF
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::