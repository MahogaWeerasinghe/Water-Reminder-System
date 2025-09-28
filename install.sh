#!/bin/bash

# Water Reminder Installation Script
# Author: Water Reminder System
# Description: Installs water reminder system system-wide or locally

set -e

# Configuration
INSTALL_DIR_SYSTEM="/usr/local/bin"
INSTALL_DIR_LOCAL="${HOME}/.local/bin"
ICON_DIR_SYSTEM="/usr/share/pixmaps"
ICON_DIR_LOCAL="${HOME}/.local/share/pixmaps"
DESKTOP_DIR_SYSTEM="/usr/share/applications"
DESKTOP_DIR_LOCAL="${HOME}/.local/share/applications"
AUTOSTART_DIR="${HOME}/.config/autostart"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if we need sudo
need_sudo() {
    [[ "$INSTALL_TYPE" == "system" ]]
}

# Function to run command with sudo if needed
run_cmd() {
    if need_sudo; then
        sudo "$@"
    else
        "$@"
    fi
}

# Function to check dependencies
check_dependencies() {
    print_status "$BLUE" "🔍 Checking dependencies..."
    
    local missing_deps=()
    
    # Check for notify-send
    if ! command -v notify-send &> /dev/null; then
        missing_deps+=("libnotify-bin")
    fi
    
    # Check for other common tools
    for tool in bash mkdir chmod; do
        if ! command -v "$tool" &> /dev/null; then
            missing_deps+=("$tool")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_status "$RED" "❌ Missing dependencies: ${missing_deps[*]}"
        echo
        echo "Please install the missing packages:"
        echo "  Ubuntu/Debian: sudo apt install ${missing_deps[*]}"
        echo "  Fedora: sudo dnf install ${missing_deps[*]}"
        echo "  Arch: sudo pacman -S ${missing_deps[*]}"
        exit 1
    fi
    
    print_status "$GREEN" "✅ All dependencies satisfied"
}

# Function to check if scripts exist
check_scripts() {
    print_status "$BLUE" "📁 Checking script files..."
    
    local required_files=(
        "water-reminder.sh"
        "water-reminder-daemon.sh"
        "water-control.sh"
    )
    
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$SCRIPT_DIR/$file" ]]; then
            missing_files+=("$file")
        fi
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        print_status "$RED" "❌ Missing script files: ${missing_files[*]}"
        echo "Please ensure all scripts are in the same directory as the installer."
        exit 1
    fi
    
    print_status "$GREEN" "✅ All script files found"
}

# Function to install scripts
install_scripts() {
    local install_dir="$1"
    
    print_status "$BLUE" "📦 Installing scripts to $install_dir..."
    
    # Create installation directory
    run_cmd mkdir -p "$install_dir"
    
    # Copy and make scripts executable
    for script in water-reminder.sh water-reminder-daemon.sh water-control.sh; do
        print_status "$YELLOW" "  Installing $script..."
        run_cmd cp "$SCRIPT_DIR/$script" "$install_dir/"
        run_cmd chmod +x "$install_dir/$script"
    done
    
    # Create water-reminder symlink for easy access
    if [[ -f "$install_dir/water-control.sh" ]]; then
        run_cmd ln -sf "$install_dir/water-control.sh" "$install_dir/water-reminder"
    fi
    
    print_status "$GREEN" "✅ Scripts installed successfully"
}

# Function to install icon
install_icon() {
    local icon_dir="$1"
    
    print_status "$BLUE" "🎨 Installing icon to $icon_dir..."
    
    run_cmd mkdir -p "$icon_dir"
    
    # Create a simple water drop icon if it doesn't exist
    local icon_file="$icon_dir/water-drop.png"
    
    if [[ ! -f "$icon_file" ]]; then
        # Create a simple SVG icon and convert to PNG if possible
        local svg_content='<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48">
  <path fill="#2196F3" d="M24 4c-8 0-16 8-16 20 0 8.837 7.163 16 16 16s16-7.163 16-16c0-12-8-20-16-20z"/>
  <path fill="#1976D2" d="M24 8c-6 0-12 6-12 16 0 6.627 5.373 12 12 12s12-5.373 12-12c0-10-6-16-12-16z"/>
</svg>'
        
        # Try to create PNG icon using available tools
        if command -v convert &> /dev/null; then
            echo "$svg_content" | run_cmd convert svg:- "$icon_file"
        elif command -v rsvg-convert &> /dev/null; then
            echo "$svg_content" | run_cmd rsvg-convert -o "$icon_file"
        else
            # Fallback: use a generic icon
            print_status "$YELLOW" "⚠️  Icon conversion tools not available, using system default"
        fi
    fi
    
    print_status "$GREEN" "✅ Icon installed"
}

