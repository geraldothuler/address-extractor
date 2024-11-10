#!/bin/bash

setup_env() {
    local app_dir="$PROJECT_ROOT/address-extractor"
    local env_config_dir="$CONFIG_DIR/env"

    # Funções internas de configuração de ambiente
    _setup_development_env() {
        log "INFO" "Configurando ambiente de desenvolvimento..."
        
        local dev_env_file="$app_dir/.env.development"
        cat > "$dev_env_file" << EOF
NEXT_PUBLIC_GEOCODING_API_URL=http://localhost:5000
NODE_ENV=development
EOF

        if [ $? -ne 0 ]; then
            log "ERROR" "Falha ao criar .env.development"
            return 1
        }
        return 0
    }

    _setup_production_env() {
        log "INFO" "Configurando ambiente de produção..."
        
        local prod_env_file="$app_dir/.env.production"
        cat > "$prod_env_file" << EOF
NEXT_PUBLIC_GEOCODING_API_URL=http://api:5000
NODE_ENV=production
EOF

        if [ $? -ne 0 ]; then
            log "ERROR" "Falha ao criar .env.production"
            return 1
        }
        return 0
    }

    _setup_data_directories() {
        log "INFO" "Configurando diretórios de dados..."
        
        local data_dirs=(
            "$app_dir/data/maps"
            "$app_dir/data/temp"
            "$app_dir/data/processed"
        )

        for dir in "${data_dirs[@]}"; do
            if ! mkdir -p "$dir"; then
                log "ERROR" "Falha ao criar diretório: $dir"
                return 1
            fi
        done

        # Configurar permissões
        if ! chmod -R 755 "$app_dir/data"; then
            log "ERROR" "Falha ao configurar permissões dos diretórios de dados"
            return 1
        }

        return 0
    }

    _setup_gitignore() {
        log "INFO" "Configurando .gitignore..."
        
        local gitignore_file="$app_dir/.gitignore"
        cat > "$gitignore_file" << EOF
# dependencies
/node_modules
/.pnp
.pnp.js

# testing
/coverage

# next.js
/.next/
/out/

# production
/build

# misc
.DS_Store
*.pem

# debug
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# local env files
.env*.local
.env.development
.env.production

# data
/data/*
!/data/.gitkeep

# temp files
*.tmp
*.temp

# IDE
.idea/
.vscode/
*.swp
*.swo

# logs
*.log
EOF

        if [ $? -ne 0 ]; then
            log "ERROR" "Falha ao criar .gitignore"
            return 1
        }
        return 0
    }

    _setup_env_example() {
        log "INFO" "Criando arquivo .env.example..."
        
        local example_env_file="$app_dir/.env.example"
        cat > "$example_env_file" << EOF
# API Configuration
NEXT_PUBLIC_GEOCODING_API_URL=http://localhost:5000

# App Configuration
NODE_ENV=development

# Feature Flags
ENABLE_FILE_UPLOAD=true
ENABLE_BATCH_PROCESSING=true

# Performance
MAX_BATCH_SIZE=100
CACHE_DURATION=3600
EOF

        if [ $? -ne 0 ]; then
            log "ERROR" "Falha ao criar .env.example"
            return 1
        }
        return 0
    }

    _validate_env_setup() {
        log "INFO" "Validando configuração de ambiente..."
        
        local required_files=(
            ".env.development"
            ".env.production"
            ".env.example"
            ".gitignore"
        )

        cd "$app_dir" || return 1

        for file in "${required_files[@]}"; do
            if [ ! -f "$file" ]; then
                log "ERROR" "Arquivo não encontrado: $file"
                return 1
            fi
        done

        # Validar diretórios de dados
        if [ ! -d "data/maps" ] || [ ! -d "data/temp" ] || [ ! -d "data/processed" ]; then
            log "ERROR" "Diretórios de dados não encontrados"
            return 1
        }

        cd - > /dev/null || return 1
        return 0
    }

    # Execução principal do setup de ambiente
    log "INFO" "Iniciando configuração de ambiente..."

    if ! _setup_development_env; then
        return 1
    fi

    if ! _setup_production_env; then
        return 1
    fi

    if ! _setup_data_directories; then
        return 1
    fi

    if ! _setup_gitignore; then
        return 1
    fi

    if ! _setup_env_example; then
        return 1
    fi

    if ! _validate_env_setup; then
        return 1
    fi

    log "SUCCESS" "Configuração de ambiente concluída com sucesso"
    return 0
}
