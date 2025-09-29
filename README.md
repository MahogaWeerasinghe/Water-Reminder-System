# 🚰 Water Reminder System

A comprehensive shell script system for Linux desktop users to stay hydrated with regular water reminders.

## ✨ Features

- **Desktop Notifications**: Beautiful notifications using `notify-send`
- **Configurable Intervals**: Set custom reminder intervals (default: 30 minutes)
- **Random Messages**: Multiple motivating reminder messages
- **Daemon Management**: Background service with proper PID management
- **Sound Notifications**: Optional sound alerts
- **Logging**: Track your hydration reminders
- **Auto-start**: Optional startup on login
- **Easy Control**: Simple command-line interface
- **Cross-DE Support**: Works with GNOME, KDE, XFCE, and more

## 🚀 Quick Start

# 1. Kill existing processes
pkill -f water-reminder

# 1. Save all files to a folder
# 2. Make executable
chmod +x *.sh

# 3. Install (optional)
./install.sh

# 4. Start using
./water-control.sh start
# or if installed: water-reminder start

**Quick Reference:**
```bash
./water-control.sh start    # ▶️  Start reminders
./water-control.sh stop     # ⏹️  Stop reminders  
./water-control.sh status   # 📊 Check status
./water-control.sh config   # ⚙️  Configure
./water-control.sh test     # 🧪 Test notification
./water-control.sh help     # ❓ Show help
```
