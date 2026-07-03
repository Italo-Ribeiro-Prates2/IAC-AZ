# Azure IAM Zero Trust Lab

Laboratório prático de governança de identidade e acesso no Microsoft Entra ID, simulando a implementação de controles de segurança para uma empresa fictícia de médio porte.

## Contexto

Empresa fictícia de 200 funcionários no setor financeiro, com times de Finance, IT, HR e Sales. Problema identificado: acesso a recursos críticos (billing, dados de RH) não seguia o princípio de least privilege, administradores tinham acesso permanente a funções privilegiadas, e não havia política de autenticação multifator consistente.

Este projeto documenta o desenho e a implementação de uma estrutura de IAM alinhada a Zero Trust, dentro das limitações de um ambiente Microsoft Entra ID Free (sem licenciamento Premium P1/P2).

## Arquitetura da solução

```
┌─────────────────────────────────────────────────┐
│                 Microsoft Entra ID                │
│                                                     │
│   SG-Finance-Users  ──Reader──▶  rg-finance-prod  │
│   SG-IT-Admins      ──Contributor──▶ rg-it-shared │
│   SG-IT-Admins      ──VM Operator (custom)──▶     │
│                          rg-it-shared              │
│                                                     │
│   Security Defaults ──▶ MFA obrigatório,          │
│                          bloqueio de auth legada   │
└─────────────────────────────────────────────────┘
```

## O que foi implementado

### 1. Grupos de segurança (RBAC)
Grupos estáticos por função de negócio, usados como unidade de atribuição de acesso em vez de atribuição individual por usuário:

| Grupo | Propósito |
|---|---|
| `SG-Finance-Users` | Time de Finance, acesso de leitura a recursos financeiros |
| `SG-IT-Admins` | Time de IT, opera infraestrutura compartilhada |

Ver detalhamento completo em [`docs/access-matrix.md`](docs/access-matrix.md).

### 2. RBAC com least privilege

| Grupo | Escopo | Role | Justificativa |
|---|---|---|---|
| SG-Finance-Users | `rg-finance-prod` | Reader | Só precisa visualizar recursos e custos, sem permissão de alteração |
| SG-IT-Admins | `rg-it-shared` | Contributor | Opera recursos, sem poder gerenciar acesso de terceiros (isso ficaria restrito a Owner) |
| SG-IT-Admins | subscription | VM Operator - Restart Only (custom) | Role customizada com permissão apenas para ligar/desligar/reiniciar VMs, sem poder deletar ou reconfigurar |

A role customizada está documentada em [`rbac/custom-role-vm-operator.json`](rbac/custom-role-vm-operator.json).

### 3. Controle de acesso condicional

O ambiente utilizado (Entra ID Free) não suporta Conditional Access granular, que exige licenciamento P1. Como controle equivalente, foi habilitado o **Security Defaults**, que aplica um baseline de proteção sem necessidade de configuração adicional:

- MFA obrigatório para todos os usuários
- MFA obrigatório para operações administrativas (portal Azure, PowerShell, CLI)
- Bloqueio de protocolos de autenticação legados (POP, IMAP, SMTP antigo)
- Proteção automática contra sinais básicos de risco de login

O desenho de uma política de Conditional Access completa (para quando uma licença P1/P2 estiver disponível) está documentado em [`conditional-access/policy-design-mfa-admins.json`](conditional-access/policy-design-mfa-admins.json).

### 4. Infraestrutura como código (Terraform)

A criação dos grupos de segurança e das atribuições de RBAC foi replicada via Terraform, demonstrando reprodutibilidade do ambiente e versionamento da infraestrutura de identidade.

```
terraform/
├── main.tf         # Providers (azuread, azurerm)
├── variables.tf    # Variáveis de configuração
├── groups.tf       # Definição dos grupos de segurança
└── rbac.tf         # Atribuições de role sobre resource groups existentes
```

Os Resource Groups (`rg-finance-prod`, `rg-it-shared`) foram provisionados manualmente durante a fase de exploração do portal e são referenciados no Terraform via `data source`, não recriados — evitando duplicidade de recursos já existentes.

## Decisões de arquitetura

- **Security Group em vez de Microsoft 365 Group**: o propósito dos grupos é controle de acesso (RBAC, autenticação), não colaboração. M365 Groups não são elegíveis para atribuição em diversos cenários de RBAC e Conditional Access.
- **Role customizada em vez de apenas roles nativas**: demonstra domínio do modelo de permissões granular do Azure (`actions`/`notActions`/`dataActions`), permitindo conceder exatamente o necessário para uma tarefa específica, sem excesso de privilégio.
- **Autenticação local via Azure CLI no Terraform**: adequado para ambiente de estudo. Em produção, seria substituído por autenticação via Service Principal com credenciais gerenciadas e least privilege.

## Limitações do ambiente e próximos passos

Este projeto foi desenvolvido em um tenant Microsoft Entra ID Free. Os seguintes recursos exigem licenciamento Premium (P1 ou P2) e não puderam ser implementados diretamente, mas estão desenhados e documentados como próxima fase:

| Recurso | Licença necessária | Status |
|---|---|---|
| Conditional Access granular | P1 | Desenho documentado em `conditional-access/` |
| Grupos dinâmicos (baseados em atributo) | P1 | Não implementado |
| Privileged Identity Management (PIM) | P2 | Não implementado |
| Access Reviews | P2 | Não implementado |

## Como reproduzir

### Pré-requisitos
- Conta Azure com uma subscription ativa
- Azure CLI instalado e autenticado (`az login`)
- Terraform >= 1.5

### Passos

1. Clone o repositório
2. Copie `terraform/terraform.tfvars.example` para `terraform/terraform.tfvars` e preencha com sua subscription ID
3. Crie manualmente os resource groups referenciados (`rg-finance-prod`, `rg-it-shared`) ou ajuste o `rbac.tf` para criá-los via Terraform
4. Execute:
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## Estrutura do repositório

```
azure-iam-zerotrust-lab/
├── README.md
├── .gitignore
├── docs/
│   └── access-matrix.md
├── rbac/
│   └── custom-role-vm-operator.json
├── conditional-access/
│   └── policy-design-mfa-admins.json
└── terraform/
    ├── main.tf
    ├── variables.tf
    ├── terraform.tfvars.example
    ├── groups.tf
    └── rbac.tf
```

## Autor

Italo Prates — IT Infrastructure Intern, em transição para Cloud Security Engineer, focado no ecossistema Microsoft Azure.

[LinkedIn] · [GitHub]