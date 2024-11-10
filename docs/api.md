# Documentação da API

## 🔌 Endpoints

### Geocodificação

#### GET /geocode
Consulta individual de endereço por coordenadas.

```http
GET /geocode?lat=-23.557467&lng=-46.689294
```

**Resposta de Sucesso:**
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

#### POST /geocode/batch
Processamento em lote de coordenadas.

```http
POST /geocode/batch
Content-Type: application/json

{
  "coordinates": [
    {
      "latitude": -23.557467,
      "longitude": -46.689294,
      "reference": "Cobli HQ"
    },
    {
      "latitude": -23.550520,
      "longitude": -46.633308,
      "reference": "Praça da Sé"
    }
  ]
}
```

**Resposta de Sucesso:**
```json
{
  "success": true,
  "results": [
    {
      "reference": "Cobli HQ",
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
    },
    {
      "reference": "Praça da Sé",
      "address": {
        "street": "Praça da Sé",
        "number": "s/n",
        "city": "São Paulo",
        "state": "SP",
        "country": "Brasil",
        "postalCode": "01001-000",
        "latitude": -23.550520,
        "longitude": -46.633308
      }
    }
  ]
}
```

### Monitoramento

#### GET /health
Verifica o status do serviço.

```http
GET /health
```

**Resposta:**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "timestamp": 1699646400,
  "services": {
    "geocoding": "available",
    "cache": "active"
  }
}
```

## 🔒 Rate Limiting

- 100 requisições por minuto por IP
- 1000 requisições por hora por API key
- Batch limitado a 1000 coordenadas por requisição

## 📊 Códigos de Status

- 200: Sucesso
- 400: Requisição inválida
- 429: Limite de requisições excedido
- 500: Erro interno do servidor

## 🔌 WebSocket (Tempo Real)

Para processamento em lote com status em tempo real:

```javascript
const ws = new WebSocket('ws://localhost:5000/ws/batch/{batchId}')

ws.onmessage = (event) => {
  const data = JSON.parse(event.data)
  console.log(`Progresso: ${data.progress}%`)
}
```