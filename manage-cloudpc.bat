@echo off
setlocal enabledelayedexpansion

:: Windows Cloud PC Management Script
:: Provides easy commands for managing the Docker-based Cloud PC environment

title Windows Cloud PC Manager

echo.
echo ================================================
echo    Windows 11 Cloud PC Management Script
echo ================================================
echo.

if "%1"=="" goto :show_help
if "%1"=="help" goto :show_help
if "%1"=="build" goto :build
if "%1"=="start" goto :start
if "%1"=="stop" goto :stop
if "%1"=="restart" goto :restart
if "%1"=="status" goto :status
if "%1"=="logs" goto :logs
if "%1"=="connect" goto :connect
if "%1"=="backup" goto :backup
if "%1"=="restore" goto :restore
if "%1"=="clean" goto :clean
goto :show_help

:show_help
echo Usage: %0 [command]
echo.
echo Available commands:
echo   build      Build the Cloud PC container
echo   start      Start the Cloud PC container
echo   stop       Stop the Cloud PC container
echo   restart    Restart the Cloud PC container
echo   status     Show container status and resource usage
echo   logs       View container logs
echo   connect    Show VNC connection information
echo   backup     Backup Cloud PC data
echo   restore    Restore Cloud PC data from backup
echo   clean      Remove containers and clean up
echo   help       Show this help message
echo.
echo Examples:
echo   %0 build
echo   %0 start
echo   %0 connect
echo.
goto :end

:build
echo Building Windows Cloud PC container...
echo This may take several minutes...
docker compose build --no-cache
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Build completed successfully!
    echo Run '%0 start' to start the Cloud PC
) else (
    echo.
    echo ❌ Build failed! Check the output above for errors.
)
goto :end

:start
echo Starting Windows Cloud PC...
docker compose up -d
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Cloud PC started successfully!
    echo.
    call :show_connection_info
) else (
    echo.
    echo ❌ Failed to start Cloud PC! Check Docker status.
)
goto :end

:stop
echo Stopping Windows Cloud PC...
docker compose down
if %ERRORLEVEL% EQU 0 (
    echo ✅ Cloud PC stopped successfully!
) else (
    echo ❌ Failed to stop Cloud PC!
)
goto :end

:restart
echo Restarting Windows Cloud PC...
docker compose restart
if %ERRORLEVEL% EQU 0 (
    echo ✅ Cloud PC restarted successfully!
    call :show_connection_info
) else (
    echo ❌ Failed to restart Cloud PC!
)
goto :end

:status
echo Checking Cloud PC status...
echo.
docker compose ps
echo.
echo Resource Usage:
docker stats --no-stream windows11-cloudpc 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Container is not running.
)
goto :end

:logs
echo Showing Cloud PC logs (Press Ctrl+C to exit)...
echo.
docker compose logs -f windows-cloud-pc
goto :end

:connect
call :show_connection_info
goto :end

:backup
echo Creating backup of Cloud PC data...
set backup_name=cloudpc-backup-%date:~-4,4%%date:~-10,2%%date:~-7,2%-%time:~0,2%%time:~3,2%%time:~6,2%
set backup_name=%backup_name: =0%
set backup_name=%backup_name::=_%

docker run --rm -v cloudpc-data:/data -v %cd%:/backup ubuntu tar czf /backup/%backup_name%.tar.gz -C /data .
if %ERRORLEVEL% EQU 0 (
    echo ✅ Backup created: %backup_name%.tar.gz
) else (
    echo ❌ Backup failed!
)
goto :end

:restore
if "%2"=="" (
    echo Usage: %0 restore [backup_file.tar.gz]
    echo.
    echo Available backups:
    dir /b *.tar.gz 2>nul
    goto :end
)

echo Restoring Cloud PC data from %2...
docker run --rm -v cloudpc-data:/data -v %cd%:/backup ubuntu tar xzf /backup/%2 -C /data
if %ERRORLEVEL% EQU 0 (
    echo ✅ Data restored successfully from %2
    echo You may need to restart the container: %0 restart
) else (
    echo ❌ Restore failed! Check if the backup file exists.
)
goto :end

:clean
echo ⚠️  WARNING: This will remove all Cloud PC containers and data!
set /p confirm=Are you sure? (y/N): 
if /i not "%confirm%"=="y" (
    echo Operation cancelled.
    goto :end
)

echo Cleaning up Cloud PC environment...
docker compose down -v
docker system prune -f
echo ✅ Cleanup completed!
goto :end

:show_connection_info
echo 🖥️  Connection Information:
echo ─────────────────────────────
echo VNC Address:  localhost:5901
echo Password:     cloudpc123
echo RDP Address:  localhost:3389
echo Web Admin:    http://localhost:8080
echo.
echo 💡 Recommended VNC Clients:
echo   - TightVNC Viewer
echo   - RealVNC Viewer  
echo   - Remote Desktop Connection (for RDP)
echo.
goto :eof

:end
echo.
pause