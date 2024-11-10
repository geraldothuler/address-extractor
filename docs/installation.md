# Guia de Instalação e Configuração

## 📋 Pré-requisitos

- Docker 20.10+
- Docker Compose 2.0+
- Go 1.20+
- Node.js 18.17+
- npm 9.0+
- Git

## 🔧 Instalação

### Método Automatizado

```bash
# Clone o repositório
git clone https://github.com/your-org/address-extractor
cd address-extractor

# Execute o script de setup
chmod +x scripts/setup.sh
./scripts/setup.sh
```

### Instalação Manual

1. **Configurar API (Go)**
```bash
cd api
go mod download
go build -o address-extractor ./cmd/server
```

2. **Configurar Frontend (Next.js)**
```bash
cd web
npm install
npm run build
```

3. **Configurar Docker**
```bash
# Na raiz do projeto
docker-compose -f config/docker/docker-compose.yml up -d
```

## ⚙️ Configuração

### Variáveis de Ambiente

#### API (.env)
```env
PORT=5000
DEBUG=false
CACHE_DURATION=3600
GEOCODING_SERVER=nominatim
```

#### Frontend (.env.local)
```env
NEXT_PUBLIC_GEOCODING_API_URL=http://localhost:5000
```

### Configuração do Docker

O sistema utiliza três serviços principais:

```yaml
services:
  web:
    build: ./web
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production

  api:
    build: ./api
    ports:
      - "5000:5000"
    volumes:
      - ./data:/app/data

  nominatim:
    image: mediagis/nominatim:4.2
    ports:
      - "8080:8080"
    volumes:
      - ./data/nominatim:/data
```

### Configuração do Geocoding

#### Nominatim
- Índice de dados OSM para São Paulo
- Cache de requisições
- Rate limiting configurado

#### Pelias (Alternativo)
- Suporte a múltiplas fontes de dados
- Elastic Search para indexação
- API flexível

## 🔄 Atualização

### Atualização da Base de Dados
```bash
# Atualizar dados OSM
./scripts/update-osm-data.sh

# Reconstruir índices
docker-compose restart nominatim
```

### Atualização do Sistema
```bash
# Pull das últimas alterações
git pull origin main

# Reconstruir containers
docker-compose -f config/docker/docker-compose.yml up -d --build
```

## 🔍 Verificação da Instalação

```bash
# Verificar status dos serviços
docker-compose ps

# Testar API
curl http://localhost:5000/health

# Testar Frontend
curl http://localhost:3000/health
```