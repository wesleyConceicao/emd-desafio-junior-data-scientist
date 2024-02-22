--1 Quantos chamados foram abertos no dia 01/04/2023?
SELECT COUNT(*) AS Quantidade_de_chamados
FROM datario.administracao_servicos_publicos.chamado_1746
WHERE DATE(data_inicio) = DATE('2023-04-01');
/*RESPOSTA: Os numeros de chamados abertos no dia 01-04-2023 foram 73 casos*/

--2 Qual o tipo de chamado que teve mais teve chamados abertos no dia 01/04/2023?
SELECT chmd.tipo, COUNT(chmd.tipo) AS numero_chamados
FROM datario.administracao_servicos_publicos.chamado_1746 chmd
WHERE DATE(data_inicio) = DATE('2023-04-01') 
GROUP BY (chmd.tipo) ORDER BY (numero_chamados) DESC;
/*RESPOSTA: Poluição sonora com 24 chamados */

-- 3 Quais os nomes dos 3 bairros que mais tiveram chamados abertos nesse dia?
SELECT br.nome AS bairro, COUNT(br.nome) AS numero_chamados
FROM datario.administracao_servicos_publicos.chamado_1746 chmd 
INNER JOIN datario.dados_mestres.bairro br ON br.id_bairro = chmd.id_bairro
WHERE DATE(data_inicio) = DATE('2023-04-01')  
GROUP BY (br.nome) ORDER BY (numero_chamados) DESC;
/*
RESPOSTA: 
Engenho de Dentro: 8
Campo Grande: 6
Leblon: 6
*/

--4 Qual o nome da subprefeitura com mais chamados abertos nesse dia?
SELECT br.subprefeitura AS subprefeitura, COUNT(br.subprefeitura) AS numero_chamados
FROM datario.administracao_servicos_publicos.chamado_1746 chmd 
INNER JOIN datario.dados_mestres.bairro br ON br.id_bairro = chmd.id_bairro
WHERE  DATE(data_inicio) = DATE('2023-04-01')  
GROUP BY (br.subprefeitura) ORDER BY (numero_chamados) DESC;
/*RESPOSTA: Zona Norte com 25 chamados */

--5 Existe algum chamado aberto nesse dia que não foi associado a um bairro ou subprefeitura na tabela de bairros? Se sim, por que isso acontece?
SELECT chmd.id_chamado, chmd.id_bairro, chmd.data_inicio, chmd.tipo, chmd.subtipo, br.nome,br.subprefeitura
FROM datario.administracao_servicos_publicos.chamado_1746 chmd
LEFT JOIN datario.dados_mestres.bairro br ON chmd.id_bairro = br.id_bairro
WHERE (br.nome IS NULL OR br.subprefeitura IS NULL) AND DATE(chmd.data_inicio) = DATE('2023-04-01'); 
/*RESPOSTA: como era um onibus e se tratava de um problema de ar condicionado por isso a localização exata não ficou registrada*/

--6 Quantos chamados com o subtipo "Perturbação do sossego" foram abertos desde 01/01/2022 até 31/12/2023 (incluindo extremidades)?
SELECT chmd.tipo, chmd.subtipo, COUNT(chmd.tipo) AS numero_chamados
FROM datario.administracao_servicos_publicos.chamado_1746 chmd
WHERE chmd.subtipo = 'Perturbação do sossego' AND chmd.data_inicio BETWEEN '2022-01-01' AND '2023-12-31' 
GROUP BY chmd.tipo, chmd.subtipo ORDER BY numero_chamados DESC;
/* RESPOSTA: Os numeros de chamados abertos com o subtipo "Perturbação do sossego" desde 01/01/2022 até 31/12/2023 foram de 42408 casos */

--7 Selecione os chamados com esse subtipo que foram abertos durante os eventos contidos na tabela de eventos (Reveillon, Carnaval e Rock in Rio).
SELECT chmd.tipo, chmd.subtipo, htl.evento
FROM datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos htl
INNER JOIN datario.administracao_servicos_publicos.chamado_1746 chmd ON DATE(chmd.data_inicio) >= DATE(htl.data_inicial) AND DATE(chmd.data_inicio) <= DATE(htl.data_final) 
WHERE chmd.subtipo = 'Perturbação do sossego' AND chmd.data_inicio BETWEEN '2022-01-01' AND '2023-12-31'

