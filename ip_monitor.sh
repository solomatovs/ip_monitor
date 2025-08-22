#!/bin/bash

set -euo pipefail

# Default values
PID_LIST=""
OUTPUT_FILE="ips_monitor_$(date +%Y%m%d_%H%M%S).log"
REALTIME=false
VERBOSE=false
KEEP_SCRIPT=false

# Simple argument parsing
while [[ $# -gt 0 ]]; do
    case $1 in
        --output) OUTPUT_FILE="$2"; shift 2 ;;
        --verbose) VERBOSE=true; shift ;;
        --keep-script) KEEP_SCRIPT=true; shift ;;
        --help) 
            echo "Usage: $0 <PID1,PID2> [options]"
            echo "Options: --output FILE, --verbose, --keep-script"
            exit 0 ;;
        *) PID_LIST="$1"; shift ;;
    esac
done

if [[ -z "$PID_LIST" ]]; then
    echo "❌ Specify root PIDs: $0 1234,5678"
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    echo "❌ sudo required"
    exit 1
fi

# PID parsing
IFS=',' read -ra PIDS <<< "$PID_LIST"
VALID_PIDS=()

echo "=== Checking root PIDs ==="
for pid in "${PIDS[@]}"; do
    pid=$(echo "$pid" | tr -d ' ')
    if kill -0 "$pid" 2>/dev/null; then
        VALID_PIDS+=("$pid")
        echo "✅ Root PID $pid: $(ps -p "$pid" -o comm= || echo unknown)"
    else
        echo "❌ PID $pid: does not exist"
    fi
done

