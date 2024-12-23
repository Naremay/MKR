#!/bin/bash

# URL сервера
server_url="http://localhost"

# Функція для виконання запитів
send_request() {
    while true; do
        curl -s $server_url > /dev/null
        sleep $((RANDOM % 6 + 5))
    done
}

# Запускаємо асинхронні запити
for i in {1..5}; do
    send_request &
done

# Очікуємо завершення потоків
wait
