package config

import (
    "os"
)

// Config armazena as configurações do serviço
type Config struct {
    GeocodingServer string
    Port            string
    Debug           bool
    NominatimURL    string
    PeliasURL       string
}

// LoadConfig carrega a configuração do ambiente
func LoadConfig() (*Config, error) {
    config := &Config{
        GeocodingServer: getEnvOrDefault("GEOCODING_SERVER", "nominatim"),
        Port:           getEnvOrDefault("PORT", "5000"),
        Debug:          getEnvOrDefault("DEBUG", "false") == "true",
        NominatimURL:   getEnvOrDefault("NOMINATIM_URL", "http://nominatim:8080"),
        PeliasURL:      getEnvOrDefault("PELIAS_URL", "http://pelias:3000"),
    }
    
    return config, nil
}

// getEnvOrDefault retorna uma variável de ambiente ou valor padrão
func getEnvOrDefault(key, defaultValue string) string {
    if value, exists := os.LookupEnv(key); exists {
        return value
    }
    return defaultValue
}
