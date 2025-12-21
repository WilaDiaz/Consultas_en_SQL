----EFT Wilangely Diaz---
----Consultas de bases de datos---

---CREACION DE USUARIOS---

SHOW USER;


CREATE USER PRY2205_EFT_DES IDENTIFIED BY "EftDes_123456!"
DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP QUOTA UNLIMITED ON USERS;

CREATE USER PRY2205_EFT_CON IDENTIFIED BY "EftCon_123456!"
DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP QUOTA 50M ON USERS;

CREATE USER PRY2205_EFT IDENTIFIED BY "Efinalt_123456!"
DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP QUOTA UNLIMITED ON USERS;


---Conexion
GRANT CREATE SESSION TO PRY2205_EFT_DES;
GRANT CREATE SESSION TO PRY2205_EFT_CON;
GRANT CREATE SESSION TO PRY2205_EFT;

---ROLES
CREATE ROLE PRY2205_EFT_ROL_DES;
CREATE ROLE PRY2205_EFT_ROL_CON;
CREATE ROLE PRY2205_EFT_ROL;


---priviledios

GRANT CREATE TABLE TO PRY2205_EFT_ROL_DES;
GRANT CREATE SEQUENCE TO PRY2205_EFT_ROL_DES;

GRANT CREATE VIEW  TO PRY2205_EFT_ROL;
GRANT CREATE ANY INDEX TO PRY2205_EFT_ROL;

---SINONIMOS

GRANT CREATE SYNONYM TO PRY2205_EFT_ROL_DES;
GRANT CREATE SYNONYM TO PRY2205_EFT_ROL;

----ASIGNACION

GRANT PRY2205_EFT_ROL_DES TO PRY2205_EFT_DES;
GRANT PRY2205_EFT_ROL_CON TO PRY2205_EFT_CON;
GRANT PRY2205_EFT_ROL     TO PRY2205_EFT;


GRANT CREATE SESSION TO PRY2205_EFT;
GRANT CREATE TABLE TO PRY2205_EFT;
GRANT CREATE SEQUENCE TO PRY2205_EFT;
GRANT CREATE VIEW TO PRY2205_EFT;
GRANT CREATE SYNONYM TO PRY2205_EFT;


GRANT SELECT ON PROFESIONAL TO PRY2205_EFT_ROL_DES;
GRANT SELECT ON EMPRESA TO PRY2205_EFT_ROL_DES;
GRANT SELECT ON PROFESION TO PRY2205_EFT_ROL_DES;
GRANT SELECT ON COMUNA TO PRY2205_EFT_ROL_DES;
GRANT SELECT ON SECTOR TO PRY2205_EFT_ROL_DES;
GRANT SELECT ON ISAPRE TO PRY2205_EFT_ROL_DES;
GRANT SELECT ON AFP TO PRY2205_EFT_ROL_DES;
GRANT SELECT ON RANGOS_SUELDOS TO PRY2205_EFT_ROL_DES;


GRANT SELECT ON PROFESIONAL TO PRY2205_EFT_ROL_CON;
GRANT SELECT ON EMPRESA TO PRY2205_EFT_ROL_CON;
GRANT SELECT ON CARTOLA_PROFESIONALES TO PRY2205_EFT_ROL_CON;


CREATE OR REPLACE SYNONYM SYN_PROFESIONAL FOR PRY2205_EFT.PROFESIONAL;
CREATE OR REPLACE SYNONYM SYN_EMPRESA     FOR PRY2205_EFT.EMPRESA;




----caso 2




GRANT SELECT ON PRY2205_EFT.PROFESIONAL     TO PRY2205_EFT_DES;
GRANT SELECT ON PRY2205_EFT.PROFESION       TO PRY2205_EFT_DES;
GRANT SELECT ON PRY2205_EFT.ISAPRE          TO PRY2205_EFT_DES;
GRANT SELECT ON PRY2205_EFT.RANGOS_SUELDOS  TO PRY2205_EFT_DES;
GRANT SELECT ON PRY2205_EFT.TIPO_CONTRATO   TO PRY2205_EFT_DES;

