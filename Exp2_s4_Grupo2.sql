-- ACTIVIDAD SEMANA 4 --

-- Caso 1: Listado de Trabajadores
SELECT 
    REPLACE(TO_CHAR(t.numrut, '99G999G999'), ',', '.') || '-' || t.dvrut AS "RUT",
    INITCAP(t.nombre) || ' ' || INITCAP(t.appaterno) || ' ' || INITCAP(t.apmaterno) AS "Nombre Completo",
    INITCAP(cc.nombre_ciudad) AS "Ciudad",
    TO_CHAR(t.sueldo_base, 'L999G999G999', 'NLS_CURRENCY=$') AS "Sueldo Base",
    INITCAP(tt.desc_categoria) AS "Categoria"
FROM trabajador t
INNER JOIN comuna_ciudad cc ON t.id_ciudad = cc.id_ciudad
INNER JOIN tipo_trabajador tt ON t.id_categoria_t = tt.id_categoria
WHERE t.sueldo_base BETWEEN 650000 AND 3000000
ORDER BY cc.nombre_ciudad DESC, t.sueldo_base ASC;

-- Caso 2: Listado Cajeros
SELECT 
    REPLACE(TO_CHAR(t.numrut, '99G999G999'), ',', '.') || '-' || t.dvrut AS "RUT trabajador",
    INITCAP(t.nombre) || ' ' || INITCAP(t.appaterno) AS "Nombre Trabajador",
    COUNT(tc.nro_ticket) AS "total Tickets",
    TO_CHAR(SUM(tc.monto_ticket), 'L999G999G999', 'NLS_CURRENCY=$') AS "Total Vendido",
    TO_CHAR(SUM(ct.valor_comision), 'L999G999G999', 'NLS_CURRENCY=$') AS "Comision Total",
    INITCAP(cc.nombre_ciudad) AS "Ciudad Trabajador"
FROM trabajador t
INNER JOIN comuna_ciudad cc ON t.id_ciudad = cc.id_ciudad
INNER JOIN tipo_trabajador tt ON t.id_categoria_t = tt.id_categoria
INNER JOIN tickets_concierto tc ON t.numrut = tc.numrut_t
INNER JOIN comisiones_ticket ct ON tc.nro_ticket = ct.nro_ticket
WHERE UPPER(tt.desc_categoria) = 'CAJERO'
GROUP BY t.numrut, t.dvrut, t.nombre, t.appaterno, cc.nombre_ciudad
HAVING SUM(tc.monto_ticket) > 50000
ORDER BY SUM(tc.monto_ticket) DESC;

-- Caso 3: Listado de Bonificaciones
SELECT 
    REPLACE(TO_CHAR(t.numrut, '99G999G999'), ',', '.') || '-' || t.dvrut AS "RUT trabajador",
    INITCAP(t.nombre) || ' ' || INITCAP(t.appaterno) AS "Nombre Trabajador",
    EXTRACT(YEAR FROM t.fecing) AS "Año Ingreso",
    EXTRACT (YEAR FROM SYSDATE)- EXTRACT (YEAR FROM t.fecing) AS "Años de antiguedad",
    CASE
    WHEN COUNT (af.numrut_carga) = 0 THEN 'SIN CARGAS'
    ELSE TO_CHAR (COUNT(af.numrut_carga)) END AS "Num. Cargas Familiares",
    i.nombre_isapre AS "Nombre Isapre",
    CASE 
        WHEN UPPER(i.nombre_isapre) = 'FONASA' THEN TO_CHAR(ROUND(t.sueldo_base * 0.01), 'L999G999G999', 'NLS_CURRENCY=$')
        ELSE 'SIN BONO'
    END AS "Bono Salud",
    CASE 
        WHEN (EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM t.fecing)) <= 10 THEN TO_CHAR(ROUND(t.sueldo_base * 0.10), 'L999G999G999', 'NLS_CURRENCY=$')
        ELSE TO_CHAR(ROUND(t.sueldo_base * 0.15), 'L999G999G999', 'NLS_CURRENCY=$')
    END AS "Bono Antiguedad"
FROM trabajador t
INNER JOIN isapre i ON t.cod_isapre = i.cod_isapre
INNER JOIN est_civil ec ON t.numrut = ec.numrut_t
LEFT JOIN asignacion_familiar af ON t.numrut = af.numrut_t
WHERE ec.fecter_estcivil IS NULL OR ec.fecter_estcivil > SYSDATE
GROUP BY t.numrut, t.dvrut, t.nombre, t.appaterno, t.fecing, t.sueldo_base, i.nombre_isapre
ORDER BY t.numrut ASC;



