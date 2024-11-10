import { Metadata } from 'next'
import DocsHeader from './DocsHeader'

export const metadata: Metadata = {
  title: 'Documentação | Address Extractor',
  description: 'Documentação completa do serviço de extração de endereços',
}

export default function DocsLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <div className="min-h-screen bg-dracula-background text-dracula-foreground">
      <DocsHeader />
      <main>{children}</main>
    </div>
  )
}