// Estrutura de rotas da aplicação
export const routes = {
   home: '/',
   docs: '/docs',
   api: {
     geocode: '/api/geocode',
     batch: '/api/batch',
     download: '/api/download',
   }
 } as const
 