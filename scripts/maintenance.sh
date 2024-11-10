#!/bin/bash

# Configurações de manutenção
MAINTENANCE_FILE="/tmp/maintenance-mode"
BACKUP_RETENTION_DAYS=30
LOG_RETENTION_DAYS=7

# Função para ativar modo de manutenção
enable_maintenance() {
    log "INFO" "Ativando modo de manutenção..."

    # Criar arquivo de manutenção
    echo "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "$MAINTENANCE_FILE"

    # Atualizar configuração do Nginx
    cat > "/etc/nginx/conf.d/maintenance.conf" << 'EOF'
location / {
    if (!-f $request_filename) {
        return 503;
    }
}

error_page 503 @maintenance;

location @maintenance {
    rewrite ^(.*)$ /maintenance.html break;
}
EOF

    # Recarregar Nginx
    nginx -s reload

    log "SUCCESS" "Modo de manutenção ativado"
    return 0
}

# Função para desativar modo de manutenção
disable_maintenance() {
    log "INFO" "Desativando modo de manutenção..."

    # Remover arquivo de manutenção
    rm -f "$MAINTENANCE_FILE"

    # Remover configuração de manutenção do Nginx
    rm -f "/etc/nginx/conf.d/maintenance.conf"

    # Recarregar Nginx
    nginx -s reload

    log "SUCCESS" "Modo de manutenção desativado"
    return 0
}

# Função para limpeza de arquivos temporários
cleanup_temp_files() {
    log "INFO" "Limpando arquivos temporários..."

    # Limpar arquivos temporários do sistema
    find /tmp -type f -name "address-extractor-*" -mtime +1 -delete

    # Limpar arquivos de log antigos
    find "$LOG_DIR" -type f -name "*.log" -mtime +"$LOG_RETENTION_DAYS" -delete

    # Limpar backups antigos
    find "$BACKUP_PATH" -type d -mtime +"$BACKUP_RETENTION_DAYS" -exec rm -rf {} \;

    log "SUCCESS" "Limpeza concluída"
    return 0
}

# Função para otimizar banco de dados
optimize_database() {
    log "INFO" "Otimizando banco de dados..."

    # Realizar vacuum no PostgreSQL
    if docker-compose exec -T postgres psql -U postgres -c "VACUUM FULL ANALYZE;"; then
        log "SUCCESS" "Otimização do banco de dados concluída"
        return 0
    else
        log "ERROR" "Falha na otimização do banco de dados"
        return 1
    fi
}

# Função para verificar integridade dos dados
check_data_integrity() {
    log "INFO" "Verificando integridade dos dados..."

    local status=0

    # Verificar arquivos de dados
    if ! find "data" -type f -name "*.osm.pbf" -exec sha256sum {} \; > /tmp/data-checksums; then
        log "ERROR" "Falha ao verificar checksums dos arquivos de dados"
        status=1
    fi

    # Verificar permissões dos diretórios
    local dirs=("data" "config" "logs")
    for dir in "${dirs[@]}"; do
        if [ ! -r "$dir" ] || [ ! -w "$dir" ]; then
            log "ERROR" "Permissões incorretas no diretório: $dir"
            status=1
        fi
    done

    return $status
}

# Função principal de manutenção
maintenance() {
    local operation=$1

    case $operation in
        "enable")
            enable_maintenance
            ;;
        "disable")
            disable_maintenance
            ;;
        "cleanup")
            cleanup_temp_files
            ;;
        "optimize")
            optimize_database
            ;;
        "check")
            check_data_integrity
            ;;
        *)
            log "ERROR" "Operação inválida. Use: enable, disable, cleanup, optimize, ou check"
            return 1
            ;;
    esac

    return $?
}

# Verificar se operação foi especificada
if [ -z "$1" ]; then
    log "ERROR" "Operação não especificada"
    echo "Uso: $0 [enable|disable|cleanup|optimize|check]"
    exit 1
fi

# Executar manutenção
maintenance "$1"