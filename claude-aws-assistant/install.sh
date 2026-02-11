#!/bin/bash
# ECK Workshop Assistant Installer
# Students run this to set up the workshop environment

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Spinner function
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⣾⣽⣻⢿⡿⣟⣯⣷'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Progress bar function
progress_bar() {
    local duration=$1
    local steps=20
    local sleep_time=$(echo "$duration / $steps" | bc -l)

    printf "["
    for ((i=0; i<steps; i++)); do
        sleep $sleep_time
        printf "▓"
    done
    printf "] "
}

# Clear screen and show animated logo
clear

# Function to print logo line by line with delay
print_logo() {
    local delay=${1:-0.02}

    echo -e "${YELLOW}                                                  ░░░░░░░░░░░░░░░░░░                                ${NC}"; sleep $delay
    echo -e "${YELLOW}                                               ░░░░░░░░░░░░░░░░░░░░░░░░                             ${NC}"; sleep $delay
    echo -e "${YELLOW}                                            ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░                          ${NC}"; sleep $delay
    echo -e "${YELLOW}                                         ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░                       ${NC}"; sleep $delay
    echo -e "${MAGENTA}                         ░░░░░          ${YELLOW}░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░                     ${NC}"; sleep $delay
    echo -e "${MAGENTA}                     ░▒▒▒▒▒▒▒▒▒▒▒░░    ${YELLOW}░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░                     ${NC}"; sleep $delay
    echo -e "${MAGENTA}                  ░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░  ${YELLOW}░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░                   ${NC}"; sleep $delay
    echo -e "${MAGENTA}                 ░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░ ${YELLOW}░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░                  ${NC}"; sleep $delay
    echo -e "${MAGENTA}                ░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░  ${YELLOW}░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░                  ${NC}"; sleep $delay
    echo -e "${MAGENTA}               ░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░ ${YELLOW}░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░                 ${NC}"; sleep $delay
    echo -e "${MAGENTA}               ░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░  ${YELLOW}░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░                ${NC}"; sleep $delay
    echo -e "${MAGENTA}               ░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░  ${YELLOW}░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░                ${NC}"; sleep $delay
    echo -e "${MAGENTA}               ░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒   ${YELLOW}░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░               ${NC}"; sleep $delay
    echo -e "${MAGENTA}               ░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░   ${YELLOW}░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░               ${NC}"; sleep $delay
    echo -e "${MAGENTA}                  ░░░░░░▒▒▒▒▒▒▒▒░  ${YELLOW}░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░               ${NC}"; sleep $delay
    echo -e "${CYAN}            ░░░░░░░░        ░░░░   ${YELLOW}░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░               ${NC}"; sleep $delay
    echo -e "${CYAN}          ░░▒▒▒▒▒▒▒▒▒▒▒░░░░       ${YELLOW}░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░                ${NC}"; sleep $delay
    echo -e "${CYAN}        ░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░   ${YELLOW}░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░                 ${NC}"; sleep $delay
    echo -e "${CYAN}      ░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░  ${YELLOW}░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   ${BLUE}░░▓▒░░           ${NC}"; sleep $delay
    echo -e "${CYAN}     ░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░ ${YELLOW}░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  ${BLUE}░░▓▓▓▓▓▓▒░         ${NC}"; sleep $delay
    echo -e "${CYAN}    ░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░  ${YELLOW}░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  ${BLUE}░░▓▓▓▓▓▓▓▓▓▓▒░       ${NC}"; sleep $delay
    echo -e "${CYAN}    ░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░  ${YELLOW}░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   ${BLUE}░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓░      ${NC}"; sleep $delay
    echo -e "${CYAN}    ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░    ${YELLOW}░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   ${BLUE}░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░     ${NC}"; sleep $delay
    echo -e "${CYAN}    ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░  ░░    ${YELLOW}░░░░░░░░░░░░░░░░░░░░░░░░░░░░  ${BLUE}░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░    ${NC}"; sleep $delay
    echo -e "${CYAN}    ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░   ░░▒▒▒▒░░░     ${YELLOW}░░░░░░░░░░░░░░░░░░░   ${BLUE}░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒    ${NC}"; sleep $delay
    echo -e "${CYAN}    ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░  ░░▒▒▒▒▒▒▒▒▒▒░░░    ${YELLOW}░░░░░░░░░░░░░░  ${BLUE}░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    ${NC}"; sleep $delay
    echo -e "${CYAN}    ░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░  ░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░     ${YELLOW}░░░░░░░░   ${BLUE}░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    ${NC}"; sleep $delay
    echo -e "${CYAN}    ░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░   ░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░        ${BLUE}░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    ${NC}"; sleep $delay
    echo -e "${CYAN}     ░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░  ░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░   ${BLUE}░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒    ${NC}"; sleep $delay
    echo -e "${CYAN}      ░▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░  ░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░   ${BLUE}░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░    ${NC}"; sleep $delay
    echo -e "${CYAN}       ░░▒▒▒▒▒▒▒▒▒▒░  ░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░  ${BLUE}░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░    ${NC}"; sleep $delay
    echo -e "${CYAN}         ░░▒▒▒▒▒▒░   ░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░ ${BLUE}░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░     ${NC}"; sleep $delay
    echo -e "${CYAN}           ░░░▒░░  ░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░  ${BLUE}░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░      ${NC}"; sleep $delay
    echo -e "${CYAN}                 ░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░   ${BLUE}░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░        ${NC}"; sleep $delay
    echo -e "${CYAN}                ░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░        ${BLUE}░░░▒▒▒▓▓▓▓▓▓▓▒░░          ${NC}"; sleep $delay
    echo -e "${CYAN}               ░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒   ${GREEN}░░░░         ░░░░░░             ${NC}"; sleep $delay
    echo -e "${CYAN}               ░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░  ${GREEN}░▒▒▒▒▒▒▒▒░░░░░░                  ${NC}"; sleep $delay
    echo -e "${CYAN}               ░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒   ${GREEN}░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░               ${NC}"; sleep $delay
    echo -e "${CYAN}               ░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░   ${GREEN}░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░               ${NC}"; sleep $delay
    echo -e "${CYAN}                ░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░  ${GREEN}░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░               ${NC}"; sleep $delay
    echo -e "${CYAN}                ░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░  ${GREEN}░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░               ${NC}"; sleep $delay
    echo -e "${CYAN}                 ░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░ ${GREEN}░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░               ${NC}"; sleep $delay
    echo -e "${CYAN}                  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░  ${GREEN}░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░                ${NC}"; sleep $delay
    echo -e "${CYAN}                  ░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░  ${GREEN}░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░                 ${NC}"; sleep $delay
    echo -e "${CYAN}                   ░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒   ${GREEN}░▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░                  ${NC}"; sleep $delay
    echo -e "${CYAN}                     ░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░     ${GREEN}░░▒▒▒▒▒▒▒▒▒░░                     ${NC}"; sleep $delay
    echo -e "${CYAN}                      ░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░                                        ${NC}"; sleep $delay
    echo -e "${CYAN}                       ░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░                                          ${NC}"; sleep $delay
    echo -e "${CYAN}                          ░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░                                            ${NC}"; sleep $delay
    echo -e "${CYAN}                             ░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░                                               ${NC}"; sleep $delay
    echo -e "${CYAN}                                ░░░░░░▒▒▒▒▒▒░░░░░░                                                  ${NC}"; sleep $delay
}

