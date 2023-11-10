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
