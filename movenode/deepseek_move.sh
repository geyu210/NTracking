#!/bin/bash
# sudo rm -f ./deepseek_move.sh* && sudo wget https://raw.githubusercontent.com/geyu210/NTracking/main/movenode/deepseek_move.sh && sudo chmod +x ./deepseek_move.sh
# set -eo pipefail

# Configuration parameters
BASE_NAME="antnode"
START_NUM=2
END_NUM=3
OLD_BASE="/var/antctl/services"
NEW_BASE="/datapool/autonomi/NTracking_nodes/services"
SERVICE_DIR="/etc/systemd/system"
LOG_FILE="/var/log/antnode_migration.log"

# Permission check
if [[ $EUID -ne 0 ]]; then
   echo "Please run this script with sudo" 
   exit 1
fi

# Initialize log
exec > >(tee -a "$LOG_FILE") 2>&1
echo "====== Migration started at $(date) ======"
echo "Debug: Creating directory $NEW_BASE"
mkdir -p "$NEW_BASE"
echo "Debug: Directory creation status: $?"
echo "Debug: Listing services:"
# ls -l $SERVICE_DIR/antnode* || echo "No service files found"

# Progress counter
total=$((END_NUM - START_NUM + 1))
current=0
echo "Debug: Will process nodes from $START_NUM to $END_NUM (total: $total)"

# Add error checking for required directories
echo "Debug: Checking required directories..."
echo "Debug: OLD_BASE=${OLD_BASE}"
[ -d "$OLD_BASE" ] && echo "OLD_BASE exists" || echo "OLD_BASE does not exist"
echo "Debug: SERVICE_DIR=${SERVICE_DIR}"
[ -d "$SERVICE_DIR" ] && echo "SERVICE_DIR exists" || echo "SERVICE_DIR does not exist"

for ((i=START_NUM; i<=END_NUM; i++)); do
    # Format node number (three digits)
    node_num=$(printf "%03d" $i)
    service_name="${BASE_NAME}${node_num}"
    service_file="${SERVICE_DIR}/${service_name}.service"
    
    echo "Debug: Checking service file: $service_file"
    if [ -f "$service_file" ]; then
        echo "Debug: Service file exists"
    else
        echo "Debug: Service file does not exist"
    fi
    ((current++))
    echo "[Progress ${current}/${total}] Processing ${service_name}"

    # Check if service exists
    if [ ! -f "$service_file" ]; then
        echo "Service ${service_name} does not exist, skipping"
        continue
    fi

    # Stop service
    if systemctl is-active --quiet "$service_name"; then
        echo "Stopping service..."
        systemctl stop "$service_name" || {
            echo "Failed to stop service, skipping this node"
            continue
        }
    fi

    # Migrate data directory
    old_dir="${OLD_BASE}/${service_name}"
    new_dir="${NEW_BASE}/${service_name}"
    
    if [ -d "$old_dir" ]; then
        echo "Migrating data directory..."
        mkdir -p "$new_dir"
        rsync -a --delete "$old_dir/" "$new_dir/" #&& rm -rf "$old_dir"
        chown -R ant:ant "$new_dir"
    else
        echo "Source directory ${old_dir} does not exist"
    fi

    # Modify service file
    echo "Updating service configuration..."
    sed -i.bak \
        -e "s#${OLD_BASE}//${service_name}#${new_dir}#g" \
        -e "s#--root-dir ${OLD_BASE}//${service_name}#--root-dir ${new_dir}#g" \
        "$service_file"

    # Verify service file
    if ! systemctl verify "$service_file" >/dev/null 2>&1; then
        echo "Service file verification failed, restoring backup..."
        mv "${service_file}.bak" "$service_file"
        continue
    fi

    # Start service
    echo "Starting service..."
    systemctl daemon-reload
    if systemctl start "$service_name"; then
        systemctl status "$service_name" --no-pager | head -n 5
    else
        echo "Start failed! Check logs: journalctl -u ${service_name}"
    fi
    echo "--------------------------------------"
done

echo "====== Migration completed at $(date) ======"
echo "Full log available at: ${LOG_FILE}"
echo "Suggested manual verifications:"
echo "1. All service statuses (systemctl list-units antnode*)"
echo "2. Data directory permissions (ls -ld ${NEW_BASE}/antnode*)"
echo "3. Node log files (journalctl -u antnodeXXX)"
