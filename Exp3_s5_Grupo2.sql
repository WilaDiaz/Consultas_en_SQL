--FORMATIVA 3--
--CASO 1--
-- LISTADO DE CLIENTES--

SELECT
REPLACE(TO_CHAR(c.numrun, '99G999G999'), ',' , '.') || '-' || c.dvrun AS "RUT CLIENTE",
INITCAP (c.pnombre || ' ' || c.snombre || ' ' || c.appaterno || ' ' || c.apmaterno ) AS "Nombre Cliente",
UPPER (p.nombre_prof_ofic) AS "Profesion",
EXTRACT (YEAR FROM c.fecha_inscripcion) AS "Año Inscripcion"
FROM cliente c
JOIN profesion_oficio p
ON c.cod_prof_ofic = p.cod_prof_ofic
JOIN tipo_cliente tc
ON c.cod_tipo_cliente = tc.cod_tipo_cliente
WHERE
UPPER (tc.nombre_tipo_cliente) = 'TRABAJADORES DEPENDIENTES'
AND UPPER (p.nombre_prof_ofic) IN ('CONTADOR' , 'VENDEDOR')
AND EXTRACT (YEAR FROM c.fecha_inscripcion) >
(SELECT ROUND (AVG(EXTRACT(YEAR FROM c2.fecha_inscripcion))) 
FROM cliente c2)
ORDER BY
"RUT CLIENTE" ASC;



--CASO 2--
--AUMENTO DE CUPO--



SELECT
REPLACE(TO_CHAR(c.numrun, '99G999G999'), ',' , '.') || '-' || c.dvrun AS "RUT CLIENTE",
EXTRACT (YEAR FROM SYSDATE) - EXTRACT (YEAR FROM c.fecha_nacimiento) AS "Edad Cliente",
TO_CHAR (tc.cupo_disp_compra, 'L999G999G999' , 'NLS_CURRENCY=$') AS "Cupo Disponible"
FROM cliente c
JOIN tarjeta_cliente tc
ON c.numrun = tc.numrun
WHERE  
tc.cupo_disp_compra >= (
SELECT MAX (tc2.cupo_disp_compra)
FROM tarjeta_cliente tc2
WHERE EXTRACT (YEAR FROM tc2.fecha_solic_tarjeta) = EXTRACT(YEAR FROM SYSDATE) -1
)
ORDER BY "Edad Cliente" ASC;


---creacion de tabla clientes_cupo_compra---

CREATE TABLE CLIENTES_CUPOS_COMPRA AS 
SELECT
c.numrun AS numrun,
c.dvrun AS dvrun,
EXTRACT (YEAR FROM SYSDATE) - EXTRACT (YEAR FROM c.fecha_nacimiento) AS edad_cliente,
tc.cupo_disp_compra AS cupo_disp_compra
FROM cliente c 
JOIN tarjeta_cliente tc 
ON c.numrun = tc.numrun
WHERE
tc.cupo_disp_compra >= (
SELECT MAX(tc2.cupo_disp_compra)
FROM tarjeta_cliente tc2
WHERE EXTRACT(YEAR FROM tc2.fecha_solic_tarjeta) = EXTRACT(YEAR FROM SYSDATE) - 1
);


SELECT
REPLACE(TO_CHAR(numrun, '99G999G999'), ',' , '.') || '-' || dvrun AS "RUT CLIENTE",
edad_cliente AS "Edad Cliente",
TO_CHAR(cupo_disp_compra,'L999G999G999', 'NLS_CURRENCY=$') AS "Cupo Disponible"
FROM CLIENTES_CUPOS_COMPRA
ORDER BY edad_cliente ASC;


SELECT * FROM clientes_cupos_compra;
