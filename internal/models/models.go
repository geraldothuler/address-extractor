package models

import "time"

// Address representa uma localização geocodificada
type Address struct {
    Street      string    `json:"street"`
    Number      string    `json:"number"`
    City        string    `json:"city"`
    State       string    `json:"state"`
    Country     string    `json:"country"`
    PostalCode  string    `json:"postal_code"`
    Latitude    float64   `json:"latitude"`
    Longitude   float64   `json:"longitude"`
    LastUpdated time.Time `json:"last_updated,omitempty"`
}

// GeocodeRequest representa uma requisição de geocodificação
type GeocodeRequest struct {
    Query string `json:"query" binding:"required"`
}

// GeocodeResponse representa a resposta do serviço de geocodificação
type GeocodeResponse struct {
    Success      bool      `json:"success"`
    Address      *Address  `json:"address,omitempty"`
    Error        string    `json:"error,omitempty"`
    ProcessingTime float64 `json:"processing_time,omitempty"`
    Source        string   `json:"source,omitempty"`
    Cached        bool     `json:"cached,omitempty"`
}

// ServerStatus representa o estado atual do servidor
type ServerStatus struct {
    Status        string    `json:"status"`
    Version       string    `json:"version"`
    Uptime        float64   `json:"uptime"`
    StartTime     time.Time `json:"start_time"`
    CacheSize     int       `json:"cache_size"`
    CacheHits     int64     `json:"cache_hits"`
    CacheMisses   int64     `json:"cache_misses"`
    RequestsTotal int64     `json:"requests_total"`
}

// NominatimResponse representa a resposta da API do Nominatim
type NominatimResponse []struct {
    PlaceID     int     `json:"place_id"`
    Lat         string  `json:"lat"`
    Lon         string  `json:"lon"`
    DisplayName string  `json:"display_name"`
    Address     struct {
        Road        string `json:"road"`
        HouseNumber string `json:"house_number"`
        City        string `json:"city"`
        State       string `json:"state"`
        Country     string `json:"country"`
        PostCode    string `json:"postcode"`
    } `json:"address"`
    Importance float64 `json:"importance"`
    Type       string  `json:"type"`
    OSMType    string  `json:"osm_type"`
    OSMID      int64   `json:"osm_id"`
}

// PeliasResponse representa a resposta da API do Pelias
type PeliasResponse struct {
    Features []struct {
        Type       string `json:"type"`
        Properties struct {
            Name     string  `json:"name"`
            Street   string  `json:"street"`
            Number   string  `json:"housenumber"`
            City     string  `json:"locality"`
            State    string  `json:"region"`
            Country  string  `json:"country"`
            PostCode string  `json:"postalcode"`
            Source   string  `json:"source"`
            Layer    string  `json:"layer"`
            Accuracy float64 `json:"accuracy"`
        } `json:"properties"`
        Geometry struct {
            Type        string    `json:"type"`
            Coordinates []float64 `json:"coordinates"`
        } `json:"geometry"`
        Confidence float64 `json:"confidence"`
    } `json:"features"`
    Type     string `json:"type"`
    License  string `json:"license"`
    Version  string `json:"version"`
}

// MapInfo representa informações sobre um mapa carregado
type MapInfo struct {
    Name         string    `json:"name"`
    DisplayName  string    `json:"display_name"`
    LastUpdated  time.Time `json:"last_updated"`
    FileSize     int64     `json:"file_size"`
    FeatureCount int       `json:"feature_count"`
    Bounds       struct {
        MinLat float64 `json:"min_lat"`
        MaxLat float64 `json:"max_lat"`
        MinLon float64 `json:"min_lon"`
        MaxLon float64 `json:"max_lon"`
    } `json:"bounds"`
}

// ErrorResponse representa um erro padronizado da API
type ErrorResponse struct {
    Success bool   `json:"success"`
    Error   string `json:"error"`
    Code    string `json:"code,omitempty"`
    Details string `json:"details,omitempty"`
}

// MetricsData representa métricas do servidor
type MetricsData struct {
    Timestamp     time.Time `json:"timestamp"`
    RequestCount  int64     `json:"request_count"`
    CacheHits     int64     `json:"cache_hits"`
    CacheMisses   int64     `json:"cache_misses"`
    AverageTime   float64   `json:"average_time"`
    ErrorCount    int64     `json:"error_count"`
    MemoryUsage   float64   `json:"memory_usage"`
    GoroutineCount int      `json:"goroutine_count"`
}

// ValidationError representa um erro de validação
type ValidationError struct {
    Field   string `json:"field"`
    Message string `json:"message"`
}

// APIResponse é uma estrutura genérica para respostas da API
type APIResponse struct {
    Success     bool        `json:"success"`
    Data        interface{} `json:"data,omitempty"`
    Error       string      `json:"error,omitempty"`
    Errors      []ValidationError `json:"errors,omitempty"`
    Meta        interface{} `json:"meta,omitempty"`
    Status      int         `json:"status"`
    RequestID   string      `json:"request_id,omitempty"`
    ProcessedAt time.Time   `json:"processed_at"`
}