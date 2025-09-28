#!/bin/bash

# Water Reminder Control Script
# Author: Water Reminder System
# Description: Easy-to-use control interface for water reminder system

# Script directory and related files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DAEMON_SCRIPT="${SCRIPT_DIR}/water-reminder-daemon.sh"
MAIN_SCRIPT="${SCRIPT_DIR}/water-reminder.sh"
CONFIG_FILE="${HOME}/.config/water-reminder/config.conf"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if scripts exist
check_scripts() {
    local missing=false
    
    if [[ ! -f "$DAEMON_SCRIPT" ]]; then
        print_status "$RED" "Error: Daemon script not found at $DAEMON_SCRIPT"
        missing=true
    fi
    
    if [[ ! -f "$MAIN_SCRIPT" ]]; then
        print_status "$RED" "Error: Main script not found at $MAIN_SCRIPT"
        missing=true
    fi
    
    if [[ "$missing" == "true" ]]; then
        echo
        print_status "$YELLOW" "Please ensure all water reminder scripts are in the same directory:"
        echo "  - water-reminder.sh"
        echo "  - water-reminder-daemon.sh"
        echo "  - water-control.sh (this script)"
        exit 1
    fi
    
    # Make scripts executable if they aren't
    chmod +x "$DAEMON_SCRIPT" "$MAIN_SCRIPT" 2>/dev/null
}

# Function to start water reminder
start_reminder() {
    print_status "$BLUE" "🚰 Starting Water Reminder System..."
    if "$DAEMON_SCRIPT" start; then
        print_status "$GREEN" "✅ Water reminder started successfully!"
        print_status "$YELLOW" "💧 You'll receive reminders to stay hydrated."
    else
        print_status "$RED" "❌ Failed to start water reminder"
        exit 1
    fi
}

# Function to stop water reminder
stop_reminder() {
    print_status "$BLUE" "🛑 Stopping Water Reminder System..."
    if "$DAEMON_SCRIPT" stop; then
        print_status "$GREEN" "✅ Water reminder stopped successfully!"
        print_status "$YELLOW" "💙 Remember to stay hydrated manually!"
    else
        print_status "$RED" "❌ Failed to stop water reminder"
        exit 1
    fi
}

# Function to restart water reminder
restart_reminder() {
    print_status "$BLUE" "🔄 Restarting Water Reminder System..."
    if "$DAEMON_SCRIPT" restart; then
        print_status "$GREEN" "✅ Water reminder restarted successfully!"
    else
        print_status "$RED" "❌ Failed to restart water reminder"
        exit 1
    fi
}

# Function to show status
show_status() {
    print_status "$BLUE" "📊 Water Reminder System Status"
    echo "================================="
    "$DAEMON_SCRIPT" status
    
    # Show configuration if available
    if [[ -f "$CONFIG_FILE" ]]; then
        echo
        print_status "$BLUE" "⚙️  Current Configuration:"
        "$MAIN_SCRIPT" --config
    fi
}

# Function to show logs
show_logs() {
    local lines=${1:-20}
    print_status "$BLUE" "📝 Water Reminder Logs (last $lines lines)"
    "$DAEMON_SCRIPT" logs "$lines"
}

# Function to test notification
test_notification() {
    print_status "$BLUE" "🧪 Testing notification system..."
    if "$MAIN_SCRIPT" --test; then
        print_status "$GREEN" "✅ Test notification sent!"
    else
        print_status "$RED" "❌ Test notification failed"
        exit 1
    fi
}