# Function to create desktop entry
create_desktop_entry() {
    local desktop_dir="$1"
    local install_dir="$2"
    local icon_path="$3"
    
    print_status "$BLUE" "🖥️  Creating desktop entry..."
    
    run_cmd mkdir -p "$desktop_dir"
    
    local desktop_file="$desktop_dir/water-reminder.desktop"
    
    run_cmd tee "$desktop_file" > /dev/null << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Water Reminder
Comment=Stay hydrated with regular water reminders
Exec=$install_dir/water-control.sh
Icon=$icon_path/water-drop.png
Terminal=false
StartupNotify=false
Categories=Utility;Health;
Keywords=water;health;reminder;hydration;
StartupWMClass=water-reminder
EOF
    
    run_cmd chmod +x "$desktop_file"
    
    print_status "$GREEN" "✅ Desktop entry created"
}

# Function to setup autostart
setup_autostart() {
    local install_dir="$1"
    
    print_status "$BLUE" "🚀 Setting up autostart (optional)..."
    
    read -rp "Do you want water reminder to start automatically on login? (y/N): " auto_choice
    
    if [[ "$auto_choice" =~ ^[Yy] ]]; then
        mkdir -p "$AUTOSTART_DIR"
        
        local autostart_file="$AUTOSTART_DIR/water-reminder.desktop"
        
        cat > "$autostart_file" << EOF
[Desktop Entry]
Type=Application
Name=Water Reminder
Comment=Automatic water reminder on startup
Exec=$install_dir/water-reminder-daemon.sh start
Icon=water-drop
Terminal=false
StartupNotify=false
Hidden=false
X-GNOME-Autostart-enabled=true
EOF
        
        chmod +x "$autostart_file"
        print_status "$GREEN" "✅ Autostart configured"
    else
        print_status "$YELLOW" "⏭️  Autostart skipped"
    fi
}

# Function to run post-install configuration
post_install_config() {
    local install_dir="$1"
    
    print_status "$BLUE" "⚙️  Post-installation configuration..."
    
    read -rp "Do you want to configure water reminder settings now? (y/N): " config_choice
    
    if [[ "$config_choice" =~ ^[Yy] ]]; then
        "$install_dir/water-control.sh" config
    else
        print_status "$YELLOW" "⏭️  Configuration skipped"
        echo "You can configure settings later by running: water-reminder config"
    fi
}

# Function to show installation summary
show_summary() {
    local install_dir="$1"
    
    print_status "$GREEN" "🎉 Installation completed successfully!"
    echo
    echo "Water Reminder System has been installed to: $install_dir"
    echo
    echo "Usage commands:"
    echo "  water-reminder start     # Start reminders"
    echo "  water-reminder stop      # Stop reminders"
    echo "  water-reminder status    # Check status"
    echo "  water-reminder config    # Configure settings"
    echo "  water-reminder help      # Show help"
    echo
    echo "Or use the full path:"
    echo "  $install_dir/water-control.sh"
    echo
    
    if [[ "$INSTALL_TYPE" == "local" ]]; then
        echo "Note: Make sure $install_dir is in your PATH"
        echo "Add this to your ~/.bashrc or ~/.zshrc:"
        echo "  export PATH=\"\$PATH:$install_dir\""
    fi
    
    echo
    print_status "$BLUE" "💧 Stay hydrated and healthy!"
}

