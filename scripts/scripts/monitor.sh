#!/bin/bash

# Configurações de monitoramento
ALERT_DISK_USAGE=80  # Porcentagem
ALERT_MEMORY_USAGE=90  # Porcentagem
LOG_DIR="/var/log/address-extractor"
METRICS_FILE="/tmp/address-extractor-metrics.json"

# Função para coletar métricas do sistema
collect_system_metrics() {
    log "INFO" "Coletando métricas do sistema..."

    # Uso de disco
    local disk_usage
    disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

    # Uso de memória
    local memory_usage
    memory_usage=$(free | awk '/Mem:/ {print int($3/$2 * 100)}')

    # Carga do sistema
    local system_load
    system_load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')

    # Criar JSON com métricas
    cat > "$METRICS_FILE" << EOF
{
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "system": {
        "disk_usage": $disk_usage,
        "memory_usage": $memory_usage,
        "load": $system_load
    }
}
EOF

    return 0
}

# Função para coletar métricas dos containers
collect_docker_metrics() {
    log "INFO" "Coletando métricas dos containers..."

    local containers=("address-extractor-web" "address-extractor-api")
    
    for container in "${containers[@]}"; do
        local stats
        stats=$(docker stats --no-stream --format "{{.Container}},{{.CPUPerc}},{{.MemUsage}},{{.NetIO}}" "$container")
        
        if [ -n "$stats" ]; then
            IFS=',' read -r -a array <<< "$stats"
            local temp_file="/tmp/$container-metrics.json"
            
            cat > "$temp_file" << EOF
{
    "container": "${array[0]}",
    "cpu_usage": "${array[1]}",
    "memory_usage": "${array[2]}",
    "network_io": "${array[3]}"
}
EOF
            # Mesclar com arquivo principal de métricas
            jq -s '.[0] * .[1]' "$METRICS_FILE" "$temp_file" > "${METRICS_FILE}.tmp" \
                && mv "${METRICS_FILE}.tmp" "$METRICS_FILE"
            rm "$temp_file"
        fi
    done

    return 0
}

# Função para coletar métricas da aplicação
collect_app_metrics() {
    log "INFO" "Coletando métricas da aplicação..."

    # Verificar endpoints de saúde
    local web_health
    web_health=$(curl -sf http://localhost:3000/health || echo "failed")
    
    local api_health
    api_health=$(curl -sf http://localhost:5000/health || echo "failed")

    # Atualizar arquivo de métricas
    local temp_file="/tmp/app-metrics.json"
    cat > "$temp_file" << EOF
{
    "application": {
        "web_status": "$([ "$web_health" != "failed" ] && echo "healthy" || echo "unhealthy")",
        "api_status": "$([ "$api_health" != "failed" ] && echo "healthy" || echo "unhealthy")"
    }
}
EOF

    jq -s '.[0] * .[1]' "$METRICS_FILE" "$temp_file" > "${METRICS_FILE}.tmp" \
        && mv "${METRICS_FILE}.tmp" "$METRICS_FILE"
    rm "$temp_file"

    return 0
}

# Função para verificar alertas
check_alerts() {
    log "INFO" "Verificando alertas..."

    local alerts=()

    # Verificar uso de disco
    local disk_usage
    disk_usage=$(jq -r '.system.disk_usage' "$METRICS_FILE")
    if [ "$disk_usage" -gt "$ALERT_DISK_USAGE" ]; then
        alerts+=("Uso de disco alto: ${disk_usage}%")
    fi

    # Verificar uso de memória
    local memory_usage
    memory_usage=$(jq -r '.system.memory_usage' "$METRICS_FILE")
    if [ "$memory_usage" -gt "$ALERT_MEMORY_USAGE" ]; then
        alerts+=("Uso de memória alto: ${memory_usage}%")
    fi

    # Verificar status da aplicação
    local web_status
    web_status=$(jq -r '.application.web_status' "$METRICS_FILE")
    if [ "$web_status" != "healthy" ]; then
        alerts+=("Frontend não está saudável")
    fi

    local api_status
    api_status=$(jq -r '.application.api_status' "$METRICS_FILE")
    if [ "$api_status" != "healthy" ]; then
        alerts+=("API não está saudável")
    fi

    # Exibir alertas
    if [ ${#alerts[@]} -gt 0 ]; then
        log "WARNING" "Alertas detectados:"
        printf '%s\n' "${alerts[@]}"
        return 1
    fi

    return 0
}

# Função para rotacionar logs
rotate_logs() {
    log "INFO" "Rotacionando logs..."

    # Criar diretório de logs se não existir
    mkdir -p "$LOG_DIR"

    # Compactar logs antigos
    find "$LOG_DIR" -name "*.log" -mtime +7 -exec gzip {} \;

    # Remover logs mais antigos que 30 dias
    find "$LOG_DIR" -name "*.log.gz" -mtime +30 -delete

    return 0
}

# Função principal de monitoramento
monitor() {
    log "INFO" "Iniciando monitoramento..."

    # Coletar métricas
    if ! collect_system_metrics; then
        log "ERROR" "Falha ao coletar métricas do sistema"
        return 1
    fi

    if ! collect_docker_metrics; then
        log "ERROR" "Falha ao coletar métricas dos containers"
        return 1
    fi

    if ! collect_app_metrics; then
        log "ERROR" "Falha ao coletar métricas da aplicação"
        return 1
    fi

    # Verificar alertas
    if ! check_alerts; then
        # Não retornamos erro aqui para não interromper o monitoramento
        log "WARNING" "Alertas detectados durante o monitoramento"
    fi

    # Rotacionar logs
    if ! rotate_logs; then
        log "WARNING" "Falha ao rotacionar logs"
    fi

    # Exibir resumo
    log "SUCCESS" "Monitoramento concluído"
    echo "Métricas disponíveis em: $METRICS_FILE"

    return 0
}

# Registrar função de limpeza
trap 'rm -f "$METRICS_FILE"' EXIT

# Executar monitoramento
monitor
