package models

// Address representa uma localização geocodificada
type Address struct {
    Street      string  `json:"street"`
    Number      string  `json:"number"`
    City        string  `json:"city"`
    State       string  `json:"state"`
    Country     string  `json:"country"`
    PostalCode  string  `json:"postal_code"`
    Latitude    float64 `json:"latitude"`
    Longitude   float64 `json:"longitude"`
}

// GeocodeRequest representa uma requisição de geocodificação
type GeocodeRequest struct {
    Query string `json:"query"`
}

// GeocodeResponse representa a resposta do serviço de geocodificação
type GeocodeResponse struct {
    Success bool     `json:"success"`
    Address *Address `json:"address,omitempty"`
    Error   string  `json:"error,omitempty"`
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
}

// PeliasResponse representa a resposta da API do Pelias
type PeliasResponse struct {
    Features []struct {
        Properties struct {
            Name     string `json:"name"`
            Street   string `json:"street"`
            Number   string `json:"housenumber"`
            City     string `json:"locality"`
            State    string `json:"region"`
            Country  string `json:"country"`
            PostCode string `json:"postalcode"`
        } `json:"properties"`
        Geometry struct {
            Coordinates []float64 `json:"coordinates"`
        } `json:"geometry"`
    } `json:"features"`
}
