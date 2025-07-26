# =============================================================================
# DOCKERFILE OTIMIZADO PARA COOLIFY - API UM DOCE
# Versão melhorada com foco em performance, segurança e compatibilidade
# =============================================================================

# Build stage - Otimizado para cache de layers
FROM node:22.15-alpine3.20 AS build

# Instalar dependências do sistema e dumb-init
RUN apk add --no-cache \
    dumb-init \
    tzdata \
    curl \
    && rm -rf /var/cache/apk/*

# Configurar timezone
ENV TZ=America/Sao_Paulo

WORKDIR /usr/src

# Copiar apenas arquivos de dependências primeiro (melhor cache)
COPY package*.json ./

# Instalar dependências com otimizações avançadas
RUN npm ci \
    --prefer-offline \
    --no-audit \
    --no-fund \
    --silent \
    --production=false \
    && npm cache clean --force

# Copiar código fonte
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

# Instalar dependências mínimas do sistema + curl para health checks
RUN apk add --no-cache \
    dumb-init \
    tzdata \
    curl \
    tini \
    && rm -rf /var/cache/apk/*

# Configurar timezone
ENV TZ=America/Sao_Paulo

# Criar usuário não-root com configurações de segurança
RUN addgroup -g 1001 -S nodejs \
    && adduser -S nodejs -u 1001 -G nodejs \
    && mkdir -p /usr/src \
    && chown -R nodejs:nodejs /usr/src

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
    PORT=3333

USER nodejs

# Expor porta da aplicação
EXPOSE 3333

# Health check otimizado para Coolify (mais tempo para startup)
HEALTHCHECK --interval=30s --timeout=15s --start-period=90s --retries=3 \
    CMD curl -f http://localhost:3333/health || exit 1

# Labels otimizadas para Coolify
LABEL maintainer="DevOps Team" \
      version="1.0.0" \
      description="API Um Doce - Optimized for Coolify" \
      coolify.managed="true" \
      traefik.enable="true"

# Usar tini como init system para melhor signal handling
ENTRYPOINT ["tini", "--"]
CMD ["./start.sh"]