package providers

import (
    "context"
    "encoding/json"
    "fmt"
    "io"
    "net/http"
    "net/url"
    "strings"
    "sync"
    "time"

    "geocoding-service/internal/models"
)

// Provider define a interface para provedores de geocoding
type Provider interface {
    // Geocode realiza a geocodificação de um endereço
    Geocode(ctx context.Context, query string) (*models.GeocodeResponse, error)
    
    // GetName retorna o nome do provider
    GetName() string
    
    // GetStatus retorna o status atual do provider
    GetStatus(ctx context.Context) (*models.ServerStatus, error)
    
    // Reset limpa caches e reinicia o provider se necessário
    Reset() error
}

// BaseProvider implementa funcionalidades comuns aos providers
type BaseProvider struct {
    client    *http.Client
    baseURL   string
    rateLimit *RateLimiter
    metrics   *ProviderMetrics
    mu        sync.RWMutex
}

// RateLimiter implementa limitação de requisições
type RateLimiter struct {
    tokens     chan struct{}
    rate       time.Duration
    lastReset  time.Time
    maxTokens  int
}

// ProviderMetrics armazena métricas do provider
type ProviderMetrics struct {
    Requests    int64
    Errors      int64
    TotalTime   time.Duration
    LastRequest time.Time
    mu          sync.RWMutex
}

// NewRateLimiter cria um novo rate limiter
func NewRateLimiter(requestsPerSecond int) *RateLimiter {
    return &RateLimiter{
        tokens:    make(chan struct{}, requestsPerSecond),
        rate:      time.Second / time.Duration(requestsPerSecond),
        maxTokens: requestsPerSecond,
    }
}

// Wait aguarda por um token disponível
func (rl *RateLimiter) Wait(ctx context.Context) error {
    select {
    case <-ctx.Done():
        return ctx.Err()
    case rl.tokens <- struct{}{}:
        go func() {
            time.Sleep(rl.rate)
            <-rl.tokens
        }()
        return nil
    }
}

// NominatimProvider implementa o provider Nominatim
type NominatimProvider struct {
    BaseProvider
}

// NewNominatimProvider cria uma nova instância do provider Nominatim
func NewNominatimProvider(client *http.Client, baseURL string) *NominatimProvider {
    return &NominatimProvider{
        BaseProvider: BaseProvider{
            client:    client,
            baseURL:   baseURL,
            rateLimit: NewRateLimiter(5), // 5 requisições por segundo
            metrics:   &ProviderMetrics{},
        },
    }
}

func (p *NominatimProvider) GetName() string {
    return "Nominatim"
}

func (p *NominatimProvider) Geocode(ctx context.Context, query string) (*models.GeocodeResponse, error) {
    start := time.Now()
    p.metrics.mu.Lock()
    p.metrics.Requests++
    p.metrics.LastRequest = start
    p.metrics.mu.Unlock()

    // Validar query
    query = strings.TrimSpace(query)
    if query == "" {
        return &models.GeocodeResponse{
            Success: false,
            Error:   "empty query",
            Source:  p.GetName(),
        }, nil
    }

    // Esperar rate limit
    if err := p.rateLimit.Wait(ctx); err != nil {
        return nil, fmt.Errorf("rate limit error: %v", err)
    }

    // Preparar requisição
    escapedQuery := url.QueryEscape(query)
    requestURL := fmt.Sprintf("%s/search?q=%s&format=json&addressdetails=1&limit=1", 
        p.baseURL, escapedQuery)

    req, err := http.NewRequestWithContext(ctx, "GET", requestURL, nil)
    if err != nil {
        return nil, fmt.Errorf("error creating request: %v", err)
    }

    // Realizar requisição
    resp, err := p.client.Do(req)
    if err != nil {
        p.metrics.mu.Lock()
        p.metrics.Errors++
        p.metrics.mu.Unlock()
        return nil, fmt.Errorf("request failed: %v", err)
    }
    defer resp.Body.Close()

    // Verificar status code
    if resp.StatusCode != http.StatusOK {
        body, _ := io.ReadAll(resp.Body)
        return nil, fmt.Errorf("server returned %d: %s", resp.StatusCode, body)
    }

    // Decodificar resposta
    var nominatimResp models.NominatimResponse
    if err := json.NewDecoder(resp.Body).Decode(&nominatimResp); err != nil {
        return nil, fmt.Errorf("failed to decode response: %v", err)
    }

    if len(nominatimResp) == 0 {
        return &models.GeocodeResponse{
            Success: false,
            Error:   "no results found",
            Source:  p.GetName(),
        }, nil
    }

    // Processar resultado
    result := nominatimResp[0]
    var lat, lon float64
    fmt.Sscanf(result.Lat, "%f", &lat)
    fmt.Sscanf(result.Lon, "%f", &lon)

    // Atualizar métricas
    elapsed := time.Since(start)
    p.metrics.mu.Lock()
    p.metrics.TotalTime += elapsed
    p.metrics.mu.Unlock()

    return &models.GeocodeResponse{
        Success: true,
        Address: &models.Address{
            Street:      result.Address.Road,
            Number:      result.Address.HouseNumber,
            City:        result.Address.City,
            State:       result.Address.State,
            Country:     result.Address.Country,
            PostalCode:  result.Address.PostCode,
            Latitude:    lat,
            Longitude:   lon,
            LastUpdated: time.Now(),
        },
        Source:         p.GetName(),
        ProcessingTime: elapsed.Seconds(),
    }, nil
}