# Print the animated logo
print_logo 0.02
echo ""
echo ""
echo -e "${WHITE}              ███████╗██╗      █████╗ ███████╗████████╗██╗ ██████╗${NC}"
echo -e "${WHITE}              ██╔════╝██║     ██╔══██╗██╔════╝╚══██╔══╝██║██╔════╝${NC}"
echo -e "${WHITE}              █████╗  ██║     ███████║███████╗   ██║   ██║██║     ${NC}"
echo -e "${WHITE}              ██╔══╝  ██║     ██╔══██║╚════██║   ██║   ██║██║     ${NC}"
echo -e "${WHITE}              ███████╗███████╗██║  ██║███████║   ██║   ██║╚██████╗${NC}"
echo -e "${WHITE}              ╚══════╝╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝ ╚═════╝${NC}"
echo ""
echo -e "${CYAN}                    ██████╗██╗      ██████╗ ██╗   ██╗██████╗ ${NC}"
echo -e "${CYAN}                   ██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗${NC}"
echo -e "${CYAN}                   ██║     ██║     ██║   ██║██║   ██║██║  ██║${NC}"
echo -e "${CYAN}                   ██║     ██║     ██║   ██║██║   ██║██║  ██║${NC}"
echo -e "${CYAN}                   ╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝${NC}"
echo -e "${CYAN}                    ╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝ ${NC}"
echo ""
echo -e "${YELLOW}                         ╔═╗╔╗╔  ╦╔═╦ ╦╔╗ ╔═╗╦═╗╔╗╔╔═╗╔╦╗╔═╗╔═╗${NC}"
echo -e "${YELLOW}                         ║ ║║║║  ╠╩╗║ ║╠╩╗║╣ ╠╦╝║║║║╣  ║ ║╣ ╚═╗${NC}"
echo -e "${YELLOW}                         ╚═╝╝╚╝  ╩ ╩╚═╝╚═╝╚═╝╩╚═╝╚╝╚═╝ ╩ ╚═╝╚═╝${NC}"
echo ""
echo -e "${WHITE}═══════════════════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${MAGENTA}                          ECK Workshop - Powered by Claude Code                              ${NC}"
echo -e "${WHITE}═══════════════════════════════════════════════════════════════════════════════════════════${NC}"
echo ""