CREATE OR REPLACE SYNONYM SYN_PROFESIONAL    FOR PRY2205_EFT.PROFESIONAL;
CREATE OR REPLACE SYNONYM SYN_PROFESION      FOR PRY2205_EFT.PROFESION;
CREATE OR REPLACE SYNONYM SYN_ISAPRE         FOR PRY2205_EFT.ISAPRE;
CREATE OR REPLACE SYNONYM SYN_RANGOS_SUELDOS FOR PRY2205_EFT.RANGOS_SUELDOS;
CREATE OR REPLACE SYNONYM SYN_TIPO_CONTRATO   FOR PRY2205_EFT.TIPO_CONTRATO;




BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE CARTOLA_PROFESIONALES PURGE';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN RAISE; END IF;
END;
/




CREATE TABLE CARTOLA_PROFESIONALES AS
SELECT
  p.rutprof                                              AS rut_profesional,
  INITCAP(p.nompro || ' ' || p.apppro || ' ' || p.apmpro) AS nombre_profesional,
  pr.nomprofesion                                        AS profesion,
  i.nomisapre                                            AS isapre,
  p.sueldo                                               AS sueldo_base,

  NVL(p.comision,0)                                      AS porc_comision_profesional,
  ROUND(p.sueldo * (NVL(p.comision,0)/100))               AS valor_total_comision,

  ROUND(
    CASE
      WHEN tc.nomtcontrato = 'Honorarios'
      THEN p.sueldo * (rs.honor_pct/100)
      ELSE 0
    END
  )                                                      AS monto_honorario,

  CASE
    WHEN tc.nomtcontrato = 'Indefinido Jornada Completa' THEN 150000
    WHEN tc.nomtcontrato = 'Indefinido Jornada Parcial'  THEN 120000
    WHEN tc.nomtcontrato = 'Plazo fijo'                  THEN 60000
    WHEN tc.nomtcontrato = 'Honorarios'                  THEN 50000
    ELSE 0
  END                                                    AS bono_movilizacion,

  ROUND(
    p.sueldo
    + (p.sueldo * (NVL(p.comision,0)/100))
    + CASE WHEN tc.nomtcontrato = 'Honorarios' THEN p.sueldo * (rs.honor_pct/100) ELSE 0 END
    + CASE
        WHEN tc.nomtcontrato = 'Indefinido Jornada Completa' THEN 150000
        WHEN tc.nomtcontrato = 'Indefinido Jornada Parcial'  THEN 120000
        WHEN tc.nomtcontrato = 'Plazo fijo'                  THEN 60000
        WHEN tc.nomtcontrato = 'Honorarios'                  THEN 50000
        ELSE 0
      END
  )                                                      AS total_a_pagar
FROM syn_profesional p
JOIN syn_profesion pr ON pr.idprofesion = p.idprofesion
JOIN syn_isapre i ON i.idisapre = p.idisapre
LEFT JOIN syn_tipo_contrato tc ON tc.idtcontrato = p.idtcontrato
LEFT JOIN syn_rangos_sueldos rs
  ON p.sueldo BETWEEN rs.s_min AND rs.s_max
ORDER BY
  profesion ASC,
  sueldo_base DESC,
  porc_comision_profesional DESC,
  rut_profesional ASC;


GRANT SELECT ON CARTOLA_PROFESIONALES TO PRY2205_EFT_CON;
SELECT * FROM CARTOLA_PROFESIONALES;


SHOW USER;
SELECT COUNT(*) FROM PRY2205_EFT_DES.CARTOLA_PROFESIONALES;
SELECT * FROM PRY2205_EFT_DES.CARTOLA_PROFESIONALES FETCH FIRST 5 ROWS ONLY;


------ caso 3 optimizacion 

