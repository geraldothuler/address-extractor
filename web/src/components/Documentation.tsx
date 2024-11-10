'use client'

import { useState, useEffect } from 'react'
import { Book, ChevronRight } from 'lucide-react'
import { marked } from 'marked'
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/Tabs'

interface DocSection {
  id: string
  title: string
  content: string
  sections: {
    id: string
    title: string
  }[]
}

const DOCS: DocSection[] = [
  {
    id: 'getting-started',
    title: 'Introdução',
    content: '# Address Extractor...',
    sections: [
      { id: 'overview', title: 'Visão Geral' },
      { id: 'architecture', title: 'Arquitetura' },
      { id: 'quick-start', title: 'Quick Start' }
    ]
  },
  {
    id: 'api-docs',
    title: 'API',
    content: '# API Documentation...',
    sections: [
      { id: 'endpoints', title: 'Endpoints' },
      { id: 'examples', title: 'Exemplos' },
      { id: 'responses', title: 'Respostas' }
    ]
  },
  // ... outros documentos
]

export default function Documentation() {
  const [activeDoc, setActiveDoc] = useState<string>('getting-started')
  const [activeSection, setActiveSection] = useState<string>('')
  const [renderedContent, setRenderedContent] = useState<string>('')

  useEffect(() => {
    // Configure marked options
    marked.setOptions({
      highlight: function(code, lang) {
        return Prism.highlight(code, Prism.languages[lang], lang)
      },
      langPrefix: 'language-'
    })
  }, [])

  useEffect(() => {
    const doc = DOCS.find(d => d.id === activeDoc)
    if (doc) {
      setRenderedContent(marked(doc.content))
    }
  }, [activeDoc])

  return (
    <div className="flex h-[calc(100vh-4rem)]">
      {/* Sidebar */}
      <div className="w-64 bg-dracula-current p-4 overflow-y-auto border-r border-dracula-purple/20">
        <div className="flex items-center gap-2 mb-6">
          <Book className="w-5 h-5 text-dracula-purple" />
          <h2 className="text-lg font-medium">Documentação</h2>
        </div>

        <nav className="space-y-1">
          {DOCS.map(doc => (
            <div key={doc.id}>
              <button
                onClick={() => setActiveDoc(doc.id)}
                className={`
                  w-full text-left px-2 py-1.5 rounded-lg text-sm
                  transition-colors duration-200
                  flex items-center justify-between
                  ${activeDoc === doc.id 
                    ? 'bg-dracula-purple/20 text-dracula-purple' 
                    : 'hover:bg-dracula-current/60'
                  }
                `}
              >
                {doc.title}
                <ChevronRight 
                  className={`w-4 h-4 transform transition-transform duration-200
                    ${activeDoc === doc.id ? 'rotate-90' : ''}`
                  } 
                />
              </button>

              {activeDoc === doc.id && (
                <div className="ml-4 mt-1 space-y-1">
                  {doc.sections.map(section => (
                    <button
                      key={section.id}
                      onClick={() => setActiveSection(section.id)}
                      className={`
                        w-full text-left px-2 py-1 rounded-lg text-sm
                        transition-colors duration-200
                        ${activeSection === section.id 
                          ? 'text-dracula-purple' 
                          : 'text-dracula-comment hover:text-dracula-foreground'
                        }
                      `}
                    >
                      {section.title}
                    </button>
                  ))}
                </div>
              )}
            </div>
          ))}
        </nav>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto p-8">
        <div 
          className="prose prose-invert max-w-none"
          dangerouslySetInnerHTML={{ __html: renderedContent }} 
        />
      </div>
    </div>
  )
}