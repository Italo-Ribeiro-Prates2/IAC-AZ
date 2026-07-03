# Matriz de Acesso — Azure IAM Zero Trust Lab

Documentação de todos os grupos de segurança, seus escopos de atribuição e a justificativa de negócio por trás de cada decisão.

## Grupos de segurança

| Grupo | Tipo de associação | Origem | Propósito |
|---|---|---|---|
| `SG-Finance-Users` | Estático (Atribuído) | Criado manualmente no portal | Time de Finance — acesso de consulta a recursos financeiros |
| `SG-IT-Admins` | Estático (Atribuído) | Criado manualmente no portal | Time de IT — opera infraestrutura compartilhada |
| `SG-Finance-Users-TF` | Estático (Atribuído) | Criado via Terraform | Réplica via IaC do grupo de Finance, para validar reprodutibilidade |
| `SG-IT-Admins-TF` | Estático (Atribuído) | Criado via Terraform | Réplica via IaC do grupo de IT, para validar reprodutibilidade |

> **Nota sobre grupos dinâmicos**: o ambiente utilizado (Microsoft Entra ID Free) não suporta grupos dinâmicos, recurso que exige licenciamento P1. Em um ambiente com essa licença, os grupos acima seriam substituídos por grupos dinâmicos com regra baseada no atributo `department` do usuário, eliminando a necessidade de manutenção manual de membros.

## Atribuições de RBAC

| Grupo | Escopo | Role | Tipo de Role | Justificativa |
|---|---|---|---|---|
| SG-Finance-Users | `rg-finance-prod` | Reader | Nativa (built-in) | Time de Finance precisa apenas visualizar recursos e custos, sem permissão de alteração — reduz risco de mudança acidental em recursos que não são de sua responsabilidade operacional |
| SG-IT-Admins | `rg-it-shared` | Contributor | Nativa (built-in) | Time de IT opera a infraestrutura compartilhada no dia a dia, mas não deve gerenciar atribuições de acesso de terceiros — essa responsabilidade fica restrita a Owner |
| SG-IT-Admins | subscription | VM Operator - Restart Only | Customizada | Permite ligar, desligar e reiniciar VMs sem conceder permissão de deleção ou reconfiguração — aplica least privilege para uma tarefa operacional específica |

## Princípios aplicados

- **Least privilege**: nenhuma atribuição concede mais acesso do que o necessário para a função. Nenhum grupo recebeu `Owner`, exceto o usuário administrador raiz do tenant.
- **Segregação por função de negócio**: grupos são organizados por área (Finance, IT), não por indivíduo, facilitando auditoria e onboarding/offboarding.
- **Escopo mínimo necessário**: atribuições são feitas no nível de Resource Group sempre que possível, evitando conceder acesso amplo no nível de subscription, exceto quando a natureza da role exige (caso da role customizada de VM, que precisa operar em qualquer resource group onde VMs existam).

## Limitações conhecidas e mitigação planejada

| Limitação | Causa | Mitigação em ambiente com licença Premium |
|---|---|---|
| Grupos são estáticos, exigem manutenção manual | Entra ID Free não suporta grupos dinâmicos (exige P1) | Migrar para grupos dinâmicos com regra de atributo `department` |
| Acesso privilegiado é permanente, não just-in-time | Entra ID Free não suporta PIM (exige P2) | Configurar PIM com elegibilidade temporária e aprovação obrigatória para roles como Contributor e Global Administrator |
| Sem revisão periódica formal de acesso | Entra ID Free não suporta Access Reviews (exige P2) | Configurar Access Review trimestral para os grupos `SG-IT-Admins` |
