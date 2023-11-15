DROP TABLE IF EXISTS empleado;
DROP TABLE IF EXISTS empleado_tt;

------ TABLAS ------

CREATE TABLE empleado (
    legajo int not null,
    nombre varchar(30),
    sueldo int,
    edad int,
    primary key (legajo)
);

CREATE TABLE empleado_tt (
    legajo int not null,
    nombre varchar(30),
    sueldo int,
    edad int,
    tt_izq timestamp, 
    tt_der timestamp,
    primary key (legajo, tt_izq),
    CHECK (tt_der>=tt_izq AND sueldo>=0 AND edad>=0)
);

------ TRIGGERS ------

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

CREATE TRIGGER empttrigger AFTER INSERT OR DELETE OR UPDATE ON empleado
FOR EACH ROW
EXECUTE FUNCTION empregister();

------ Historial de Empleados ------

CREATE OR REPLACE FUNCTION historial_empleados(pdate timestamp) RETURNS VOID AS $$
    DECLARE 
            myCursor CURSOR FOR SELECT legajo, nombre, sueldo, edad, tt_izq, tt_der 
            FROM empleado_tt order by legajo;

        rec RECORD;    
        Nro_Movimiento int := 0;
        leg_anterior int :=null;

    BEGIN
        IF EXTRACT(year from pdate)!= EXTRACT(YEAR FROM CURRENT_DATE) THEN
            RAISE NOTICE 'La fecha tiene que ser de este año calendario';
            RETURN;
        END IF;
        RAISE NOTICE '--------------------------------------------------------------------------------';
        RAISE NOTICE '---------------------------HISTORIAL DE EMPLEADOS-------------------------------'; 
        RAISE NOTICE '--------------------------------------------------------------------------------';
        RAISE NOTICE '--------Estado-------Legajo-------Sueldo-------Edad-------Nro_Movimiento--------';
        RAISE NOTICE '--------------------------------------------------------------------------------';
        OPEN MYCURSOR;
        LOOP
            FETCH MYCURSOR INTO REC;
            EXIT WHEN NOT FOUND;    
            IF (leg_anterior IS NULL OR leg_anterior = rec.legajo) THEN
                Nro_Movimiento := Nro_Movimiento + 1;
            ELSE 
                Nro_Movimiento := 1;
            END IF;
            leg_anterior := rec.legajo;
            PERFORM checkState(pdate, REC, Nro_Movimiento);
        END LOOP;
        CLOSE myCursor;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION checkState(ppdate TIMESTAMP, rec RECORD, Nro_Movimiento INT) RETURNS VOID AS $$
    DECLARE 
        estado VARCHAR(30);
   
    BEGIN
        IF (ppdate > rec.tt_izq AND rec.tt_der = 'infinity') THEN 
            estado := 'Vigente Anterior';
        ELSIF (ppdate <= rec.tt_izq AND  rec.tt_der='infinity') THEN 
                estado := 'Vigente';
        ELSE
                estado := 'No Vigente';
        END IF;
        RAISE NOTICE '% % % % %', estado, rec.legajo, rec.sueldo, rec.edad, Nro_Movimiento;
    END;
$$ LANGUAGE plpgsql;
