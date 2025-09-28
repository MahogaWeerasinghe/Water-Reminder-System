#!/bin/bash

# Water Reminder Daemon Script
# Author: Water Reminder System
# Description: Manages the water reminder as a background daemon

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="${SCRIPT_DIR}/water-reminder.sh"
PID_FILE="${HOME}/.local/share/water-reminder/water-reminder.pid"
LOG_FILE="${HOME}/.local/share/water-reminder/daemon.log"

# Ensure directories exist
mkdir -p "$(dirname "$PID_FILE")"
mkdir -p "$(dirname "$LOG_FILE")"

# Function to log daemon messages
log_daemon() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] DAEMON: $1" >> "$LOG_FILE"
}

# Function to check if daemon is running
is_running() {
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            return 0
        else
            # PID file exists but process is dead, clean up
            rm -f "$PID_FILE"
            return 1
        fi
    fi
    return 1
}

# Function to start daemon
start_daemon() {
    if is_running; then
        echo "Water reminder daemon is already running (PID: $(cat "$PID_FILE"))"
        return 1
    fi
    
    if [[ ! -f "$MAIN_SCRIPT" ]]; then
        echo "Error: Main script not found at $MAIN_SCRIPT"
        return 1
    fi
    
    if [[ ! -x "$MAIN_SCRIPT" ]]; then
        echo "Error: Main script is not executable. Run: chmod +x $MAIN_SCRIPT"
        return 1
    fi
    
    echo "Starting water reminder daemon..."
    log_daemon "Starting daemon"
    
    # Start the main script in background
    nohup "$MAIN_SCRIPT" --continuous > /dev/null 2>&1 &
    local pid=$!
    
    # Save PID
    echo "$pid" > "$PID_FILE"
    
    # Verify it started successfully
    sleep 2
    if is_running; then
        echo "Water reminder daemon started successfully (PID: $pid)"
        log_daemon "Daemon started successfully with PID $pid"
        return 0
    else
        echo "Failed to start water reminder daemon"
        log_daemon "Failed to start daemon"
        return 1
    fi
}

# Function to stop daemon
stop_daemon() {
    if ! is_running; then
        echo "Water reminder daemon is not running"
        return 1
    fi
    
    local pid
    pid=$(cat "$PID_FILE")
    echo "Stopping water reminder daemon (PID: $pid)..."
    log_daemon "Stopping daemon with PID $pid"
    
    # Send TERM signal
    if kill "$pid" 2>/dev/null; then
        # Wait for process to terminate
        local count=0
        while kill -0 "$pid" 2>/dev/null && [[ $count -lt 10 ]]; do
            sleep 1
            ((count++))
        done
        
        # If still running, force kill
        if kill -0 "$pid" 2>/dev/null; then
            echo "Process didn't terminate gracefully, forcing termination..."
            kill -9 "$pid" 2>/dev/null
        fi
        
        rm -f "$PID_FILE"
        echo "Water reminder daemon stopped"
        log_daemon "Daemon stopped successfully"
        return 0
    else
        echo "Failed to stop daemon (process may have already terminated)"
        rm -f "$PID_FILE"
        return 1
    fi
}

# Function to restart daemon
restart_daemon() {
    echo "Restarting water reminder daemon..."
    stop_daemon
    sleep 2
    start_daemon
}

# Function to show daemon status
show_status() {
    if is_running; then
        local pid
        pid=$(cat "$PID_FILE")
        echo "Water reminder daemon is running (PID: $pid)"
        
        # Show process info if available
        if command -v ps &> /dev/null; then
            echo "Process info:"
            ps -p "$pid" -o pid,ppid,cmd,etime 2>/dev/null || echo "Process details unavailable"
        fi
        return 0
    else
        echo "Water reminder daemon is not running"
        return 1
    fi
}

# Function to show daemon logs
show_logs() {
    local lines=${1:-20}
    
    if [[ -f "$LOG_FILE" ]]; then
        echo "Last $lines lines from daemon log:"
        echo "=================================="
        tail -n "$lines" "$LOG_FILE"
    else
        echo "No daemon log file found at $LOG_FILE"
    fi
}

# Function to show help
show_help() {
    cat << EOF
Water Reminder Daemon Manager

Usage: $0 {start|stop|restart|status|logs} [options]

Commands:
    start       Start the water reminder daemon
    stop        Stop the water reminder daemon
    restart     Restart the water reminder daemon
    status      Show daemon status
    logs [N]    Show last N lines of daemon log (default: 20)
    help        Show this help message

Files:
    Main script: $MAIN_SCRIPT
    PID file:    $PID_FILE
    Log file:    $LOG_FILE

Examples:
    $0 start          # Start daemon
    $0 status         # Check if running
    $0 logs 50        # Show last 50 log lines
    $0 restart        # Restart daemon
EOF
}

# Main function
main() {
    case "${1:-}" in
        start)
            start_daemon
            ;;
        stop)
            stop_daemon
            ;;
        restart)
            restart_daemon
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs "${2:-20}"
            ;;
        help|--help|-h)
            show_help
            ;;
        "")
            echo "Error: No command specified"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
        *)
            echo "Error: Unknown command '$1'"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"