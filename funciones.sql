DROP TABLE IF EXISTS empleado;
DROP TABLE IF EXISTS empleado_tt;

CREATE TABLE empleado (
legajo int not null,
nombre varchar(30),
sueldo int,
edad int,
primary key (legajo));

CREATE TABLE empleado_tt (
legajo int not null,
nombre varchar(30),
sueldo int,
edad int,
tt_izq timestamp, 
tt_der timestamp,
primary key (legajo, tt_izq),
CHECK (tt_der>=tt_izq AND sueldo>=0 AND edad>=0));

COPY empleados FROM '/empleados.csv' DELIMITER ',' CSV HEADER;

CREATE OR REPLACE FUNCTION empregister() RETURNS TRIGGER AS $$
BEGIN 
    IF TG_OP = 'INSERT' THEN
        INSERT INTO empleado_tt(legajo, nombre, sueldo, edad, tt_izq, tt_der)
        VALUES (NEW.legajo, NEW.nombre, NEW.sueldo, NEW.edad, current_timestamp, 'infinity');
    ELSIF TG_OP = 'UPDATE' THEN 
        UPDATE empleado_tt SET tt_der = current_timestamp WHERE tt_der = 'infinity' AND legajo = OLD.legajo;
        INSERT INTO empleado_tt(legajo, nombre, sueldo, edad, tt_izq, tt_der)
        VALUES (NEW.legajo, NEW.nombre, NEW.sueldo, NEW.edad, current_timestamp, 'infinity');
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE empleado_tt SET tt_der = current_timestamp WHERE tt_der = 'infinity' AND legajo = OLD.legajo;
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

create trigger empttrigger after insert or delete or update on empleado
for each row
execute function empregister();

CREATE OR REPLACE FUNCTION historial_empleados(pdate timestamp) RETURNS VOID AS $$
        DECLARE 
                myCursor CURSOR FOR SELECT legajo, nombre, sueldo, edad, tt_izq, tt_der 
                FROM empleados_tt order by legajo, Nro_Movimiento;

          rec RECORD;    
          Nro_Movimiento int := 0;
         

BEGIN
        RAISE NOTICE '--------------------------------------------------------------------------------';
        RAISE NOTICE '---------------------------HISTORIAL DE EMPLEADOS-------------------------------'; 
        RAISE NOTICE '--------------------------------------------------------------------------------';
        RAISE NOTICE '--------Estado-------Legajo-------Sueldo-------Edad-------Nro_Movimiento--------';
        RAISE NOTICE '--------------------------------------------------------------------------------';
        OPEN MYCURSOR;
LOOP
                FETCH MYCURSOR INTO REC;
                EXIT WHEN NOT FOUND;
                RAISE NOTICE '';
              PERFORM checkState(pdate, REC, Nro_Movimiento);
                  Nro_Movimiento := Nro_Movimiento + 1;
                END LOOP;

 CLOSE myCursor;
 end;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION checkState(ppdate timestamp, rec RECORD, Nro_Movimiento int) RETURNS VOID AS $$
        DECLARE 
        estado VARCHAR(30);
   
BEGIN
        if Extract(year from ppdate)!=extract(YEAR FROM CURRENT_DATE) THEN
                RAISE EXCEPTION 'la fecha tiene que ser de este año calendario';
        ELSIF ppdate > rec.tt_izq AND rec.tt_der = 'infinity' THEN 
        estado := 'Vigente Anterior';
    ELSIF ppdate > rec.tt_izq AND ppdate < rec.tt_der THEN 
        estado := 'Vigente';
    ELSE
        estado := 'No Vigente';
    END IF;
 
    RAISE NOTICE '% % % % %', estado, rec.legajo, rec.sueldo, rec.edad, Nro_Movimiento;
    
END;
$$ LANGUAGE plpgsql;


