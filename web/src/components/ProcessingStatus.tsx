'use client'

import { useEffect, useState } from 'react'
import { CircularProgressbar, buildStyles } from 'react-circular-progressbar'
import { Download, RefreshCw } from 'lucide-react'
import { Button } from '@/components/ui/Button'
import 'react-circular-progressbar/dist/styles.css'

interface ProcessingStatusProps {
  current: number
  total: number
  status: string
  isComplete: boolean
  downloadUrl?: string
  onRetry?: () => void
}

export default function ProcessingStatus({
  current,
  total,
  status,
  isComplete,
  downloadUrl,
  onRetry
}: ProcessingStatusProps) {
  const [percentage, setPercentage] = useState(0)

  useEffect(() => {
    setPercentage(Math.round((current / total) * 100))
  }, [current, total])

  return (
    <div className="bg-dracula-current rounded-lg p-6 shadow-lg">
      <div className="flex items-center space-x-8">
        <div className="w-40 h-40">
          <CircularProgressbar
            value={percentage}
            text={`${percentage}%`}
            styles={buildStyles({
              textColor: '#f8f8f2',
              pathColor: '#bd93f9',
              trailColor: '#44475a',
              textSize: '16px',
            })}
          />
        </div>
        
        <div className="flex-1">
          <h3 className="text-xl font-medium mb-2">
            {isComplete ? 'Processamento Concluído!' : 'Processando...'}
          </h3>
          
          <p className="text-dracula-comment mb-4">{status}</p>
          
          <div className="space-y-2">
            <p>
              <span className="text-dracula-comment">Registros processados:</span>{' '}
              <span className="text-dracula-purple">{current}</span>
              <span className="text-dracula-comment"> de </span>
              <span className="text-dracula-purple">{total}</span>
            </p>

            {isComplete && (
              <div className="flex space-x-4 mt-4">
                {downloadUrl && (
                  <Button onClick={() => window.open(downloadUrl, '_blank')}>
                    <Download className="w-4 h-4 mr-2" />
                    Baixar Arquivo
                  </Button>
                )}
                {onRetry && (
                  <Button variant="secondary" onClick={onRetry}>
                    <RefreshCw className="w-4 h-4 mr-2" />
                    Processar Novo Arquivo
                  </Button>
                )}
              </div>
            )}
          </div>
        </div>
      </div>

      {!isComplete && (
        <div className="mt-6">
          <div className="h-1 bg-dracula-background rounded-full overflow-hidden">
            <div
              className="h-full bg-dracula-purple transition-all duration-500 ease-in-out"
              style={{ width: `${percentage}%` }}
            />
          </div>
        </div>
      )}
    </div>
  )
}
