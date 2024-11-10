package config

import (
    "encoding/json"
    "fmt"
    "os"
    "path/filepath"
)

// Paths define os caminhos padrão do sistema
const (
    DataDir        = "data"
    MapsDir        = "data/maps"
    ConfigsDir     = "data/configs"
    PostgresDir    = "data/postgres"
    NominatimDir   = "data/nominatim"
    ElasticDir     = "data/elasticsearch"
)

// Config armazena as configurações do serviço
type Config struct {
    // Configurações do servidor
    GeocodingServer string `json:"geocoding_server"`
    Port            string `json:"port"`
    Debug           bool   `json:"debug"`

    // Configurações de caminhos
    MapPath         string `json:"map_path"`
    ConfigPath      string `json:"config_path"`
    DataPath        string `json:"data_path"`

    // URLs dos serviços
    NominatimURL    string `json:"nominatim_url"`
    PeliasURL       string `json:"pelias_url"`

    // Configurações de cache
    CacheDuration   int    `json:"cache_duration"`
    CacheCleanup    int    `json:"cache_cleanup"`
}

// LoadConfig carrega a configuração do ambiente e arquivo
func LoadConfig() (*Config, error) {
    config := &Config{
        GeocodingServer: getEnvOrDefault("GEOCODING_SERVER", "nominatim"),
        Port:           getEnvOrDefault("PORT", "5000"),
        Debug:          getEnvOrDefault("DEBUG", "false") == "true",
        NominatimURL:   getEnvOrDefault("NOMINATIM_URL", "http://nominatim:8080"),
        PeliasURL:      getEnvOrDefault("PELIAS_URL", "http://pelias:3000"),
        CacheDuration:  24, // horas
        CacheCleanup:   48, // horas
    }

    // Configurar caminhos
    config.DataPath = getEnvOrDefault("DATA_PATH", DataDir)
    config.MapPath = getEnvOrDefault("MAP_PATH", filepath.Join(config.DataPath, "maps"))
    config.ConfigPath = getEnvOrDefault("CONFIG_PATH", filepath.Join(config.DataPath, "configs"))

    // Carregar configurações adicionais do arquivo se existir
    configFile := filepath.Join(config.ConfigPath, "config.json")
    if err := config.loadFromFile(configFile); err != nil {
        return nil, fmt.Errorf("error loading config file: %v", err)
    }

    // Validar configuração
    if err := config.validate(); err != nil {
        return nil, fmt.Errorf("invalid configuration: %v", err)
    }

    return config, nil
}

// loadFromFile carrega configurações de um arquivo JSON
func (c *Config) loadFromFile(path string) error {
    // Se o arquivo não existe, usa as configurações padrão
    if _, err := os.Stat(path); os.IsNotExist(err) {
        return nil
    }

    data, err := os.ReadFile(path)
    if err != nil {
        return fmt.Errorf("error reading config file: %v", err)
    }

    if err := json.Unmarshal(data, c); err != nil {
        return fmt.Errorf("error parsing config file: %v", err)
    }

    return nil
}

// validate verifica se a configuração é válida
func (c *Config) validate() error {
    // Verificar se os diretórios existem
    dirs := map[string]string{
        "data":     c.DataPath,
        "maps":     c.MapPath,
        "configs":  c.ConfigPath,
    }

    for name, path := range dirs {
        if _, err := os.Stat(path); os.IsNotExist(err) {
            if err := os.MkdirAll(path, 0755); err != nil {
                return fmt.Errorf("could not create %s directory at %s: %v", name, path, err)
            }
        }
    }

    // Validar servidor de geocodificação
    switch c.GeocodingServer {
    case "nominatim", "pelias":
        // valores válidos
    default:
        return fmt.Errorf("invalid geocoding server: %s", c.GeocodingServer)
    }

    return nil
}

// SaveConfig salva a configuração atual em arquivo
func (c *Config) SaveConfig() error {
    data, err := json.MarshalIndent(c, "", "    ")
    if err != nil {
        return fmt.Errorf("error marshaling config: %v", err)
    }

    configFile := filepath.Join(c.ConfigPath, "config.json")
    if err := os.WriteFile(configFile, data, 0644); err != nil {
        return fmt.Errorf("error writing config file: %v", err)
    }

    return nil
}

// getEnvOrDefault retorna uma variável de ambiente ou valor padrão
func getEnvOrDefault(key, defaultValue string) string {
    if value, exists := os.LookupEnv(key); exists {
        return value
    }
    return defaultValue
}
