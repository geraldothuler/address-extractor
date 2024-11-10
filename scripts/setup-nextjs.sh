#!/bin/bash

# Configuração do setup do Next.js
setup_nextjs() {
    local base_dir="$PROJECT_ROOT/address-extractor"
    local template_dir="$TEMPLATES_DIR/nextjs"
    local temp_dir="/tmp/nextjs-setup"

    # Funções internas de setup
    _create_project() {
        log "INFO" "Criando projeto Next.js..."
        
        if [ -d "$base_dir" ]; then
            log "WARNING" "Diretório do projeto já existe"
            if ! mv "$base_dir" "${base_dir}_backup_$(date +%Y%m%d_%H%M%S)"; then
                return 1
            fi
        fi

        if ! npx create-next-app@latest "$base_dir" \
            --typescript \
            --tailwind \
            --eslint \
            --app \
            --no-git \
            --use-npm \
            --src-dir; then
            return 1
        fi

        return 0
    }

    _copy_template_files() {
        log "INFO" "Copiando arquivos do template..."
        
        if [ ! -d "$template_dir" ]; then
            log "ERROR" "Diretório de template não encontrado"
            return 1
        fi

        # Criar estrutura de diretórios temporária
        mkdir -p "$temp_dir"
        
        # Copiar arquivos mantendo a estrutura
        cp -r "$template_dir"/* "$base_dir/"
        local status=$?

        # Limpar diretório temporário
        rm -rf "$temp_dir"

        return $status
    }

    _install_dependencies() {
        log "INFO" "Instalando dependências..."
        
        local deps=(
            "@radix-ui/react-tabs"
            "xlsx"
            "react-circular-progressbar"
            "lucide-react"
        )

        local dev_deps=(
            "@types/node"
            "@types/react"
            "@types/react-dom"
            "prettier"
            "typescript"
        )

        cd "$base_dir" || return 1

        # Instalar dependências de produção
        if ! npm install "${deps[@]}"; then
            return 1
        fi

        # Instalar dependências de desenvolvimento
        if ! npm install -D "${dev_deps[@]}"; then
            return 1
        fi

        cd - > /dev/null || return 1
        return 0
    }

    _setup_environment() {
        log "INFO" "Configurando ambiente de desenvolvimento..."
        
        cd "$base_dir" || return 1

        # Copiar arquivo de ambiente exemplo
        if [ -f "$CONFIG_DIR/.env.example" ]; then
            cp "$CONFIG_DIR/.env.example" .env.local
        else
            # Criar .env.local padrão se não existir exemplo
            cat > .env.local << EOF
NEXT_PUBLIC_GEOCODING_API_URL=http://localhost:5000
EOF
        fi

        # Configurar scripts do package.json
        local temp_package="$temp_dir/package.json"
        jq '.scripts = {
            "dev": "next dev",
            "build": "next build",
            "start": "next start",
            "lint": "next lint",
            "format": "prettier --write \"src/**/*.{ts,tsx}\"",
            "type-check": "tsc --noEmit"
        }' package.json > "$temp_package" && mv "$temp_package" package.json

        cd - > /dev/null || return 1
        return 0
    }

    # Execução principal do setup
    log "INFO" "Iniciando setup do Next.js..."

    # Criar projeto base
    if ! _create_project; then
        log "ERROR" "Falha ao criar projeto Next.js"
        return 1
    fi

    # Copiar arquivos do template
    if ! _copy_template_files; then
        log "ERROR" "Falha ao copiar arquivos do template"
        return 1
    fi

    # Instalar dependências
    if ! _install_dependencies; then
        log "ERROR" "Falha ao instalar dependências"
        return 1
    fi

    # Configurar ambiente
    if ! _setup_environment; then
        log "ERROR" "Falha ao configurar ambiente"
        return 1
    fi

    log "SUCCESS" "Setup do Next.js concluído com sucesso"
    return 0
}
