#!/bin/bash

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configurações
PROJECT_ROOT=$(pwd)
TEMP_DIR="/tmp/project-restructure"

# Função para logging
log() {
    local level=$1
    local message=$2
    echo -e "${!level}[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message${NC}"
}

# Função para criar nova estrutura de diretórios
create_new_structure() {
    log "INFO" "Criando nova estrutura de diretórios..."

    local directories=(
        "api/cmd/server"
        "api/internal/config"
        "api/internal/handlers"
        "api/internal/models"
        "api/internal/providers"
        "api/internal/service"
        "web"
        "scripts"
        "config/docker"
    )

    for dir in "${directories[@]}"; do
        if mkdir -p "$dir"; then
            log "SUCCESS" "Criado diretório: $dir"
        else
            log "ERROR" "Falha ao criar diretório: $dir"
            return 1
        fi
    done

    return 0
}

# Função para mover arquivos Go
move_go_files() {
    log "INFO" "Movendo arquivos Go..."

    # Mapear arquivos para novos locais
    local file_mappings=(
        "main.go:api/cmd/server/main.go"
        "config.go:api/internal/config/config.go"
        "handlers.go:api/internal/handlers/handlers.go"
        "models.go:api/internal/models/models.go"
        "providers.go:api/internal/providers/providers.go"
        "service.go:api/internal/service/service.go"
    )

    # Criar diretório temporário
    mkdir -p "$TEMP_DIR"

    # Mover cada arquivo
    for mapping in "${file_mappings[@]}"; do
        local source="${mapping%%:*}"
        local target="${mapping#*:}"
        
        if [ -f "$source" ]; then
            # Criar diretório de destino
            mkdir -p "$(dirname "$target")"
            
            # Copiar arquivo para nova localização
            if cp "$source" "$target"; then
                log "SUCCESS" "Movido: $source -> $target"
                # Armazenar arquivo original no temp para backup
                mv "$source" "$TEMP_DIR/"
            else
                log "ERROR" "Falha ao mover: $source"
                return 1
            fi
        else
            log "WARNING" "Arquivo não encontrado: $source"
        fi
    done

    return 0
}

# Função para atualizar go.mod
update_go_mod() {
    log "INFO" "Atualizando go.mod..."

    cd api || return 1

    # Inicializar novo módulo Go
    if ! go mod init address-extractor-api; then
        log "ERROR" "Falha ao inicializar módulo Go"
        return 1
    fi

    # Atualizar dependências
    if ! go mod tidy; then
        log "ERROR" "Falha ao atualizar dependências"
        return 1
    fi

    cd - > /dev/null || return 1
    return 0
}

# Função para atualizar imports nos arquivos Go
update_imports() {
    log "INFO" "Atualizando imports..."

    # Nome do módulo
    local MODULE_NAME="address-extractor-api"
    
    # Encontrar todos os arquivos .go
    find api -name "*.go" -type f | while read -r file; do
        # Atualizar imports
        sed -i'' -e "s|\"geocoding-service/|\"${MODULE_NAME}/|g" "$file"
        
        # Verificar se houve erro
        if [ $? -ne 0 ]; then
            log "ERROR" "Falha ao atualizar imports em: $file"
            return 1
        fi
    done

    return 0
}

# Função para atualizar Dockerfile
update_dockerfile() {
    log "INFO" "Atualizando Dockerfile..."

    if [ -f "Dockerfile" ]; then
        if mv Dockerfile api/Dockerfile; then
            log "SUCCESS" "Dockerfile movido para api/"
            
            # Atualizar caminhos no Dockerfile
            sed -i'' \
                -e 's|COPY \.|COPY cmd cmd/|g' \
                -e 's|COPY internal|COPY internal internal/|g' \
                "api/Dockerfile"
        else
            log "ERROR" "Falha ao mover Dockerfile"
            return 1
        fi
    fi

    return 0
}

# Função para atualizar docker-compose
update_docker_compose() {
    log "INFO" "Atualizando docker-compose.yml..."

    if [ -f "docker-compose.yml" ]; then
        # Criar diretório de configuração Docker se não existir
        mkdir -p config/docker
        
        if mv docker-compose.yml config/docker/; then
            log "SUCCESS" "docker-compose.yml movido para config/docker/"
            
            # Atualizar caminhos no docker-compose
            sed -i'' \
                -e 's|build: \.|build: ./api|g' \
                -e 's|context: \.|context: ../../api|g' \
                "config/docker/docker-compose.yml"
        else
            log "ERROR" "Falha ao mover docker-compose.yml"
            return 1
        fi
    fi

    return 0
}

# Função para criar backup
create_backup() {
    log "INFO" "Criando backup dos arquivos originais..."

    local backup_dir="backup_$(date +%Y%m%d_%H%M%S)"
    
    if mkdir -p "$backup_dir"; then
        # Copiar arquivos existentes para backup
        for file in *.go Dockerfile docker-compose.yml go.mod go.sum; do
            if [ -f "$file" ]; then
                cp "$file" "$backup_dir/"
            fi
        done
        
        log "SUCCESS" "Backup criado em: $backup_dir"
        return 0
    else
        log "ERROR" "Falha ao criar backup"
        return 1
    fi
}

# Função para validar reestruturação
validate_restructure() {
    log "INFO" "Validando reestruturação..."

    # Verificar diretórios essenciais
    local required_dirs=(
        "api/cmd/server"
        "api/internal"
        "web"
        "scripts"
        "config"
    )

    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            log "ERROR" "Diretório não encontrado: $dir"
            return 1
        fi
    done

    # Verificar se arquivos Go foram movidos corretamente
    local required_files=(
        "api/cmd/server/main.go"
        "api/internal/config/config.go"
        "api/internal/handlers/handlers.go"
        "api/internal/models/models.go"
        "api/go.mod"
    )

    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            log "ERROR" "Arquivo não encontrado: $file"
            return 1
        fi
    done

    # Tentar compilar projeto Go
    cd api || return 1
    if ! go build ./cmd/server; then
        log "ERROR" "Falha ao compilar projeto Go"
        cd - > /dev/null || return 1
        return 1
    fi
    cd - > /dev/null || return 1

    log "SUCCESS" "Validação concluída com sucesso"
    return 0
}

# Função para limpar arquivos temporários
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}

# Função principal
main() {
    log "INFO" "Iniciando reestruturação do projeto..."

    # Criar backup
    if ! create_backup; then
        return 1
    fi

    # Criar nova estrutura
    if ! create_new_structure; then
        return 1
    fi

    # Mover arquivos Go
    if ! move_go_files; then
        return 1
    fi

    # Atualizar go.mod
    if ! update_go_mod; then
        return 1
    fi

    # Atualizar imports
    if ! update_imports; then
        return 1
    fi

    # Atualizar Dockerfile
    if ! update_dockerfile; then
        return 1
    fi

    # Atualizar docker-compose
    if ! update_docker_compose; then
        return 1
    fi

    # Validar reestruturação
    if ! validate_restructure; then
        log "ERROR" "Falha na validação da reestruturação"
        return 1
    fi

    log "SUCCESS" "Reestruturação concluída com sucesso"
    
    # Exibir próximos passos
    echo -e "\n${BLUE}Próximos passos:${NC}"
    echo "1. Revise os arquivos na nova estrutura"
    echo "2. Teste a compilação do projeto Go: cd api && go build ./cmd/server"
    echo "3. Teste o build do Docker: docker-compose -f config/docker/docker-compose.yml build"
    echo "4. Se necessário, restaure o backup de: $(pwd)/backup_*"
}

# Registrar cleanup
trap cleanup EXIT

# Executar script
main
