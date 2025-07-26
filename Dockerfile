# =============================================================================
# DOCKERFILE OTIMIZADO - API UM DOCE
# Otimizado para Coolify com 2 vCPUs / 4GB RAM / 80GB disco
# =============================================================================

# Build stage - Otimizado para cache de layers
FROM node:22.15-alpine3.20 AS build

# Instalar dependências do sistema e dumb-init
RUN apk add --no-cache \
    dumb-init \
    tzdata \
    && cp /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime \
    && echo "America/Sao_Paulo" > /etc/timezone \
    && apk del tzdata

# Configurar diretório de trabalho
WORKDIR /usr/src

# Copiar apenas arquivos de dependências primeiro (melhor cache)
COPY package*.json ./

# Instalar dependências com otimizações avançadas
RUN npm ci \
    --prefer-offline \
    --no-audit \
    --no-fund \
    --ignore-scripts \
    && npm cache clean --force

# Copiar código fonte e schema do Prisma
COPY src ./src
COPY prisma ./prisma

# Gerar cliente Prisma
RUN npx prisma generate

# Limpar dependências de desenvolvimento e manter apenas produção
RUN npm prune --production \
    && npm cache clean --force \
    && rm -rf /tmp/* /var/cache/apk/*

# =============================================================================
# Production stage - Imagem final otimizada
# =============================================================================
FROM node:22.15-alpine3.20

# Instalar dependências mínimas do sistema
RUN apk add --no-cache \
    dumb-init \
    tzdata \
    tini \
    && cp /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime \
    && echo "America/Sao_Paulo" > /etc/timezone \
    && apk del tzdata \
    && rm -rf /var/cache/apk/*

# Criar usuário não-root com configurações de segurança
RUN addgroup -g 1001 -S nodejs \
    && adduser -S nodejs -u 1001 -G nodejs \
    && mkdir -p /usr/src \
    && chown -R nodejs:nodejs /usr/src

# Configurar diretório de trabalho
WORKDIR /usr/src

# Copiar aplicação do build stage com ownership correto
COPY --from=build --chown=nodejs:nodejs /usr/src/package.json ./package.json
COPY --from=build --chown=nodejs:nodejs /usr/src/node_modules ./node_modules 
COPY --from=build --chown=nodejs:nodejs /usr/src/src ./src
COPY --from=build --chown=nodejs:nodejs /usr/src/prisma ./prisma

# Copiar e configurar script de inicialização
COPY --chown=nodejs:nodejs start.sh ./start.sh
RUN chmod +x start.sh

# Configurar Node.js para produção com otimizações de memória
ENV NODE_ENV=production \
    NODE_OPTIONS="--max-old-space-size=3072 --enable-source-maps" \
    NPM_CONFIG_LOGLEVEL=warn \
    NPM_CONFIG_PROGRESS=false

# Mudar para usuário não-root
USER nodejs

# Expor porta da aplicação
EXPOSE 3333

# Health check otimizado para produção (menos frequente)
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3333/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) }).on('error', () => process.exit(1))"

# Labels para melhor organização e Coolify
LABEL maintainer="DevOps Team" \
      version="1.0.0" \
      description="API Um Doce - Optimized for Coolify" \
      org.opencontainers.image.source="https://github.com/your-repo"

# Usar tini como init system (alternativa ao dumb-init, mais leve)
ENTRYPOINT ["tini", "--"]
CMD ["./start.sh"]