func (p *NominatimProvider) GetStatus(ctx context.Context) (*models.ServerStatus, error) {
    p.metrics.mu.RLock()
    defer p.metrics.mu.RUnlock()

    avgTime := float64(0)
    if p.metrics.Requests > 0 {
        avgTime = float64(p.metrics.TotalTime) / float64(p.metrics.Requests) / float64(time.Second)
    }

    return &models.ServerStatus{
        Status:        "active",
        RequestsTotal: p.metrics.Requests,
        CacheHits:     0, // Nominatim não tem cache interno
        CacheMisses:   0,
        StartTime:     p.metrics.LastRequest,
        Uptime:        time.Since(p.metrics.LastRequest).Seconds(),
    }, nil
}

func (p *NominatimProvider) Reset() error {
    p.metrics.mu.Lock()
    defer p.metrics.mu.Unlock()

    p.metrics.Requests = 0
    p.metrics.Errors = 0
    p.metrics.TotalTime = 0
    p.metrics.LastRequest = time.Time{}

    return nil
}

// PeliasProvider implementa o provider Pelias
type PeliasProvider struct {
    BaseProvider
}

// NewPeliasProvider cria uma nova instância do provider Pelias
func NewPeliasProvider(client *http.Client, baseURL string) *PeliasProvider {
    return &PeliasProvider{
        BaseProvider: BaseProvider{
            client:    client,
            baseURL:   baseURL,
            rateLimit: NewRateLimiter(10), // 10 requisições por segundo
            metrics:   &ProviderMetrics{},
        },
    }
}

func (p *PeliasProvider) GetName() string {
    return "Pelias"
}

func (p *PeliasProvider) Geocode(ctx context.Context, query string) (*models.GeocodeResponse, error) {
    start := time.Now()
    p.metrics.mu.Lock()
    p.metrics.Requests++
    p.metrics.LastRequest = start
    p.metrics.mu.Unlock()

    // Validar query
    query = strings.TrimSpace(query)
    if query == "" {
        return &models.GeocodeResponse{
            Success: false,
            Error:   "empty query",
            Source:  p.GetName(),
        }, nil
    }

    // Esperar rate limit
    if err := p.rateLimit.Wait(ctx); err != nil {
        return nil, fmt.Errorf("rate limit error: %v", err)
    }

    // Preparar requisição
    escapedQuery := url.QueryEscape(query)
    requestURL := fmt.Sprintf("%s/v1/search?text=%s&size=1", p.baseURL, escapedQuery)

    req, err := http.NewRequestWithContext(ctx, "GET", requestURL, nil)
    if err != nil {
        return nil, fmt.Errorf("error creating request: %v", err)
    }

    // Realizar requisição
    resp, err := p.client.Do(req)
    if err != nil {
        p.metrics.mu.Lock()
        p.metrics.Errors++
        p.metrics.mu.Unlock()
        return nil, fmt.Errorf("request failed: %v", err)
    }
    defer resp.Body.Close()

    // Verificar status code
    if resp.StatusCode != http.StatusOK {
        body, _ := io.ReadAll(resp.Body)
        return nil, fmt.Errorf("server returned %d: %s", resp.StatusCode, body)
    }

    // Decodificar resposta
    var peliasResp models.PeliasResponse
    if err := json.NewDecoder(resp.Body).Decode(&peliasResp); err != nil {
        return nil, fmt.Errorf("failed to decode response: %v", err)
    }

    if len(peliasResp.Features) == 0 {
        return &models.GeocodeResponse{
            Success: false,
            Error:   "no results found",
            Source:  p.GetName(),
        }, nil
    }

    // Processar resultado
    feature := peliasResp.Features[0]
    
    // Atualizar métricas
    elapsed := time.Since(start)
    p.metrics.mu.Lock()
    p.metrics.TotalTime += elapsed
    p.metrics.mu.Unlock()

    return &models.GeocodeResponse{
        Success: true,
        Address: &models.Address{
            Street:      feature.Properties.Street,
            Number:      feature.Properties.Number,
            City:        feature.Properties.City,
            State:       feature.Properties.State,
            Country:     feature.Properties.Country,
            PostalCode:  feature.Properties.PostCode,
            Latitude:    feature.Geometry.Coordinates[1],
            Longitude:   feature.Geometry.Coordinates[0],
            LastUpdated: time.Now(),
        },
        Source:         p.GetName(),
        ProcessingTime: elapsed.Seconds(),
    }, nil
}

func (p *PeliasProvider) GetStatus(ctx context.Context) (*models.ServerStatus, error) {
    p.metrics.mu.RLock()
    defer p.metrics.mu.RUnlock()

    avgTime := float64(0)
    if p.metrics.Requests > 0 {
        avgTime = float64(p.metrics.TotalTime) / float64(p.metrics.Requests) / float64(time.Second)
    }

    return &models.ServerStatus{
        Status:        "active",
        RequestsTotal: p.metrics.Requests,
        CacheHits:     0,
        CacheMisses:   0,
        StartTime:     p.metrics.LastRequest,
        Uptime:        time.Since(p.metrics.LastRequest).Seconds(),
    }, nil
}

func (p *PeliasProvider) Reset() error {
    p.metrics.mu.Lock()
    defer p.metrics.mu.Unlock()

    p.metrics.Requests = 0
    p.metrics.Errors = 0
    p.metrics.TotalTime = 0
    p.metrics.LastRequest = time.Time{}

    return nil
}