sleep 1

# ============================================
# Step 1: Check/Install Claude Code
# ============================================
echo -e "${CYAN}▸ Step 1/5:${NC} Checking for Claude Code..."
sleep 0.5

if ! command -v claude &> /dev/null; then
    echo -e "  ${YELLOW}⚠${NC}  Claude Code not found"
    echo ""
    echo -e "  ${WHITE}Would you like to install it now?${NC}"
    read -p "  [Y/n]: " INSTALL_CLAUDE

    if [[ "$INSTALL_CLAUDE" =~ ^[Nn]$ ]]; then
        echo ""
        echo -e "  Install manually: ${CYAN}curl -fsSL https://claude.ai/install.sh | bash${NC}"
        exit 1
    fi

    echo ""
    echo -e "  ${CYAN}Installing Claude Code...${NC}"
    echo ""
    curl -fsSL https://claude.ai/install.sh | bash

    export PATH="$HOME/.claude/bin:$PATH"

    if ! command -v claude &> /dev/null; then
        echo -e "  ${RED}✗${NC} Installation issue - try opening a new terminal"
        exit 1
    fi
    echo ""
    echo -e "  ${GREEN}✓${NC} Claude Code installed"
else
    echo -e "  ${GREEN}✓${NC} Claude Code found"
fi

sleep 0.3

# ============================================
# Step 2: AWS Bedrock Configuration
# ============================================
echo ""
echo -e "${CYAN}▸ Step 2/5:${NC} Configuring Claude Code with AWS Bedrock..."
sleep 0.5

# Check if AWS credentials are available
if ! aws sts get-caller-identity &>/dev/null; then
    echo ""
    echo -e "  ${RED}✗${NC} AWS credentials not found"
    echo ""
    echo -e "  Please configure AWS credentials first:"
    echo -e "  ${CYAN}source /root/.workshop-env${NC}"
    echo ""
    exit 1
fi

# Set Bedrock environment variables
export CLAUDE_CODE_USE_BEDROCK=1
export AWS_REGION="${AWS_REGION:-us-east-2}"

echo -e "  ${GREEN}✓${NC} AWS credentials detected"
echo -e "  ${GREEN}✓${NC} Bedrock mode enabled (using your AWS credentials)"

