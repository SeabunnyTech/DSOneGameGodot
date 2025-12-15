@echo off
chcp 65001
CLS
ECHO ==========================================
ECHO      Windows 靜態 IP 設定工具 (RPi 直連用)
ECHO ==========================================
ECHO.

:: --- 設定區塊 (若您的網卡名稱不同，請修改下方 "乙太網路") ---
SET "ADAPTER_NAME=乙太網路"
SET "IP_ADDR=10.10.10.2"
SET "SUBNET=255.255.255.0"
:: -------------------------------------------------------

ECHO 正在尋找名為 "%ADAPTER_NAME%" 的網路介面...
netsh interface show interface | findstr "%ADAPTER_NAME%" >nul
IF %ERRORLEVEL% NEQ 0 (
    ECHO.
    ECHO [錯誤] 找不到名為 "%ADAPTER_NAME%" 的網卡！
    ECHO 請檢查您的網卡名稱是否為 "乙太網路" 或 "Ethernet"。
    ECHO 您目前的網卡列表如下：
    netsh interface show interface
    ECHO.
    PAUSE
    EXIT
)

ECHO.
ECHO 正在設定 IP 為 %IP_ADDR% ...
netsh interface ip set address "%ADAPTER_NAME%" static %IP_ADDR% %SUBNET%

IF %ERRORLEVEL% EQU 0 (
    ECHO.
    ECHO [成功] IP 已設定完成！
    ECHO ----------------------------------
    ECHO 目前設定如下：
    netsh interface ip show config name="%ADAPTER_NAME%" | findstr "IP"
    ECHO ----------------------------------
    ECHO 現在您可以嘗試連線 Raspberry Pi (10.10.10.1)
) ELSE (
    ECHO.
    ECHO [失敗] 設定失敗，請確認您是否「以系統管理員身分執行」。
)

PAUSE