# Function to uninstall
uninstall() {
    print_status "$BLUE" "🗑️  Uninstalling Water Reminder System..."
    
    # Determine install type
    local install_dir=""
    if [[ -f "$INSTALL_DIR_SYSTEM/water-control.sh" ]]; then
        install_dir="$INSTALL_DIR_SYSTEM"
        INSTALL_TYPE="system"
    elif [[ -f "$INSTALL_DIR_LOCAL/water-control.sh" ]]; then
        install_dir="$INSTALL_DIR_LOCAL"
        INSTALL_TYPE="local"
    else
        print_status "$RED" "❌ Water Reminder System not found"
        exit 1
    fi
    
    # Stop daemon if running
    if [[ -x "$install_dir/water-reminder-daemon.sh" ]]; then
        "$install_dir/water-reminder-daemon.sh" stop 2>/dev/null || true
    fi
    
    # Remove scripts
    for script in water-reminder.sh water-reminder-daemon.sh water-control.sh water-reminder; do
        if [[ -f "$install_dir/$script" ]]; then
            print_status "$YELLOW" "  Removing $script..."
            run_cmd rm -f "$install_dir/$script"
        fi
    done
    
    # Remove desktop entries
    for desktop_dir in "$DESKTOP_DIR_SYSTEM" "$DESKTOP_DIR_LOCAL"; do
        if [[ -f "$desktop_dir/water-reminder.desktop" ]]; then
            run_cmd rm -f "$desktop_dir/water-reminder.desktop"
        fi
    done
    
    # Remove autostart
    if [[ -f "$AUTOSTART_DIR/water-reminder.desktop" ]]; then
        rm -f "$AUTOSTART_DIR/water-reminder.desktop"
    fi
    
    # Ask about user data
    read -rp "Do you want to remove user configuration and logs? (y/N): " remove_data
    if [[ "$remove_data" =~ ^[Yy] ]]; then
        rm -rf "${HOME}/.config/water-reminder"
        rm -rf "${HOME}/.local/share/water-reminder"
        print_status "$YELLOW" "  User data removed"
    fi
    
    print_status "$GREEN" "✅ Water Reminder System uninstalled"
}

# Function to show help
show_help() {
    cat << EOF
Water Reminder Installation Script

Usage: $0 [OPTIONS] [COMMAND]

COMMANDS:
    install         Install water reminder system (default)
    uninstall       Remove water reminder system
    help            Show this help message

OPTIONS:
    --system        Install system-wide (requires sudo)
    --local         Install for current user only (default)
    --force         Force installation without prompts

EXAMPLES:
    $0                      # Interactive local installation
    $0 --system            # System-wide installation
    $0 --local install     # Local installation
    $0 uninstall          # Remove installation

DEPENDENCIES:
    - bash
    - libnotify-bin (for notifications)
    - Standard Unix tools (mkdir, chmod, etc.)

The installer will:
    1. Check dependencies
    2. Install scripts to appropriate directory
    3. Create desktop entry
    4. Optionally setup autostart
    5. Configure initial settings
EOF
}

# Main installation function
install_system() {
    print_status "$BLUE" "🚰 Water Reminder System Installer"
    echo "===================================="
    echo
    
    # Show installation type
    if [[ "$INSTALL_TYPE" == "system" ]]; then
        print_status "$YELLOW" "📍 Installing system-wide (requires sudo)"
        install_dir="$INSTALL_DIR_SYSTEM"
        icon_dir="$ICON_DIR_SYSTEM"
        desktop_dir="$DESKTOP_DIR_SYSTEM"
    else
        print_status "$YELLOW" "📍 Installing locally for current user"
        install_dir="$INSTALL_DIR_LOCAL"
        icon_dir="$ICON_DIR_LOCAL"
        desktop_dir="$DESKTOP_DIR_LOCAL"
    fi
    
    echo
    
    # Run installation steps
    check_dependencies
    check_scripts
    install_scripts "$install_dir"
    install_icon "$icon_dir"
    create_desktop_entry "$desktop_dir" "$install_dir" "$icon_dir"
    
    if [[ "$INSTALL_TYPE" == "local" ]]; then
        setup_autostart "$install_dir"
    fi
    
    if [[ "$FORCE_INSTALL" != "true" ]]; then
        post_install_config "$install_dir"
    fi
    
    show_summary "$install_dir"
}

# Main function
main() {
    # Default values
    INSTALL_TYPE="local"
    FORCE_INSTALL="false"
    COMMAND="install"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --system)
                INSTALL_TYPE="system"
                shift
                ;;
            --local)
                INSTALL_TYPE="local"
                shift
                ;;
            --force)
                FORCE_INSTALL="true"
                shift
                ;;
            install)
                COMMAND="install"
                shift
                ;;
            uninstall)
                COMMAND="uninstall"
                shift
                ;;
            help|--help|-h)
                show_help
                exit 0
                ;;
            *)
                print_status "$RED" "Unknown option: $1"
                echo
                show_help
                exit 1
                ;;
        esac
    done
    
    # Execute command
    case "$COMMAND" in
        install)
            install_system
            ;;
        uninstall)
            uninstall
            ;;
        *)
            print_status "$RED" "Unknown command: $COMMAND"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"