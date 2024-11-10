'use client'

import { useState } from 'react'
import Link from 'next/link'
import { FileSpreadsheet, MapPin, Book } from 'lucide-react'
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/Tabs'
import FileUpload from '@/components/FileUpload'
import AddressLookup from '@/components/AddressLookup'
import ColumnMapping from '@/components/ColumnMapping'
import ProcessingStatus from '@/components/ProcessingStatus'

export default function Home() {
  const [file, setFile] = useState<File | null>(null)
  const [isProcessing, setIsProcessing] = useState(false)
  const [progress, setProgress] = useState({ current: 0, total: 0 })

  return (
    <main className="min-h-screen bg-dracula-background p-4 md:p-8">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="flex justify-between items-center mb-8">
          <h1 className="text-2xl font-bold text-dracula-purple">
            Address Extractor
          </h1>
          <Link
            href="/docs"
            className="flex items-center gap-2 text-dracula-comment hover:text-dracula-purple transition-colors"
          >
            <Book className="w-5 h-5" />
            <span>Documentação</span>
          </Link>
        </div>

        {/* Main Content */}
        <Tabs defaultValue="batch" className="space-y-6">
          <TabsList className="bg-dracula-current">
            <TabsTrigger value="batch" className="gap-2">
              <FileSpreadsheet className="w-4 h-4" />
              Processamento em Lote
            </TabsTrigger>
            <TabsTrigger value="single" className="gap-2">
              <MapPin className="w-4 h-4" />
              Consulta Individual
            </TabsTrigger>
          </TabsList>

          <TabsContent value="batch">
            {!file && !isProcessing && (
              <FileUpload
                onFileSelected={(selectedFile) => {
                  setFile(selectedFile)
                }}
              />
            )}

            {file && !isProcessing && (
              <ColumnMapping
                columns={[
                  { key: 'lat', name: 'Latitude' },
                  { key: 'lng', name: 'Longitude' },
                ]}
                onMappingComplete={(mapping) => {
                  setIsProcessing(true)
                  // Simular processamento
                  let current = 0
                  const interval = setInterval(() => {
                    current += 1
                    setProgress({ current, total: 100 })
                    if (current >= 100) {
                      clearInterval(interval)
                    }
                  }, 100)
                }}
              />
            )}

            {isProcessing && (
              <ProcessingStatus
                current={progress.current}
                total={progress.total}
                status={`Processando ${progress.current} de ${progress.total} registros...`}
                isComplete={progress.current === progress.total}
                downloadUrl={progress.current === progress.total ? '/api/download' : undefined}
                onRetry={() => {
                  setFile(null)
                  setIsProcessing(false)
                  setProgress({ current: 0, total: 0 })
                }}
              />
            )}
          </TabsContent>

          <TabsContent value="single">
            <AddressLookup />
          </TabsContent>
        </Tabs>
      </div>
    </main>
  )
}