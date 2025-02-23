#!/bin/bash
# sudo rm -f ./move_node.sh && sudo wget --no-cache https://raw.githubusercontent.com/geyu210/NTracking/main/movenode/move_node.sh && sudo chmod +x move_node.sh
#todo: 1. 暂停当前服务
#sudo systemctl stop antnode001


# 读取配置文件
if [ -f "/var/antctl/movenode_config" ]; then
    source /var/antctl/movenode_config
    # service_number=$(printf "%03d" $service_number)
    echo "service_number: $service_number"
else
    echo "配置文件 /var/antctl/movenode_config 不存在"
    exit 1
fi
# 获取服务名称
service_name="antnode$(printf "%03d" $service_number)"
service_file="/etc/systemd/system/${service_name}.service"

# 检查服务文件是否存在
if [ ! -f "$service_file" ]; then
    echo "服务文件 $service_file 不存在。"
    exit 1
fi

# 备份原始服务文件
sudo cp "$service_file" "${service_file}.bak"
echo "已备份服务文件到 ${service_file}.bak"


# 定义旧路径和新路径
old_path="/var/antctl/services//${service_name}"
new_path="/datapool/autonomi/NTracking_nodes/services/${service_name}"

# Stop service
if sudo systemctl is-active --quiet "$service_name"; then
    echo "Stopping service..."
    sudo systemctl stop "$service_name" || {
        echo "Failed to stop service, skipping this node"
        exit 1
    }
fi

if [ -d "$old_path" ]; then
    echo "Migrating data directory..."
    sudo mkdir -p "$new_path"
    sudo rsync -a --delete "$old_path/" "$new_path/"
    sudo chown -R ant:ant "$new_path"
else
    echo "Source directory ${old_path} does not exist"
fi

# 使用 sed 替换服务文件中所有匹配的旧路径为新路径
sudo sed -i "s#${old_path}#${new_path}#g" "$service_file"

# 确认修改完成
echo "已更新 $service_file 中的路径："
echo "  ${old_path} -> ${new_path}"

# 应用更改并重启服务
echo "正在重新加载 systemd 配置..."
sudo systemctl daemon-reload

echo "正在重启服务 ${service_name}..."
if sudo systemctl restart "${service_name}"; then
    echo "服务重启成功"
    sudo systemctl status "${service_name}" --no-pager | head -n 5
    
    # 更新配置文件中的节点编号
    next_number=$((service_number + 1))
    # 使用临时文件方式更新配置
    echo "service_number=$next_number" | sudo tee /var/antctl/movenode_config.tmp > /dev/null
    sudo mv /var/antctl/movenode_config.tmp /var/antctl/movenode_config
    sudo chmod 644 /var/antctl/movenode_config
    
    # 验证更新是否成功
    if [ -f "/var/antctl/movenode_config" ]; then
        echo "配置文件已更新，下一个节点编号: $next_number"
    else
        echo "配置文件更新失败"
        exit 1
    fi
else
    echo "服务重启失败！请检查日志：journalctl -u ${service_name}"
    exit 1
fi

echo "通过命令查询服务状态：sudo systemctl status ${service_name} --no-pager ..."