-- ============================================================================
-- SCRIPT DE CRIAÇÃO DO BANCO DE DADOS E TABELAS (STAR SCHEMA)
-- Projeto: PNCP - Controladoria Geral / Análise de Compras Públicas 2025
-- ============================================================================

CREATE DATABASE IF NOT EXISTS pncp_controladoria
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE pncp_controladoria;

-- Limpeza preventiva de tabelas (ordem inversa das dependências)
DROP TABLE IF EXISTS fato_item_contratado;
DROP TABLE IF EXISTS dim_orgao;
DROP TABLE IF EXISTS dim_fornecedor;
DROP TABLE IF EXISTS dim_modalidade;
DROP TABLE IF EXISTS dim_localidade;

-- ============================================================================
-- 1. DIMENSÃO ÓRGÃO (quem comprou)
-- ============================================================================
CREATE TABLE dim_orgao (
    sk_orgao INT NOT NULL,
    cnpj_orgao VARCHAR(14) NOT NULL,
    nome_orgao VARCHAR(255) NOT NULL,
    poder VARCHAR(20) NOT NULL DEFAULT 'Não informado',
    PRIMARY KEY (sk_orgao),
    UNIQUE KEY uk_orgao_cnpj (cnpj_orgao)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 2. DIMENSÃO FORNECEDOR (quem vendeu)
-- ============================================================================
CREATE TABLE dim_fornecedor (
    sk_fornecedor INT NOT NULL,
    ni_fornecedor VARCHAR(20) NOT NULL,
    nome_fornecedor VARCHAR(255) NULL,
    tipo_pessoa VARCHAR(5) NULL,
    porte VARCHAR(50) NULL,
    PRIMARY KEY (sk_fornecedor),
    UNIQUE KEY uk_fornecedor_ni (ni_fornecedor)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 3. DIMENSÃO MODALIDADE (como comprou)
-- ============================================================================
CREATE TABLE dim_modalidade (
    sk_modalidade INT NOT NULL,
    modalidade_id INT NOT NULL,
    nome_modalidade VARCHAR(100) NOT NULL,
    PRIMARY KEY (sk_modalidade),
    UNIQUE KEY uk_modalidade_id (modalidade_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 4. DIMENSÃO LOCALIDADE (onde comprou)
-- ============================================================================
CREATE TABLE dim_localidade (
    sk_localidade INT NOT NULL,
    uf_sigla VARCHAR(2) NOT NULL,
    uf_nome VARCHAR(50) NULL,
    regiao VARCHAR(20) NOT NULL,
    PRIMARY KEY (sk_localidade),
    UNIQUE KEY uk_localidade_uf (uf_sigla)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insere o registro de exceção para FKs não encontradas (SK = -1) em cada dimensão
INSERT INTO dim_orgao (sk_orgao, cnpj_orgao, nome_orgao, poder)
VALUES (-1, '00000000000000', 'Não informado', 'Não informado');

INSERT INTO dim_fornecedor (sk_fornecedor, ni_fornecedor, nome_fornecedor, tipo_pessoa, porte)
VALUES (-1, '00000000000000', 'Não informado', 'NI', 'Não informado');

INSERT INTO dim_modalidade (sk_modalidade, modalidade_id, nome_modalidade)
VALUES (-1, -1, 'Não informado');

INSERT INTO dim_localidade (sk_localidade, uf_sigla, uf_nome, regiao)
VALUES (-1, 'NI', 'Não informado', 'Não informado');

-- ============================================================================
-- 5. TABELA FATO ITEM CONTRATADO (o que foi comprado)
-- ============================================================================
CREATE TABLE fato_item_contratado (
    sk_fato INT AUTO_INCREMENT NOT NULL,
    numero_controle_pncp VARCHAR(50) NOT NULL,
    numero_item INT NOT NULL,
    sk_orgao INT NOT NULL,
    sk_fornecedor INT NOT NULL,
    sk_modalidade INT NOT NULL,
    sk_localidade INT NOT NULL,
    data_publicacao DATE NOT NULL,
    data_homologacao DATE NULL,
    descricao_item TEXT NULL,
    perfil_gasto VARCHAR(50) NOT NULL,
    quantidade DECIMAL(18,4) NOT NULL,
    valor_unitario_estimado DECIMAL(18,4) NOT NULL,
    valor_total_estimado DECIMAL(18,2) NOT NULL,
    valor_unitario_homologado DECIMAL(18,4) NOT NULL,
    valor_total_homologado DECIMAL(18,2) NOT NULL,
    comparavel TINYINT NOT NULL DEFAULT 1,
    economia_valor DECIMAL(18,2) NULL,
    dias_ciclo INT NULL,
    PRIMARY KEY (sk_fato),
    UNIQUE KEY uk_fato_item (numero_controle_pncp, numero_item),
    CONSTRAINT fk_fato_orgao FOREIGN KEY (sk_orgao) REFERENCES dim_orgao (sk_orgao),
    CONSTRAINT fk_fato_fornecedor FOREIGN KEY (sk_fornecedor) REFERENCES dim_fornecedor (sk_fornecedor),
    CONSTRAINT fk_fato_modalidade FOREIGN KEY (sk_modalidade) REFERENCES dim_modalidade (sk_modalidade),
    CONSTRAINT fk_fato_localidade FOREIGN KEY (sk_localidade) REFERENCES dim_localidade (sk_localidade),
    CONSTRAINT chk_fato_quantidade CHECK (quantidade > 0),
    CONSTRAINT chk_fato_vlr_unit_est CHECK (valor_unitario_estimado > 0),
    CONSTRAINT chk_fato_vlr_unit_hom CHECK (valor_unitario_homologado > 0),
    CONSTRAINT chk_fato_vlr_tot_est CHECK (valor_total_estimado >= 0),
    CONSTRAINT chk_fato_vlr_tot_hom CHECK (valor_total_homologado >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;