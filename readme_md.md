# Projeto Avaliativo - Ciência e Análise de Dados do PNCP (Portal Nacional de Contratações Públicas)

## 📌 Contexto do Projeto

Este projeto consiste em uma solução de **Ciência e Análise de Dados End-to-End** focada na transparência e no controle das contratações públicas brasileiras registradas no Portal Nacional de Contratações Públicas (**PNCP**).

A solução abrange desde a **extração, limpeza e higienização dos dados brutos** via scripts em Python, até o **desenvolvimento de um modelo dimensional Star Schema** no MySQL e a **construção de um Dashboard Executivo Interativo** no Power BI focado em princípios de UI/UX (CRAP), acompanhado de análises descritivas e prescritivas para auxílio à gestão pública e auditoria da Controladoria Geral.

## 🏗️ Arquitetura do Sistema e Estrutura de Pastas

A estrutura do projeto foi padronizada para garantir reprodutibilidade, governança e modularidade do código:

```
.
├── data/
│   ├── raw/                 # Dados brutos baixados (compras.csv, itens.csv, resultados.csv)
│   └── processed/           # Dados higienizados exportados pelo Python (Star Schema em CSV)
├── docs/
│   └── img/                 # Imagens e capturas para documentação (ex: sprints.png)
├── powerbi/
│   └── dashboard_pncp.pbix  # Arquivo compilado do Power BI
├── sql/
│   ├── 01_criar_banco.sql   # DDL de criação do banco, tabelas, chaves e restrições
│   └── 02_perguntas.sql     # Consultas analíticas SQL para validação de hipóteses
├── src/
│   ├── banco.py             # Módulo de conexão e execução de queries/scripts no MySQL
│   ├── carregar.py          # Script de automação DDL e carga batch em lote no MySQL
│   ├── config.py            # Gerenciador de caminhos de diretórios e variáveis do .env
│   ├── limpeza.py           # Funções puras de higienização, regex e regras de exceção
│   └── montar_tabelas.py    # Pipeline ETL de limpeza, enriquecimento e geração do Star Schema
├── .env.example             # Modelo das variáveis de ambiente necessárias
├── .gitignore                # Regras de omissão para git (oculta .env, raw e temporários)
├── README.md                # Documentação técnica e estratégica do projeto
└── requirements.txt         # Dependências das bibliotecas Python do projeto

```

## 📐 Modelagem de Dados (Star Schema)

O modelo dimensional foi desenhado para maximizar a performance analítica e facilitar o consumo no Power BI através de um esquema em estrela (**Star Schema**) composto por **1 Tabela Fato** e **4 Tabelas Dimensão**, com integridade referencial mantida por chaves substitutas (`SK_`):

```
                       +-----------------------+
                       |    dim_modalidade     |
                       +-----------------------+
                       | PK  sk_modalidade     |
                       |     modalidade_id     |
                       |     nome_modalidade   |
                       +-----------+-----------+
                                   | 1
                                   |
                                   | N
+-----------------------+      +---+-----------------------+      +-----------------------+
|       dim_orgao       |      |    fato_item_contratado   |      |    dim_fornecedor     |
+-----------------------+      +---------------------------+      +-----------------------+
| PK  sk_orgao          | 1  N | PK  sk_fato               | N  1 | PK  sk_fornecedor     |
|     cnpj_orgao        +------+ FK  sk_orgao              +------+     ni_fornecedor       |
|     nome_orgao        |      | FK  sk_fornecedor         |      |     nome_fornecedor     |
|     poder             |      | FK  sk_modalidade         |      |     tipo_pessoa         |
+-----------------------+      | FK  sk_localidade         |      |     porte               |
                               |     numero_controle_pncp  |      +-----------------------+
                               |     numero_item           |
                               |     data_publicacao       |
                               |     data_homologacao      |
                               |     descricao_item        |
                               |     perfil_gasto          |
                               |     quantidade            |
                               |     valor_total_estimado  |
                               |     valor_total_homologado|
                               |     comparavel            |
                               |     economia_valor        |
                               |     dias_ciclo            |
                               +-----------+---------------+
                                           | N
                                           |
                                           | 1
                       +-------------------+---+
                       |    dim_localidade     |
                       +-----------------------+
                       | PK  sk_localidade     |
                       |     uf_sigla          |
                       |     uf_nome           |
                       |     regiao            |
                       +-----------------------+

```

## 🎯 Regras de Negócio e Tratamento de Anomalias

Durante a fase de ETL em Python (`src/montar_tabelas.py`), aplicou-se um protocolo rigoroso de tratamento de inconsistências:

1. **Padronização de Documentos:** Tratamento automático de CNPJ (14 dígitos) e CPF (11 dígitos) com preservação de zeros à esquerda através de expressão regular.

2. **Resolução de Duplicidades de Vencedores:** Deduplicação estrita ordenando os resultados pela menor ordem de classificação e sequencial, garantindo exatamente **1 vencedor por item**.

3. **Filtro de Itens Rejeitados (99 itens):** Exclusão de registros com quantidades ou valores unitários nulos/zerados, itens sigilosos, estimativas inconsistentes ($< R\$ 1,00$) e discrepâncias atípicas ($V_{homologado} > 1000 \times V_{estimado}$).

4. **Métrica de Comparabilidade e Economia:** Filtro de itens onde o deságio é matematicamente comparável (excluindo credenciamentos e razões atípicas fora de $0,1 \le \frac{V_{homologado}}{V_{estimado}} \le 10$).

