#!/bin/sh
# manage_files.sh
set -e

SHARED_DIR="/data"
LOCK_FILE="$SHARED_DIR/.manage_files.lock"
CONTAINER_ID=$(hostname)
FILE_COUNTER=0

echo "Контейнер $CONTAINER_ID запущен. Общий каталог: $SHARED_DIR. Файл блокировки: $LOCK_FILE"

while true; do
  CREATED_FILE_THIS_ITERATION=""
  FILE_COUNTER=$((FILE_COUNTER + 1))

  TEMP_OUTPUT_FILE="/tmp/created_file_path_$CONTAINER_ID.txt"

  (
    if flock -x -w 5 200; then
      _found_path=""
      _next_filename_num=1
      while true; do
        _current_filename_base=$(printf "%03d" "$_next_filename_num")
        _target_file="$SHARED_DIR/$_current_filename_base"

        if [ ! -e "$_target_file" ]; then
          echo "$CONTAINER_ID $FILE_COUNTER" > "$_target_file"
          _found_path="$_target_file"
          echo "$(date +%T) [Контейнер $CONTAINER_ID]: Создан файл $_target_file (Счетчик: $FILE_COUNTER)" >&2
          break
        fi

        _next_filename_num=$((_next_filename_num + 1))
        if [ $_next_filename_num -gt 1000 ]; then
            echo "$(date +%T) [Контейнер $CONTAINER_ID]: ОШИБКА - Не удалось найти свободное имя файла до 999." >&2
            _found_path=""
            break
        fi
      done
      echo "$_found_path" > "$TEMP_OUTPUT_FILE"
      flock -u 200
    else
      echo "$(date +%T) [Контейнер $CONTAINER_ID]: ОШИБКА - Не удалось получить блокировку для создания файла." >&2
      echo "" > "$TEMP_OUTPUT_FILE"
    fi
  ) 200>"$LOCK_FILE"

  CREATED_FILE_THIS_ITERATION=$(cat "$TEMP_OUTPUT_FILE")
  rm -f "$TEMP_OUTPUT_FILE"

  if [ -z "$CREATED_FILE_THIS_ITERATION" ]; then
    echo "$(date +%T) [Контейнер $CONTAINER_ID]: Создание файла пропущено или не удалось (Счетчик: $FILE_COUNTER)."
    FILE_COUNTER=$((FILE_COUNTER - 1))
  fi

  sleep 1

  if [ -n "$CREATED_FILE_THIS_ITERATION" ]; then
    if [ -f "$CREATED_FILE_THIS_ITERATION" ]; then
        rm "$CREATED_FILE_THIS_ITERATION"
        echo "$(date +%T) [Контейнер $CONTAINER_ID]: Удален файл $CREATED_FILE_THIS_ITERATION"
    else
        echo "$(date +%T) [Контейнер $CONTAINER_ID]: Файл $CREATED_FILE_THIS_ITERATION не найден для удаления."
    fi
  fi

  sleep 1
done
