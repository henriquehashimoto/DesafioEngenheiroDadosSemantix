-- VISUALIZANDO TABELAS COM OS DADOS FORNECIDOS

SELECT TOP 100 * FROM staging.[dbo].[access_log_Aug95]
SELECT TOP 100 * FROM staging.[dbo].[access_log_Jul95]
SELECT COUNT(*) FROM staging.[dbo].[access_log_Aug95]
SELECT COUNT(*) FROM staging.[dbo].[access_log_Jul95]

SELECT TOP 100 * FROM dw..predict_client



--==================================================== 
-- UNINDO OS DOIS ARQUIVOS DE LOGS
--==================================================== 
IF OBJECT_ID ('TEMPDB..#Logs') IS NOT NULL
	DROP TABLE #Logs
SELECT
	coluna1 AS Request
INTO
	#Logs
FROM
	staging.[dbo].[access_log_Aug95] AS AUG
UNION ALL
	(SELECT * FROM staging.[dbo].[access_log_Jul95] AS JUL)
--(3.461.612 rows affected) TOTAL DE LINHAS APÓS UNION
	

--==================================================== 
-- TABELA TEMP COM INFORMAÇÃO DO HOST E OS ULTIMOS CARACTERES (PARA CLASSIFICAR SE É OU NÃO ERRO 404)
--====================================================
IF OBJECT_ID ('tempdb..#HostsError') IS NOT NULL
	DROP TABLE #HostsError
SELECT
	LEFT(Request, charindex(' - - ', Request) ) AS Host,
	RIGHT(Request,5) AS 'Error404',
	Request
INTO
	#HostsError
FROM
	#Logs


-- CONTANDO QUANTOS HOSTS DISTINTOS
SELECT 
	COUNT(DISTINCT Host) 
FROM 
	#HostsError
--TOTAL: 137979


--==================================================== 
-- ERROR 404
--==================================================== 
SELECT TOP 1000 * FROM #HostsError WHERE SUBSTRING(Error404,1,3) = '404'

SELECT 
	COUNT(*) 
FROM 
	#HostsError 
WHERE	
	SUBSTRING(Error404,1,4) = '404 ' -- É CONTADO O QUE POSSUI 404 + ESPAÇO POIS EXISTE OUTROS ERROS QUE POSSUEM 404+NUMEROS, O QUE SERIA 
									 -- OUTROS ERROS, POR EXEMPLO, ESTARIA SELECIONANDO O ERRO 40458. QUE É DIFERENTE DO QUE QUEREMOS
--TOTAL: 20901



--==================================================== 
-- URL COM MAIS ERROS 404
--==================================================== 
SELECT TOP 5
	Host,
	COUNT(*) AS TotalErrors404
FROM 
	#HostsError
WHERE
	SUBSTRING(Error404,1,4) = '404 ' 
GROUP BY
	Host
ORDER BY 2 DESC

--Host                                     TotalErrors404
------------------------------------------ --------------
--hoohoo.ncsa.uiuc.edu                     251
--piweba3y.prodigy.com                     157
--jbiagioni.npt.nuwc.navy.mil              132
--piweba1y.prodigy.com                     114
--www-d4.proxy.aol.com                     91


--==================================================== 
-- DIAS COM MAIS ERROS DE 404
--==================================================== 
SELECT TOP 1000 * FROM #HostsError


SELECT 
	SUBSTRING(Request,(charindex('[', Request)+1),11) AS DataError404, --SUBSTRING PARA PEGAR APENAS A INFORMAÇÃO DE DATA DE CADA REQUEST
	COUNT(*) AS TotalErros
FROM 
	#HostsError
WHERE
	SUBSTRING(Error404,1,4) = '404 ' 
GROUP BY SUBSTRING(Request,(charindex('[', Request)+1),11)
ORDER BY 2 DESC


--DataError404 TotalErros
-------------- -----------
--06/Jul/1995  640
--19/Jul/1995  639
--30/Aug/1995  571


--==================================================== 
--O total de bytes retornados.
--==================================================== 
--VERIFICANDO O TOTAL DOS DOIS ARQUIVOS
SELECT 
    t.NAME AS TableName,
    s.Name AS SchemaName,
    p.rows AS RowCounts,
    SUM(a.total_pages) * 8 AS TotalSpaceKB, 
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS TotalSpaceMB,
    SUM(a.used_pages) * 8 AS UsedSpaceKB, 
    CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS UsedSpaceMB, 
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB,
    CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS UnusedSpaceMB
FROM 
    sys.tables t
INNER JOIN      
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    t.NAME NOT LIKE 'dt%' 
    AND t.is_ms_shipped = 0
    AND i.OBJECT_ID > 255 
	AND T.name IN ('access_log_Aug95', 'access_log_Jul95')
GROUP BY 
    t.Name, s.Name, p.Rows
ORDER BY 
    t.Name


--TableName                SchemaName    RowCounts            TotalSpaceKB         TotalSpaceMB    UsedSpaceKB          UsedSpaceMB     UnusedSpaceKB        UnusedSpaceMB
-------------------------- ------------- -------------------- -------------------- --------------- -------------------- --------------- -------------------- -----------------------
--access_log_Aug95         dbo           1569897              256344               250.34          224296               219.04          32048                31.30
--access_log_Jul95         dbo           1891715              308896               301.66          270280               263.95          38616                37.71
