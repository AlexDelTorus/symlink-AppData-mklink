@echo off
chcp 65001
setlocal enabledelayedexpansion
cls
cd /d %~dp0
call _symlink_maps.bat

rem   Меню
:main_menu
set "RequestMode="
cls
echo   —————————————————————————————————————————————————————————————
echo.
echo     [1]  Прописать только новые
echo.
echo     [2]  Перезаписать старые, добавить новые
echo.
echo     [3]  Откатить - удалить прописанное
echo.
echo     сначала скрипт проверит на не переименованные .temp
echo     потом соответсвие папок и мапингу
echo.
echo   —————————————————————————————————————————————————————————————
echo.
set /p choice=".   Запустить вариант "
CALL :process_choice %choice%
goto :main_menu

:process_choice
cls
if "%~1"=="1" CALL :process_one "AddNewSymlink"
if "%~1"=="2" CALL :process_one "RewriteAllSymlink"
if "%~1"=="3" CALL :process_one "DeleteSymlink"
exit /b

rem ==========================================================
rem ==========================================================

:process_one
set "RequestMode=%~1"

call :VerificationCompliance

for /d %%A in (_appdata-*) do (
	rem  _appdata-ACDSee
    set "LocalProfilePath=%%~nxA"
    call :DistributorRequested "!LocalProfilePath!"

)
pause
goto :main_menu

rem ==========================================================
rem ==========================================================


:DistributorRequested
rem _appdata-ACDSee
set "LocalProfileFolder=%~1"
rem KEY = ACDSee - Убираем префикс "_appdata-" для map_
set "KEY_Profile=%LocalProfileFolder:_appdata-=%"
rem Задаём временное имя папки
set "TEMP_ProfileFolder=_appdata-%KEY_Profile%.temp"

rem PATH_UserAppData = C:\Users\$USER$\AppData\Local\ACD Systems
call set "PATH_UserAppData=%%map_%KEY_Profile%%%"

rem Получаем путь из маппинга
if not defined PATH_UserAppData ( call :warn "%KEY_Profile%" "Не задан путь в маппинге" & exit /b )


if "%RequestMode%"=="AddNewSymlink" ( call :AddNewSymlink "%LocalProfileFolder%" )
if "%RequestMode%"=="RewriteAllSymlink" ( call :RewriteAllSymlink "%LocalProfileFolder%" )
if "%RequestMode%"=="DeleteSymlink" ( call :DeleteSymlink "%LocalProfileFolder%" )
exit /b




rem ACDSee
rem %KEY_Profile%

rem C:\Users\$USER$\AppData\Local\ACD Systems
rem %PATH_UserAppData%

rem _appdata-ACDSee.temp
rem %TEMP_ProfileFolder%

rem AddNewSymlink
rem %RequestMode%




rem ==========================================================
rem =================  AddNewSymlink  ========================
rem ==========================================================


:AddNewSymlink
:AddNewSymlink_repeat_symlink

call :Warning_CheckFolder "%LocalProfileFolder%"
call :CheckFolder "%PATH_UserAppData%"

if "!IS_CheckFolder!"=="0" (
	echo   █   %KEY_Profile%

	call :create_EveryFolderInPath  "%PATH_UserAppData%"
	call :makeSymlink "%PATH_UserAppData%" "%LocalProfileFolder%"

) else (
	call :is_link "%PATH_UserAppData%"

	if "!IS_LINK!"=="0" (
		echo   █   %KEY_Profile%

		RD /S /Q "%PATH_UserAppData%"
		call :makeSymlink "%PATH_UserAppData%" "%LocalProfileFolder%"

	)
)

if "!REPEAT_ACTION!"=="1" ( goto :AddNewSymlink_repeat_symlink )

exit /b










rem ==========================================================
rem ================  RewriteAllSymlink  =====================
rem ==========================================================
rem Перезаписать старые, создать новые

:RewriteAllSymlink
:RewriteAllSymlink_repeat_symlink

call :Warning_CheckFolder "%LocalProfileFolder%"
call :CheckFolder "%PATH_UserAppData%"

if "!IS_CheckFolder!"=="1" (

	call :is_link "%PATH_UserAppData%"
	if "!IS_LINK!"=="1" (
		echo   █   %KEY_Profile%
		call :Rename_ProfileFolder "%LocalProfileFolder%" "%TEMP_ProfileFolder%"
		RD /S /Q "%PATH_UserAppData%"
		call :makeSymlink "%PATH_UserAppData%" "%LocalProfileFolder%"
		call :Rename_ProfileFolder "%TEMP_ProfileFolder%" "%LocalProfileFolder%"
	) else (
		echo   █   %KEY_Profile%
		RD /S /Q "%PATH_UserAppData%"
		call :makeSymlink "%PATH_UserAppData%" "%LocalProfileFolder%"
	)

) else (
	echo   █   %KEY_Profile%
	call :create_EveryFolderInPath  "%PATH_UserAppData%"
	call :makeSymlink "%PATH_UserAppData%" "%LocalProfileFolder%"
)

if "!REPEAT_ACTION!"=="1" ( goto :RewriteAllSymlink_repeat_symlink )
exit /b












rem ==========================================================
rem ===================  DeleteSymlink  ======================
rem ==========================================================
rem Откатить - удалить прописанное

:DeleteSymlink
:DeleteSymlink_repeat_symlink

call :Warning_CheckFolder "%LocalProfileFolder%"
call :CheckFolder "%PATH_UserAppData%"

