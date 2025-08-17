#!/bin/bash

echo "Pulling database from device..."
adb pull /storage/emulated/0/Download/resource_allocator_export.db ./

if [ $? -eq 0 ]; then
    echo "Database pulled successfully!"
    echo "You can open it with:"
    echo "  - sqlitebrowser resource_allocator_export.db"
    echo "  - sqlite3 resource_allocator_export.db"
    echo "  - Or any SQLite viewer"
else
    echo "Failed to pull database. Make sure:"
    echo "  - Device is connected (adb devices)"
    echo "  - Database is exported from the app"
    echo "  - USB debugging is enabled"
fi

echo "Press Enter to continue..."
read
