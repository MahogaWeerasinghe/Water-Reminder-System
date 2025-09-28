#!/bin/bash

# Water Reminder Script - Main notification logic
# Author: Water Reminder System
# Description: Displays desktop notifications to remind users to drink water

# Configuration file path
CONFIG_FILE="${HOME}/.config/water-reminder/config.conf"
LOG_FILE="${HOME}/.local/share/water-reminder/water-reminder.log"

# Default configuration
DEFAULT_INTERVAL=30  # minutes
DEFAULT_SOUND_ENABLED=true
DEFAULT_ICON_PATH="/usr/share/pixmaps/water-drop.png"

# Reminder messages array
MESSAGES=(
    "💧 Time to hydrate! Drink some water 💧"
    "🚰 Stay healthy - drink water now! 🚰"
    "💙 Your body needs water - take a sip! 💙"
    # "⏰ Water break time! Stay hydrated ⏰"
    # "🌊 Refresh yourself with some water 🌊"
    # "💧 Hydration checkpoint - drink up! 💧"
    # "🚰 Keep your body happy with water 🚰"
    # "💙 Water is life - have some now! 💙"
    # "⭐ Stay hydrated, stay healthy! ⭐"
    # "🌟 Your daily water reminder is here! 🌟"
)

# Function to create directories if they don't exist
create_directories() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    mkdir -p "$(dirname "$LOG_FILE")"
}

# Function to load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    else
        # Create default config file
        cat > "$CONFIG_FILE" << EOF
# Water Reminder Configuration
INTERVAL=$DEFAULT_INTERVAL
SOUND_ENABLED=$DEFAULT_SOUND_ENABLED
ICON_PATH=$DEFAULT_ICON_PATH
CUSTOM_MESSAGE=""
EOF
    fi
    
    # Set defaults if not defined
    INTERVAL=${INTERVAL:-$DEFAULT_INTERVAL}
    SOUND_ENABLED=${SOUND_ENABLED:-$DEFAULT_SOUND_ENABLED}
    ICON_PATH=${ICON_PATH:-$DEFAULT_ICON_PATH}
}

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Function to get random message
get_random_message() {
    if [[ -n "$CUSTOM_MESSAGE" ]]; then
        echo "$CUSTOM_MESSAGE"
    else
        echo "${MESSAGES[$RANDOM % ${#MESSAGES[@]}]}"
    fi
}

# Function to check if notify-send is available
check_dependencies() {
    if ! command -v notify-send &> /dev/null; then
        echo "Error: notify-send is not installed. Please install libnotify-bin package."
        log_message "ERROR: notify-send not found"
        exit 1
    fi
}

# Function to send notification
send_notification() {
    local message="$1"
    local icon="$2"
    local sound="$3"
    
    # Build notify-send command
    local cmd="notify-send"
    cmd+=" --urgency=normal"
    cmd+=" --expire-time=5000"
    cmd+=" --app-name='Water Reminder'"
    
    # Add icon if it exists
    if [[ -f "$icon" ]]; then
        cmd+=" --icon='$icon'"
    else
        cmd+=" --icon=dialog-information"
    fi
    
    # Add sound if enabled
    if [[ "$sound" == "true" ]]; then
        cmd+=" --hint=string:sound-name:water-drop"
    fi
    
    cmd+=" 'Water Reminder' '$message'"
    
    # Execute notification
    eval "$cmd"
    
    # Log the reminder
    log_message "Reminder sent: $message"
}

# Function to show single reminder
show_reminder() {
    local message
    message=$(get_random_message)
    send_notification "$message" "$ICON_PATH" "$SOUND_ENABLED"
}

# Function to run continuous reminders
run_continuous() {
    local interval_seconds=$((INTERVAL * 60))
    
    log_message "Water reminder started with ${INTERVAL} minute intervals"
    echo "Water reminder started! Reminders every $INTERVAL minutes."
    echo "Press Ctrl+C to stop."
    
    while true; do
        show_reminder
        sleep "$interval_seconds"
    done
}

# Function to show help
show_help() {
    cat << EOF
Water Reminder Script - Stay Hydrated!

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -c, --continuous    Run continuous reminders (default mode)
    -o, --once          Send a single reminder
    -i, --interval N    Set reminder interval in minutes (default: $DEFAULT_INTERVAL)
    -m, --message MSG   Set custom reminder message
    --no-sound         Disable sound notifications
    --config           Show current configuration
    --test             Test notification system

Examples:
    $0                          # Run with default settings
    $0 --interval 45           # Set 45-minute intervals
    $0 --once                  # Send single reminder
    $0 --message "Drink H2O!"  # Custom message
    $0 --no-sound             # Silent notifications

Configuration file: $CONFIG_FILE
Log file: $LOG_FILE
EOF
}

# Function to show current configuration
show_config() {
    echo "Current Water Reminder Configuration:"
    echo "===================================="
    echo "Interval: $INTERVAL minutes"
    echo "Sound enabled: $SOUND_ENABLED"
    echo "Icon path: $ICON_PATH"
    echo "Custom message: ${CUSTOM_MESSAGE:-"(using random messages)"}"
    echo "Config file: $CONFIG_FILE"
    echo "Log file: $LOG_FILE"
}

# Function to test notification
test_notification() {
    echo "Testing notification system..."
    send_notification "🧪 Test notification - Water reminder is working!" "$ICON_PATH" "$SOUND_ENABLED"
    echo "Test notification sent!"
}

# Main function
main() {
    create_directories
    check_dependencies
    load_config
    
    local run_once=false
    local test_mode=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--continuous)
                run_once=false
                shift
                ;;
            -o|--once)
                run_once=true
                shift
                ;;
            -i|--interval)
                if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                    INTERVAL="$2"
                    shift 2
                else
                    echo "Error: --interval requires a numeric value"
                    exit 1
                fi
                ;;
            -m|--message)
                if [[ -n "$2" ]]; then
                    CUSTOM_MESSAGE="$2"
                    shift 2
                else
                    echo "Error: --message requires a message text"
                    exit 1
                fi
                ;;
            --no-sound)
                SOUND_ENABLED=false
                shift
                ;;
            --config)
                show_config
                exit 0
                ;;
            --test)
                test_mode=true
                shift
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    if [[ "$test_mode" == "true" ]]; then
        test_notification
        exit 0
    fi
    
    if [[ "$run_once" == "true" ]]; then
        show_reminder
    else
        run_continuous
    fi
}

# Handle Ctrl+C gracefully
trap 'echo -e "\nWater reminder stopped. Stay hydrated!"; log_message "Water reminder stopped by user"; exit 0' INT

# Run main function
main "$@"