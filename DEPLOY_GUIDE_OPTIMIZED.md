# 🚀 GUIA DE DEPLOY OTIMIZADO PARA COOLIFY

## 📋 **RESUMO DAS MELHORIAS IMPLEMENTADAS**

### ✅ **Problemas Resolvidos:**
- **CURL instalado** na imagem Docker (resolvia o "no available server")
- **Labels Traefik completas** para roteamento adequado
- **Health checks otimizados** com timeouts adequados
- **Resource limits** configurados para 4GB RAM
- **Logging estruturado** implementado
- **Backup automático** no processo de deploy

### 🔧 **Otimizações Aplicadas:**
- **Multi-stage build** otimizado para cache
- **Usuário não-root** com configurações de segurança
- **Graceful shutdown** melhorado
- **Network isolation** configurada
- **Timezone** configurado para America/Sao_Paulo

## 🚀 **COMO FAZER O DEPLOY NO COOLIFY**

### **Opção 1: Deploy Automático (Recomendado)**

```bash
# 1. Execute o script de deploy otimizado
./deploy-coolify.sh
```

### **Opção 2: Deploy Manual**

```bash
# 1. Criar backup dos dados existentes
mkdir -p backups
docker run --rm -v controle_pedidos_db:/data -v $PWD/backups:/backup alpine:latest tar czf /backup/db-backup-$(date +%Y%m%d_%H%M%S).tar.gz -C /data .

# 2. Parar serviços existentes
docker-compose -f docker-compose-coolify.yaml down --remove-orphans

# 3. Limpar imagens antigas
docker image prune -f

# 4. Build e start com nova configuração
docker-compose -f docker-compose-coolify.yaml up -d --build --force-recreate

# 5. Verificar status
docker-compose -f docker-compose-coolify.yaml ps
docker-compose -f docker-compose-coolify.yaml logs -f api-um-doce
```

## 🔍 **VALIDAÇÃO DO DEPLOY**

### **1. Verificar Containers**
```bash
# Status dos containers
docker-compose -f docker-compose-coolify.yaml ps

# Logs da aplicação
docker-compose -f docker-compose-coolify.yaml logs -f api-um-doce

# Health check interno
docker-compose -f docker-compose-coolify.yaml exec api-um-doce curl -f http://localhost:3333/health
```

### **2. Verificar Conectividade Externa**
```bash
# Health check externo
curl -v https://api.umdoce.dev.br/health

# Endpoint raiz
curl -v https://api.umdoce.dev.br/

# Verificar headers de resposta
curl -I https://api.umdoce.dev.br/health
```

### **3. Verificar Traefik/Coolify**
- Acesse o dashboard do Coolify
- Verifique se o serviço aparece como "healthy"
- Confirme se as rotas estão configuradas corretamente

## 🛠️ **TROUBLESHOOTING**

### **Problema: "no available server"**
```bash
# 1. Verificar se o container está healthy
docker-compose -f docker-compose-coolify.yaml ps

# 2. Verificar logs do container
docker-compose -f docker-compose-coolify.yaml logs api-um-doce

# 3. Testar health check interno
docker-compose -f docker-compose-coolify.yaml exec api-um-doce curl -f http://localhost:3333/health

# 4. Verificar se curl está instalado
docker-compose -f docker-compose-coolify.yaml exec api-um-doce which curl
```

### **Problema: Container não inicia**
```bash
# 1. Verificar logs detalhados
docker-compose -f docker-compose-coolify.yaml logs --details api-um-doce

# 2. Verificar conectividade com banco
docker-compose -f docker-compose-coolify.yaml exec postgresql pg_isready -U admin -d controle_pedidos

# 3. Verificar variáveis de ambiente
docker-compose -f docker-compose-coolify.yaml exec api-um-doce env | grep -E "(DB_|DATABASE_|NODE_)"
```

### **Problema: Performance baixa**
```bash
# 1. Verificar uso de recursos
docker stats

# 2. Verificar logs de memória
docker-compose -f docker-compose-coolify.yaml logs api-um-doce | grep -i memory

# 3. Ajustar NODE_OPTIONS se necessário
# Edite docker-compose-coolify.yaml e ajuste --max-old-space-size
```

## 📊 **MONITORAMENTO (OPCIONAL)**

Para monitoramento avançado, use:

```bash
# Deploy com monitoramento
docker-compose -f docker-compose-coolify.yaml -f docker-compose-monitoring.yaml up -d

# Acessar dashboards
# Grafana: http://grafana.umdoce.dev.br (admin/admin123)
# Prometheus: http://prometheus.umdoce.dev.br
```

## 🔄 **ROLLBACK EM CASO DE PROBLEMAS**

```bash
# 1. Parar serviços atuais
docker-compose -f docker-compose-coolify.yaml down

# 2. Restaurar backup mais recente
cp backups/docker-compose-YYYYMMDD_HHMMSS.yaml docker-compose-coolify.yaml

# 3. Subir com configuração anterior
docker-compose -f docker-compose-coolify.yaml up -d

# 4. Restaurar dados do banco se necessário
# (Consulte backup em backups/db-backup-*.tar.gz)
```

## 📋 **CHECKLIST DE VALIDAÇÃO**

- [ ] Container `api-um-doce` está com status "healthy"
- [ ] Container `postgresql` está com status "healthy"  
- [ ] Health check interno responde: `curl http://localhost:3333/health`
- [ ] Health check externo responde: `curl https://api.umdoce.dev.br/health`
- [ ] Endpoint raiz responde: `curl https://api.umdoce.dev.br/`
- [ ] Logs não mostram erros críticos
- [ ] Traefik está roteando corretamente
- [ ] Coolify mostra serviço como ativo

## 🔒 **CONFIGURAÇÕES DE SEGURANÇA IMPLEMENTADAS**

- ✅ Usuário não-root (nodejs:1001)
- ✅ Security options: no-new-privileges
- ✅ Resource limits configurados
- ✅ Network isolation
- ✅ Secrets via environment variables
- ✅ Health checks com timeouts adequados
- ✅ Logging estruturado
- ✅ Graceful shutdown

## 📈 **PERFORMANCE OTIMIZADA PARA 4GB RAM**

- **PostgreSQL**: 1GB limit, 512MB reserved
- **API**: 2GB limit, 512MB reserved  
- **Node.js**: --max-old-space-size=1536MB
- **Health checks**: Intervalos otimizados
- **Logging**: Rotação automática (10MB, 3 arquivos)

---

**🎯 Resultado Esperado:** Após aplicar essas configurações, o erro "no available server" deve ser resolvido e a API deve ficar acessível em https://api.umdoce.dev.br