if "!IS_CheckFolder!"=="1" (
	call :is_link "%PATH_UserAppData%"
	if "!IS_LINK!"=="1" (
		echo   █   %KEY_Profile%
		call :Rename_ProfileFolder "%LocalProfileFolder%" "%TEMP_ProfileFolder%"
		RD /S /Q "%PATH_UserAppData%"
		call :Rename_ProfileFolder "%TEMP_ProfileFolder%" "%LocalProfileFolder%"
		if "!REPEAT_ACTION!"=="1" ( goto :DeleteSymlink_repeat_symlink )
	)
)
exit /b






















rem ==================================================================
rem ==================================================================
rem ==================================================================
rem            ФУНКЦИИ
rem ==================================================================
rem ==================================================================
rem ==================================================================






:is_link
set "IS_LINK="
fsutil reparsepoint query "%~1" >nul 2>&1
rem 1 ссылка, 0 папка
if %errorlevel%==0 ( set "IS_LINK=1" ) else ( set "IS_LINK=0" )
exit /b


rem ==========================================================


:CheckFolder
set "IS_CheckFolder="
if exist "%~1" ( set "IS_CheckFolder=1" ) else ( set "IS_CheckFolder=0"	)
exit /b


rem ==========================================================


:Warning_CheckFolder
set "IS_CheckFolder="
if exist "%~1" ( set "IS_CheckFolder=1" ) else (
	set "IS_CheckFolder=0"
	call :warn "%~1" "Папка не найдена." & exit /b
	)
exit /b



rem ==========================================================


:Warning_CheckMakedSymlink
set "IS_CheckFolder="
set "IS_LINK="
set "REPEAT_ACTION="

call :CheckFolder "%~1"
call :is_link "%~1"

if "!IS_CheckFolder!"=="1" (
	if "!IS_LINK!"=="1" (
		 set "REPEAT_ACTION=0" & exit /b
	) else (
		call :warn "%~1" "ССЫЛКА НЕ СОЗДАЛАСЬ (это обычная папка)"
		call :Dialog_RepeatSelection
		exit /b
	)
) else (
	call :warn "%~1" "ПУТЬ НЕ СОЗДАЛСЯ"
	call :Dialog_RepeatSelection
	exit /b
)
exit /b


rem ==========================================================

:makeSymlink
set "makeLinkPath=%~1"
set "Localpath=%~2"
mklink /j "%makeLinkPath%" "%cd%\%Localpath%" >nul 2>&1
call :Warning_CheckMakedSymlink "%~1"
exit /b


rem ==========================================================


:Rename_ProfileFolder
call :Warning_CheckFolder "%~1"
rename "%~1" "%~2"
call :Warning_CheckFolder "%~2"
if not exist "%~2" ( call :warn "%~1" "ОШИБКА ПРИ ПЕРЕИМЕНОВАНИИ" & exit /b)
exit /b



rem ==========================================================


:create_EveryFolderInPath
set "fullpath=%~1"
for %%i in ("%fullpath%") do ( set "parent=%%~dpi" )
if not exist "!parent!" ( mkdir "!parent!" )
mkdir "%fullpath%"
RD /S /Q "%fullpath%"
exit /b


rem ==========================================================


:Dialog_RepeatSelection
set "REPEAT_ACTION="
choice /c 12 /n /m " [1] Повторить  [2] Отменить: "
if errorlevel 2 ( set "REPEAT_ACTION=0" & exit /b)
if errorlevel 1 ( set "REPEAT_ACTION=1" & exit /b)
exit /b


rem ==========================================================


:VerificationCompliance
rem === Переименование зависших папок .temp ===
for /d %%T in (_appdata-*.temp) do (
	set "Verif_TempFolder=%%~nxT"
	set "Verif_FixedFolder=!Verif_TempFolder:.temp=!"
	if not exist "!Verif_FixedFolder!" (
		echo   ► Переименование зависшей папки: !Verif_TempFolder! → !Verif_FixedFolder!
		rename "!Verif_TempFolder!" "!Verif_FixedFolder!"
	)
)

rem === Проверка соответствия _appdata-* и map_* ===
echo.
echo   █   Проверка соответствия папок и маппинга...
echo.

rem Проверка 1: есть папка, но нет мапинга
for /d %%A in (_appdata-*) do (
	set "Verif_FOLDER=%%~nxA"
	set "Verif_KEY=!Verif_FOLDER:_appdata-=!"
	call set "Verif_TMP_MAP=%%map_!Verif_KEY!%%"
	if not defined Verif_TMP_MAP (
		call :warn "НЕТ МАПИНГА" "!Verif_FOLDER!  → ключ map_!Verif_KEY!" & exit /b
		pause
	)
)

rem Проверка 2: есть мапинг, но нет папки
for /f "tokens=1* delims==" %%M in ('set map_') do (
	set "Verif_MAPVAR=%%M"
	set "Verif_KEY=!Verif_MAPVAR:map_=!"
	if not exist "_appdata-!Verif_KEY!" (
		call :warn "НЕТ МАПИНГА" "!Verif_MAPVAR! → _appdata-!Verif_KEY!"  & exit /b
	)
)
exit /b




:warn
echo.
echo ████████████████████████████████████████████████████████
echo ████
echo ████      %~1
echo ████      %~2
echo ████
echo ████████████████████████████████████████████████████████
echo.
pause
exit /b
