#!/bin/bash
#todo: 1. 暂停当前服务
#sudo systemctl stop antnode001


# 检查是否提供了一个参数（服务名称）
if [ $# -ne 1 ]; then
    echo "用法: $0 <service_name>"
    exit 1
fi

# 获取服务名称
service_name=$1
service_file="/etc/systemd/system/${service_name}.service"

# 检查服务文件是否存在
if [ ! -f "$service_file" ]; then
    echo "服务文件 $service_file 不存在。"
    exit 1
fi

# 备份原始服务文件
cp "$service_file" "${service_file}.bak"
echo "已备份服务文件到 ${service_file}.bak"

# 定义旧路径和新路径
old_path="/var/antctl/services//${service_name}"
new_path="/datapool/autonomi/NTracking_nodes/services/${service_name}"

# 使用 sed 替换服务文件中所有匹配的旧路径为新路径
sed -i "s#${old_path}#${new_path}#g" "$service_file"

# 确认修改完成
echo "已更新 $service_file 中的路径："
echo "  ${old_path} -> ${new_path}"
echo "请运行以下命令以应用更改："
echo "  sudo systemctl daemon-reload"
echo "  sudo systemctl restart ${service_name}"