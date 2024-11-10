'use client'

import { useCallback, useState } from 'react'
import { useDropzone } from 'react-dropzone'
import { Upload, FileSpreadsheet, X } from 'lucide-react'
import { Button } from '@/components/ui/Button'
import { formatBytes } from '@/lib/utils'

interface FileUploadProps {
  onFileSelected: (file: File) => void
  accept?: string[]
  maxSize?: number
}

export default function FileUpload({
  onFileSelected,
  accept = ['.xlsx', '.xls', '.csv'],
  maxSize = 10 * 1024 * 1024, // 10MB
}: FileUploadProps) {
  const [error, setError] = useState<string>('')
  const [selectedFile, setSelectedFile] = useState<File | null>(null)

  const onDrop = useCallback((acceptedFiles: File[], rejectedFiles: any[]) => {
    if (rejectedFiles.length > 0) {
      const error = rejectedFiles[0].errors[0]
      if (error.code === 'file-too-large') {
        setError(`Arquivo muito grande. Máximo: ${formatBytes(maxSize)}`)
      } else {
        setError('Formato de arquivo não suportado')
      }
      return
    }

    if (acceptedFiles.length > 0) {
      setError('')
      setSelectedFile(acceptedFiles[0])
      onFileSelected(acceptedFiles[0])
    }
  }, [maxSize, onFileSelected])

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: {
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': ['.xlsx'],
      'application/vnd.ms-excel': ['.xls'],
      'text/csv': ['.csv']
    },
    maxSize,
    multiple: false
  })

  const removeFile = () => {
    setSelectedFile(null)
    setError('')
  }

  return (
    <div className="w-full">
      <div
        {...getRootProps()}
        className={`
          flex flex-col items-center justify-center p-8 border-2 border-dashed 
          rounded-lg transition-all duration-200 ease-in-out cursor-pointer
          ${isDragActive 
            ? 'border-dracula-purple bg-dracula-purple/10' 
            : 'border-dracula-current hover:border-dracula-purple hover:bg-dracula-current/10'
          }
        `}
      >
        <input {...getInputProps()} />

        {selectedFile ? (
          <div className="flex items-center space-x-4">
            <FileSpreadsheet className="w-8 h-8 text-dracula-purple" />
            <div>
              <p className="text-dracula-foreground font-medium">
                {selectedFile.name}
              </p>
              <p className="text-sm text-dracula-comment">
                {formatBytes(selectedFile.size)}
              </p>
            </div>
            <Button
              variant="ghost"
              size="icon"
              onClick={(e) => {
                e.stopPropagation()
                removeFile()
              }}
            >
              <X className="w-4 h-4" />
            </Button>
          </div>
        ) : (
          <div className="text-center">
            <div className="mb-4">
              {isDragActive ? (
                <Upload className="w-12 h-12 text-dracula-purple mx-auto" />
              ) : (
                <FileSpreadsheet className="w-12 h-12 text-dracula-comment mx-auto" />
              )}
            </div>
            <p className="text-lg mb-2">
              {isDragActive ? (
                "Solte o arquivo aqui"
              ) : (
                "Arraste um arquivo Excel ou CSV aqui"
              )}
            </p>
            <p className="text-sm text-dracula-comment">
              ou clique para selecionar
            </p>
            <p className="text-sm text-dracula-comment mt-2">
              Formatos suportados: XLSX, XLS, CSV (máx. {formatBytes(maxSize)})
            </p>
          </div>
        )}
      </div>

      {error && (
        <div className="mt-2 p-3 rounded-lg bg-dracula-red/10 border border-dracula-red text-dracula-red text-sm">
          {error}
        </div>
      )}
    </div>
  )
}