#!/bin/bash

# Definições de cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configurações base
PROJECT_ROOT=$(pwd)
SCRIPTS_DIR="$PROJECT_ROOT/scripts"
CONFIG_DIR="$PROJECT_ROOT/config"
TEMPLATES_DIR="$PROJECT_ROOT/templates"

# Função para logging padronizado
log() {
    local level=$1
    local message=$2
    local color

    case $level in
        "INFO")     color=$BLUE ;;
        "SUCCESS")  color=$GREEN ;;
        "WARNING")  color=$YELLOW ;;
        "ERROR")    color=$RED ;;
        *)          color=$NC ;;
    esac

    echo -e "${color}[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message${NC}"
}

# Função para verificar dependências
check_dependencies() {
    log "INFO" "Verificando dependências necessárias..."
    
    local required_commands=("node" "npm" "docker" "docker-compose" "git")
    local missing_commands=()

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_commands+=("$cmd")
        fi
    done

    if [ ${#missing_commands[@]} -gt 0 ]; then
        log "ERROR" "Dependências faltando: ${missing_commands[*]}"
        return 1
    fi

    # Verificar versão do Node.js (mínimo 18.17.0)
    local node_version=$(node -v | cut -d 'v' -f 2)
    if [[ "$(printf '%s\n' "18.17.0" "$node_version" | sort -V | head -n1)" != "18.17.0" ]]; then
        log "ERROR" "Node.js 18.17.0 ou superior é necessário"
        return 1
    fi

    log "SUCCESS" "Todas as dependências estão instaladas"
    return 0
}

# Função para criar estrutura de diretórios
create_directory_structure() {
    log "INFO" "Criando estrutura de diretórios..."
    
    local directories=(
        "scripts"
        "config"
        "templates/nextjs"
        "data"
    )

    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log "SUCCESS" "Diretório criado: $dir"
        else
            log "INFO" "Diretório já existe: $dir"
        fi
    done
}

# Função para carregar scripts auxiliares
load_scripts() {
    log "INFO" "Carregando scripts auxiliares..."
    
    local script_files=(
        "setup-nextjs.sh"
        "setup-docker.sh"
        "setup-env.sh"
    )

    for script in "${script_files[@]}"; do
        local script_path="$SCRIPTS_DIR/$script"
        if [ -f "$script_path" ]; then
            source "$script_path"
            log "SUCCESS" "Script carregado: $script"
        else
            log "ERROR" "Script não encontrado: $script"
            return 1
        fi
    done

    return 0
}

# Função de limpeza em caso de erro
cleanup() {
    if [ $? -ne 0 ]; then
        log "ERROR" "Ocorreu um erro durante a instalação"
        log "INFO" "Realizando limpeza..."
        # Adicionar lógica de limpeza aqui
    fi
}

# Função principal
main() {
    log "INFO" "Iniciando setup do projeto..."

    # Verificar dependências
    if ! check_dependencies; then
        exit 1
    fi

    # Criar estrutura de diretórios
    create_directory_structure

    # Carregar scripts auxiliares
    if ! load_scripts; then
        exit 1
    fi

    # Executar setup do Next.js
    if ! setup_nextjs; then
        exit 1
    fi

    # Configurar Docker
    if ! setup_docker; then
        exit 1
    fi

    # Configurar variáveis de ambiente
    if ! setup_env; then
        exit 1
    fi

    log "SUCCESS" "Setup concluído com sucesso!"
}

# Registrar função de cleanup
trap cleanup EXIT

# Executar script principal
main