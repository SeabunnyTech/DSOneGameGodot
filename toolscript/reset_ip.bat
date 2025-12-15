@echo off
chcp 65001
CLS
ECHO ==========================================
ECHO      恢復自動取得 IP (DHCP)
ECHO ==========================================
ECHO.

:: 請確保名稱與您電腦上的一致
SET "ADAPTER_NAME=乙太網路"

ECHO 正在將 "%ADAPTER_NAME%" 恢復為自動取得 IP...
netsh interface ip set address "%ADAPTER_NAME%" source=dhcp

IF %ERRORLEVEL% EQU 0 (
    ECHO.
    ECHO [成功] 已恢復為自動取得 IP。
) ELSE (
    ECHO.
    ECHO [失敗] 請確認您是否「以系統管理員身分執行」。
)

PAUSE