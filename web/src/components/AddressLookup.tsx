'use client'

import { useState } from 'react'
import { Search, Loader2 } from 'lucide-react'
import { Button } from '@/components/ui/Button'

type Address = {
  street: string
  number: string
  city: string
  state: string
  country: string
  postalCode: string
  latitude: number
  longitude: number
}

export default function AddressLookup() {
  const [latitude, setLatitude] = useState('')
  const [longitude, setLongitude] = useState('')
  const [loading, setLoading] = useState(false)
  const [address, setAddress] = useState<Address | null>(null)
  const [error, setError] = useState('')

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError('')
    setAddress(null)

    try {
      const response = await fetch(
        `/api/geocode?lat=${latitude}&lng=${longitude}`
      )
      const data = await response.json()

      if (!data.success) {
        throw new Error(data.error || 'Não foi possível encontrar o endereço')
      }

      setAddress(data.address)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao buscar endereço')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="p-6 bg-dracula-current rounded-lg">
      <form onSubmit={handleSubmit} className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm mb-2">Latitude</label>
            <input
              type="text"
              value={latitude}
              onChange={(e) => setLatitude(e.target.value)}
              placeholder="-23.557467"
              className="w-full"
              required
            />
          </div>
          <div>
            <label className="block text-sm mb-2">Longitude</label>
            <input
              type="text"
              value={longitude}
              onChange={(e) => setLongitude(e.target.value)}
              placeholder="-46.689294"
              className="w-full"
              required
            />
          </div>
        </div>

        <Button 
          type="submit" 
          className="w-full"
          disabled={loading}
        >
          {loading ? (
            <div className="flex items-center justify-center">
              <Loader2 className="w-4 h-4 mr-2 animate-spin" />
              Buscando...
            </div>
          ) : (
            <div className="flex items-center justify-center">
              <Search className="w-4 h-4 mr-2" />
              Buscar Endereço
            </div>
          )}
        </Button>

        {error && (
          <div className="p-4 bg-dracula-red/10 border border-dracula-red rounded text-dracula-red text-sm">
            {error}
          </div>
        )}

        {address && (
          <div className="mt-6 p-4 bg-dracula-background rounded-lg space-y-2">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="text-sm text-dracula-comment">Endereço</label>
                <p className="font-medium">{address.street}, {address.number}</p>
              </div>
              <div>
                <label className="text-sm text-dracula-comment">Cidade/Estado</label>
                <p className="font-medium">{address.city}, {address.state}</p>
              </div>
              <div>
                <label className="text-sm text-dracula-comment">País</label>
                <p className="font-medium">{address.country}</p>
              </div>
              <div>
                <label className="text-sm text-dracula-comment">CEP</label>
                <p className="font-medium">{address.postalCode}</p>
              </div>
            </div>
            <div className="pt-4 border-t border-dracula-current mt-4">
              <label className="text-sm text-dracula-comment">Coordenadas</label>
              <p className="font-medium text-dracula-purple">
                {address.latitude}, {address.longitude}
              </p>
            </div>
          </div>
        )}
      </form>
    </div>
  )
}