sleep 0.3

# ============================================
# Step 3: Configure Plugin
# ============================================
echo ""
echo -e "${CYAN}▸ Step 3/5:${NC} Setting up workshop plugin..."
sleep 0.5

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

mkdir -p "$PROJECT_ROOT/.claude"

cat > "$PROJECT_ROOT/.claude/settings.json" << 'EOF'
{
  "plugins": ["./claude-aws-assistant/eck-workshop-plugin"],
  "permissions": {
    "allow": [
      "Bash(aws *)",
      "Bash(terraform *)",
      "Bash(kubectl *)",
      "Bash(helm *)",
      "Bash(brew *)",
      "Read",
      "Write",
      "Glob",
      "Grep"
    ],
    "deny": []
  }
}
EOF

echo -e "  ${GREEN}✓${NC} Plugin configured"

sleep 0.3

# ============================================
# Step 4: Install Workshop Files
# ============================================
echo ""
echo -e "${CYAN}▸ Step 4/5:${NC} Installing workshop files..."
sleep 0.5

if [ ! -f "$PROJECT_ROOT/CLAUDE.md" ]; then
    cp "$SCRIPT_DIR/CLAUDE.md" "$PROJECT_ROOT/CLAUDE.md"
    echo -e "  ${GREEN}✓${NC} Workshop instructions installed"
else
    echo -e "  ${GREEN}✓${NC} Workshop instructions found"
fi

sleep 0.3

# ============================================
# Step 5: Initialize State
# ============================================
echo ""
echo -e "${CYAN}▸ Step 5/5:${NC} Initializing workshop state..."
sleep 0.5

cat > "$SCRIPT_DIR/.workshop-state.json" << EOF
{
  "currentPhase": 0,
  "completedSteps": [],
  "startedAt": null,
  "lastActivity": null
}
EOF

echo -e "  ${GREEN}✓${NC} Ready to go"

sleep 0.5

# ============================================
# Complete!
# ============================================
echo ""
echo -e "${WHITE}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}  ✓ Setup Complete!${NC}"
echo ""
echo -e "${WHITE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

sleep 1

echo -e "${CYAN}"
cat << 'ART'

    ┌─────────────────────────────────────────────────────────┐
    │                                                         │
    │   🚀  Workshop Ready!                                   │
    │                                                         │
    │   Your AI instructor will guide you through:            │
    │                                                         │
    │     Phase 1: Environment Setup                          │
    │     Phase 2: Deploy Infrastructure                      │
    │     Phase 3: Deploy ECK Stack                           │
    │     Phase 4: Fleet & Monitoring                         │
    │     Phase 5: APM & Observability                        │
    │     Phase 6: ML & ELSER                                 │
    │     Phase 7: AI Assistant                               │
    │     Phase 8: Exploration                                │
    │                                                         │
    └─────────────────────────────────────────────────────────┘

ART
echo -e "${NC}"

# Countdown with progress bar (10 seconds)
echo ""
echo -e "  ${WHITE}Launching in 10 seconds...${NC}"
echo ""
echo -ne "  ${CYAN}["
for i in {1..20}; do
    echo -ne "░"
done
echo -ne "]${NC}"

# Animate the progress bar
for i in {1..20}; do
    sleep 0.5
    # Move cursor back to start of bar
    echo -ne "\r  ${CYAN}["
    # Fill completed portion
    for ((j=1; j<=i; j++)); do
        echo -ne "${GREEN}█${NC}"
    done
    # Fill remaining portion
    for ((j=i+1; j<=20; j++)); do
        echo -ne "${CYAN}░${NC}"
    done
    echo -ne "${CYAN}]${NC} $((10 - i/2))s "
done

echo ""
echo ""
echo -e "  ${GREEN}🚀 Launching workshop...${NC}"
echo ""
sleep 1

# Change to project directory and launch Claude with /workshop
cd "$PROJECT_ROOT"
exec claude "/workshop"
