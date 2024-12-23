#!/bin/bash

# Перемикаємо контейнер на конкретне ядро CPU
run_container() {
    container_name=$1
    cpu=$2
    docker run -d --name $container_name --cpuset-cpus=$cpu your-docker-image
}

check_and_scale() {
    while true; do
        # Перевіряємо завантаження контейнерів
        for container in srv1 srv2 srv3; do
            # Отримуємо CPU usage
            cpu_usage=$(docker stats --no-stream --format "{{.CPUPerc}}" $container 2>/dev/null | cut -d'.' -f1)
            
            # Логіка перевірки завантаження
            if [[ $container == "srv1" && $cpu_usage -ge 70 ]]; then
                if [[ ! $(docker ps -q -f name=srv2) ]]; then
                    run_container "srv2" 1
                fi
            elif [[ $container == "srv2" && $cpu_usage -ge 70 ]]; then
                if [[ ! $(docker ps -q -f name=srv3) ]]; then
                    run_container "srv3" 2
                fi
            fi
        done

        # Зупиняємо контейнери, якщо вони простоюють
        for container in srv3 srv2; do
            if [[ $(docker ps -q -f name=$container) ]]; then
                idle_time=$(docker inspect --format='{{.State.IdleTime}}' $container)
                if [[ $idle_time -ge 120 ]]; then
                    docker stop $container && docker rm $container
                fi
            fi
        done

        # Перевірка оновлення версій контейнерів
        new_version=$(docker pull your-docker-image | grep "Downloaded newer image")
        if [[ $new_version ]]; then
            for container in srv1 srv2 srv3; do
                if [[ $(docker ps -q -f name=$container) ]]; then
                    docker stop $container && docker rm $container
                    run_container $container ${container: -1}
                fi
            done
        fi

        sleep 120
    done
}

# Запускаємо перший контейнер
if [[ ! $(docker ps -q -f name=srv1) ]]; then
    run_container "srv1" 0
fi

# Запускаємо основну функцію
check_and_scale