# Function to configure reminder
configure_reminder() {
    print_status "$BLUE" "⚙️  Water Reminder Configuration"
    echo "================================="
    
    # Create config directory if it doesn't exist
    mkdir -p "$(dirname "$CONFIG_FILE")"
    
    # Load current config or set defaults
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    fi
    
    local interval=${INTERVAL:-30}
    local sound_enabled=${SOUND_ENABLED:-true}
    local custom_message=${CUSTOM_MESSAGE:-""}
    
    echo
    echo "Current settings:"
    echo "  Interval: $interval minutes"
    echo "  Sound: $sound_enabled"
    echo "  Custom message: ${custom_message:-"(using random messages)"}"
    echo
    
    read -rp "Enter reminder interval in minutes [$interval]: " new_interval
    interval=${new_interval:-$interval}
    
    read -rp "Enable sound notifications? (true/false) [$sound_enabled]: " new_sound
    sound_enabled=${new_sound:-$sound_enabled}
    
    read -rp "Enter custom message (or press Enter for random messages): " new_message
    custom_message=${new_message:-$custom_message}
    
    # Save configuration
    cat > "$CONFIG_FILE" << EOF
# Water Reminder Configuration
INTERVAL=$interval
SOUND_ENABLED=$sound_enabled
CUSTOM_MESSAGE="$custom_message"
ICON_PATH="\${ICON_PATH:-/usr/share/pixmaps/water-drop.png}"
EOF
    
    print_status "$GREEN" "✅ Configuration saved!"
    
    # Ask if user wants to restart if daemon is running
    if "$DAEMON_SCRIPT" status >/dev/null 2>&1; then
        echo
        read -rp "Restart water reminder to apply changes? (y/N): " restart_choice
        if [[ "$restart_choice" =~ ^[Yy] ]]; then
            restart_reminder
        fi
    fi
}

# Function to show help
show_help() {
    cat << EOF
🚰 Water Reminder Control Panel

Usage: $0 [COMMAND] [OPTIONS]

COMMANDS:
    start           Start water reminder daemon
    stop            Stop water reminder daemon  
    restart         Restart water reminder daemon
    status          Show current status and configuration
    logs [N]        Show last N lines of logs (default: 20)
    test            Send a test notification
    config          Interactive configuration setup
    help            Show this help message

EXAMPLES:
    $0 start        # Start reminders
    $0 status       # Check if running
    $0 logs 50      # Show last 50 log entries
    $0 config       # Change settings
    $0 test         # Test notifications

QUICK SETUP:
    1. Run: $0 config      # Set your preferences
    2. Run: $0 start       # Start reminders
    3. Run: $0 status      # Verify it's working

FILES:
    Config: $CONFIG_FILE
    Scripts: $SCRIPT_DIR/

💧 Stay hydrated and healthy! 💧
EOF
}

# Function to show interactive menu
show_menu() {
    while true; do
        clear
        print_status "$BLUE" "🚰 Water Reminder Control Panel"
        echo "================================="
        echo
        echo "1) ▶️  Start reminders"
        echo "2) ⏹️  Stop reminders"
        echo "3) 🔄 Restart reminders"
        echo "4) 📊 Show status"
        echo "5) 📝 View logs"
        echo "6) 🧪 Test notification"
        echo "7) ⚙️  Configure settings"
        echo "8) ❓ Help"
        echo "9) 🚪 Exit"
        echo
        
        read -rp "Select option (1-9): " choice
        echo
        
        case $choice in
            1) start_reminder ;;
            2) stop_reminder ;;
            3) restart_reminder ;;
            4) show_status ;;
            5) 
                read -rp "How many log lines to show? [20]: " log_lines
                show_logs "${log_lines:-20}"
                ;;
            6) test_notification ;;
            7) configure_reminder ;;
            8) show_help ;;
            9) 
                print_status "$GREEN" "💧 Stay hydrated! Goodbye!"
                exit 0
                ;;
            *)
                print_status "$RED" "Invalid option. Please choose 1-9."
                ;;
        esac
        
        echo
        read -rp "Press Enter to continue..."
    done
}

# Main function
main() {
    check_scripts
    
    case "${1:-menu}" in
        start)
            start_reminder
            ;;
        stop)
            stop_reminder
            ;;
        restart)
            restart_reminder
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs "${2:-20}"
            ;;
        test)
            test_notification
            ;;
        config)
            configure_reminder
            ;;
        help|--help|-h)
            show_help
            ;;
        menu)
            show_menu
            ;;
        *)
            print_status "$RED" "Unknown command: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"