import { Inter } from 'next/font/google'
import './globals.css'
import type { Metadata } from 'next'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'Address Extractor',
  description: 'Extraia endereços a partir de coordenadas geográficas',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="pt-BR">
      <body className={`${inter.className} bg-dracula-background text-dracula-foreground`}>
        {children}
      </body>
    </html>
  )
}