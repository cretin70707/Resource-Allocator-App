@echo off
echo Pulling database from device...
adb pull /storage/emulated/0/Download/resource_allocator_export.db ./
if %errorlevel% == 0 (
    echo Database pulled successfully!
    echo Opening with DB Browser...
    start resource_allocator_export.db
) else (
    echo Failed to pull database. Make sure device is connected and database is exported.
)
pause