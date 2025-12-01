--SUMATIVA 2--
--Wilangely Diaz--
--Analista programador computacional - Consultas en SQL--

--CASO 1--

SELECT
v.id_profesional    AS id_profesional,
p.appaterno || ' ' || p.apmaterno || ', ' || INITCAP (p.nombre)     AS nombre_completo,
NVL (pb.num_asesorias_banca, 0) AS  nro_asesorias_banca,
NVL (pb.monto_banca, 0)     AS  monto_total_banca,
NVL (pr.num_asesorias_retail, 0)    AS nro_asesorias_retail,
NVL (pr.monto_retail, 0)    AS monto_total_retail,
NVL (pb.num_asesorias_banca, 0) + NVL (pr.num_asesorias_retail, 0)  AS total_asesorias,
NVL (pb.monto_banca, 0) + NVL (pr.monto_retail, 0)  AS total_honorarios
FROM 
(SELECT 
id_profesional 
FROM 
( SELECT a.id_profesional, 3    AS cod_sector
FROM asesoria a
JOIN empresa e
ON a.cod_empresa = e.cod_empresa
WHERE e.cod_sector = 3

UNION

SELECT a.id_profesional, 4  AS cod_sector
FROM asesoria a
JOIN empresa e
ON a.cod_empresa = e.cod_empresa
WHERE e.cod_sector = 4 ) x
GROUP BY id_profesional
HAVING COUNT(DISTINCT cod_sector) = 2 ) v
JOIN profesional p
ON p.id_profesional = v.id_profesional
LEFT JOIN 
(
SELECT
a.id_profesional,
COUNT(*)          AS num_asesorias_banca,
SUM(a.honorario)  AS monto_banca
FROM asesoria a
JOIN empresa e
ON a.cod_empresa = e.cod_empresa
WHERE e.cod_sector = 3
GROUP BY a.id_profesional
) pb
  ON pb.id_profesional = v.id_profesional

LEFT JOIN
( SELECT
a.id_profesional,
COUNT(*)    AS num_asesorias_retail,
SUM(a.honorario)    AS monto_retail
FROM asesoria a
JOIN empresa e
ON a.cod_empresa = e.cod_empresa
WHERE e.cod_sector = 4
GROUP BY a.id_profesional ) pr
ON pr.id_profesional = v.id_profesional
ORDER BY v.id_profesional;










--CASO 2--

CREATE TABLE REPORTE_MES (
id_profesional              NUMBER (10),
nombre_completo             VARCHAR(60),
nombre_profesion            VARCHAR(40),
comuna_residencia           VARCHAR(40),
nro_asesorias               NUMBER(5),
monto_total_honorarios      NUMBER(12,2),
honorario_promedio          NUMBER(12,2),
honorario_minimo            NUMBER(12,2),
honorario_maximo            NUMBER(12,2)
);

INSERT INTO REPORTE_MES (
    id_profesional,
    nombre_completo,
    nombre_profesion,
    comuna_residencia,
    nro_asesorias,
    monto_total_honorarios,
    honorario_promedio,
    honorario_minimo,
    honorario_maximo
)

SELECT
p.id_profesional        AS id_profesional,
p.appaterno || ' ' || p.apmaterno || ', ' || INITCAP (p.nombre)     AS nombre_completo,
pr.nombre_profesion     AS nombre_profesion,
NVL (c.nom_comuna, 'SIN INFORMACION')   AS comuna_residencia,
COUNT(*)    AS nro_asesorias,
ROUND(SUM(a.honorario),0)       AS monto_total_honorario,
ROUND(AVG(a.honorario), 0)      AS honorario_promedio,
ROUND(MIN(a.honorario),0)       AS honorario_minimo,
ROUND(MAX(a.honorario), 0)      AS honorario_maximo
FROM profesional p
JOIN asesoria a 
ON a.id_profesional = p.id_profesional
JOIN profesion pr
ON pr.cod_profesion = p.cod_profesion
LEFT JOIN comuna c 
ON c.cod_comuna = p.cod_comuna
WHERE a.fin_asesoria >= ADD_MONTHS(TRUNC(ADD_MONTHS(SYSDATE, -12), 'YEAR'), 3)
AND a.fin_asesoria < ADD_MONTHS(ADD_MONTHS(TRUNC(ADD_MONTHS(SYSDATE, -12), 'YEAR'), 3), 1)
GROUP BY
p.id_profesional,
p.appaterno,
p.apmaterno,
p.nombre,
pr.nombre_profesion,
NVL(c.nom_comuna, 'SIN INFORMACION');


COMMIT;

SELECT *
FROM REPORTE_MES
ORDER BY id_profesional;










--CASO 3--

SELECT
p.id_profesional        AS id_profesional,
p.appaterno || ' ' || p.apmaterno || ', ' || INITCAP (p.nombre)     AS nombre_profesional,
ROUND(NVL(SUM(a.honorario),0),0)        AS total_honorarios_marzo,
p.sueldo    AS sueldo_actual
FROM profesional p
JOIN asesoria a 
ON a.id_profesional = p.id_profesional
WHERE a.fin_asesoria >= ADD_MONTHS(TRUNC(ADD_MONTHS(SYSDATE,-12),'YEAR'), 2)
AND a.fin_asesoria <  ADD_MONTHS(TRUNC(ADD_MONTHS(SYSDATE,-12),'YEAR'), 3)
GROUP BY
p.id_profesional,
p.appaterno,
p.apmaterno,
p.nombre,
p.sueldo
ORDER BY
p.id_profesional;


UPDATE profesional p
SET sueldo = 
(
SELECT ROUND(
    CASE
    WHEN NVL(SUM(a.honorario), 0) <1000000
    THEN p.sueldo * 1.10
    ELSE p.sueldo * 1.15
    END
    )
FROM asesoria a 
WHERE a.id_profesional = p.id_profesional
AND a.fin_asesoria  >= ADD_MONTHS(TRUNC(ADD_MONTHS(SYSDATE,-12),'YEAR'), 2)
AND a.fin_asesoria <  ADD_MONTHS(TRUNC(ADD_MONTHS(SYSDATE,-12),'YEAR'), 3)
)
WHERE EXISTS (
SELECT 1
FROM asesoria a 
WHERE a.id_profesional = p.id_profesional
AND a.fin_asesoria >= ADD_MONTHS(TRUNC(ADD_MONTHS(SYSDATE,-12),'YEAR'), 2)
AND a.fin_asesoria <  ADD_MONTHS(TRUNC(ADD_MONTHS(SYSDATE,-12),'YEAR'), 3)
);
COMMIT;


SELECT
p.id_profesional    AS id_profesional,
p.appaterno || ' ' || p.apmaterno || ', ' || INITCAP (p.nombre)  AS  nombre_profesional,
ROUND(NVL(SUM(a.honorario),0),0)        AS total_honorarios_marzo,
p.sueldo        AS sueldo_actual
FROM profesional p
JOIN asesoria a 
ON a.id_profesional = p.id_profesional
WHERE a.fin_asesoria >= ADD_MONTHS(TRUNC(ADD_MONTHS(SYSDATE,-12),'YEAR'), 2)
AND a.fin_asesoria <  ADD_MONTHS(TRUNC(ADD_MONTHS(SYSDATE,-12),'YEAR'), 3)
GROUP BY
p.id_profesional,
p.appaterno,
p.apmaterno,
p.nombre,
p.sueldo
ORDER BY
p.id_profesional;