--8 Quantos chamados desse subtipo foram abertos em cada evento?
SELECT chmd.subtipo, htl.evento, COUNT(chmd.subtipo) AS numero_chamados
FROM datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos htl
INNER JOIN datario.administracao_servicos_publicos.chamado_1746 chmd ON DATE(chmd.data_inicio) >= DATE(htl.data_inicial) AND DATE(chmd.data_inicio) <= DATE(htl.data_final) 
WHERE chmd.subtipo = 'Perturbação do sossego' AND chmd.data_inicio BETWEEN '2022-01-01' AND '2023-12-31' 
GROUP BY chmd.subtipo, htl.evento ORDER BY numero_chamados DESC;
/*
RESPOSTA
Rock in Rio: 834
Carnaval: 241
Reveillon : 137
*/

--9 Qual evento teve a maior média diária de chamados abertos desse subtipo?
SELECT evento, round(AVG(numero_chamados),2) AS media_chamados
FROM (
    SELECT htl.evento, COUNT(chmd.id_chamado) / (DATE_DIFF(DATE(htl.data_final), DATE(htl.data_inicial), DAY) + 1) AS numero_chamados
    FROM datario.administracao_servicos_publicos.chamado_1746 chmd
    INNER JOIN datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos htl ON DATE(chmd.data_inicio) >= DATE(htl.data_inicial) AND DATE(chmd.data_inicio) <= DATE(htl.data_final) 
    WHERE chmd.subtipo = 'Perturbação do sossego' AND chmd.data_inicio BETWEEN '2022-01-01' AND '2023-12-31'
    GROUP BY htl.evento, htl.data_inicial, htl.data_final)
    AS eventos_chamados GROUP BY evento ORDER BY media_chamados DESC;
/*
RESPOSTA:
Carnaval        60.25
Reveillon       45.67
Rock in Rio    119.14
*/

-- 10 Compare as médias diárias de chamados abertos desse subtipo durante os eventos específicos (Reveillon, Carnaval e Rock in Rio) e a média diária de chamados abertos desse subtipo considerando todo o período de 01/01/2022 até 31/12/2023.
WITH eventos AS (
    SELECT evento, data_inicial, data_final
    FROM datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos 
    WHERE evento IN ('Reveillon', 'Carnaval', 'Rock in Rio')
),
media_eventos AS (
    SELECT evento, round(AVG(numero_chamados),2) AS media_chamados
FROM (
    SELECT htl.evento, COUNT(chmd.id_chamado) / (DATE_DIFF(DATE(htl.data_final), DATE(htl.data_inicial), DAY) + 1) AS numero_chamados
    FROM datario.administracao_servicos_publicos.chamado_1746 chmd
    INNER JOIN datario.turismo_fluxo_visitantes.rede_hoteleira_ocupacao_eventos htl ON DATE(chmd.data_inicio) >= DATE(htl.data_inicial) AND DATE(chmd.data_inicio) <= DATE(htl.data_final) 
    WHERE chmd.subtipo = 'Perturbação do sossego' AND chmd.data_inicio BETWEEN '2022-01-01' AND '2023-12-31'
    GROUP BY htl.evento, htl.data_inicial, htl.data_final)
    AS eventos_chamados
    GROUP BY evento
),
media_total AS (
    SELECT round(AVG(contagem_chamados),2) AS media_diaria_total
    FROM (
        SELECT COUNT(id_chamado) / (DATE_DIFF(DATE('2023-12-31'), DATE('2022-01-01'), DAY) + 1) AS contagem_chamados
        FROM datario.administracao_servicos_publicos.chamado_1746
        WHERE subtipo = 'Perturbação do sossego' AND data_inicio BETWEEN '2022-01-01' AND '2023-12-31'
    )
)
(SELECT 'Reveillon' AS evento, media_chamados, NULL FROM media_eventos WHERE evento = 'Reveillon'
UNION ALL
SELECT 'Carnaval' AS evento, media_chamados, NULL FROM media_eventos WHERE evento = 'Carnaval'
UNION ALL
SELECT 'Rock in Rio' AS evento, media_chamados, NULL FROM media_eventos WHERE evento = 'Rock in Rio'
UNION ALL
SELECT 'Total' AS evento, media_diaria_total, NULL FROM media_total) 
/*
RESPOSTA

tabela com as médias do periodo e total	
Rock in Rio
119.5
----------
Carnaval
60.25
----------
Reveillon
45.67
----------
Total
58.09
----------