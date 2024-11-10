package service

import (
    "net/http"
    "time"
    
    "github.com/patrickmn/go-cache"
    
    "address-extractor-api/internal/config"
    "address-extractor-api/internal/models"
    "address-extractor-api/internal/providers"
)

// GeocodingService representa o serviço principal de geocodificação
type GeocodingService struct {
    config   *config.Config
    cache    *cache.Cache
    provider providers.Provider
}

// NewGeocodingService cria uma nova instância do serviço
func NewGeocodingService(cfg *config.Config) *GeocodingService {
    client := &http.Client{
        Timeout: 10 * time.Second,
    }

    var provider providers.Provider
    switch cfg.GeocodingServer {
    case "pelias":
        provider = providers.NewPeliasProvider(client, cfg.PeliasURL)
    default:
        provider = providers.NewNominatimProvider(client, cfg.NominatimURL)
    }

    return &GeocodingService{
        config:   cfg,
        cache:    cache.New(24*time.Hour, 48*time.Hour),
        provider: provider,
    }
}

// Geocode processa uma requisição de geocodificação
func (s *GeocodingService) Geocode(query string) (*models.GeocodeResponse, error) {
    // Verificar cache
    if cached, found := s.cache.Get(query); found {
        return cached.(*models.GeocodeResponse), nil
    }

    // Processar requisição
    response, err := s.provider.Geocode(query)
    if err != nil {
        return nil, err
    }

    // Armazenar no cache se sucesso
    if response.Success {
        s.cache.Set(query, response, cache.DefaultExpiration)
    }

    return response, nil
}
