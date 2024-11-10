package handlers

import (
    "net/http"
    "time"
    
    "github.com/gin-gonic/gin"
    
    "geocoding-service/internal/models"
    "geocoding-service/internal/service"
)

// Handler gerencia as rotas HTTP
type Handler struct {
    service *service.GeocodingService
}

// NewHandler cria uma nova instância do handler
func NewHandler(service *service.GeocodingService) *Handler {
    return &Handler{
        service: service,
    }
}

// HealthCheck verifica o status do serviço
func (h *Handler) HealthCheck(c *gin.Context) {
    c.JSON(http.StatusOK, gin.H{
        "status": "healthy",
        "timestamp": time.Now().Unix(),
    })
}

// GeocodePost processa requisições POST de geocodificação
func (h *Handler) GeocodePost(c *gin.Context) {
    var req models.GeocodeRequest
    if err := c.BindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, models.GeocodeResponse{
            Success: false,
            Error:   "invalid request format",
        })
        return
    }

    h.processGeocode(c, req.Query)
}

// GeocodeGet processa requisições GET de geocodificação
func (h *Handler) GeocodeGet(c *gin.Context) {
    query := c.Query("q")
    if query == "" {
        c.JSON(http.StatusBadRequest, models.GeocodeResponse{
            Success: false,
            Error:   "query parameter 'q' is required",
        })
        return
    }

    h.processGeocode(c, query)
}

// processGeocode processa a requisição de geocodificação
func (h *Handler) processGeocode(c *gin.Context, query string) {
    result, err := h.service.Geocode(query)
    if err != nil {
        c.JSON(http.StatusInternalServerError, models.GeocodeResponse{
            Success: false,
            Error:   err.Error(),
        })
        return
    }

    c.JSON(http.StatusOK, result)
}
