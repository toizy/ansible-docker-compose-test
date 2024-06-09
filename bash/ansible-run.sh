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

echo -e "${BOLD}Running playbook checks${NORMAL}\n"

# Inventory

if ! ansible-playbook -i "${INVENTORY_FILEPATH}" "${PLAYBOOK_FILEPATH}"; then
	echo -e "\n${RED}${BOLD}Something went wrong.${NORMAL}"
fi