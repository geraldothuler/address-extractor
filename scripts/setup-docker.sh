#!/bin/bash

setup_docker() {
    local app_dir="$PROJECT_ROOT/address-extractor"
    local docker_config_dir="$CONFIG_DIR/docker"

    # Funções internas de setup do Docker
    _copy_docker_files() {
        log "INFO" "Copiando arquivos Docker..."

        # Copiar Dockerfile para o projeto
        if ! cp "$docker_config_dir/Dockerfile" "$app_dir/"; then
            log "ERROR" "Falha ao copiar Dockerfile"
            return 1
        fi

        # Copiar docker-compose
        if ! cp "$docker_config_dir/docker-compose.yml" "$app_dir/"; then
            log "ERROR" "Falha ao copiar docker-compose.yml"
            return 1
        fi

        # Copiar .dockerignore
        if ! cp "$docker_config_dir/.dockerignore" "$app_dir/"; then
            log "ERROR" "Falha ao copiar .dockerignore"
            return 1
        }

        return 0
    }

    _validate_docker_config() {
        log "INFO" "Validando configuração Docker..."
        
        cd "$app_dir" || return 1

        # Validar Dockerfile
        if ! docker build --no-cache --quiet -t address-extractor-validate .; then
            log "ERROR" "Dockerfile inválido"
            return 1
        fi

        # Limpar imagem de validação
        docker rmi address-extractor-validate &>/dev/null

        # Validar docker-compose
        if ! docker-compose config --quiet; then
            log "ERROR" "docker-compose.yml inválido"
            return 1
        }

        cd - > /dev/null || return 1
        return 0
    }

    _setup_docker_network() {
        log "INFO" "Configurando rede Docker..."
        
        local network_name="address-extractor-network"

        # Criar rede se não existir
        if ! docker network inspect "$network_name" &>/dev/null; then
            if ! docker network create "$network_name"; then
                log "ERROR" "Falha ao criar rede Docker"
                return 1
            fi
        fi

        return 0
    }

    # Execução principal do setup Docker
    log "INFO" "Iniciando setup do Docker..."

    if ! _copy_docker_files; then
        return 1
    fi

    if ! _validate_docker_config; then
        return 1
    fi

    if ! _setup_docker_network; then
        return 1
    }

    log "SUCCESS" "Setup do Docker concluído com sucesso"
    return 0
}
