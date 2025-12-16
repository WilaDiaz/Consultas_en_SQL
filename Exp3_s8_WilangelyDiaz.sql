---Sumativa 3---
---Wilangely Diaz---
---Consultas en SQL---

---PASO 1---
---CREACION DE USUARIOS Y ROLES---

CREATE USER PRY2205_USER1
IDENTIFIED BY "User1_123456!"
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON USERS;

CREATE USER PRY2205_USER2
IDENTIFIED BY "User2_123456!"
DEFAULT TABLESPACE USERS
TEMPORARY TABLESPACE TEMP
QUOTA 50M ON USERS;



---ROLES-

CREATE ROLE PRY2205_ROL_D;
CREATE ROLE PRY2205_ROL_P;


---PRIVILEGIOS DE SISTEMA-----

--USER1


GRANT CREATE TABLE TO PRY2205_ROL_D;
GRANT CREATE VIEW TO PRY2205_ROL_D;
GRANT CREATE SYNONYM TO PRY2205_ROL_D;


--USER2

GRANT CREATE TABLE TO PRY2205_ROL_P;
GRANT CREATE SEQUENCE TO PRY2205_ROL_P;
GRANT CREATE TRIGGER TO PRY2205_ROL_P;

----asignacion de roles a usuarios---

GRANT PRY2205_ROL_D TO PRY2205_USER1;
GRANT PRY2205_ROL_P TO PRY2205_USER2;

--CONEXION

GRANT CREATE SESSION TO PRY2205_USER1;
GRANT CREATE SESSION TO PRY2205_USER2;



---------------------------PRIVILEGIOS

GRANT SELECT ON PRY2205_USER1.LIBRO    TO PRY2205_USER2;
GRANT SELECT ON PRY2205_USER1.EJEMPLAR TO PRY2205_USER2;
GRANT SELECT ON PRY2205_USER1.PRESTAMO TO PRY2205_USER2;
GRANT SELECT ON PRY2205_USER1.EMPLEADO TO PRY2205_USER2;




---------------------------------------------------------------------------
-------------------------SINONIMOS
-- USUARIO PRY2205_USER1

CREATE PUBLIC SYNONYM SYN_LIBRO    FOR PRY2205_USER1.LIBRO;
CREATE PUBLIC SYNONYM SYN_EJEMPLAR FOR PRY2205_USER1.EJEMPLAR;
CREATE PUBLIC SYNONYM SYN_PRESTAMO FOR PRY2205_USER1.PRESTAMO;
CREATE PUBLIC SYNONYM SYN_EMPLEADO FOR PRY2205_USER1.EMPLEADO;
CREATE SYNONYM SYN_ALUMNO          FOR ALUMNO;
CREATE SYNONYM SYN_CARRERA         FOR CARRERA;
CREATE SYNONYM SYN_REBAJA          FOR REBAJA_MULTA;
CREATE SYNONYM SYN_VALOR_MULTA     FOR VALOR_MULTA_PRESTAMO;




CREATE OR REPLACE VIEW VW_DETALLE_MULTAS AS
SELECT
    p.prestamoid                                           AS id_prestamo,
    INITCAP(a.nombre || ' ' || a.apaterno || ' ' || a.amaterno) AS nombre_alumno,
    c.descripcion                                          AS carrera,
    l.libroid                                              AS id_libro,
    INITCAP(l.nombre_libro)                                AS nombre_libro,
    l.precio                                               AS precio_libro,
    p.fecha_termino                                        AS fecha_termino,
    p.fecha_entrega                                        AS fecha_entrega,
    (p.fecha_entrega - p.fecha_termino)                    AS dias_atraso,
    ROUND((l.precio * 0.03) * (p.fecha_entrega - p.fecha_termino)) AS multa_base,
    NVL(rm.porc_rebaja_multa, 0)                           AS porc_rebaja,
    ROUND(
      ((l.precio * 0.03) * (p.fecha_entrega - p.fecha_termino))
      * (1 - NVL(rm.porc_rebaja_multa,0)/100)
    )                                                      AS multa_final
FROM syn_prestamo p
JOIN syn_alumno  a ON a.alumnoid  = p.alumnoid
JOIN syn_carrera c ON c.carreraid = a.carreraid
JOIN syn_libro   l ON l.libroid   = p.libroid
LEFT JOIN syn_rebaja rm ON rm.carreraid = c.carreraid
WHERE EXTRACT(YEAR FROM p.fecha_termino) = EXTRACT(YEAR FROM SYSDATE) - 2
  AND p.fecha_entrega > p.fecha_termino
ORDER BY p.fecha_entrega DESC;



CREATE INDEX IDX_PRESTAMO_FECHAS
ON PRESTAMO (fecha_termino, fecha_entrega);

CREATE INDEX IDX_PRESTAMO_ALUMNO
ON PRESTAMO (alumnoid);



SELECT index_name
FROM user_indexes
WHERE table_name = 'PRESTAMO';

-----------------------------------------------------------------
-----------------------------------------------------------------
-- USUARIO PRY2205_USER2


CREATE SEQUENCE SEQ_CONTROL_STOCK
  START WITH 1
  INCREMENT BY 1
  NOCACHE;

SHOW USER;



SELECT COUNT(*) FROM SYN_LIBRO;
SELECT COUNT(*) FROM SYN_EJEMPLAR;
SELECT COUNT(*) FROM SYN_PRESTAMO;



CREATE TABLE CONTROL_STOCK_LIBROS AS
SELECT
  TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'MM'),-24),'MM/YYYY')       AS fecha_proceso,
  l.libroid                                                   AS id_libro,
  INITCAP(l.nombre_libro)                                     AS nombre_libro,
  COUNT(e.ejemplarid)                                         AS total_ejemplares,
  NVL(pres.ejemplares_prestamo,0)                             AS ejemplares_prestamo,
  (COUNT(e.ejemplarid) - NVL(pres.ejemplares_prestamo,0))     AS ejemplares_disponibles,
  ROUND(
    (NVL(pres.ejemplares_prestamo,0) / NULLIF(COUNT(e.ejemplarid),0)) * 100
  , 2)                                                        AS porc_prestamo,
  CASE
    WHEN (COUNT(e.ejemplarid) - NVL(pres.ejemplares_prestamo,0)) > 2 THEN 'S'
    ELSE 'N'
  END                                                         AS ind_stock
FROM syn_libro l
JOIN syn_ejemplar e
  ON e.libroid = l.libroid
LEFT JOIN (
    SELECT
      p.libroid,
      COUNT(DISTINCT (p.ejemplarid || '-' || p.libroid)) AS ejemplares_prestamo
    FROM syn_prestamo p
    WHERE p.empleadoid IN (190,180,150)
      AND p.fecha_inicio >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-24)
      AND p.fecha_inicio <  ADD_MONTHS(TRUNC(SYSDATE,'MM'),-23)
    GROUP BY p.libroid
) pres
  ON pres.libroid = l.libroid
GROUP BY
  l.libroid,
  l.nombre_libro,
  pres.ejemplares_prestamo
ORDER BY
  l.libroid;
  
  
ALTER TABLE CONTROL_STOCK_LIBROS ADD correlativo NUMBER;
UPDATE CONTROL_STOCK_LIBROS
SET correlativo = SEQ_CONTROL_STOCK.NEXTVAL;

COMMIT;

-----------------------------------------------------------------
-----------------------------------------------------------------






SELECT *
FROM VW_DETALLE_MULTAS
WHERE fecha_termino >= ADD_MONTHS(TRUNC(SYSDATE), -24);