if [ ${#VALID_PIDS[@]} -eq 0 ]; then
    echo "❌ No valid root PIDs"
    exit 1
fi

# Preparing values
ROOT_PIDS_LIST="${VALID_PIDS[*]}"

# Creating the final script directly
GENERATED_SCRIPT="generated_ips_monitor_$.d"

[[ "$VERBOSE" == "true" ]] && echo "Creating script: $GENERATED_SCRIPT"

# Create script directly, using template as base
cat > "$GENERATED_SCRIPT" << EOF
#!/usr/sbin/dtrace -Cs

BEGIN {
    printf("=== Мониторинг корневых PID и их потомков ===");
    printf("=== Корневые PID: ${ROOT_PIDS_LIST} ===");
    connection_count = 0;
    
    /* Инициализация корневых PID через ассоциативный массив */
$(for pid in "${VALID_PIDS[@]}"; do
    echo "    tracked_pids[$pid] = 1;"
done)
    
    printf("Инициализация завершена. Начинаем мониторинг...");
    printf("Отслеживаем ${#VALID_PIDS[@]} корневых PID");
}

#define IS_TRACKED_PID(check_pid) \\
    (tracked_pids[check_pid] == 1)

proc:::create {
    if (IS_TRACKED_PID(ppid)) {
        tracked_pids[pid] = 1;
        printf("➕ НОВЫЙ_ПОТОМОК: PID %d создан процессом %d", pid, ppid);
    }
}

proc:::exit {
    /* Очищаем корневые PID при выходе */
    if (tracked_pids[pid] == 1) {
        tracked_pids[pid] = 0;
        printf("🚫 PID_ЗАВЕРШЕН: PID %d", pid);
    }
}

/* Добавить новые probe-ы для отслеживания информации о сокетах */
syscall::getsockname:entry {
    if (IS_TRACKED_PID(pid)) {
        printf("GETSOCKNAME [PID %d]: FD=%d", pid, arg0);
        self->sockname_fd = arg0;
        self->sockname_addr_ptr = arg1;
        self->sockname_len_ptr = arg2;
    }
}

syscall::getsockname:return {
    if (IS_TRACKED_PID(pid) && self->sockname_addr_ptr != 0) {
        if (arg1 == 0) { /* успех */
            this->addr_len = *(socklen_t*)copyin(self->sockname_len_ptr, 4);
            if (this->addr_len >= 16) {
                this->addr = copyin(self->sockname_addr_ptr, this->addr_len);
                this->family = *(uint8_t*)((char*)this->addr + 1);
                
                if (this->family == 2) {
                    this->port = *(uint16_t*)((char*)this->addr + 2);
                    this->port = ((this->port & 0xFF) << 8) | ((this->port >> 8) & 0xFF);
                    this->ip = *(uint32_t*)((char*)this->addr + 4);
                    printf("  -> 📍 LOCAL IPv4: %d.%d.%d.%d:%d (FD=%d)",
                           this->ip & 0xFF, (this->ip >> 8) & 0xFF,
                           (this->ip >> 16) & 0xFF, (this->ip >> 24) & 0xFF,
                           this->port, self->sockname_fd);
                }
            }
        }
        self->sockname_fd = 0;
        self->sockname_addr_ptr = 0;
        self->sockname_len_ptr = 0;
    }
}

syscall::getpeername:entry {
    if (IS_TRACKED_PID(pid)) {
        printf("GETPEERNAME [PID %d]: FD=%d", pid, arg0);
        self->peername_fd = arg0;
        self->peername_addr_ptr = arg1;
        self->peername_len_ptr = arg2;
    }
}

syscall::getpeername:return {
    if (IS_TRACKED_PID(pid) && self->peername_addr_ptr != 0) {
        if (arg1 == 0) { /* успех */
            this->addr_len = *(socklen_t*)copyin(self->peername_len_ptr, 4);
            if (this->addr_len >= 16) {
                this->addr = copyin(self->peername_addr_ptr, this->addr_len);
                this->family = *(uint8_t*)((char*)this->addr + 1);
                
                if (this->family == 2) {
                    this->port = *(uint16_t*)((char*)this->addr + 2);
                    this->port = ((this->port & 0xFF) << 8) | ((this->port >> 8) & 0xFF);
                    this->ip = *(uint32_t*)((char*)this->addr + 4);
                    printf("  -> 🎯 PEER IPv4: %d.%d.%d.%d:%d (FD=%d)",
                           this->ip & 0xFF, (this->ip >> 8) & 0xFF,
                           (this->ip >> 16) & 0xFF, (this->ip >> 24) & 0xFF,
                           this->port, self->peername_fd);
                    connection_count++;
                }
            }
        }
        self->peername_fd = 0;
        self->peername_addr_ptr = 0;
        self->peername_len_ptr = 0;
    }
}

/* Улучшенная обработка socket создания с запоминанием типов */
syscall::socket:entry {
    if (IS_TRACKED_PID(pid)) {
        printf("SOCKET [PID %d]: domain=%d, type=%d, protocol=%d", 
               pid, arg0, arg1, arg2);
        
        /* Сохраняем параметры сокета для использования в return */
        self->socket_domain = arg0;
        self->socket_type = arg1;
        self->socket_protocol = arg2;
        
        if (arg0 == 1) { printf("  -> AF_UNIX"); }
        else if (arg0 == 2) { printf("  -> AF_INET (IPv4)"); }
        else if (arg0 == 30) { printf("  -> AF_INET6"); }
        else if (arg0 == 32) { printf("  -> AF_SYSTEM"); }
        else { printf("  -> Семейство: %d", arg0); }
        
        if (arg1 == 1) { printf("  -> SOCK_STREAM (TCP)"); }
        else if (arg1 == 2) { printf("  -> SOCK_DGRAM (UDP)"); }
        else { printf("  -> Тип: %d", arg1); }
    }
}

syscall::socket:return {
    if (IS_TRACKED_PID(pid)) {
        if (arg1 >= 0) {
            printf("SOCKET_SUCCESS [PID %d]: FD=%d", pid, arg1);
            
            /* Запоминаем тип сокета для FD */
            if (self->socket_domain == 2 && self->socket_type == 2) {
                printf("  -> 📝 Запомнили UDP сокет FD=%d", arg1);
                /* В идеале здесь бы сохранить в ассоциативный массив, но DTrace ограничен */
            }
        } else {
            printf("SOCKET_FAILED [PID %d]: error=%d", pid, arg1);
        }
        
        /* Очищаем временные переменные */
        self->socket_domain = 0;
        self->socket_type = 0;
        self->socket_protocol = 0;
    }
}

syscall::connect:entry {
    if (IS_TRACKED_PID(pid)) {
        printf("CONNECT_ENTRY [PID %d]: FD=%d, addr_len=%d", 
               pid, arg0, arg2);
        
        if (arg2 >= 16) {
            this->addr = copyin(arg1, 16);
            this->family = *(uint8_t*)((char*)this->addr + 1);
            
            if (this->family == 2) {
                this->port = *(uint16_t*)((char*)this->addr + 2);
                this->port = ((this->port & 0xFF) << 8) | ((this->port >> 8) & 0xFF);
                this->ip = *(uint32_t*)((char*)this->addr + 4);
                printf("  -> 🎯 IPv4: %d.%d.%d.%d:%d",
                       this->ip & 0xFF, (this->ip >> 8) & 0xFF,
                       (this->ip >> 16) & 0xFF, (this->ip >> 24) & 0xFF,
                       this->port);
                connection_count++;
            }
            else if (this->family == 30) {
                this->port = *(uint16_t*)((char*)this->addr + 2);
                this->port = ((this->port & 0xFF) << 8) | ((this->port >> 8) & 0xFF);
                printf("  -> 🎯 IPv6 порт: %d", this->port);
                connection_count++;
            }
            else if (this->family == 1) {
                printf("  -> Unix socket");
            }
            else if (this->family == 32) {
                printf("  -> AF_SYSTEM (macOS IPC)");
            }
            else {
                printf("  -> Семейство: %d", this->family);
            }
        }
    }
}

syscall::connect:return {
    if (IS_TRACKED_PID(pid)) {
        if (arg1 == 0) {
            printf("✅ CONNECT_SUCCESS [PID %d]", pid);
        } else {
            printf("❌ CONNECT_FAILED [PID %d]: error=%d", pid, arg1);
        }
    }
}

syscall::sendto:entry {
    if (IS_TRACKED_PID(pid)) {
        printf("SENDTO [PID %d]: FD=%d, bytes=%d, addr_len=%d", 
               pid, arg0, arg2, arg5);
        
        if (arg5 >= 16) {
            /* arg4 = адрес назначения, arg5 = длина адреса */
            this->addr = copyin(arg4, arg5);
            this->family = *(uint8_t*)((char*)this->addr + 1);
            
            if (this->family == 2) {
                /* IPv4 адрес */
                this->port = *(uint16_t*)((char*)this->addr + 2);
                this->port = ((this->port & 0xFF) << 8) | ((this->port >> 8) & 0xFF);
                this->ip = *(uint32_t*)((char*)this->addr + 4);
                printf("  -> 🎯 IPv4: %d.%d.%d.%d:%d",
                       this->ip & 0xFF, (this->ip >> 8) & 0xFF,
                       (this->ip >> 16) & 0xFF, (this->ip >> 24) & 0xFF,
                       this->port);
                connection_count++;
            }
            else if (this->family == 30) {
                /* IPv6 адрес */
                this->port = *(uint16_t*)((char*)this->addr + 2);
                this->port = ((this->port & 0xFF) << 8) | ((this->port >> 8) & 0xFF);
                printf("  -> 🎯 IPv6 порт: %d", this->port);
                connection_count++;
            }
            else if (this->family == 1) {
                printf("  -> Unix socket");
            }
            else {
                printf("  -> Семейство: %d", this->family);
            }
        } else if (arg5 == 0) {
            printf("  -> Без адреса (подключенный UDP)");
        } else {
            printf("  -> Короткий адрес (длина: %d)", arg5);
        }
    }
}

syscall::sendto:return {
    if (IS_TRACKED_PID(pid)) {
        if (arg1 >= 0) {
            printf("✅ SENDTO_SUCCESS [PID %d]: отправлено=%d байт", pid, arg1);
        } else {
            printf("❌ SENDTO_FAILED [PID %d]: error=%d", pid, arg1);
        }
    }
}

syscall::recvfrom:entry {
    if (IS_TRACKED_PID(pid)) {
        printf("RECVFROM_ENTRY [PID %d]: FD=%d, buf_size=%d", pid, arg0, arg2);
        
        /* Сохраняем указатели для использования в return */
        self->recvfrom_addr_ptr = arg4;  /* буфер для адреса источника */
        self->recvfrom_addr_len_ptr = arg5; /* указатель на длину адреса */
    }
}

syscall::recvfrom:return {
    if (IS_TRACKED_PID(pid) && arg1 > 0) {
        printf("RECVFROM [PID %d]: bytes=%d", pid, arg1);
        
        /* Пытаемся получить адрес источника, если он был запрошен */
        if (self->recvfrom_addr_ptr != 0 && self->recvfrom_addr_len_ptr != 0) {
            this->addr_len = *(socklen_t*)copyin(self->recvfrom_addr_len_ptr, 4);
            
            if (this->addr_len >= 16) {
                this->addr = copyin(self->recvfrom_addr_ptr, this->addr_len);
                this->family = *(uint8_t*)((char*)this->addr + 1);
                
                if (this->family == 2) {
                    /* IPv4 источник */
                    this->port = *(uint16_t*)((char*)this->addr + 2);
                    this->port = ((this->port & 0xFF) << 8) | ((this->port >> 8) & 0xFF);
                    this->ip = *(uint32_t*)((char*)this->addr + 4);
                    printf("  <- 🎯 FROM IPv4: %d.%d.%d.%d:%d",
                           this->ip & 0xFF, (this->ip >> 8) & 0xFF,
                           (this->ip >> 16) & 0xFF, (this->ip >> 24) & 0xFF,
                           this->port);
                    connection_count++;
                }
                else if (this->family == 30) {
                    /* IPv6 источник */
                    this->port = *(uint16_t*)((char*)this->addr + 2);
                    this->port = ((this->port & 0xFF) << 8) | ((this->port >> 8) & 0xFF);
                    printf("  <- 🎯 FROM IPv6 порт: %d", this->port);
                    connection_count++;
                }
                else if (this->family == 1) {
                    printf("  <- Unix socket");
                }
                else {
                    printf("  <- Семейство: %d", this->family);
                }
            } else if (this->addr_len > 0) {
                printf("  <- Короткий адрес источника (длина: %d)", this->addr_len);
            }
        }
        
        /* Очищаем сохраненные указатели */
        self->recvfrom_addr_ptr = 0;
        self->recvfrom_addr_len_ptr = 0;
    }
}

/* Перехват дублирования файловых дескрипторов */
syscall::dup:entry {
    if (IS_TRACKED_PID(pid)) {
        printf("DUP [PID %d]: старый_FD=%d", pid, arg0);
        self->dup_old_fd = arg0;
    }
}

syscall::dup:return {
    if (IS_TRACKED_PID(pid) && self->dup_old_fd != 0) {
        if (arg1 >= 0) {
            printf("✅ DUP_SUCCESS [PID %d]: %d -> %d", 
                   pid, self->dup_old_fd, arg1);
            
            /* Если дублируем сетевой сокет, отмечаем это */
            if (self->dup_old_fd >= 3) {  /* Исключаем stdin/stdout/stderr */
                printf("  -> 📋 Скопирован сокет: FD %d теперь дублирует FD %d", 
                       arg1, self->dup_old_fd);
            }
        } else {
            printf("❌ DUP_FAILED [PID %d]: FD=%d, error=%d", 
                   pid, self->dup_old_fd, arg1);
        }
        self->dup_old_fd = 0;
    }
}

syscall::dup2:entry {
    if (IS_TRACKED_PID(pid)) {
        printf("DUP2 [PID %d]: %d -> %d", pid, arg0, arg1);
        self->dup2_old_fd = arg0;
        self->dup2_new_fd = arg1;
    }
}

syscall::dup2:return {
    if (IS_TRACKED_PID(pid) && self->dup2_old_fd != 0) {
        if (arg1 >= 0) {
            printf("✅ DUP2_SUCCESS [PID %d]: %d -> %d", 
                   pid, self->dup2_old_fd, self->dup2_new_fd);
            
            /* Особенно интересно, если копируем в высокие номера FD */
            if (self->dup2_new_fd > 10) {
                printf("  -> 📋 Сокет скопирован: FD %d = копия FD %d", 
                       self->dup2_new_fd, self->dup2_old_fd);
            }
        } else {
            printf("❌ DUP2_FAILED [PID %d]: %d -> %d, error=%d", 
                   pid, self->dup2_old_fd, self->dup2_new_fd, arg1);
        }
        self->dup2_old_fd = 0;
        self->dup2_new_fd = 0;
    }
}

/* Также перехватим fcntl с F_DUPFD - еще один способ дублирования */
syscall::fcntl:entry {
    if (IS_TRACKED_PID(pid) && (arg1 == 0 || arg1 == 1030)) {
        /* F_DUPFD = 0, F_DUPFD_CLOEXEC = 1030 (на macOS) */
        printf("FCNTL_DUPFD [PID %d]: FD=%d, cmd=%d, минимальный_FD=%d", 
               pid, arg0, arg1, arg2);
        self->fcntl_old_fd = arg0;
        self->fcntl_cmd = arg1;
    }
}

syscall::fcntl:return {
    if (IS_TRACKED_PID(pid) && self->fcntl_old_fd != 0) {
        if (arg1 >= 0) {
            printf("✅ FCNTL_DUPFD_SUCCESS [PID %d]: %d -> %d (cmd=%d)", 
                   pid, self->fcntl_old_fd, arg1, self->fcntl_cmd);
            
            if (arg1 > 10) {
                printf("  -> 📋 Fcntl скопировал сокет: FD %d = копия FD %d", 
                       arg1, self->fcntl_old_fd);
            }
        } else {
            printf("❌ FCNTL_DUPFD_FAILED [PID %d]: FD=%d, error=%d", 
                   pid, self->fcntl_old_fd, arg1);
        }
        self->fcntl_old_fd = 0;
        self->fcntl_cmd = 0;
    }
}

tick-60s {
    printf("=== ⏰ СТАТИСТИКА ЗА МИНУТУ ===");
    printf("Всего IP соединений: %d", connection_count);
}

END {
    printf("=== МОНИТОРИНГ ЗАВЕРШЕН ===");
    printf("Итого IP соединений: %d", connection_count);
}
EOF

chmod +x "$GENERATED_SCRIPT"

# Cleanup on exit
cleanup() {
    if [[ "$KEEP_SCRIPT" == "false" && -f "$GENERATED_SCRIPT" ]]; then
        rm -f "$GENERATED_SCRIPT"
    elif [[ "$KEEP_SCRIPT" == "true" ]]; then
        echo "🔧 Generated script saved: $GENERATED_SCRIPT"
    fi
}
trap cleanup EXIT

echo "=== Monitoring settings ==="
echo "Root PIDs: ${VALID_PIDS[*]}"
echo "Output file: $OUTPUT_FILE"
echo "=============================="
echo ""

echo "Starting monitoring of root PIDs and their descendants..."
echo "Press Ctrl+C to stop"
echo ""

dtrace -o "$OUTPUT_FILE" -C -s "$GENERATED_SCRIPT"

if [[ -f "$OUTPUT_FILE" ]]; then
    echo ""
    echo "=== Results ==="
    echo "📄 File: $OUTPUT_FILE"
    echo "📊 Lines: $(wc -l < "$OUTPUT_FILE")"
    echo ""
    echo "🎯 IP connections:"
    grep -o "IPv4: [0-9.]*:[0-9]*" "$OUTPUT_FILE" | sort | uniq -c | sort -nr || echo "No IPs found"
    echo ""

    # Извлекаем уникальные IP адреса
    unique_ips=$(grep -o "IPv4: [0-9.]*:[0-9]*" "$OUTPUT_FILE" 2>&1 | \
                sed 's/IPv4: //' | \
                cut -d':' -f1 | \
                sort -u)
    
    total_ips=$(echo "$unique_ips" | wc -l)

    if [ "$total_ips" -ne 0 ]; then
        echo "🎯 Mikrotik firewall list:"
        echo "/ip firewall address-list"
        echo "$unique_ips" | while IFS= read -r ip; do
            if [[ -n "$ip" ]]; then
                echo "add address=$ip list=vpn_traffik"
            fi
        done
        echo ""
    fi

    echo "📋 Unique ips: $total_ips"
fi