# Calaja Central

Servidor central do ecossistema Calaja Miner.

## Funções

- Receber métricas das rigs
- Disponibilizar API REST
- Exibir dashboard web
- Mostrar visão geral e detalhe por rig

## Rotas

- `/` → visão geral das rigs
- `/rig/<rig_id>` → página individual da rig
- `/api/status` → recebimento de status das rigs
- `/api/rigs` → retorno JSON com todas as rigs
- `/health` → healthcheck

## Porta padrão

- `5001`

## Estrutura

- `app.py` → backend Flask
- `templates/` → páginas HTML
- `static/` → CSS
- `requirements.txt` → dependências Python

## Próximos passos

- histórico de hashrate
- gráficos por rig
- alertas online/offline
- controle remoto
