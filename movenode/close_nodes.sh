# sudo rm -f ./update_node.sh && sudo wget --no-cache https://raw.githubusercontent.com/geyu210/NTracking/main/movenode/update_node.sh && sudo chmod +x update_node.sh

. /var/antctl/config

#stop_config:
#next_stop=1700
#target=2300
# 获取当前时间
current_time=$(date "+%Y-%m-%d %H:%M:%S")
echo "[$current_time] 开始更新节点"

# 读取配置文件
if [ -f "/var/antctl/stop_config" ]; then
    source /var/antctl/stop_config
    echo "[$current_time] 准备更新节点: $next_stop"
else
    echo "[$current_time] 错误：配置文件 /var/antctl/stop_config 不存在"
    exit 1
fi

# 获取服务名称
service_name="antnode$(printf "%03d" $next_update)"
service_file="/etc/systemd/system/${service_name}.service"
echo "[$current_time] 目标节点: $service_name"





while [ $next_stop -le $target ]; do
    # 获取服务名称
    service_name="antnode$(printf "%03d" $next_stop)"
    echo "[$current_time] 正在停止节点: $service_name"

    # 检查服务文件是否存在
if [ ! -f "$service_file" ]; then
    echo "[$current_time] 错误：服务文件 $service_file 不存在"
    exit 1
fi

    
    # 停止服务
    sudo systemctl stop $service_name.service
    sleep 3
    echo "[$current_time] 节点服务已停止"
    
    # 更新 next_stop 值并保存到配置文件
    next_stop=$((next_stop + 1))
    echo "next_stop=$next_stop" | sudo tee /var/antctl/stop_config > /dev/null
    echo "[$current_time] 更新配置文件，下一个停止节点: $next_stop"
done

echo "[$current_time] 所有目标节点已停止 ($target)"











