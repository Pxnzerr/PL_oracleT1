-- ============================================================================
-- Exemplos práticos de uso e verificação dos triggers de auditoria/formatação
-- Pré-requisito: executar antes o script principal `trigger_estudo.sql`
-- ============================================================================
SET SERVEROUTPUT ON;
-- 1. Exemplo de formatação automática de nome (espaços extras e letras minúsculas)
INSERT INTO funcionarios (id, nome, cargo, salario)
VALUES (
        10,
        '   mariana costa   ',
        'Engenheira de Software',
        7000.00
    );
-- 2. Atualização de cargo SEM alteração de salário:
--    O trigger `trg_audita_salario` NÃO deve registrar nova entrada em `log_salarios`.
UPDATE funcionarios
SET cargo = 'Engenheira de Software Senior'
WHERE id = 10;
ç -- 3. Atualização de nome e salário simultaneamente:
--    Deve formatar o nome em maiúsculas e registrar a variação salarial no log.
UPDATE funcionarios
SET nome = '  mariana costa almeida  ',
    salario = 8400.00
WHERE id = 10;
COMMIT;
-- 4. Bloco anônimo de validação dos comportamentos esperados
DECLARE v_nome_salvo funcionarios.nome %TYPE;
v_total_logs_id10 NUMBER;
BEGIN
SELECT nome INTO v_nome_salvo
FROM funcionarios
WHERE id = 10;
SELECT COUNT(*) INTO v_total_logs_id10
FROM log_salarios
WHERE id_funcionario = 10;
IF v_nome_salvo = 'MARIANA COSTA ALMEIDA' THEN DBMS_OUTPUT.PUT_LINE(
    '[OK] Trigger trg_formata_nome_func formatou o nome corretamente.'
);
ELSE DBMS_OUTPUT.PUT_LINE('[ERRO] Nome inesperado: ' || v_nome_salvo);
END IF;
IF v_total_logs_id10 = 1 THEN DBMS_OUTPUT.PUT_LINE(
    '[OK] Trigger trg_audita_salario registrou apenas a alteracao salarial.'
);
ELSE DBMS_OUTPUT.PUT_LINE(
    '[ERRO] Quantidade de logs esperada = 1, obtida = ' || v_total_logs_id10
);
END IF;
END;
/ -- 5. Consulta analítica de exemplo: histórico de reajustes com percentual de aumento
SELECT f.id,
    f.nome,
    l.salario_antigo,
    l.salario_novo,
    ROUND(
        (
            (l.salario_novo - l.salario_antigo) / l.salario_antigo
        ) * 100,
        2
    ) AS percentual_reajuste,
    l.data_alteracao,
    l.usuario
FROM funcionarios f
    JOIN log_salarios l ON l.id_funcionario = f.id
ORDER BY l.data_alteracao DESC;