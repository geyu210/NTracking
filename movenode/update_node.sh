# antup node --version 0.3.9
# sudo nano  update_config 
# sudo rm -f ./update_node.sh && sudo wget --no-cache https://raw.githubusercontent.com/geyu210/NTracking/main/movenode/update_node.sh && sudo chmod +x update_node.sh
# tail -f /var/antctl/update_node.log

. /var/antctl/config

# 获取当前时间
current_time=$(date "+%Y-%m-%d %H:%M:%S")
echo "[$current_time] 开始更新节点"

# 读取配置文件
if [ -f "/var/antctl/update_config" ]; then
    source /var/antctl/update_config
    
    # 检查是否达到停止更新的节点编号
    if [ "$next_update" -ge "$stop_at" ]; then
        echo "[$current_time] 已达到预定的停止更新节点编号($stop_at)，程序终止"
        exit 0
    fi
    
    echo "[$current_time] 准备更新节点: $next_update"
else
    echo "[$current_time] 错误：配置文件 /var/antctl/update_config 不存在"
    exit 1
fi

# 获取服务名称
service_name="antnode$(printf "%03d" $next_update)"
service_file="/etc/systemd/system/${service_name}.service"
echo "[$current_time] 目标节点: $service_name"

# 检查服务文件是否存在
if [ ! -f "$service_file" ]; then
    echo "[$current_time] 错误：服务文件 $service_file 不存在"
    exit 1
fi

echo "[$current_time] 开始复制新版本节点文件..."
echo "原节点版本："
old_version=$($NodeStorage/$service_name/antnode --version | awk 'NR==1 {print $3}')
echo $old_version

echo "[$current_time] 复制新节点文件..."
sudo cp -f /home/geyu/.local/bin/antnode $NodeStorage/$service_name/
echo "[$current_time] 节点文件复制完成"
echo "更新后节点版本："
new_version=$($NodeStorage/$service_name/antnode --version | awk 'NR==1 {print $3}')
echo $new_version

# 更新文件权限
sudo chown ant:ant $NodeStorage/$service_name/antnode
if [ $? -eq 0 ]; then
    log_message+="[$current_time] 文件权限更新成功\n"
else
    log_message+="[$current_time] 警告：文件权限更新失败\n"
fi

# 检查节点编号是否在需要重启的范围内
if [ "$next_update" -ge "$restart_start" ] && [ "$next_update" -le "$restart_end" ]; then
    echo "[$current_time] 节点编号 $next_update 在重启范围内 ($restart_start-$restart_end)，执行重启..."
    echo "[$current_time] 重启节点服务..."
    sudo systemctl restart $service_name.service
    echo "[$current_time] 等待节点启动..."
    sleep 15
    echo "[$current_time] 获取节点元数据..."
    node_metadata="$(curl -s 127.0.0.1:$((13*1000+$next_update))/metadata)"
    echo "13*1000+$next_update = $((13*1000+$next_update)) "
    PeerId="$(echo "$node_metadata" | grep ant_networking_peer_id | awk 'NR==3 {print $1}' | cut -d'"' -f 2)"
    echo "$service_name Started PeerId=$PeerId"
else
    echo "[$current_time] 节点编号 $next_update 不在重启范围内，跳过重启步骤"
fi

echo "[$current_time] 更新配置文件..."
# 使用sed仅替换next_update的值，保留其他内容
sudo sed -i "s/^next_update=.*/next_update=$((next_update+1))/" /var/antctl/update_config
echo "[$current_time] 更新完成，下一个更新节点编号: $((next_update+1))"


