# Estágio de construção
FROM node:18-alpine AS builder

# Definir diretório de trabalho
WORKDIR /app/web

# Copiar apenas o package.json
COPY web/package*.json ./

# Instalar dependências
RUN npm install

# Copiar código fonte
COPY web .

# Build da aplicação
RUN npm run build

# Estágio de produção
FROM node:18-alpine AS runner

# Definir variáveis de ambiente
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Criar usuário não-root
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Definir diretório de trabalho
WORKDIR /app/web

# Copiar arquivos necessários do estágio de build
COPY --from=builder --chown=nextjs:nodejs /app/web/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/web/.next/static ./.next/static
COPY --from=builder --chown=nextjs:nodejs /app/web/public ./public

# Usuário não-root
USER nextjs

# Expor porta
EXPOSE 3000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s \
    CMD wget --quiet --tries=1 --spider http://localhost:3000/health || exit 1

# Comando de inicialização
CMD ["node", "server.js"]