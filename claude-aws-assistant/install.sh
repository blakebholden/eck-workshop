#!/bin/bash
# ECK Workshop Installer - Combined AWS Credentials + Claude Code Setup
# Students run this single script to configure everything

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
# Step 1: Collect Student Info & AWS Credentials
# ============================================
echo -e "${CYAN}▸ Step 1/6:${NC} Workshop Configuration"
echo ""

# Get student name for unique resource naming
echo -e "  ${WHITE}Enter your name (lowercase, no spaces, e.g., jsmith):${NC}"
echo -n "  > "
read STUDENT_NAME
STUDENT_NAME=$(echo "$STUDENT_NAME" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]-')

if [ -z "$STUDENT_NAME" ]; then
    echo -e "  ${RED}✗${NC} Student name is required"
    exit 1
fi

echo -e "  ${GREEN}✓${NC} Student name: ${CYAN}$STUDENT_NAME${NC}"
echo ""

# Get AWS credentials
echo -e "  ${WHITE}Enter your AWS credentials:${NC}"
echo ""
echo -n "  AWS Access Key ID: "
read AWS_ACCESS_KEY_ID
AWS_ACCESS_KEY_ID=$(echo "$AWS_ACCESS_KEY_ID" | tr -d '[:space:]')

echo -n "  AWS Secret Access Key: "
read -s AWS_SECRET_ACCESS_KEY
AWS_SECRET_ACCESS_KEY=$(echo "$AWS_SECRET_ACCESS_KEY" | tr -d '[:space:]')
echo ""

echo -n "  AWS Region [us-east-2]: "
read AWS_REGION_INPUT
AWS_REGION=$(echo "${AWS_REGION_INPUT:-us-east-2}" | tr -d '[:space:]')

# Validate inputs
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo -e "  ${RED}✗${NC} AWS credentials are required"
    exit 1
fi

echo ""
sleep 0.3

# ============================================
# Step 2: Configure AWS Credentials
# ============================================
echo -e "${CYAN}▸ Step 2/6:${NC} Configuring AWS credentials..."
sleep 0.5

# Export environment variables for immediate use
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION="$AWS_REGION"
export AWS_REGION
export STUDENT_NAME
export TF_VAR_cluster_name="eck-${STUDENT_NAME}-dev"

# Claude Code via Bedrock (uses same AWS credentials)
export CLAUDE_CODE_USE_BEDROCK=1

# Configure AWS CLI profile
aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID" --profile eck-workshop
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY" --profile eck-workshop
aws configure set region "$AWS_REGION" --profile eck-workshop

# Persist environment variables
cat > /root/.workshop-env << ENVEOF
export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
export AWS_DEFAULT_REGION="$AWS_REGION"
export AWS_REGION="$AWS_REGION"
export AWS_PROFILE=eck-workshop
export STUDENT_NAME="$STUDENT_NAME"
export TF_VAR_cluster_name="eck-${STUDENT_NAME}-dev"

# Claude Code via Amazon Bedrock
export CLAUDE_CODE_USE_BEDROCK=1
ENVEOF

# Add to bashrc
grep -q "workshop-env" /root/.bashrc 2>/dev/null || echo "source /root/.workshop-env" >> /root/.bashrc

echo -e "  ${GREEN}✓${NC} AWS credentials configured"
echo -e "  ${GREEN}✓${NC} Cluster name: ${CYAN}eck-${STUDENT_NAME}-dev${NC}"

sleep 0.3

# ============================================
# Step 3: Verify AWS Access
# ============================================
echo ""
echo -e "${CYAN}▸ Step 3/6:${NC} Verifying AWS access..."
sleep 0.5

if AWS_PAGER="" aws sts get-caller-identity &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} AWS credentials verified"
else
    echo -e "  ${RED}✗${NC} AWS credential verification failed"
    echo ""
    echo -e "  Please check your credentials and try again."
    exit 1
