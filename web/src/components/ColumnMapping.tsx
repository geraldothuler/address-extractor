'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/Button'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/Select'
import { AlertCircle } from 'lucide-react'

interface Column {
  key: string
  name: string
}

interface AddressField {
  id: string
  label: string
  required: boolean
}

interface ColumnMapping {
  latitude: string
  longitude: string
  mappings: {
    field: string
    targetColumn?: string
    createNew: boolean
  }[]
}

interface ColumnMappingProps {
  columns: Column[]
  onMappingComplete: (mapping: ColumnMapping) => void
}

const ADDRESS_FIELDS: AddressField[] = [
  { id: 'street', label: 'Rua', required: false },
  { id: 'number', label: 'Número', required: false },
  { id: 'city', label: 'Cidade', required: false },
  { id: 'state', label: 'Estado', required: false },
  { id: 'country', label: 'País', required: false },
  { id: 'postalCode', label: 'CEP', required: false }
]

export default function ColumnMapping({ columns, onMappingComplete }: ColumnMappingProps) {
  const [mapping, setMapping] = useState<ColumnMapping>({
    latitude: '',
    longitude: '',
    mappings: ADDRESS_FIELDS.map(field => ({
      field: field.id,
      createNew: true
    }))
  })

  const [errors, setErrors] = useState<{ [key: string]: string }>({})

  const validateMapping = (): boolean => {
    const newErrors: { [key: string]: string } = {}

    if (!mapping.latitude) {
      newErrors.latitude = 'Selecione a coluna de latitude'
    }
    if (!mapping.longitude) {
      newErrors.longitude = 'Selecione a coluna de longitude'
    }

    const hasErrors = Object.keys(newErrors).length > 0
    setErrors(newErrors)
    return !hasErrors
  }

  const handleSubmit = () => {
    if (validateMapping()) {
      onMappingComplete(mapping)
    }
  }

  const updateMapping = (type: 'latitude' | 'longitude', value: string) => {
    setMapping(prev => ({
      ...prev,
      [type]: value
    }))
    
    if (errors[type]) {
      setErrors(prev => {
        const newErrors = { ...prev }
        delete newErrors[type]
        return newErrors
      })
    }
  }

  const updateFieldMapping = (fieldId: string, targetColumn?: string) => {
    setMapping(prev => ({
      ...prev,
      mappings: prev.mappings.map(m => 
        m.field === fieldId ? {
          ...m,
          targetColumn,
          createNew: !targetColumn
        } : m
      )
    }))
  }

  return (
    <div className="space-y-6 bg-dracula-current p-6 rounded-lg">
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="block text-sm mb-2">
            Latitude <span className="text-dracula-red">*</span>
          </label>
          <Select
            value={mapping.latitude}
            onValueChange={value => updateMapping('latitude', value)}
          >
            <SelectTrigger className={errors.latitude ? 'border-dracula-red' : ''}>
              <SelectValue placeholder="Selecione a coluna" />
            </SelectTrigger>
            <SelectContent>
              {columns.map(col => (
                <SelectItem key={col.key} value={col.key}>
                  {col.name}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          {errors.latitude && (
            <p className="mt-1 text-sm text-dracula-red flex items-center">
              <AlertCircle className="w-4 h-4 mr-1" />
              {errors.latitude}
            </p>
          )}
        </div>

        <div>
          <label className="block text-sm mb-2">
            Longitude <span className="text-dracula-red">*</span>
          </label>
          <Select
            value={mapping.longitude}
            onValueChange={value => updateMapping('longitude', value)}
          >
            <SelectTrigger className={errors.longitude ? 'border-dracula-red' : ''}>
              <SelectValue placeholder="Selecione a coluna" />
            </SelectTrigger>
            <SelectContent>
              {columns.map(col => (
                <SelectItem key={col.key} value={col.key}>
                  {col.name}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          {errors.longitude && (
            <p className="mt-1 text-sm text-dracula-red flex items-center">
              <AlertCircle className="w-4 h-4 mr-1" />
              {errors.longitude}
            </p>
          )}
        </div>
      </div>

      <div className="space-y-4">
        <h3 className="text-lg font-medium border-b border-dracula-purple/20 pb-2">
          Campos de Endereço
        </h3>
        
        <div className="space-y-4">
          {ADDRESS_FIELDS.map(field => (
            <div key={field.id} className="flex items-center gap-4">
              <div className="w-24">
                <label className="text-sm">
                  {field.label}
                  {field.required && <span className="text-dracula-red ml-1">*</span>}
                </label>
              </div>
              
              <div className="flex-1">
                <Select
                  value={mapping.mappings.find(m => m.field === field.id)?.targetColumn || ''}
                  onValueChange={value => updateFieldMapping(field.id, value)}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Criar nova coluna" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="">Criar nova coluna</SelectItem>
                    {columns.map(col => (
                      <SelectItem key={col.key} value={col.key}>
                        {col.name}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>
          ))}
        </div>

        <div className="pt-4 border-t border-dracula-purple/20">
          <Button
            onClick={handleSubmit}
            className="w-full"
            size="lg"
          >
            Iniciar Processamento
          </Button>
        </div>
      </div>
    </div>
  )
}