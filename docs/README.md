# Address Extractor

Serviço de extração e enriquecimento de endereços a partir de coordenadas geográficas.

## 🌟 Visão Geral

O Address Extractor é uma solução completa para processar coordenadas geográficas e obter informações detalhadas de endereços, permitindo tanto consultas individuais quanto processamento em lote através de planilhas.

### Para o Time de Produto

O Address Extractor resolve o desafio de enriquecer bases de dados com informações precisas de endereços a partir de coordenadas geográficas. Principais benefícios:

- Interface intuitiva para upload de planilhas
- Processamento em lote eficiente
- Consultas individuais rápidas
- Flexibilidade no mapeamento de dados
- Download dos resultados em formato Excel
- Tema escuro para menor fadiga visual

### Para o Time Técnico

Sistema distribuído construído com:
- Frontend: Next.js 14, TypeScript, Tailwind CSS
- Backend: Go 1.20, Docker
- Geocoding: Nominatim/Pelias
- Cache em memória para otimização

## 🏗 Arquitetura

```mermaid
graph TB
    subgraph "Frontend"
        UI[Interface Web]
        FileProcessor[Processador de Arquivos]
        Cache[Cache Cliente]
    end

    subgraph "Backend"
        API[API Go]
        GeoService[Serviço de Geocoding]
        MemCache[Cache em Memória]
    end

    subgraph "Serviços de Geocoding"
        Nominatim
        Pelias
    end

    UI --> FileProcessor
    FileProcessor --> API
    UI --> Cache
    API --> MemCache
    API --> GeoService
    GeoService --> Nominatim
    GeoService --> Pelias
```

## 🔄 Fluxo de Dados

```mermaid
sequenceDiagram
    participant User as Usuário
    participant Web as Frontend
    participant API as Backend
    participant Geo as Geocoding
    participant Cache as Cache

    User->>Web: Upload planilha
    Web->>Web: Validação arquivo
    Web->>Web: Mapeamento colunas
    Web->>API: Envio coordenadas
    
    alt Cached
        API->>Cache: Verifica cache
        Cache-->>API: Retorna dados
    else Not Cached
        API->>Geo: Consulta endereço
        Geo-->>API: Retorna endereço
        API->>Cache: Armazena cache
    end
    
    API-->>Web: Retorna resultados
    Web->>Web: Atualiza planilha
    Web-->>User: Download resultado
```

## 🚀 Exemplos de Uso

### API REST

#### Consulta Individual

```bash
curl -X POST http://localhost:5000/geocode \
  -H "Content-Type: application/json" \
  -d '{
    "latitude": -23.557467,
    "longitude": -46.689294
  }'
```

Resposta:
```json
{
  "success": true,
  "address": {
    "street": "Rua Lourenço Marques",
    "number": "297",
    "city": "São Paulo",
    "state": "SP",
    "country": "Brasil",
    "postalCode": "04547-100",
    "latitude": -23.557467,
    "longitude": -46.689294
  }
}
```

#### Processamento em Lote

```bash
curl -X POST http://localhost:5000/batch \
  -H "Content-Type: application/json" \
  -d '{
    "coordinates": [
      {
        "latitude": -23.557467,
        "longitude": -46.689294
      },
      {
        "latitude": -23.550520,
        "longitude": -46.633308
      }
    ]
  }'
```