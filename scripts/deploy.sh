#!/bin/bash

# Configurações de deploy
DEPLOY_PATH="/opt/address-extractor"
BACKUP_PATH="/opt/backups/address-extractor"
DOCKER_REGISTRY="docker.io"
APP_NAME="address-extractor"

# Função para realizar backup
perform_backup() {
    log "INFO" "Realizando backup..."

    # Criar diretório de backup
    local backup_date=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$BACKUP_PATH/$backup_date"
    
    mkdir -p "$backup_dir"

    # Backup dos arquivos de configuração
    if [ -d "$DEPLOY_PATH" ]; then
        cp -r "$DEPLOY_PATH/config" "$backup_dir/"
        cp -r "$DEPLOY_PATH/.env*" "$backup_dir/" 2>/dev/null || true
        
        # Backup do banco de dados se existir
        if [ -d "$DEPLOY_PATH/data" ]; then
            cp -r "$DEPLOY_PATH/data" "$backup_dir/"
        fi
    fi

    log "SUCCESS" "Backup criado em: $backup_dir"
    return 0
}

# Função para preparar ambiente
prepare_environment() {
    log "INFO" "Preparando ambiente de deploy..."

    # Criar diretório de deploy
    mkdir -p "$DEPLOY_PATH"

    # Configurar permissões
    chmod 755 "$DEPLOY_PATH"

    # Criar diretórios necessários
    local dirs=(
        "config"
        "data"
        "logs"
    )

    for dir in "${dirs[@]}"; do
        mkdir -p "$DEPLOY_PATH/$dir"
    done

    return 0
}

# Função para atualizar aplicação
update_application() {
    log "INFO" "Atualizando aplicação..."

    cd "$DEPLOY_PATH" || return 1

    # Pull das imagens mais recentes
    if ! docker-compose pull; then
        log "ERROR" "Falha ao baixar imagens Docker"
        return 1
    fi

    # Parar containers existentes
    docker-compose down --remove-orphans

    # Iniciar novos containers
    if ! docker-compose up -d; then
        log "ERROR" "Falha ao iniciar containers"
        return 1
    fi

    # Verificar status dos containers
    sleep 10
    if ! docker-compose ps | grep -q "Up"; then
        log "ERROR" "Containers não estão rodando"
        docker-compose logs
        return 1
    fi

    return 0
}

# Função para verificar saúde da aplicação
check_health() {
    log "INFO" "Verificando saúde da aplicação..."

    # Aguardar aplicação inicializar
    sleep 5

    # Verificar endpoint de saúde do frontend
    if ! curl -sf http://localhost:3000/health > /dev/null; then
        log "ERROR" "Frontend não está respondendo"
        return 1
    fi

    # Verificar endpoint de saúde da API
    if ! curl -sf http://localhost:5000/health > /dev/null; then
        log "ERROR" "API não está respondendo"
        return 1
    fi

    return 0
}

# Função para limpeza
cleanup_old_versions() {
    log "INFO" "Limpando versões antigas..."

    # Remover imagens antigas
    docker image prune -f

    # Limpar backups antigos (manter últimos 5)
    cd "$BACKUP_PATH" || return 1
    ls -1t | tail -n +6 | xargs -r rm -rf

    return 0
}

# Função principal de deploy
deploy() {
    log "INFO" "Iniciando processo de deploy..."

    # Realizar backup
    if ! perform_backup; then
        log "ERROR" "Falha ao realizar backup"
        return 1
    fi

    # Preparar ambiente
    if ! prepare_environment; then
        log "ERROR" "Falha ao preparar ambiente"
        return 1
    fi

    # Atualizar aplicação
    if ! update_application; then
        log "ERROR" "Falha ao atualizar aplicação"
        return 1
    fi

    # Verificar saúde
    if ! check_health; then
        log "ERROR" "Verificação de saúde falhou"
        # Realizar rollback
        return 1
    fi

    # Limpeza
    if ! cleanup_old_versions; then
        log "WARNING" "Falha ao limpar versões antigas"
    fi

    log "SUCCESS" "Deploy concluído com sucesso"
    return 0
}

# Registrar função de limpeza para casos de erro
trap 'log "ERROR" "Deploy interrompido"; docker-compose down' ERR

# Executar deploy
deploy