5. **Ajuste Cronológico e Ciclo:** Descarte de datas de homologação anteriores à data de publicação do edital, calculando a métrica em dias apenas para ciclos válidos.

6. **Classificação do Perfil do Gasto:** Segmentação do gasto em **Obras e engenharia**, **Serviços** e **Bens** por varredura textual na descrição dos itens.

## 🔍 Prova Real e Validação de Métricas Metodológicas

A validação da limpeza dos dados em Python e da carga em lote no MySQL bateu de forma **100% exata** com a Prova Real e os gabaritos do projeto:

| Métrica / Indicador | Resultado Obtido | Gabarito (Prova Real) | Status | 
| ----- | ----- | ----- | ----- | 
| **Itens na Fato** | **6.126** | 6.126 | ✅ OK | 
| **Contratações Distintas** | **1.962** | 1.962 | ✅ OK | 
| **Fornecedores Cadastrados** | **2.652** | 2.652 | ✅ OK | 
| **Órgãos Compradores (CNPJ)** | **363** | 363 | ✅ OK | 
| **Volume Total Homologado** | **R\$ 8.044.498.805,74** | R\$ 8,04 bi | ✅ OK | 
| **Itens Comparáveis** | **5.457** | 5.457 | ✅ OK | 
| **Economia Percentual (%)** | **14,46%** | 14,46% | ✅ OK | 
| **Ciclo Médio / Máximo** | **48,1 / 611 dias** | 48,1 / 611 dias | ✅ OK | 
| **Itens sem Ciclo** | **230** | 230 | ✅ OK | 
| **Perfil do Gasto (Volume)** | **Obras (60,8%), Serv. (36,6%), Bens (2,6%)** | 60,8% / 36,6% / 2,6% | ✅ OK | 

## 📊 Medidas DAX Implementadas no Power BI

Foram desenvolvidas **15 medidas explícitas em DAX** organizadas em pastas temáticas:

### 📁 P1 - Economia

* **`Valor Estimado Comparável`**: Soma do valor estimado filtrando `comparavel = 1`.

* **`Volume Homologado`**: Soma total do valor homologado de todas as contratações.

* **`Economia (R$)`**: Diferença absoluta entre a estimativa comparável e o valor final homologado.

* **`Economia %`**: Razão entre a Economia em R\$ e o Valor Estimado Comparável.

* **`% de Itens Comparáveis`**: Proporção de itens elegíveis para o cálculo de deságio.

### 📁 P2 - Fornecedores

* **`Participação do Fornecedor %`**: Representatividade do volume do fornecedor em relação ao total geral.

* **`Ranking do Fornecedor`**: Ranking dinâmico ordenado por volume homologado (`RANKX`).

* **`Concentração Top 10 %`**: Percentual acumulado do orçamento público concentrado nos 10 maiores fornecedores.

### 📁 P3 - Modalidades

* **`Participação no Volume %`**: Distribuição do volume financeiro alocado por modalidade.

* **`Deságio vs Média Geral (p.p.)`**: Variação em pontos percentuais entre o deságio da modalidade e o deságio médio global.

### 📁 P4 - Ciclo

* **`Ciclo Médio (dias)`**: Média de dias decorridos entre publicação do edital e homologação.

* **`Ciclo Máximo (dias)`**: Duração máxima registrada em dias no ciclo licitatório.

* **`Itens sem Ciclo`**: Contagem de registros pendentes de homologação formal.

### 📁 P5 - Regional

* **`Qtd Unidades Compradoras`**: Contagem distinta de CNPJs de órgãos compradores por região/UF.

### 📁 P6 - Perfil

* **`Ticket Médio por Item (R$)`**: Razão entre o volume financeiro homologado e a quantidade de itens.

## 🚀 Como Executar o Projeto

### 1. Pré-requisitos

* Python 3.10+

* MySQL Server 8.0+

* Power BI Desktop

* Driver [MySQL Connector/NET](https://dev.mysql.com/downloads/connector/net/) instalado no Windows

### 2. Configuração do Ambiente Python e `.env`

Clone o repositório e instale as dependências:

```
# Instalar dependências
pip install -r requirements.txt

```

Crie um arquivo `.env` na raiz do projeto com as credenciais do seu MySQL local (conforme modelo `.env.example`):

```
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=sua_senha
MYSQL_DATABASE=pncp_controladoria

```

### 3. Processamento de Dados (ETL)

Execute o script de limpeza e montagem do Star Schema:

```
python -m src.montar_tabelas

```

*Os arquivos CSV limpos serão gerados na pasta `data/processed/`.*

### 4. Carga do Banco de Dados MySQL

Execute o script de criação de DDL e carga batch:

```
python -m src.carregar

```

*O script executará `sql/01_criar_banco.sql`, criará o schema e fará a inserção em lote com conferência automática de contagens.*

### 5. Execução de Consultas Analíticas SQL

As consultas analíticas estão salvas em `sql/02_perguntas.sql` e podem ser executadas no MySQL Workbench ou via extensão MySQL do VS Code.

### 6. Execução do Dashboard no Power BI

1. Abra o Power BI Desktop.

2. Conecte no banco MySQL `pncp_controladoria` em modo **Importar**.

3. Abra o arquivo `powerbi/dashboard_pncp.pbix` para visualizar o relatório executivo interativo.

## 📅 Planejamento e Acompanhamento de Sprints

O desenvolvimento do projeto seguiu a metodologia ágil dividida em Sprints focadas:

## 👨‍💻 Autor e Licença

Desenvolvido como projeto avaliativo de Ciência e Análise de Dados.
Licenciado sob a [MIT License](LICENSE).