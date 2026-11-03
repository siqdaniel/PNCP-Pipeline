-- ============================================================================
-- CONSULTAS DE NEGÓCIO DA CONTROLADORIA (sql/02_perguntas.sql)
-- Projeto: PNCP - Controladoria Geral / Análise de Compras Públicas 2025
-- ============================================================================

USE pncp_controladoria;

-- ============================================================================
-- PERGUNTAS 1: Economia global do Poder Público
-- Qual é o percentual e o valor financeiro nominal economizado pelo governo 
-- (diferença entre valor estimado e valor homologado)?
-- ============================================================================
SELECT 
    SUM(CASE WHEN comparavel = 1 THEN valor_total_estimado ELSE 0 END) AS valor_estimado_comparavel,
    SUM(valor_total_homologado) AS volume_homologado,
    SUM(economia_valor) AS economia_nominal,
    ROUND(
        (SUM(economia_valor) / 
        NULLIF(SUM(CASE WHEN comparavel = 1 THEN valor_total_estimado ELSE 0 END), 0)) * 100, 2
    ) AS economia_percentual
FROM fato_item_contratado;


-- ============================================================================
-- PERGUNTAS 2: Concentração e risco de fornecedores
-- Quem são os maiores fornecedores em volume financeiro e qual percentual 
-- do orçamento público está concentrado neles?
-- ============================================================================
WITH total_geral AS (
    SELECT SUM(valor_total_homologado) AS volume_total FROM fato_item_contratado
),
fornecedores_volume AS (
    SELECT 
        f.ni_fornecedor,
        f.nome_fornecedor,
        SUM(t.valor_total_homologado) AS volume_fornecedor
    FROM fato_item_contratado t
    JOIN dim_fornecedor f ON t.sk_fornecedor = f.sk_fornecedor
    GROUP BY f.ni_fornecedor, f.nome_fornecedor
)
SELECT 
    fv.ni_fornecedor,
    fv.nome_fornecedor,
    fv.volume_fornecedor,
    ROUND((fv.volume_fornecedor / NULLIF(tg.volume_total, 0)) * 100, 4) AS participacao_percentual
FROM fornecedores_volume fv
CROSS JOIN total_geral tg
ORDER BY fv.volume_fornecedor DESC
LIMIT 10;


-- ============================================================================
-- PERGUNTAS 3: Eficácia por modalidade
-- Quais modalidades licitatórias trazem maior deságio/economia e quais 
-- concentram o maior volume de recursos?
-- ============================================================================
SELECT 
    m.modalidade_id,
    m.nome_modalidade,
    SUM(t.valor_total_homologado) AS volume_homologado,
    SUM(CASE WHEN t.comparavel = 1 THEN t.valor_total_estimado ELSE 0 END) AS estimado_comparavel,
    SUM(CASE WHEN t.comparavel = 1 THEN t.economia_valor ELSE 0 END) AS economia_valor,
    ROUND(
        (SUM(CASE WHEN t.comparavel = 1 THEN t.economia_valor ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN t.comparavel = 1 THEN t.valor_total_estimado ELSE 0 END), 0)) * 100, 2
    ) AS desagio_percentual,
    ROUND(
        (SUM(t.valor_total_homologado) / 
        NULLIF((SELECT SUM(valor_total_homologado) FROM fato_item_contratado), 0)) * 100, 2
    ) AS participacao_volume_percentual
FROM fato_item_contratado t
JOIN dim_modalidade m ON t.sk_modalidade = m.sk_modalidade
GROUP BY m.modalidade_id, m.nome_modalidade
ORDER BY volume_homologado DESC;


-- ============================================================================
-- PERGUNTAS 4: Tempo do ciclo de compras
-- Qual a duração média (em dias) entre o lançamento do edital e a sua 
-- homologação final, segmentada por órgão? (Filtro: órgãos com 5+ itens com ciclo)
-- ============================================================================
SELECT 
    o.nome_orgao,
    COUNT(t.dias_ciclo) AS itens_com_ciclo,
    ROUND(AVG(t.dias_ciclo), 1) AS ciclo_medio_dias,
    MAX(t.dias_ciclo) AS ciclo_maximo_dias
FROM fato_item_contratado t
JOIN dim_orgao o ON t.sk_orgao = o.sk_orgao
WHERE t.dias_ciclo IS NOT NULL
GROUP BY o.nome_orgao
HAVING COUNT(t.dias_ciclo) >= 5
ORDER BY ciclo_medio_dias DESC;


-- ============================================================================
-- PERGUNTAS 5: Distribuição regional
-- Quais estados e regiões concentram as maiores despesas e quais apresentam 
-- os melhores indicadores de desconto?
-- ============================================================================
SELECT 
    l.regiao,
    l.uf_sigla,
    l.uf_nome,
    COUNT(DISTINCT o.cnpj_orgao) AS qtd_unidades_compradoras,
    SUM(t.valor_total_homologado) AS volume_homologado,
    ROUND(
        (SUM(CASE WHEN t.comparavel = 1 THEN t.economia_valor ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN t.comparavel = 1 THEN t.valor_total_estimado ELSE 0 END), 0)) * 100, 2
    ) AS desagio_percentual
FROM fato_item_contratado t
JOIN dim_localidade l ON t.sk_localidade = l.sk_localidade
JOIN dim_orgao o ON t.sk_orgao = o.sk_orgao
GROUP BY l.regiao, l.uf_sigla, l.uf_nome
ORDER BY volume_homologado DESC;


-- ============================================================================
-- PERGUNTAS 6: Perfil dos gastos
-- Como os recursos se distribuem entre bens, serviços e obras e engenharia?
-- ============================================================================
SELECT 
    t.perfil_gasto,
    COUNT(*) AS quantidade_itens,
    SUM(t.valor_total_homologado) AS volume_homologado,
    ROUND(
        (SUM(t.valor_total_homologado) / 
        NULLIF((SELECT SUM(valor_total_homologado) FROM fato_item_contratado), 0)) * 100, 2
    ) AS participacao_percentual,
    ROUND(SUM(t.valor_total_homologado) / NULLIF(COUNT(*), 0), 2) AS ticket_medio_item
FROM fato_item_contratado t
GROUP BY t.perfil_gasto
ORDER BY volume_homologado DESC;