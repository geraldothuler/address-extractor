package providers

import (
    "encoding/json"
    "fmt"
    "net/http"
    "net/url"
    "strings"

    "address-extractor-api/internal/models"
)

// Provider define a interface para provedores de geocoding
type Provider interface {
    Geocode(query string) (*models.GeocodeResponse, error)
}

// NominatimProvider implementa o provedor Nominatim
type NominatimProvider struct {
    client  *http.Client
    baseURL string
}

// NewNominatimProvider cria uma nova instância do provedor Nominatim
func NewNominatimProvider(client *http.Client, baseURL string) *NominatimProvider {
    return &NominatimProvider{
        client:  client,
        baseURL: baseURL,
    }
}

func (p *NominatimProvider) Geocode(query string) (*models.GeocodeResponse, error) {
    query = strings.TrimSpace(query)
    if query == "" {
        return &models.GeocodeResponse{
            Success: false,
            Error:   "empty query",
        }, nil
    }

    escapedQuery := url.QueryEscape(query)
    requestURL := fmt.Sprintf("%s/search?q=%s&format=json&addressdetails=1&limit=1", 
        p.baseURL, escapedQuery)

    resp, err := p.client.Get(requestURL)
    if err != nil {
        return nil, fmt.Errorf("request failed: %v", err)
    }
    defer resp.Body.Close()

    var nominatimResp models.NominatimResponse
    if err := json.NewDecoder(resp.Body).Decode(&nominatimResp); err != nil {
        return nil, fmt.Errorf("failed to decode response: %v", err)
    }

    if len(nominatimResp) == 0 {
        return &models.GeocodeResponse{
            Success: false,
            Error:   "no results found",
        }, nil
    }

    result := nominatimResp[0]
    var lat, lon float64
    fmt.Sscanf(result.Lat, "%f", &lat)
    fmt.Sscanf(result.Lon, "%f", &lon)

    return &models.GeocodeResponse{
        Success: true,
        Address: &models.Address{
            Street:     result.Address.Road,
            Number:     result.Address.HouseNumber,
            City:       result.Address.City,
            State:      result.Address.State,
            Country:    result.Address.Country,
            PostalCode: result.Address.PostCode,
            Latitude:   lat,
            Longitude:  lon,
        },
    }, nil
}

// PeliasProvider implementa o provedor Pelias
type PeliasProvider struct {
    client  *http.Client
    baseURL string
}

// NewPeliasProvider cria uma nova instância do provedor Pelias
func NewPeliasProvider(client *http.Client, baseURL string) *PeliasProvider {
    return &PeliasProvider{
        client:  client,
        baseURL: baseURL,
    }
}

func (p *PeliasProvider) Geocode(query string) (*models.GeocodeResponse, error) {
    query = strings.TrimSpace(query)
    if query == "" {
        return &models.GeocodeResponse{
            Success: false,
            Error:   "empty query",
        }, nil
    }

    escapedQuery := url.QueryEscape(query)
    requestURL := fmt.Sprintf("%s/v1/search?text=%s&size=1", p.baseURL, escapedQuery)

    resp, err := p.client.Get(requestURL)
    if err != nil {
        return nil, fmt.Errorf("request failed: %v", err)
    }
    defer resp.Body.Close()

    var peliasResp models.PeliasResponse
    if err := json.NewDecoder(resp.Body).Decode(&peliasResp); err != nil {
        return nil, fmt.Errorf("failed to decode response: %v", err)
    }

    if len(peliasResp.Features) == 0 {
        return &models.GeocodeResponse{
            Success: false,
            Error:   "no results found",
        }, nil
    }

    feature := peliasResp.Features[0]
    return &models.GeocodeResponse{
        Success: true,
        Address: &models.Address{
            Street:     feature.Properties.Street,
            Number:     feature.Properties.Number,
            City:       feature.Properties.City,
            State:      feature.Properties.State,
            Country:    feature.Properties.Country,
            PostalCode: feature.Properties.PostCode,
            Latitude:   feature.Geometry.Coordinates[1],
            Longitude:  feature.Geometry.Coordinates[0],
        },
    }, nil
}