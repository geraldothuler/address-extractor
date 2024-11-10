#!/bin/bash

setup_validation() {
    local app_dir="$PROJECT_ROOT/address-extractor"
    local validation_temp="/tmp/address-extractor-validation"

    # Funções internas de validação
    _validate_nextjs_build() {
        log "INFO" "Validando build do Next.js..."
        
        cd "$app_dir" || return 1

        # Limpar cache
        if [ -d ".next" ]; then
            rm -rf .next
        fi

        # Tentar build
        if ! npm run build > "$validation_temp/build.log" 2>&1; then
            log "ERROR" "Falha no build do Next.js"
            cat "$validation_temp/build.log"
            return 1
        fi

        cd - > /dev/null || return 1
        return 0
    }

    _validate_docker_services() {
        log "INFO" "Validando serviços Docker..."
        
        cd "$app_dir" || return 1

        # Validar compose
        if ! docker-compose config --quiet; then
            log "ERROR" "Configuração do docker-compose inválida"
            return 1
        fi

        # Testar build das imagens
        if ! docker-compose build --quiet; then
            log "ERROR" "Falha no build dos containers"
            return 1
        }

        # Teste rápido dos serviços
        if ! docker-compose up -d; then
            log "ERROR" "Falha ao iniciar serviços"
            return 1
        }

        # Aguardar serviços iniciarem
        log "INFO" "Aguardando serviços iniciarem..."
        sleep 10

        # Verificar saúde dos serviços
        local services=("web" "api")
        for service in "${services[@]}"; do
            if ! docker-compose ps "$service" | grep -q "Up"; then
                log "ERROR" "Serviço $service não está rodando"
                docker-compose logs "$service"
                docker-compose down
                return 1
            fi
        done

        # Verificar endpoints de saúde
        if ! curl -sf http://localhost:3000/health > /dev/null; then
            log "ERROR" "Endpoint de saúde do Next.js não responde"
            docker-compose down
            return 1
        fi

        if ! curl -sf http://localhost:5000/health > /dev/null; then
            log "ERROR" "Endpoint de saúde da API não responde"
            docker-compose down
            return 1
        fi

        # Parar serviços
        docker-compose down

        cd - > /dev/null || return 1
        return 0
    }

    _validate_environment() {
        log "INFO" "Validando variáveis de ambiente..."
        
        cd "$app_dir" || return 1

        local required_vars=(
            "NEXT_PUBLIC_GEOCODING_API_URL"
            "NODE_ENV"
        )

        # Verificar .env.development
        for var in "${required_vars[@]}"; do
            if ! grep -q "^${var}=" .env.development; then
                log "ERROR" "Variável $var não encontrada em .env.development"
                return 1
            fi
        done

        # Verificar .env.production
        for var in "${required_vars[@]}"; do
            if ! grep -q "^${var}=" .env.production; then
                log "ERROR" "Variável $var não encontrada em .env.production"
                return 1
            fi
        done

        cd - > /dev/null || return 1
        return 0
    }

    _validate_dependencies() {
        log "INFO" "Validando dependências do projeto..."
        
        cd "$app_dir" || return 1

        # Verificar dependências Node
        if ! npm audit; then
            log "WARNING" "Encontradas vulnerabilidades nas dependências"
            if ! ask_question "Continuar mesmo com vulnerabilidades?" "no"; then
                return 1
            fi
        fi

        # Verificar tipos TypeScript
        if ! npm run type-check > "$validation_temp/type-check.log" 2>&1; then
            log "ERROR" "Erro na verificação de tipos TypeScript"
            cat "$validation_temp/type-check.log"
            return 1
        fi

        cd - > /dev/null || return 1
        return 0
    }

    _test_api_integration() {
        log "INFO" "Testando integração com API..."
        
        # Preparar dados de teste
        local test_data='{
            "latitude": -23.550520,
            "longitude": -46.633308
        }'

        # Testar API
        local api_response
        api_response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "$test_data" \
            http://localhost:5000/geocode)

        if ! echo "$api_response" | jq -e .success > /dev/null; then
            log "ERROR" "Teste de integração com API falhou"
            echo "Resposta: $api_response"
            return 1
        fi

        return 0
    }

    # Criar diretório temporário para logs
    mkdir -p "$validation_temp"

    # Execução principal da validação
    log "INFO" "Iniciando validação do setup..."

    if ! _validate_nextjs_build; then
        return 1
    fi

    if ! _validate_docker_services; then
        return 1
    fi

    if ! _validate_environment; then
        return 1
    fi

    if ! _validate_dependencies; then
        return 1
    fi

    if ! _test_api_integration; then
        return 1
    fi

    # Limpar arquivos temporários
    rm -rf "$validation_temp"

    log "SUCCESS" "Validação concluída com sucesso"
    return 0
}
