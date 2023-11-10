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
primary key (legajo),
primary key (tt_izq),
foreign key (legajo) references empleado,
CHECK (tt_der>=tt_izq AND sueldo>=0 AND edad>=0));




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

