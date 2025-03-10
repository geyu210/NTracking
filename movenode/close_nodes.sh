# sudo rm -f ./close_nodes.sh && sudo wget --no-cache https://raw.githubusercontent.com/geyu210/NTracking/main/movenode/close_nodes.sh && sudo chmod +x close_nodes.sh

. /var/antctl/config

#stop_config:
#next_stop=1700
#target=2300
# 获取当前时间
current_time=$(date "+%Y-%m-%d %H:%M:%S")
echo "[$current_time] 开始停止节点"

# 读取配置文件
if [ -f "/var/antctl/stop_config" ]; then
    source /var/antctl/stop_config
    echo "[$current_time] 准备停止节点: $next_stop"
else
    echo "[$current_time] 错误：配置文件 /var/antctl/stop_config 不存在"
    exit 1
fi




while [ $next_stop -le $target ]; do
    # 获取服务名称
    service_name="antnode$(printf "%03d" $next_stop)"
    echo "[$current_time] 正在停止节点: $service_name"
    
    # 停止服务
    sudo systemctl stop $service_name.service
    sleep 3
    
    # 验证服务是否已经停止
    max_attempts=5
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        if ! systemctl is-active --quiet $service_name.service; then
            echo "[$current_time] 节点服务已成功停止"
            break
        else
            echo "[$current_time] 等待服务停止，尝试次数: $attempt/$max_attempts"
            sleep 3
            attempt=$((attempt + 1))
        fi
    done
    
    if [ $attempt -gt $max_attempts ]; then
        echo "[$current_time] 警告：服务可能未完全停止"
    fi
    
    # 更新 next_stop 值并保存到配置文件，保留 target 设置
    next_stop=$((next_stop + 1))
    sed -i "s/^next_stop=.*/next_stop=$next_stop/" /var/antctl/stop_config
    echo "[$current_time] 更新配置文件，下一个停止节点: $next_stop"
done

echo "[$current_time] 所有目标节点已停止 ($target)"











