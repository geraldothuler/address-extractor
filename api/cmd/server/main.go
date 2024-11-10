package main

import (
    "fmt"
    "log"
    "net/http"
    "time"
    
    "github.com/gin-gonic/gin"
    "github.com/gin-contrib/cors"
    
    "address-extractor-api/internal/config"
    "address-extractor-api/internal/handlers"
    "address-extractor-api/internal/service"
)

func main() {
    // Carregar configuração
    cfg, err := config.LoadConfig()
    if err != nil {
        log.Fatalf("Error loading config: %v", err)
    }

    // Configurar modo do Gin
    if !cfg.Debug {
        gin.SetMode(gin.ReleaseMode)
    }

    // Criar instâncias dos componentes
    svc := service.NewGeocodingService(cfg)
    handler := handlers.NewHandler(svc)
    
    // Configurar router
    r := setupRouter(cfg, handler)

    // Configurar servidor HTTP
    srv := &http.Server{
        Addr:         ":" + cfg.Port,
        Handler:      r,
        ReadTimeout:  15 * time.Second,
        WriteTimeout: 15 * time.Second,
        IdleTimeout:  60 * time.Second,
    }

    // Iniciar servidor
    log.Printf("Starting server on port %s", cfg.Port)
    if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
        log.Fatalf("Error starting server: %v", err)
    }
}

func setupRouter(cfg *config.Config, handler *handlers.Handler) *gin.Engine {
    r := gin.Default()

    // Configurar CORS
    r.Use(cors.New(cors.Config{
        AllowAllOrigins: true,
        AllowMethods:    []string{"GET", "POST", "OPTIONS"},
        AllowHeaders:    []string{"Origin", "Content-Type", "Accept"},
        MaxAge:          12 * time.Hour,
    }))

    // Configurar middleware de logging
    r.Use(gin.LoggerWithFormatter(func(param gin.LogFormatterParams) string {
        return fmt.Sprintf("%s - [%s] \"%s %s %s %d %s \"%s\" %s\"\n",
            param.ClientIP,
            param.TimeStamp.Format(time.RFC1123),
            param.Method,
            param.Path,
            param.Request.Proto,
            param.StatusCode,
            param.Latency,
            param.Request.UserAgent(),
            param.ErrorMessage,
        )
    }))

    // Configurar middleware de recuperação
    r.Use(gin.Recovery())

    // Definir rotas
    r.GET("/health", handler.HealthCheck)
    r.POST("/geocode", handler.GeocodePost)
    r.GET("/geocode", handler.GeocodeGet)

    return r
}