CREATE OR REPLACE SYNONYM SYN_EMPRESA  FOR PRY2205_EFT.EMPRESA;
CREATE OR REPLACE SYNONYM SYN_ASESORIA FOR PRY2205_EFT.ASESORIA;
CREATE OR REPLACE SYNONYM SYN_COMUNA   FOR PRY2205_EFT.COMUNA;
CREATE OR REPLACE SYNONYM SYN_SECTOR   FOR PRY2205_EFT.SECTOR;


----1era vista

CREATE OR REPLACE VIEW VW_EMPRESAS_ASESORADAS AS
SELECT
  (e.rut_empresa || '-' || e.dv_empresa)                          AS rut_empresa,
  e.nomempresa                                                   AS nombre_empresa,
  CASE
  WHEN e.fecha_iniciacion_actividades IS NULL THEN NULL
  WHEN e.fecha_iniciacion_actividades < DATE '1950-01-01' THEN NULL
  WHEN e.fecha_iniciacion_actividades > SYSDATE THEN NULL
  ELSE TRUNC(MONTHS_BETWEEN(SYSDATE, e.fecha_iniciacion_actividades)/12)
END AS anios_antiguedad,
  e.iva_declarado                                                AS iva_declarado,

  COUNT(*)                                                       AS asesorias_totales,
  ROUND(COUNT(*)/12, 2)                                          AS asesorias_promedio_anual,

  ROUND(e.iva_declarado * ( (COUNT(*)/12) / 100 ), 0)             AS devolucion_iva_estimada,

  CASE
    WHEN (COUNT(*)/12) > 5 THEN 'CLIENTE PREMIUM'
    WHEN (COUNT(*)/12) BETWEEN 3 AND 5 THEN 'CLIENTE'
    ELSE 'CLIENTE POCO CONCURRIDO'
  END                                                            AS tipo_cliente,

  CASE
    WHEN (COUNT(*)/12) > 5 AND COUNT(*) >= 7 THEN '1 ASESORÍA GRATIS'
    WHEN (COUNT(*)/12) > 5 AND COUNT(*) <  7 THEN '1 ASESORÍA 40% DE DESCUENTO'
    WHEN (COUNT(*)/12) BETWEEN 3 AND 5 AND COUNT(*) = 5 THEN '1 ASESORÍA 30% DE DESCUENTO'
    WHEN (COUNT(*)/12) BETWEEN 3 AND 5 AND COUNT(*) < 5 THEN '1 ASESORÍA 20% DE DESCUENTO'
    ELSE 'CAPTAR CLIENTE'
  END                                                            AS promocion_recomendacion
FROM syn_empresa e
JOIN syn_asesoria a
  ON a.idempresa = e.idempresa
WHERE a.fin >= TRUNC(ADD_MONTHS(SYSDATE, -12), 'YYYY')   
  AND a.fin <  TRUNC(SYSDATE, 'YYYY')                   
GROUP BY
  e.rut_empresa, e.dv_empresa,
  e.nomempresa,
  e.fecha_iniciacion_actividades,
  e.iva_declarado;


GRANT SELECT ON VW_EMPRESAS_ASESORADAS TO PRY2205_EFT_CON;

--------------------------------------
SELECT *
FROM VW_EMPRESAS_ASESORADAS
ORDER BY nombre_empresa ASC;
--------------------------------------
SHOW USER;
SELECT * FROM PRY2205_EFT.VW_EMPRESAS_ASESORADAS ORDER BY nombre_empresa;




------------------------------------------
----caso 3.2
------------------------------------------

DROP INDEX IDX_ASESORIA_FIN_IDEMPRESA;


EXPLAIN PLAN FOR
SELECT *
FROM VW_EMPRESAS_ASESORADAS
ORDER BY nombre_empresa;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);




CREATE INDEX IDX_ASESORIA_FIN_IDEMPRESA
ON ASESORIA (FIN, IDEMPRESA);


EXPLAIN PLAN FOR
SELECT *
FROM VW_EMPRESAS_ASESORADAS
ORDER BY nombre_empresa;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
