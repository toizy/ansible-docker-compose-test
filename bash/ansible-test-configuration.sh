#!/bin/bash
#
# Paths
# --------------------------------------
SCRIPT_FULLNAME=$(readlink -e "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_FULLNAME")"/"
ANSIBLE_DIR="../ansible/"
#
# Constants
#
INVENTORY_FILENAME="inventory.yml"
PLAYBOOK_FILENAME="deploy.yml"

INVENTORY_FILEPATH="${SCRIPT_DIR}${ANSIBLE_DIR}${INVENTORY_FILENAME}"
PLAYBOOK_FILEPATH="${SCRIPT_DIR}${ANSIBLE_DIR}${PLAYBOOK_FILENAME}"
#
# Includes
# --------------------------------------
. "${SCRIPT_DIR}colored-console.sh"
#
# Payload
# --------------------------------------
reset_color

echo -e "${BOLD}Running syntax checks${NORMAL}\n"

# Inventory

echo -e "${GRAY}${BOLD}${INVENTORY_FILENAME}${NORMAL} checks..."

# Ensure yamllint is installed, then execute
if command -v yamllint &> /dev/null; then
	if ! yamllint "${INVENTORY_FILEPATH}"; then
		echo -e "\n${RED}${BOLD}Something went wrong while checking inventory with yamllint.${NORMAL}"
	else
		echo -e "${INVENTORY_FILENAME} is ok"
	fi
else
	echo -e "${RED}${BOLD}yamllint${NORMAL} not found, skipping..."
fi

echo -e "\n"

if ! ansible-inventory -i "${INVENTORY_FILEPATH}" --list; then
	echo -e "${RED}${BOLD}Something went wrong while checking inventory.${NORMAL}"
fi

# Playbook

echo -e "\n${GRAY}${BOLD}${PLAYBOOK_FILENAME}${NORMAL} checks..."

if ! ansible-playbook -i "${INVENTORY_FILEPATH}" "${PLAYBOOK_FILEPATH}" --syntax-check; then
	echo -e "\n${RED}${BOLD}Something went wrong while checking playbook.${NORMAL}"
else
	echo -e "${PLAYBOOK_FILENAME} is ok"
fi