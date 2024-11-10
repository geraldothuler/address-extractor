/** @type {import('next').NextConfig} */
const nextConfig = {
   reactStrictMode: true,
   swcMinify: true,
   output: 'standalone', // Otimizado para Docker
   // Configurações de imagem se necessário
   images: {
     domains: ['localhost'],
   },
   // Configurações de ambiente
   env: {
     NEXT_PUBLIC_GEOCODING_API_URL: process.env.NEXT_PUBLIC_GEOCODING_API_URL,
   },
   // Configurações do webpack se necessário
   webpack: (config, { buildId, dev, isServer, defaultLoaders, webpack }) => {
     // Exemplo de configuração para XLSX
     config.resolve.fallback = {
       ...config.resolve.fallback,
       fs: false,
       stream: false,
     };
     return config;
   },
 }
 
 module.exports = nextConfig
 