fi

sleep 0.3

# ============================================
# Step 4: Check/Install Claude Code
# ============================================
echo ""
echo -e "${CYAN}▸ Step 4/6:${NC} Checking for Claude Code..."
sleep 0.5

if ! command -v claude &> /dev/null; then
    echo -e "  ${YELLOW}⚠${NC}  Claude Code not found, installing..."
    echo ""

    # Check if npm/node is installed
    if ! command -v node &> /dev/null; then
        echo -e "  Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >/dev/null 2>&1
        apt-get install -y nodejs >/dev/null 2>&1
    fi

    # Install Claude Code
    npm install -g @anthropic-ai/claude-code >/dev/null 2>&1

    if ! command -v claude &> /dev/null; then
        echo -e "  ${RED}✗${NC} Installation issue - trying alternate method..."
        curl -fsSL https://claude.ai/install.sh | bash
        export PATH="$HOME/.claude/bin:$PATH"
    fi

    if command -v claude &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} Claude Code installed"
    else
        echo -e "  ${RED}✗${NC} Installation failed - you can install manually later"
    fi
else
    echo -e "  ${GREEN}✓${NC} Claude Code found"
fi

sleep 0.3

# ============================================
# Step 5: Configure Claude Code for Bedrock
# ============================================
echo ""
echo -e "${CYAN}▸ Step 5/6:${NC} Configuring Claude Code with AWS Bedrock..."
sleep 0.5

# Create Claude settings directory and configuration
mkdir -p /root/.claude

cat > /root/.claude/settings.json << SETTINGS
{
  "theme": "dark",
  "env": {
    "CLAUDE_CODE_USE_BEDROCK": "1",
    "AWS_REGION": "$AWS_REGION"
  }
}
SETTINGS

echo -e "  ${GREEN}✓${NC} Bedrock mode enabled (using your AWS credentials)"

sleep 0.3

# ============================================
# Step 6: Initialize Workshop State
# ============================================
echo ""
echo -e "${CYAN}▸ Step 6/6:${NC} Initializing workshop..."
sleep 0.5

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Set up project settings for Claude
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
      "Read",
      "Write",
      "Glob",
      "Grep"
    ],
    "deny": []
  }
}
EOF

# Copy CLAUDE.md if it exists
if [ -f "$SCRIPT_DIR/CLAUDE.md" ] && [ ! -f "$PROJECT_ROOT/CLAUDE.md" ]; then
    cp "$SCRIPT_DIR/CLAUDE.md" "$PROJECT_ROOT/CLAUDE.md"
fi

# Initialize workshop state
cat > "$SCRIPT_DIR/.workshop-state.json" << EOF
{
  "currentPhase": 1,
  "studentConfig": {
    "clusterName": "eck-${STUDENT_NAME}-dev",
    "studentName": "$STUDENT_NAME",
    "awsRegion": "$AWS_REGION"
  },
  "completedSteps": [],
  "startedAt": "$(date -Iseconds)",
  "lastActivity": null
}
EOF

echo -e "  ${GREEN}✓${NC} Workshop initialized"

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
    │     Phase 1: Environment Setup       ✓ Complete         │
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

echo -e "  ${WHITE}Configuration Summary:${NC}"
echo -e "    Student Name:    ${CYAN}$STUDENT_NAME${NC}"
echo -e "    Cluster Name:    ${CYAN}eck-${STUDENT_NAME}-dev${NC}"
echo -e "    AWS Region:      ${CYAN}$AWS_REGION${NC}"
echo -e "    Claude Code:     ${GREEN}Enabled (via Bedrock)${NC}"
echo ""

# Countdown with progress bar (10 seconds)
echo ""
echo -e "  ${WHITE}Launching Claude Code in 10 seconds...${NC}"
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

# Source environment and launch Claude
source /root/.workshop-env
cd "$PROJECT_ROOT"
exec claude "/workshop"
