/* ---- CASO 1 ---- */
/* ---- ENTREGA FORMATIVA ---- */

SELECT
f.numfactura AS  "N°Factura",
TO_CHAR(f.fecha, 'DD "de" MONTH "de" YYYY', 'NLS_DATE_LANGUAGE=SPANISH') AS "Fecha Emision",
LPAD(TO_CHAR(f.rutcliente), 10, '0') AS "RUT Cliente",
TO_CHAR(ROUND(f.neto, 0), '$99,999,999') AS "Monto Neto",
TO_CHAR(ROUND(f.iva, 0), '$99,999,999') AS "Monto IVA",
TO_CHAR(ROUND(f.total, 0), '$99,999,999') AS "Monto Factura",
CASE
WHEN f.neto BETWEEN 0 AND 50000 THEN 'Bajo'
WHEN f.neto BETWEEN 50001 AND 100000 THEN  'Medio'
ELSE 'Alto'
END AS "Categoria Monto",

CASE f.codpago
WHEN 1 THEN 'EFECTIVO'
WHEN 2 THEN 'TARJETA DEBITO'
WHEN 3 THEN 'TARJETA CREDITO'
ELSE 'CHEQUE'
END AS "Forma de pago"
FROM factura f
WHERE f.fecha >= ADD_MONTHS(TRUNC(SYSDATE,'YYYY'), -12)
AND f.fecha < TRUNC(SYSDATE,'YYYY')
ORDER BY 
f.fecha DESC,
f.neto DESC;

/* ---- CASO 2 ---- */

SELECT
LPAD(TO_CHAR(c.rutcliente), 10, '*') AS "RUT",
c.nombre AS "Cliente",
NVL(TO_CHAR(c.telefono),'Sin telefono') AS "Telefono",
NVL(co.descripcion,'Sin comuna') AS "Comuna",
NVL(c.mail, 'Correo no registrado') AS "Correo",
CASE
WHEN c.mail IS NOT NULL AND INSTR(c.mail,'@') > 0
THEN SUBSTR(c.mail, INSTR(c.mail,'@')+1)
ELSE 'Sin Dominio'
END AS "Dominio correo",
c.credito AS "Credito",
c.saldo AS "Saldo",
CASE
WHEN (c.saldo/c.credito) < 0.5 THEN 'Bueno'
WHEN (c.saldo/c.credito) <= 0.8 THEN 'Regular'
ELSE 'Critico'
END AS "Estado credito",
CASE
WHEN (c.saldo/c.credito) < 0.5 THEN TO_CHAR(ROUND(c.credito - c.saldo, 0), '$999,999,999')
WHEN (c.saldo/c.credito) <= 0.8 THEN TO_CHAR(ROUND(c.saldo, 0), '$999,999,999')
ELSE NULL
END AS "Detalle"
FROM cliente c
LEFT JOIN comuna co ON co.codcomuna = c.codcomuna
WHERE c.estado = 'A'
AND c.credito >0
ORDER BY
c.nombre ASC;



/* ---- CASO 3 ---- */

SELECT
p.codproducto AS "ID",
p.descripcion AS "Descripcion",
NVL(TO_CHAR(p.valorcompradolar,'999G999D999'), 'Sin Registro') AS "Compra USD",
CASE
WHEN p.valorcompradolar IS NOT NULL THEN TO_CHAR(ROUND(p.valorcompradolar * &TIPOCAMBIO_DOLAR, 0),'$999,999,999')
ELSE 'Sin Registro'
END AS "Compra CLP",
p.totalstock AS "Stock",
CASE
WHEN p.totalstock IS NULL THEN 'sin datos'
WHEN p.totalstock < &UMBRAL_BAJO THEN '¡Reabastecer pronto'
WHEN p.totalstock <= &UMBRAL_ALTO THEN '¡ALERTA stock muy bajo!'
ELSE 'OK'
END AS "Alerta",

TO_CHAR(p.vunitario,'$999,999,999') AS "Valor Unitario",
CASE
WHEN p.totalstock > 80 THEN TO_CHAR(ROUND(p.vunitario * 0.10, 0), '$999,999,999')
ELSE TO_CHAR (0, '$999,999,999')
END AS "Descuento",
CASE
WHEN p.totalstock > 80 THEN TO_CHAR(p.vunitario - ROUND(p.vunitario * 0.10, 0), '$999,999,999')
ELSE TO_CHAR(p.vunitario, '$999,999,999')
END AS "Valor Final",
p.procedencia AS "Proc."
FROM producto p
WHERE UPPER(p.descripcion) LIKE '%ZAPATO%'
AND p.procedencia = 'I'
ORDER BY p.codproducto DESC;
