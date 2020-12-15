--
-- PostgreSQL database dump
--

-- Dumped from database version 10.1
-- Dumped by pg_dump version 11.2

-- Started on 2019-07-01 22:24:56

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 8 (class 2615 OID 208053)
-- Name: auditoria; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA auditoria;


ALTER SCHEMA auditoria OWNER TO postgres;

--
-- TOC entry 301 (class 1255 OID 208083)
-- Name: if_modified_func(); Type: FUNCTION; Schema: auditoria; Owner: postgres
--

CREATE FUNCTION auditoria.if_modified_func() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog', 'audit'
    AS $$
DECLARE
    v_old_data TEXT;
    v_new_data TEXT;
BEGIN
 
    IF (TG_OP = 'UPDATE') THEN
        v_old_data := ROW(OLD.*);
        v_new_data := ROW(NEW.*);
        INSERT INTO auditoria.logged_actions (schema_name,table_name,user_name,action,original_data,new_data,query) 
        VALUES (TG_TABLE_SCHEMA::TEXT,TG_TABLE_NAME::TEXT,session_user::TEXT,substring(TG_OP,1,1),v_old_data,v_new_data, current_query());
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        v_old_data := ROW(OLD.*);
        INSERT INTO auditoria.logged_actions (schema_name,table_name,user_name,action,original_data,query)
        VALUES (TG_TABLE_SCHEMA::TEXT,TG_TABLE_NAME::TEXT,session_user::TEXT,substring(TG_OP,1,1),v_old_data, current_query());
        RETURN OLD;
    ELSIF (TG_OP = 'INSERT') THEN
        v_new_data := ROW(NEW.*);
        INSERT INTO auditoria.logged_actions (schema_name,table_name,user_name,action,new_data,query)
        VALUES (TG_TABLE_SCHEMA::TEXT,TG_TABLE_NAME::TEXT,session_user::TEXT,substring(TG_OP,1,1),v_new_data, current_query());
        RETURN NEW;
    ELSE
        RAISE WARNING '[auditoria.IF_MODIFIED_FUNC] - Other action occurred: %, at %',TG_OP,now();
        RETURN NULL;
    END IF;
 
EXCEPTION
    WHEN data_exception THEN
        RAISE WARNING '[auditoria.IF_MODIFIED_FUNC] - UDF ERROR [DATA EXCEPTION] - SQLSTATE: %, SQLERRM: %',SQLSTATE,SQLERRM;
        RETURN NULL;
    WHEN unique_violation THEN
        RAISE WARNING '[auditoria.IF_MODIFIED_FUNC] - UDF ERROR [UNIQUE] - SQLSTATE: %, SQLERRM: %',SQLSTATE,SQLERRM;
        RETURN NULL;
    WHEN OTHERS THEN
        RAISE WARNING '[auditoria.IF_MODIFIED_FUNC] - UDF ERROR [OTHER] - SQLSTATE: %, SQLERRM: %',SQLSTATE,SQLERRM;
        RETURN NULL;
END;
$$;


ALTER FUNCTION auditoria.if_modified_func() OWNER TO postgres;

--
-- TOC entry 305 (class 1255 OID 200396)
-- Name: act_solicitud(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.act_solicitud(v_id_solicitud integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
    
DECLARE
      v_productos_sol int;
      v_productos_asi int;
      v_exito int;
    BEGIN
     
      v_productos_sol = 0;
      v_productos_asi = 0; 
      v_exito = 0;
     
     SELECT COUNT(1) INTO v_productos_sol FROM solicitud_detalle WHERE  id_solicitud = v_id_solicitud;
     SELECT COUNT(1) INTO v_productos_asi FROM solicitud_detalle WHERE  id_solicitud = v_id_solicitud AND asignado=TRUE;

     IF v_productos_sol > v_productos_asi AND v_productos_asi = 0 THEN
        UPDATE solicitud SET id_estatus_solicitud = 3 WHERE id_solicitud = v_id_solicitud;
     END IF;
     IF v_productos_sol > v_productos_asi AND v_productos_asi > 0 THEN
        UPDATE solicitud SET id_estatus_solicitud = 2 WHERE id_solicitud = v_id_solicitud;
     END IF;
     IF v_productos_sol = v_productos_asi THEN
        UPDATE solicitud SET id_estatus_solicitud = 1 WHERE id_solicitud = v_id_solicitud;
     END IF;

     -- BUSCO EL NUEVO ID DE USUARIO PARA ENVIARLO COMO PARTE DE LA RESPUESTA
     --SELECT currval('solicitud_solicitud_id_seq') INTO v_id_solicitud;

     v_exito := 1;
     RETURN;
    
    END;
$$;


ALTER FUNCTION public.act_solicitud(v_id_solicitud integer) OWNER TO postgres;

--
-- TOC entry 296 (class 1255 OID 208068)
-- Name: createtablesseguimiento(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.createtablesseguimiento(nombtabla text, esquema text, db text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE QQ text;
BEGIN
QQ:= 'DROP TABLE IF EXISTS "auditoria". ' || nombtabla || ';
CREATE TABLE "auditoria".' || nombtabla || ' (
idmovimiento serial NOT NULL,
usuariodb text NOT NULL DEFAULT "current_user"(),
accion text NOT NULL,
acciontimestamp timestamp WITH TIME ZONE NOT NULL DEFAULT now(),
oldmovimiento ' || esquema ||'.' || nombtabla || ',
newmovimiento ' || esquema ||'.' || nombtabla || ',
consulta varchar
/* Keys */
CONSTRAINT ' || nombtabla || '_pkey
PRIMARY KEY (idmovimiento),
/* Checks */
CONSTRAINT ' || nombtabla || '_check CHECK (accion = ANY (ARRAY["INSERT"::text, "UPDATE"::text, "DELETE"::text]))
) ;
ALTER TABLE "auditoria".' || nombtabla || '
OWNER TO postgres;';
EXECUTE QQ;
execute public.CrearTrigger(nombtabla,esquema,db);
END;
$$;


ALTER FUNCTION public.createtablesseguimiento(nombtabla text, esquema text, db text) OWNER TO postgres;

--
-- TOC entry 311 (class 1255 OID 200397)
-- Name: nueva_orden(integer, integer, character varying, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.nueva_orden(p_num_orden integer, p_id_solicitud integer, p_observacion character varying, p_id_emp integer, p_id_funcionario integer, p_id_empleado_retira integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare clave integer;
begin
   insert into orden_salida(id_solicitud,observacion,id_emp,id_funcionario,id_empleado_retira) 
      values (p_id_solicitud,p_observacion,p_id_emp,p_id_funcionario,p_id_empleado_retira) 
      returning id_orden into clave;

   update orden_salida set num_orden=p_num_orden+clave where id_orden = clave; 

   update solicitud set id_orden=clave where id_solicitud=p_id_solicitud;

   return clave;
end;
$$;


ALTER FUNCTION public.nueva_orden(p_num_orden integer, p_id_solicitud integer, p_observacion character varying, p_id_emp integer, p_id_funcionario integer, p_id_empleado_retira integer) OWNER TO postgres;

--
-- TOC entry 309 (class 1255 OID 200398)
-- Name: nueva_solicitud(integer, integer, integer, character varying, date, integer, integer, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.nueva_solicitud(p_id_equipo integer, p_id_funcionario integer, p_id_empleado integer, p_descripcion character varying, p_fecha_solicitud date, p_id_tipo_solicitud integer, p_id_estatus_solicitud integer, p_id_ubicacion integer, p_id_oficina integer, p_id_departamento integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare clave integer;
begin
   insert into solicitud(id_equipo,id_funcionario,id_empleado,descripcion,fecha_solicitud,id_tipo_solicitud,id_estatus_solicitud,id_ubicacion,id_oficina,id_departamento) 
      values (p_id_equipo,p_id_funcionario,p_id_empleado,p_descripcion,p_fecha_solicitud,p_id_tipo_solicitud,p_id_estatus_solicitud,p_id_ubicacion,p_id_oficina,p_id_departamento) 
      returning id_solicitud into clave;
   return clave;
end;
$$;


ALTER FUNCTION public.nueva_solicitud(p_id_equipo integer, p_id_funcionario integer, p_id_empleado integer, p_descripcion character varying, p_fecha_solicitud date, p_id_tipo_solicitud integer, p_id_estatus_solicitud integer, p_id_ubicacion integer, p_id_oficina integer, p_id_departamento integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 294 (class 1259 OID 208072)
-- Name: logged_actions; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.logged_actions (
    schema_name text NOT NULL,
    table_name text NOT NULL,
    user_name text,
    action_tstamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    action text NOT NULL,
    original_data text,
    new_data text,
    query text,
    CONSTRAINT logged_actions_action_check CHECK ((action = ANY (ARRAY['I'::text, 'D'::text, 'U'::text])))
);


ALTER TABLE auditoria.logged_actions OWNER TO postgres;

--
-- TOC entry 197 (class 1259 OID 200399)
-- Name: almacen; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.almacen (
    id_almacen integer NOT NULL,
    id_equipo integer NOT NULL,
    fecha_entrada date,
    fecha_despacho date,
    telefono character varying(15),
    stock integer,
    active boolean,
    fecha_elim date,
    usr_id integer
);


ALTER TABLE public.almacen OWNER TO postgres;

--
-- TOC entry 3433 (class 0 OID 0)
-- Dependencies: 197
-- Name: TABLE almacen; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.almacen IS 'Tabla donde se registra los datos del almacen a donde llegan los equipos.';


--
-- TOC entry 3434 (class 0 OID 0)
-- Dependencies: 197
-- Name: COLUMN almacen.id_almacen; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.almacen.id_almacen IS 'Campo clave de la tabla almacen';


--
-- TOC entry 3435 (class 0 OID 0)
-- Dependencies: 197
-- Name: COLUMN almacen.id_equipo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.almacen.id_equipo IS 'Campo que relaciona la tabla almacen con la tabla equipo';


--
-- TOC entry 3436 (class 0 OID 0)
-- Dependencies: 197
-- Name: COLUMN almacen.fecha_entrada; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.almacen.fecha_entrada IS 'Campo que registra la fecha de entrada del equipo al almacen';


--
-- TOC entry 3437 (class 0 OID 0)
-- Dependencies: 197
-- Name: COLUMN almacen.fecha_despacho; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.almacen.fecha_despacho IS 'Campo que registra la fecha en que se le dio salida al equipo';


--
-- TOC entry 3438 (class 0 OID 0)
-- Dependencies: 197
-- Name: COLUMN almacen.telefono; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.almacen.telefono IS 'Campo que registra el numero de telefono del almacen';


--
-- TOC entry 3439 (class 0 OID 0)
-- Dependencies: 197
-- Name: COLUMN almacen.stock; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.almacen.stock IS 'Campo que registra el stock de los equipos';


--
-- TOC entry 198 (class 1259 OID 200402)
-- Name: almacen_id_almacen_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.almacen_id_almacen_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.almacen_id_almacen_seq OWNER TO postgres;

--
-- TOC entry 3440 (class 0 OID 0)
-- Dependencies: 198
-- Name: almacen_id_almacen_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.almacen_id_almacen_seq OWNED BY public.almacen.id_almacen;


--
-- TOC entry 199 (class 1259 OID 200404)
-- Name: articulo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.articulo (
    id_articulo integer NOT NULL,
    articulo character varying(150),
    codigo_snc character varying(20),
    active boolean,
    fecha_elim date,
    usr_id integer
);


ALTER TABLE public.articulo OWNER TO postgres;

--
-- TOC entry 200 (class 1259 OID 200407)
-- Name: articulo_id_articulo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.articulo_id_articulo_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.articulo_id_articulo_seq OWNER TO postgres;

--
-- TOC entry 3441 (class 0 OID 0)
-- Dependencies: 200
-- Name: articulo_id_articulo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.articulo_id_articulo_seq OWNED BY public.articulo.id_articulo;


--
-- TOC entry 285 (class 1259 OID 200946)
-- Name: articulos_alfa; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.articulos_alfa AS
 SELECT articulo.id_articulo AS id,
    articulo.articulo AS text
   FROM public.articulo
  WHERE (articulo.active IS NOT FALSE)
  ORDER BY articulo.articulo;


ALTER TABLE public.articulos_alfa OWNER TO postgres;

--
-- TOC entry 286 (class 1259 OID 200950)
-- Name: articulos_json; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.articulos_json AS
 SELECT ((('[ '::text || string_agg((t.value)::text, ', '::text)) || ' ]'::text))::json AS json
   FROM ( SELECT json_array_elements.value
           FROM json_array_elements('[{ "id" : -1, "text" : "" }]'::json) json_array_elements(value)
        UNION ALL
         SELECT to_json(t_1.*) AS to_json
           FROM public.articulos_alfa t_1) t;


ALTER TABLE public.articulos_json OWNER TO postgres;

--
-- TOC entry 201 (class 1259 OID 200409)
-- Name: cancelacion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cancelacion (
    id_cancelacion integer NOT NULL,
    id_solicitud_detalle integer,
    fecha_cancelacion date,
    id_funcionario integer,
    active boolean,
    fecha_elim date,
    usr_id integer,
    observacion text,
    id_equipo integer,
    id_empleado_cancela integer
);


ALTER TABLE public.cancelacion OWNER TO postgres;

--
-- TOC entry 202 (class 1259 OID 200415)
-- Name: departamento; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.departamento (
    id_departamento integer NOT NULL,
    nombre character varying,
    telf_departamento integer,
    active boolean,
    fecha_elim date,
    usr_id integer
);


ALTER TABLE public.departamento OWNER TO postgres;

--
-- TOC entry 3442 (class 0 OID 0)
-- Dependencies: 202
-- Name: TABLE departamento; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.departamento IS 'Registra los diversos departamentos del SAREN';


--
-- TOC entry 3443 (class 0 OID 0)
-- Dependencies: 202
-- Name: COLUMN departamento.id_departamento; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.departamento.id_departamento IS 'Campo clave para registrar los diversos departamentos del SAREN';


--
-- TOC entry 3444 (class 0 OID 0)
-- Dependencies: 202
-- Name: COLUMN departamento.nombre; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.departamento.nombre IS 'Nombre del departamento';


--
-- TOC entry 3445 (class 0 OID 0)
-- Dependencies: 202
-- Name: COLUMN departamento.telf_departamento; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.departamento.telf_departamento IS 'Campo que registra el telefono del departamento';


--
-- TOC entry 203 (class 1259 OID 200421)
-- Name: departamento_id_departamento_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.departamento_id_departamento_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.departamento_id_departamento_seq OWNER TO postgres;

--
-- TOC entry 3446 (class 0 OID 0)
-- Dependencies: 203
-- Name: departamento_id_departamento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.departamento_id_departamento_seq OWNED BY public.departamento.id_departamento;


--
-- TOC entry 287 (class 1259 OID 200954)
-- Name: desincorporacion_id_desincorporacion_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.desincorporacion_id_desincorporacion_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999999999999
    CACHE 1;


ALTER TABLE public.desincorporacion_id_desincorporacion_seq OWNER TO postgres;

--
-- TOC entry 288 (class 1259 OID 200956)
-- Name: desincorporacion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.desincorporacion (
    id_desincorporacion integer DEFAULT nextval('public.desincorporacion_id_desincorporacion_seq'::regclass) NOT NULL,
    id_motivo integer,
    fecha_desincorporacion date DEFAULT now(),
    id_funcionario integer,
    active boolean,
    fecha_elim date,
    usr_id integer,
    observacion text,
    id_equipo integer,
    id_empleado_notifica integer
);


ALTER TABLE public.desincorporacion OWNER TO postgres;

--
-- TOC entry 208 (class 1259 OID 200437)
-- Name: empleado; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.empleado (
    id_empleado integer NOT NULL,
    primer_nombre character varying(20),
    segundo_nombre character varying(20),
    primer_apellido character varying(20),
    segundo_apellido character varying(20),
    cedula integer,
    direccion character varying(100),
    email character varying(30),
    id_departamento integer,
    id_telefono integer,
    id_estatus integer,
    cargo character varying(20),
    active boolean,
    fecha_elim date,
    usr_id integer,
    id_oficina integer,
    id_usuario integer DEFAULT 0,
    id_ubicacion integer,
    telefono bigint
);


ALTER TABLE public.empleado OWNER TO postgres;

--
-- TOC entry 3447 (class 0 OID 0)
-- Dependencies: 208
-- Name: TABLE empleado; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.empleado IS 'Tabla que registra los distintos usuarios del sistema(analista de soporte, analista de almacen, coordinador de soporte)';


--
-- TOC entry 3448 (class 0 OID 0)
-- Dependencies: 208
-- Name: COLUMN empleado.id_empleado; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.empleado.id_empleado IS 'Campo clave de la tabla empleado';


--
-- TOC entry 3449 (class 0 OID 0)
-- Dependencies: 208
-- Name: COLUMN empleado.primer_nombre; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.empleado.primer_nombre IS 'Nombre del usuario';


--
-- TOC entry 3450 (class 0 OID 0)
-- Dependencies: 208
-- Name: COLUMN empleado.segundo_nombre; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.empleado.segundo_nombre IS 'Segundo nombre del usuario';


--
-- TOC entry 3451 (class 0 OID 0)
-- Dependencies: 208
-- Name: COLUMN empleado.primer_apellido; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.empleado.primer_apellido IS 'Primer apellido del usuario';


--
-- TOC entry 3452 (class 0 OID 0)
-- Dependencies: 208
-- Name: COLUMN empleado.segundo_apellido; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.empleado.segundo_apellido IS 'Segundo apellido del usuario';


--
-- TOC entry 3453 (class 0 OID 0)
-- Dependencies: 208
-- Name: COLUMN empleado.cedula; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.empleado.cedula IS 'Cedula del usuario';


--
-- TOC entry 3454 (class 0 OID 0)
-- Dependencies: 208
-- Name: COLUMN empleado.direccion; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.empleado.direccion IS 'Direccion del usuario';


--
-- TOC entry 3455 (class 0 OID 0)
-- Dependencies: 208
-- Name: COLUMN empleado.email; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.empleado.email IS 'Email del usuario';


--
-- TOC entry 3456 (class 0 OID 0)
-- Dependencies: 208
-- Name: COLUMN empleado.id_departamento; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.empleado.id_departamento IS 'Campo que relaciona la tabla empleado con la tabla departamento';


--
-- TOC entry 3457 (class 0 OID 0)
-- Dependencies: 208
-- Name: COLUMN empleado.id_telefono; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.empleado.id_telefono IS 'Campo que relaciona la tabla empleado con la tabla telefono';


--
-- TOC entry 3458 (class 0 OID 0)
-- Dependencies: 208
-- Name: COLUMN empleado.id_estatus; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.empleado.id_estatus IS 'Campo que relaciona la tabla empleado con la tabla estatus_empleado';


--
-- TOC entry 216 (class 1259 OID 200470)
-- Name: equipo_old; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.equipo_old (
    id_equipo integer NOT NULL,
    cod_equipo integer,
    serial character varying(20),
    id_estatus integer,
    id_ubicacion integer,
    num_bien_nac character varying(15),
    descripcion character varying(30),
    num_factura integer,
    fecha_factura date,
    id_proveedor integer,
    valor double precision,
    active boolean,
    fecha_elim date,
    usr_id integer
);


ALTER TABLE public.equipo_old OWNER TO postgres;

--
-- TOC entry 3459 (class 0 OID 0)
-- Dependencies: 216
-- Name: TABLE equipo_old; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.equipo_old IS 'Tabla que registra las caracteristicas de  los distintos equipos tecnologicos';


--
-- TOC entry 3460 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN equipo_old.id_equipo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipo_old.id_equipo IS 'Campo clave de la tabla equipo';


--
-- TOC entry 3461 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN equipo_old.cod_equipo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipo_old.cod_equipo IS 'Codigo del equipo';


--
-- TOC entry 3462 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN equipo_old.serial; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipo_old.serial IS 'Campo que registra el serial del equipo';


--
-- TOC entry 3463 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN equipo_old.id_estatus; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipo_old.id_estatus IS 'Campo que registra el estatus del equipo que puede ser: 1=asignado, 2=prestado, 3=dañado.';


--
-- TOC entry 3464 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN equipo_old.id_ubicacion; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipo_old.id_ubicacion IS 'Campo que registra la ubicacion del equipo, que puede ser: 1=almacen, 2=oficina, 3=departamento.';


--
-- TOC entry 3465 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN equipo_old.num_bien_nac; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipo_old.num_bien_nac IS 'Campo que registra el numero de bien nacional del equipo';


--
-- TOC entry 3466 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN equipo_old.descripcion; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipo_old.descripcion IS 'Descripcion del equipo';


--
-- TOC entry 3467 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN equipo_old.num_factura; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipo_old.num_factura IS 'Numero de factura de compra del equipo';


--
-- TOC entry 3468 (class 0 OID 0)
-- Dependencies: 216
-- Name: COLUMN equipo_old.valor; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipo_old.valor IS 'Campo que registra el valor monetario del bien';


--
-- TOC entry 217 (class 1259 OID 200473)
-- Name: equipo_id_equipo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.equipo_id_equipo_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.equipo_id_equipo_seq OWNER TO postgres;

--
-- TOC entry 3469 (class 0 OID 0)
-- Dependencies: 217
-- Name: equipo_id_equipo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.equipo_id_equipo_seq OWNED BY public.equipo_old.id_equipo;


--
-- TOC entry 218 (class 1259 OID 200475)
-- Name: equipo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.equipo (
    id_equipo integer DEFAULT nextval('public.equipo_id_equipo_seq'::regclass) NOT NULL,
    cod_equipo integer,
    serial character varying(20),
    id_estatus integer,
    id_ubicacion integer,
    num_bien_nac character varying(15),
    descripcion character varying(150),
    num_factura integer,
    fecha_factura date,
    id_proveedor integer,
    valor double precision,
    id_articulo integer,
    active boolean,
    fecha_elim date,
    usr_id integer,
    id_marca integer,
    id_oficina integer,
    id_departamento integer,
    id_solicitud_detalle_reserva integer DEFAULT 0
);


ALTER TABLE public.equipo OWNER TO postgres;

--
-- TOC entry 3470 (class 0 OID 0)
-- Dependencies: 218
-- Name: TABLE equipo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.equipo IS 'Tabla que registra las caracteristicas de  los distintos equipos tecnologicos';


--
-- TOC entry 3471 (class 0 OID 0)
-- Dependencies: 218
-- Name: COLUMN equipo.id_equipo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipo.id_equipo IS 'Campo clave de la tabla equipo';


--
-- TOC entry 3472 (class 0 OID 0)
-- Dependencies: 218
-- Name: COLUMN equipo.cod_equipo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipo.cod_equipo IS 'Codigo del equipo';


--
-- TOC entry 3473 (class 0 OID 0)
-- Dependencies: 218
-- Name: COLUMN equipo.serial; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipo.serial IS 'Campo que registra el serial del equipo';


--
-- TOC entry 3474 (class 0 OID 0)
-- Dependencies: 218
-- Name: COLUMN equipo.id_estatus; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipo.id_estatus IS 'Campo que registra el estatus del equipo que puede ser: 1=asignado, 2=prestado, 3=dañado.';


--
-- TOC entry 3475 (class 0 OID 0)
-- Dependencies: 218
-- Name: COLUMN equipo.id_ubicacion; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipo.id_ubicacion IS 'Campo que registra la ubicacion del equipo, que puede ser: 1=almacen, 2=oficina, 3=departamento.';


--
-- TOC entry 3476 (class 0 OID 0)
-- Dependencies: 218
-- Name: COLUMN equipo.num_bien_nac; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipo.num_bien_nac IS 'Campo que registra el numero de bien nacional del equipo';


--
-- TOC entry 3477 (class 0 OID 0)
-- Dependencies: 218
-- Name: COLUMN equipo.descripcion; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipo.descripcion IS 'Descripcion del equipo';


--
-- TOC entry 3478 (class 0 OID 0)
-- Dependencies: 218
-- Name: COLUMN equipo.num_factura; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipo.num_factura IS 'Numero de factura de compra del equipo';


--
-- TOC entry 3479 (class 0 OID 0)
-- Dependencies: 218
-- Name: COLUMN equipo.valor; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipo.valor IS 'Campo que registra el valor monetario del bien';


--
-- TOC entry 3480 (class 0 OID 0)
-- Dependencies: 218
-- Name: COLUMN equipo.id_articulo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipo.id_articulo IS 'Campo que registra el Tipo de Articulo del Equipo';


--
-- TOC entry 290 (class 1259 OID 200968)
-- Name: motivo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.motivo (
    id_motivo integer NOT NULL,
    motivo character varying(30),
    active boolean,
    fecha_elim date,
    usr_id integer
);


ALTER TABLE public.motivo OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 200555)
-- Name: usuario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.usuario_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.usuario_seq OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 200557)
-- Name: usuario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuario (
    alias character varying(60) NOT NULL,
    email character varying(100),
    id integer DEFAULT nextval('public.usuario_seq'::regclass) NOT NULL,
    nombres character varying(80) NOT NULL,
    password character varying(255) NOT NULL,
    id_rol integer,
    active boolean,
    fecha_elim date,
    usr_id integer,
    intentos integer DEFAULT 0,
    ingreso boolean DEFAULT false
);


ALTER TABLE public.usuario OWNER TO postgres;

--
-- TOC entry 291 (class 1259 OID 200974)
-- Name: desincorporaciones; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.desincorporaciones AS
 SELECT desincorporacion.id_desincorporacion,
    motivo.motivo,
    desincorporacion.fecha_desincorporacion,
    desincorporacion.id_funcionario,
    usuario.nombres,
    equipo.cod_equipo,
    equipo.serial,
    equipo.num_bien_nac,
    equipo.descripcion,
    desincorporacion.id_empleado_notifica,
    empleado.primer_nombre,
    empleado.primer_apellido
   FROM public.desincorporacion,
    public.equipo,
    public.usuario,
    public.empleado,
    public.motivo
  WHERE ((desincorporacion.id_funcionario = usuario.id) AND (desincorporacion.id_motivo = motivo.id_motivo) AND (desincorporacion.id_equipo = equipo.id_equipo) AND (desincorporacion.id_empleado_notifica = empleado.id_empleado));


ALTER TABLE public.desincorporaciones OWNER TO postgres;

--
-- TOC entry 204 (class 1259 OID 200423)
-- Name: devolucion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.devolucion (
    id_devolucion integer NOT NULL,
    id_solicitud_detalle integer,
    fecha_devolucion date,
    id_funcionario integer,
    active boolean,
    fecha_elim date,
    usr_id integer,
    observacion text,
    id_equipo integer,
    id_empleado_entrega integer
);


ALTER TABLE public.devolucion OWNER TO postgres;

--
-- TOC entry 205 (class 1259 OID 200429)
-- Name: devolucion_id_devolucion_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.devolucion_id_devolucion_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.devolucion_id_devolucion_seq OWNER TO postgres;

--
-- TOC entry 3481 (class 0 OID 0)
-- Dependencies: 205
-- Name: devolucion_id_devolucion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.devolucion_id_devolucion_seq OWNED BY public.devolucion.id_devolucion;


--
-- TOC entry 206 (class 1259 OID 200431)
-- Name: dummy; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dummy (
    id integer,
    text character varying(250)
);


ALTER TABLE public.dummy OWNER TO postgres;

--
-- TOC entry 207 (class 1259 OID 200434)
-- Name: dummy2; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dummy2 (
    id character varying(1),
    text character varying(250)
);


ALTER TABLE public.dummy2 OWNER TO postgres;

--
-- TOC entry 209 (class 1259 OID 200441)
-- Name: empleado_activo; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.empleado_activo AS
 SELECT empleado.id_empleado,
    (((empleado.primer_apellido)::text || ' '::text) || (empleado.primer_nombre)::text) AS nombres,
    empleado.cedula,
    empleado.direccion,
    empleado.email,
    empleado.id_departamento,
    empleado.id_telefono,
    empleado.id_estatus,
    empleado.cargo,
    empleado.active,
    empleado.fecha_elim,
    empleado.usr_id
   FROM public.empleado
  WHERE ((empleado.active IS NOT FALSE) AND (empleado.id_usuario = 0))
  ORDER BY empleado.id_empleado;


ALTER TABLE public.empleado_activo OWNER TO postgres;

--
-- TOC entry 210 (class 1259 OID 200446)
-- Name: estatus_empleado; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.estatus_empleado (
    id_estatus integer NOT NULL,
    estatus character varying(30),
    active boolean,
    fecha_elim date,
    usr_id integer
);


ALTER TABLE public.estatus_empleado OWNER TO postgres;

--
-- TOC entry 3482 (class 0 OID 0)
-- Dependencies: 210
-- Name: TABLE estatus_empleado; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.estatus_empleado IS 'Tabla que registra el estatus de los empleados';


--
-- TOC entry 3483 (class 0 OID 0)
-- Dependencies: 210
-- Name: COLUMN estatus_empleado.id_estatus; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.estatus_empleado.id_estatus IS 'Campo clave de la tabla estatus_empleado';


--
-- TOC entry 211 (class 1259 OID 200449)
-- Name: oficina_id_oficina_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.oficina_id_oficina_seq
    START WITH 492
    INCREMENT BY 1
    MINVALUE 491
    MAXVALUE 99999999999999999
    CACHE 1;


ALTER TABLE public.oficina_id_oficina_seq OWNER TO postgres;

--
-- TOC entry 212 (class 1259 OID 200451)
-- Name: oficina; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.oficina (
    id_oficina integer DEFAULT nextval('public.oficina_id_oficina_seq'::regclass) NOT NULL,
    nombre_oficina character varying(250),
    direccion text,
    codigo character varying(20),
    telefono character varying(12),
    id_parroquia character varying(12),
    active boolean,
    fecha_elim date,
    usr_id integer
);


ALTER TABLE public.oficina OWNER TO postgres;

--
-- TOC entry 3484 (class 0 OID 0)
-- Dependencies: 212
-- Name: TABLE oficina; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.oficina IS 'Tabla de las distintas Notarias y Registros adscritos al SAREN';


--
-- TOC entry 3485 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN oficina.id_oficina; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.oficina.id_oficina IS 'Campo identificador de la tabla oficina';


--
-- TOC entry 3486 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN oficina.nombre_oficina; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.oficina.nombre_oficina IS 'Nombre del Registro o Notaria';


--
-- TOC entry 3487 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN oficina.direccion; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.oficina.direccion IS 'Campo para la direccion de la Oficina(Notaria o Registro)';


--
-- TOC entry 3488 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN oficina.telefono; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.oficina.telefono IS 'Telefono de la Oficina';


--
-- TOC entry 3489 (class 0 OID 0)
-- Dependencies: 212
-- Name: COLUMN oficina.id_parroquia; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.oficina.id_parroquia IS 'Campo que relaciona la tabla oficina con la tabla parroquia';


--
-- TOC entry 213 (class 1259 OID 200458)
-- Name: ubicacion_v2; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ubicacion_v2 (
    id_ubicacion integer NOT NULL,
    ubicacion character varying(20),
    active boolean,
    fecha_elim date,
    usr_id integer
);


ALTER TABLE public.ubicacion_v2 OWNER TO postgres;

--
-- TOC entry 3490 (class 0 OID 0)
-- Dependencies: 213
-- Name: TABLE ubicacion_v2; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.ubicacion_v2 IS 'Tabla que registra las distintas ubicaciones donde puede encontrarse el equipo';


--
-- TOC entry 3491 (class 0 OID 0)
-- Dependencies: 213
-- Name: COLUMN ubicacion_v2.id_ubicacion; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.ubicacion_v2.id_ubicacion IS 'Campo clave de la tabla ubicacion';


--
-- TOC entry 3492 (class 0 OID 0)
-- Dependencies: 213
-- Name: COLUMN ubicacion_v2.ubicacion; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.ubicacion_v2.ubicacion IS 'Campo que registra las distintas locaciones donde puede encontrarse el equipo';


--
-- TOC entry 214 (class 1259 OID 200461)
-- Name: empleados; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.empleados AS
 SELECT empleado.id_empleado,
    empleado.primer_nombre,
    empleado.segundo_nombre,
    empleado.primer_apellido,
    empleado.segundo_apellido,
    empleado.cedula,
    empleado.direccion,
    empleado.email,
    empleado.id_departamento,
    (((departamento.nombre)::text || '-'::text) || (oficina.codigo)::text) AS nombre,
    empleado.telefono,
    empleado.id_estatus,
    estatus_empleado.estatus,
    empleado.cargo,
    (((oficina.nombre_oficina)::text || '-'::text) || (oficina.codigo)::text) AS nombre_oficina,
    empleado.id_oficina,
    empleado.id_ubicacion,
    ubicacion_v2.ubicacion,
    empleado.id_usuario,
    empleado.active
   FROM public.empleado,
    public.estatus_empleado,
    public.departamento,
    public.ubicacion_v2,
    public.oficina
  WHERE ((empleado.id_estatus = estatus_empleado.id_estatus) AND (empleado.id_departamento = departamento.id_departamento) AND (empleado.id_ubicacion = ubicacion_v2.id_ubicacion) AND (empleado.id_oficina = oficina.id_oficina))
  ORDER BY empleado.id_empleado;


ALTER TABLE public.empleados OWNER TO postgres;

--
-- TOC entry 215 (class 1259 OID 200466)
-- Name: empleados_sin_usuario; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.empleados_sin_usuario AS
 SELECT empleado.cedula,
    (((empleado.primer_nombre)::text || ' '::text) || (empleado.primer_apellido)::text) AS nombres,
    empleado.email,
    empleado.id_oficina,
    empleado.id_usuario
   FROM public.empleado
  WHERE (empleado.id_usuario = 0);


ALTER TABLE public.empleados_sin_usuario OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 200480)
-- Name: equipo_marca; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.equipo_marca (
    id integer NOT NULL,
    id_equipo integer,
    id_marca integer,
    active boolean,
    fecha_elim date,
    usr_id integer
);


ALTER TABLE public.equipo_marca OWNER TO postgres;

--
-- TOC entry 3493 (class 0 OID 0)
-- Dependencies: 219
-- Name: TABLE equipo_marca; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.equipo_marca IS 'Tabla que registra los indicadores de la relacion de los equipos con sus marcas';


--
-- TOC entry 3494 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN equipo_marca.id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipo_marca.id IS 'Campo clave de la tabla equipo_marca';


--
-- TOC entry 3495 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN equipo_marca.id_equipo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipo_marca.id_equipo IS 'Campo que relaciona la tabla equipo con la tabla marca';


--
-- TOC entry 3496 (class 0 OID 0)
-- Dependencies: 219
-- Name: COLUMN equipo_marca.id_marca; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.equipo_marca.id_marca IS 'Campo que relaciona la tabla marca con la tabla equipo';


--
-- TOC entry 220 (class 1259 OID 200483)
-- Name: equipo_marca_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.equipo_marca_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.equipo_marca_id_seq OWNER TO postgres;

--
-- TOC entry 3497 (class 0 OID 0)
-- Dependencies: 220
-- Name: equipo_marca_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.equipo_marca_id_seq OWNED BY public.equipo_marca.id;


--
-- TOC entry 221 (class 1259 OID 200485)
-- Name: estatus_equipo_v2; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.estatus_equipo_v2 (
    id_estatus_eq integer NOT NULL,
    estatus character varying(25),
    active boolean,
    fecha_elim date,
    usr_id integer
);


ALTER TABLE public.estatus_equipo_v2 OWNER TO postgres;

--
-- TOC entry 3498 (class 0 OID 0)
-- Dependencies: 221
-- Name: TABLE estatus_equipo_v2; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.estatus_equipo_v2 IS 'Tabla que registra el estatus del equipo tecnologico, que puede ser: asignado, prestado, dañado...';


--
-- TOC entry 222 (class 1259 OID 200488)
-- Name: proveedor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.proveedor (
    id_proveedor integer NOT NULL,
    nombre_prov character varying(30),
    direccion character varying(100),
    telefono integer,
    apellido_prov character varying(30),
    active boolean,
    fecha_elim date,
    usr_id integer
);


ALTER TABLE public.proveedor OWNER TO postgres;

--
-- TOC entry 3499 (class 0 OID 0)
-- Dependencies: 222
-- Name: TABLE proveedor; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.proveedor IS 'Tabla que registra los proveedores de los equipos';


--
-- TOC entry 3500 (class 0 OID 0)
-- Dependencies: 222
-- Name: COLUMN proveedor.id_proveedor; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.proveedor.id_proveedor IS 'Campo clave de la tabla proveedor';


--
-- TOC entry 3501 (class 0 OID 0)
-- Dependencies: 222
-- Name: COLUMN proveedor.nombre_prov; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.proveedor.nombre_prov IS 'Nombre del proveedor';


--
-- TOC entry 3502 (class 0 OID 0)
-- Dependencies: 222
-- Name: COLUMN proveedor.direccion; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.proveedor.direccion IS 'Direccion del Proveedor';


--
-- TOC entry 3503 (class 0 OID 0)
-- Dependencies: 222
-- Name: COLUMN proveedor.telefono; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.proveedor.telefono IS 'Numero de telefono del proveedor';


--
-- TOC entry 223 (class 1259 OID 200491)
-- Name: equipos; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.equipos AS
 SELECT equipo.id_equipo,
    equipo.cod_equipo,
    equipo.serial,
    estatus_equipo_v2.estatus,
    ubicacion_v2.ubicacion,
    equipo.num_bien_nac,
    equipo.descripcion,
    equipo.num_factura,
    equipo.fecha_factura,
    concat(proveedor.nombre_prov, ' ', proveedor.apellido_prov) AS proveedor,
    equipo.valor,
    articulo.articulo,
    equipo.active,
    equipo.fecha_elim,
    equipo.usr_id,
    equipo.id_solicitud_detalle_reserva
   FROM public.equipo,
    public.estatus_equipo_v2,
    public.ubicacion_v2,
    public.proveedor,
    public.articulo
  WHERE ((equipo.id_estatus = estatus_equipo_v2.id_estatus_eq) AND (equipo.id_ubicacion = ubicacion_v2.id_ubicacion) AND (equipo.id_proveedor = proveedor.id_proveedor) AND (equipo.id_articulo = articulo.id_articulo));


ALTER TABLE public.equipos OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 200496)
-- Name: equipos_disponibles; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.equipos_disponibles AS
 SELECT equipo.id_equipo,
    equipo.cod_equipo,
    equipo.serial,
    equipo.id_estatus,
    estatus_equipo_v2.estatus,
    equipo.id_ubicacion,
    ubicacion_v2.ubicacion,
    equipo.num_bien_nac,
    equipo.descripcion,
    equipo.num_factura,
    equipo.fecha_factura,
    equipo.id_proveedor,
    proveedor.nombre_prov,
    proveedor.apellido_prov,
    equipo.valor,
    equipo.id_articulo,
    articulo.articulo
   FROM public.equipo,
    public.estatus_equipo_v2,
    public.ubicacion_v2,
    public.articulo,
    public.proveedor
  WHERE ((equipo.id_estatus = estatus_equipo_v2.id_estatus_eq) AND (equipo.id_ubicacion = ubicacion_v2.id_ubicacion) AND (equipo.id_articulo = articulo.id_articulo) AND (equipo.id_proveedor = proveedor.id_proveedor) AND (equipo.active IS NOT FALSE) AND (equipo.id_estatus = 5) AND (length((equipo.num_bien_nac)::text) > 0) AND (equipo.id_solicitud_detalle_reserva = 0))
  ORDER BY equipo.id_equipo;


ALTER TABLE public.equipos_disponibles OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 200501)
-- Name: equipos_itinerantes; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.equipos_itinerantes AS
 SELECT equipo.id_equipo,
    equipo.cod_equipo,
    equipo.serial,
    estatus_equipo_v2.estatus,
    ubicacion_v2.ubicacion,
    equipo.num_bien_nac,
    equipo.descripcion,
    equipo.num_factura,
    equipo.fecha_factura,
    equipo.valor,
    oficina.nombre_oficina,
    departamento.nombre,
    equipo.id_estatus,
    equipo.id_ubicacion,
    equipo.id_solicitud_detalle_reserva
   FROM public.equipo,
    public.oficina,
    public.departamento,
    public.estatus_equipo_v2,
    public.ubicacion_v2
  WHERE ((equipo.id_estatus = estatus_equipo_v2.id_estatus_eq) AND (equipo.id_oficina = oficina.id_oficina) AND (equipo.id_departamento = departamento.id_departamento) AND (equipo.id_ubicacion = ubicacion_v2.id_ubicacion) AND (equipo.id_estatus <> 5))
  ORDER BY equipo.id_equipo;


ALTER TABLE public.equipos_itinerantes OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 200506)
-- Name: funcionario; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.funcionario AS
 SELECT empleado.id_empleado AS id_funcionario,
    empleado.id_oficina,
    concat(empleado.primer_nombre, ' ', empleado.segundo_nombre) AS nombre,
    concat(empleado.primer_apellido, ' ', empleado.segundo_apellido) AS apellido,
    empleado.cedula,
    empleado.id_telefono AS telefono,
    empleado.email,
    empleado.cargo,
    empleado.active,
    empleado.fecha_elim,
    empleado.usr_id,
    empleado.id_usuario
   FROM public.empleado
  WHERE ((empleado.id_usuario > 0) AND (empleado.active IS NOT FALSE));


ALTER TABLE public.funcionario OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 200510)
-- Name: solicitud_solicitud_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.solicitud_solicitud_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 99999999999999999
    CACHE 1;


ALTER TABLE public.solicitud_solicitud_id_seq OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 200512)
-- Name: solicitud; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.solicitud (
    id_solicitud integer DEFAULT nextval('public.solicitud_solicitud_id_seq'::regclass) NOT NULL,
    id_equipo integer,
    id_funcionario integer,
    id_empleado integer,
    descripcion character varying(100),
    fecha_solicitud date,
    id_tipo_solicitud integer,
    id_estatus_solicitud integer,
    active boolean,
    fecha_elim date,
    usr_id integer,
    id_orden integer DEFAULT 0,
    id_ubicacion integer DEFAULT 1,
    id_oficina integer DEFAULT 0,
    id_departamento integer DEFAULT 0
);


ALTER TABLE public.solicitud OWNER TO postgres;

--
-- TOC entry 3504 (class 0 OID 0)
-- Dependencies: 228
-- Name: TABLE solicitud; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.solicitud IS 'Tabla que registra las solicitudes de equipos';


--
-- TOC entry 3505 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN solicitud.id_solicitud; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.solicitud.id_solicitud IS 'Campo clave de la tabla solicitud';


--
-- TOC entry 3506 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN solicitud.id_equipo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.solicitud.id_equipo IS 'Campo que relaciona la tabla solicitud a la tabla equipo';


--
-- TOC entry 3507 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN solicitud.id_funcionario; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.solicitud.id_funcionario IS 'Campo que relaciona la tabla solicitud con la tabla funcionario';


--
-- TOC entry 3508 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN solicitud.id_empleado; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.solicitud.id_empleado IS 'Campo que relaciona la tabla solicitud con la tabla usuario';


--
-- TOC entry 3509 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN solicitud.descripcion; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.solicitud.descripcion IS 'Descripcion de la Solicitud';


--
-- TOC entry 3510 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN solicitud.fecha_solicitud; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.solicitud.fecha_solicitud IS 'Campo Fecha de la solicitud';


--
-- TOC entry 229 (class 1259 OID 200520)
-- Name: solicitud_detalle; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.solicitud_detalle (
    id_solicitud_detalle integer NOT NULL,
    id_solicitud integer,
    id_equipo integer,
    active boolean,
    fecha_elim date,
    usr_id integer,
    asignado boolean DEFAULT false
);


ALTER TABLE public.solicitud_detalle OWNER TO postgres;

--
-- TOC entry 3511 (class 0 OID 0)
-- Dependencies: 229
-- Name: TABLE solicitud_detalle; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.solicitud_detalle IS 'Tabla que contiene el detalle de los equipos o articulos solicitados';


--
-- TOC entry 230 (class 1259 OID 200524)
-- Name: equipos_itinerantes_ori; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.equipos_itinerantes_ori AS
 SELECT solicitud_detalle.id_equipo,
    equipo.cod_equipo,
    equipo.serial,
    equipo.num_bien_nac,
    equipo.descripcion AS descripcion_equipo,
    articulo.articulo,
    solicitud_detalle.id_solicitud,
    solicitud.id_funcionario,
    solicitud.id_empleado,
    solicitud.descripcion AS descripcion_solicitud,
    solicitud.fecha_solicitud,
    empleado.primer_apellido,
    empleado.segundo_apellido,
    empleado.primer_nombre,
    empleado.segundo_nombre,
    funcionario.apellido,
    funcionario.nombre,
    estatus_equipo_v2.estatus,
    solicitud_detalle.id_solicitud_detalle
   FROM public.solicitud_detalle,
    public.equipo,
    public.articulo,
    public.solicitud,
    public.empleado,
    public.funcionario,
    public.estatus_equipo_v2
  WHERE ((solicitud_detalle.id_equipo = equipo.id_equipo) AND (solicitud_detalle.id_solicitud = solicitud.id_solicitud) AND (equipo.id_articulo = articulo.id_articulo) AND (equipo.id_estatus = estatus_equipo_v2.id_estatus_eq) AND (solicitud.id_empleado = empleado.id_empleado) AND (solicitud.id_funcionario = funcionario.id_funcionario) AND (equipo.id_estatus <> 5) AND (solicitud_detalle.asignado = true))
  ORDER BY equipo.id_equipo;


ALTER TABLE public.equipos_itinerantes_ori OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 200529)
-- Name: equipos_reservados; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.equipos_reservados AS
 SELECT equipo.id_equipo,
    equipo.cod_equipo,
    equipo.serial,
    equipo.id_estatus,
    estatus_equipo_v2.estatus,
    equipo.id_ubicacion,
    ubicacion_v2.ubicacion,
    equipo.num_bien_nac,
    equipo.descripcion,
    equipo.num_factura,
    equipo.fecha_factura,
    equipo.id_proveedor,
    proveedor.nombre_prov,
    proveedor.apellido_prov,
    equipo.valor,
    equipo.id_articulo,
    articulo.articulo,
    equipo.id_solicitud_detalle_reserva AS id_solicitud
   FROM public.equipo,
    public.estatus_equipo_v2,
    public.ubicacion_v2,
    public.articulo,
    public.proveedor
  WHERE ((equipo.id_estatus = estatus_equipo_v2.id_estatus_eq) AND (equipo.id_ubicacion = ubicacion_v2.id_ubicacion) AND (equipo.id_articulo = articulo.id_articulo) AND (equipo.id_proveedor = proveedor.id_proveedor) AND (equipo.active IS NOT FALSE) AND (equipo.id_estatus = 5) AND (length((equipo.num_bien_nac)::text) > 0) AND (equipo.id_solicitud_detalle_reserva > 0))
  ORDER BY equipo.id_equipo;


ALTER TABLE public.equipos_reservados OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 200534)
-- Name: equipos_sin_bn; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.equipos_sin_bn AS
 SELECT equipo.id_equipo,
    equipo.cod_equipo,
    equipo.serial,
    equipo.id_estatus,
    estatus_equipo_v2.estatus,
    equipo.id_ubicacion,
    ubicacion_v2.ubicacion,
    equipo.num_bien_nac,
    equipo.descripcion,
    equipo.num_factura,
    equipo.fecha_factura,
    equipo.id_proveedor,
    (((proveedor.nombre_prov)::text || ' '::text) || (proveedor.apellido_prov)::text) AS proveedor,
    equipo.valor,
    equipo.id_articulo,
    articulo.articulo
   FROM public.equipo,
    public.estatus_equipo_v2,
    public.ubicacion_v2,
    public.articulo,
    public.proveedor
  WHERE ((equipo.id_estatus = estatus_equipo_v2.id_estatus_eq) AND (equipo.id_ubicacion = ubicacion_v2.id_ubicacion) AND (equipo.id_articulo = articulo.id_articulo) AND (equipo.id_proveedor = proveedor.id_proveedor) AND (equipo.active IS NOT FALSE) AND ((equipo.num_bien_nac IS NULL) OR (length((equipo.num_bien_nac)::text) = 0)))
  ORDER BY equipo.id_equipo;


ALTER TABLE public.equipos_sin_bn OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 200539)
-- Name: estado; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.estado (
    id_estado character varying(2) NOT NULL,
    nombre_estado character varying(50) NOT NULL,
    active boolean,
    fecha_elim date,
    usr_id integer
);


ALTER TABLE public.estado OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 200543)
-- Name: estatus_empleado_id_estatus_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.estatus_empleado_id_estatus_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.estatus_empleado_id_estatus_seq OWNER TO postgres;

--
-- TOC entry 3512 (class 0 OID 0)
-- Dependencies: 234
-- Name: estatus_empleado_id_estatus_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.estatus_empleado_id_estatus_seq OWNED BY public.estatus_empleado.id_estatus;


--
-- TOC entry 235 (class 1259 OID 200545)
-- Name: estatus_equipo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.estatus_equipo (
    id_estatus_eq integer NOT NULL,
    id_equipo integer,
    estatus character varying(15),
    active boolean,
    fecha_elim date,
    usr_id integer
);


ALTER TABLE public.estatus_equipo OWNER TO postgres;

--
-- TOC entry 3513 (class 0 OID 0)
-- Dependencies: 235
-- Name: TABLE estatus_equipo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.estatus_equipo IS 'Tabla que registra el estatus del equipo tecnologico, que puede ser: asignado, prestado, dañado...';


--
-- TOC entry 3514 (class 0 OID 0)
-- Dependencies: 235
-- Name: COLUMN estatus_equipo.id_estatus_eq; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.estatus_equipo.id_estatus_eq IS 'Campo clave de la tabla estatus_equipo';


--
-- TOC entry 3515 (class 0 OID 0)
-- Dependencies: 235
-- Name: COLUMN estatus_equipo.id_equipo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.estatus_equipo.id_equipo IS 'Campo que relaciona la tabla estatus_equipo con la tabla equipo';


--
-- TOC entry 3516 (class 0 OID 0)
-- Dependencies: 235
-- Name: COLUMN estatus_equipo.estatus; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.estatus_equipo.estatus IS 'Campo que registra los distintos estatus del equipo';


--
-- TOC entry 236 (class 1259 OID 200548)
-- Name: estatus_equipo_id_estatus_eq_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.estatus_equipo_id_estatus_eq_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.estatus_equipo_id_estatus_eq_seq OWNER TO postgres;

--
-- TOC entry 3517 (class 0 OID 0)
-- Dependencies: 236
-- Name: estatus_equipo_id_estatus_eq_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.estatus_equipo_id_estatus_eq_seq OWNED BY public.estatus_equipo.id_estatus_eq;


--
-- TOC entry 237 (class 1259 OID 200550)
-- Name: estatus_equipo_v2_id_estatus_eq_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.estatus_equipo_v2_id_estatus_eq_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.estatus_equipo_v2_id_estatus_eq_seq OWNER TO postgres;

--
-- TOC entry 3518 (class 0 OID 0)
-- Dependencies: 237
-- Name: estatus_equipo_v2_id_estatus_eq_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.estatus_equipo_v2_id_estatus_eq_seq OWNED BY public.estatus_equipo_v2.id_estatus_eq;


--
-- TOC entry 238 (class 1259 OID 200552)
-- Name: estatus_solicitud; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.estatus_solicitud (
    id_estatus_solicitud integer NOT NULL,
    descripcion character varying(50),
    active boolean,
    fecha_elim date,
    usr_id integer
);


ALTER TABLE public.estatus_solicitud OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 200566)
-- Name: funcionario_activo; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.funcionario_activo AS
 SELECT funcionario.id_funcionario,
    funcionario.id_oficina,
    ((funcionario.apellido || ' '::text) || funcionario.nombre) AS nombres,
    funcionario.cedula,
    funcionario.telefono,
    funcionario.email,
    funcionario.cargo,
    funcionario.active,
    funcionario.fecha_elim,
    funcionario.usr_id
   FROM public.funcionario,
    public.usuario
  WHERE ((funcionario.id_usuario = usuario.id) AND (funcionario.active IS NOT FALSE) AND (usuario.active IS NOT FALSE))
  ORDER BY funcionario.id_funcionario;


ALTER TABLE public.funcionario_activo OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 200570)
-- Name: funcionario_old; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.funcionario_old (
    id_funcionario integer NOT NULL,
    id_oficina integer,
    nombre character varying(20),
    apellido character varying(20),
    cedula integer,
    telefono integer,
    email character varying(30),
    cargo character varying(20),
    active boolean,
    fecha_elim date,
    usr_id integer
);


ALTER TABLE public.funcionario_old OWNER TO postgres;

--
-- TOC entry 3519 (class 0 OID 0)
-- Dependencies: 242
-- Name: TABLE funcionario_old; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.funcionario_old IS 'Tabla que registra los dintintos funcionarios que realizan solicitudes de equipos al SAREN';


--
-- TOC entry 3520 (class 0 OID 0)
-- Dependencies: 242
-- Name: COLUMN funcionario_old.id_funcionario; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.funcionario_old.id_funcionario IS 'Campo identificador de la tabla funcionario';


--
-- TOC entry 3521 (class 0 OID 0)
-- Dependencies: 242
-- Name: COLUMN funcionario_old.id_oficina; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.funcionario_old.id_oficina IS 'Campo que relaciona la tabla funcionario con la tabla oficina';


--
-- TOC entry 3522 (class 0 OID 0)
-- Dependencies: 242
-- Name: COLUMN funcionario_old.nombre; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.funcionario_old.nombre IS 'Primer nombre del funcionario';


--
-- TOC entry 3523 (class 0 OID 0)
-- Dependencies: 242
-- Name: COLUMN funcionario_old.apellido; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.funcionario_old.apellido IS 'Primer apellido del funcionario';


--
-- TOC entry 3524 (class 0 OID 0)
-- Dependencies: 242
-- Name: COLUMN funcionario_old.cedula; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.funcionario_old.cedula IS 'Campo que registra la cedula del funcionario';


--
-- TOC entry 3525 (class 0 OID 0)
-- Dependencies: 242
-- Name: COLUMN funcionario_old.telefono; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.funcionario_old.telefono IS 'Campo que registra el telefono del funcionario';


--
-- TOC entry 3526 (class 0 OID 0)
-- Dependencies: 242
-- Name: COLUMN funcionario_old.email; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.funcionario_old.email IS 'Campo que registra el email del funcionario';


--
-- TOC entry 3527 (class 0 OID 0)
-- Dependencies: 242
-- Name: COLUMN funcionario_old.cargo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.funcionario_old.cargo IS 'Cargo del funcionario';


--
-- TOC entry 243 (class 1259 OID 200573)
-- Name: funcionario_id_funcionario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.funcionario_id_funcionario_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.funcionario_id_funcionario_seq OWNER TO postgres;

--
-- TOC entry 3528 (class 0 OID 0)
-- Dependencies: 243
-- Name: funcionario_id_funcionario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.funcionario_id_funcionario_seq OWNED BY public.funcionario_old.id_funcionario;


--
-- TOC entry 244 (class 1259 OID 200575)
-- Name: marca; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.marca (
    id_marca integer NOT NULL,
    descripcion character varying(30),
    active boolean,
    fecha_elim date,
    usr_id integer
);


ALTER TABLE public.marca OWNER TO postgres;

--
-- TOC entry 3529 (class 0 OID 0)
-- Dependencies: 244
-- Name: TABLE marca; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.marca IS 'Tabla que registra las distintas marcas de los equipos tecnologicos';


--
-- TOC entry 3530 (class 0 OID 0)
-- Dependencies: 244
-- Name: COLUMN marca.id_marca; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.marca.id_marca IS 'Campo clave de la tabla marca';


--
-- TOC entry 3531 (class 0 OID 0)
-- Dependencies: 244
-- Name: COLUMN marca.descripcion; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.marca.descripcion IS 'Campo que registra la descripcion de la marca de los equipos tecnologicos';


--
-- TOC entry 245 (class 1259 OID 200578)
-- Name: marca_id_marca_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.marca_id_marca_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.marca_id_marca_seq OWNER TO postgres;

--
-- TOC entry 3532 (class 0 OID 0)
-- Dependencies: 245
-- Name: marca_id_marca_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.marca_id_marca_seq OWNED BY public.marca.id_marca;


--
-- TOC entry 246 (class 1259 OID 200580)
-- Name: modelo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.modelo (
    id_modelo integer NOT NULL,
    id_equipo integer,
    id_marca integer,
    descripcion character varying(100),
    active boolean,
    fecha_elim date,
    usr_id integer
);


ALTER TABLE public.modelo OWNER TO postgres;

--
-- TOC entry 3533 (class 0 OID 0)
-- Dependencies: 246
-- Name: TABLE modelo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.modelo IS 'Tabla que registra el modelo de los equipos tecnologicos';


--
-- TOC entry 3534 (class 0 OID 0)
-- Dependencies: 246
-- Name: COLUMN modelo.id_modelo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.modelo.id_modelo IS 'Campo clave de la tabla modelo';


--
-- TOC entry 3535 (class 0 OID 0)
-- Dependencies: 246
-- Name: COLUMN modelo.id_equipo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.modelo.id_equipo IS 'Campo quie relaciona la tabla modelo con la tabla equipo';


--
-- TOC entry 3536 (class 0 OID 0)
-- Dependencies: 246
-- Name: COLUMN modelo.id_marca; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.modelo.id_marca IS 'Tabla que relaciona la tabla modelo con la tabla marca';


--
-- TOC entry 3537 (class 0 OID 0)
-- Dependencies: 246
-- Name: COLUMN modelo.descripcion; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.modelo.descripcion IS 'Campo que registra la descripcion del modelo de los equipos';


--
-- TOC entry 247 (class 1259 OID 200583)
-- Name: modelo_id_modelo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.modelo_id_modelo_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.modelo_id_modelo_seq OWNER TO postgres;

--
-- TOC entry 3538 (class 0 OID 0)
-- Dependencies: 247
-- Name: modelo_id_modelo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.modelo_id_modelo_seq OWNED BY public.modelo.id_modelo;


--
-- TOC entry 289 (class 1259 OID 200966)
-- Name: motivo_id_motivo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.motivo_id_motivo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.motivo_id_motivo_seq OWNER TO postgres;

--
-- TOC entry 3539 (class 0 OID 0)
-- Dependencies: 289
-- Name: motivo_id_motivo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.motivo_id_motivo_seq OWNED BY public.motivo.id_motivo;


--
-- TOC entry 248 (class 1259 OID 200585)
-- Name: municipio; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.municipio (
    id_municipio character varying(4) NOT NULL,
    nombre_municipio character varying(50) NOT NULL,
    id_estado character varying(2) NOT NULL,
    active boolean,
    fecha_elim date,
    usr_id integer
);


ALTER TABLE public.municipio OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 200588)
-- Name: orden_salida; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.orden_salida (
    id_orden integer NOT NULL,
    num_orden integer,
    id_solicitud integer,
    observacionx character varying(100),
    id_emp integer,
    id_funcionario integer,
    id_equipo integer,
    active boolean,
    fecha_elim date,
    usr_id integer,
    fecha_generacion date DEFAULT now(),
    id_empleado_retira integer,
    observacion text
);


ALTER TABLE public.orden_salida OWNER TO postgres;

--
-- TOC entry 3540 (class 0 OID 0)
-- Dependencies: 249
-- Name: TABLE orden_salida; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.orden_salida IS 'Tabla que registra las ordenes de salida de los distintos equipos';


--
-- TOC entry 3541 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN orden_salida.id_orden; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.orden_salida.id_orden IS 'Campo clave de la tabla orden_salida';


--
-- TOC entry 3542 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN orden_salida.num_orden; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.orden_salida.num_orden IS 'Campo que registra el numero de orden de la tabla orden_salida';


--
-- TOC entry 3543 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN orden_salida.id_solicitud; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.orden_salida.id_solicitud IS 'Campo que relaciona la tabla orden_salida con la tabla solicitud';


--
-- TOC entry 3544 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN orden_salida.observacionx; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.orden_salida.observacionx IS 'Campo que registra las observaciones de las ordenes de salida';


--
-- TOC entry 3545 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN orden_salida.id_emp; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.orden_salida.id_emp IS 'Campo que relaciona la tabla orden_salida con la tabla empleado';


--
-- TOC entry 3546 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN orden_salida.id_funcionario; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.orden_salida.id_funcionario IS 'Campo que relaciona la tabla orden_salida con la tabla funcionario';


--
-- TOC entry 3547 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN orden_salida.id_equipo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.orden_salida.id_equipo IS 'Campo que relaciona la tabla orden_salida con la tabla equipo';


--
-- TOC entry 250 (class 1259 OID 200595)
-- Name: orden_salida_id_orden_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.orden_salida_id_orden_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.orden_salida_id_orden_seq OWNER TO postgres;

--
-- TOC entry 3548 (class 0 OID 0)
-- Dependencies: 250
-- Name: orden_salida_id_orden_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.orden_salida_id_orden_seq OWNED BY public.orden_salida.id_orden;


--
-- TOC entry 251 (class 1259 OID 200597)
-- Name: tipo_solicitud; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipo_solicitud (
    id_tipo_solicitud integer NOT NULL,
    descripcion character varying(50),
    active boolean,
    fecha_elim date,
    usr_id integer
);


ALTER TABLE public.tipo_solicitud OWNER TO postgres;

--
-- TOC entry 252 (class 1259 OID 200600)
-- Name: solicitudes; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.solicitudes AS
 SELECT solicitud.id_solicitud,
    (((empleado.primer_nombre)::text || ' '::text) || (empleado.primer_apellido)::text) AS empleado,
    ((funcionario.nombre || ' '::text) || funcionario.apellido) AS funcionario,
    solicitud.descripcion,
    solicitud.fecha_solicitud,
    tipo_solicitud.descripcion AS tipo_solicitud,
    estatus_solicitud.descripcion AS estatus_solicitud,
    solicitud.active,
    solicitud.id_tipo_solicitud,
    solicitud.id_estatus_solicitud,
    solicitud.id_orden,
    ( SELECT count(solicitud_detalle.id_solicitud_detalle) AS count
           FROM public.solicitud_detalle
          WHERE (solicitud.id_solicitud = solicitud_detalle.id_solicitud)) AS solicitados
   FROM public.solicitud,
    public.empleado,
    public.funcionario,
    public.estatus_solicitud,
    public.tipo_solicitud
  WHERE ((solicitud.id_funcionario = funcionario.id_funcionario) AND (solicitud.id_empleado = empleado.id_empleado) AND (solicitud.id_tipo_solicitud = tipo_solicitud.id_tipo_solicitud) AND (solicitud.id_estatus_solicitud = estatus_solicitud.id_estatus_solicitud))
  ORDER BY solicitud.id_solicitud DESC;


ALTER TABLE public.solicitudes OWNER TO postgres;

--
-- TOC entry 253 (class 1259 OID 200605)
-- Name: ordenes_salida; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.ordenes_salida AS
 SELECT orden_salida.id_orden,
    orden_salida.num_orden,
    orden_salida.observacion,
    solicitudes.descripcion,
    solicitudes.fecha_solicitud,
    solicitudes.id_solicitud
   FROM public.orden_salida,
    public.solicitudes
  WHERE (orden_salida.id_solicitud = solicitudes.id_solicitud)
  ORDER BY orden_salida.id_orden DESC;


ALTER TABLE public.ordenes_salida OWNER TO postgres;

--
-- TOC entry 254 (class 1259 OID 200609)
-- Name: ordenes_salidax; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.ordenes_salidax AS
 SELECT orden_salida.id_orden,
    orden_salida.num_orden,
    orden_salida.observacionx AS observacion,
    solicitudes.descripcion,
    solicitudes.fecha_solicitud
   FROM public.orden_salida,
    public.solicitudes
  WHERE (orden_salida.id_solicitud = solicitudes.id_solicitud)
  ORDER BY orden_salida.id_orden DESC;


ALTER TABLE public.ordenes_salidax OWNER TO postgres;

--
-- TOC entry 255 (class 1259 OID 200613)
-- Name: parroquia; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.parroquia (
    id_parroquia character varying(12) NOT NULL,
    nombre_parroquia character varying(50) NOT NULL,
    id_municipio character varying(4) NOT NULL,
    active boolean,
    fecha_elim date,
    usr_id integer
);


ALTER TABLE public.parroquia OWNER TO postgres;

--
-- TOC entry 256 (class 1259 OID 200616)
-- Name: permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.permissions (
    perm_id integer NOT NULL,
    perm_desc character varying(60),
    accion character varying(100),
    active boolean,
    fecha_elim date,
    usr_id integer
);


ALTER TABLE public.permissions OWNER TO postgres;

--
-- TOC entry 293 (class 1259 OID 208048)
-- Name: permisos; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.permisos AS
 SELECT permissions.perm_id,
    (((permissions.perm_desc)::text || ' Accion:'::text) || (permissions.accion)::text) AS permiso,
    permissions.active
   FROM public.permissions
  WHERE (permissions.active IS NOT FALSE)
  ORDER BY permissions.perm_id;


ALTER TABLE public.permisos OWNER TO postgres;

--
-- TOC entry 257 (class 1259 OID 200619)
-- Name: permissions_perm_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.permissions_perm_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.permissions_perm_id_seq OWNER TO postgres;

--
-- TOC entry 3549 (class 0 OID 0)
-- Dependencies: 257
-- Name: permissions_perm_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.permissions_perm_id_seq OWNED BY public.permissions.perm_id;


--
-- TOC entry 258 (class 1259 OID 200621)
-- Name: proveedor_id_proveedor_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.proveedor_id_proveedor_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.proveedor_id_proveedor_seq OWNER TO postgres;

--
-- TOC entry 3550 (class 0 OID 0)
-- Dependencies: 258
-- Name: proveedor_id_proveedor_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.proveedor_id_proveedor_seq OWNED BY public.proveedor.id_proveedor;


--
-- TOC entry 259 (class 1259 OID 200623)
-- Name: reserva; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reserva (
    id_reserva integer NOT NULL,
    id_solicitud integer,
    fecha_reserva date DEFAULT now(),
    observacion character varying(100),
    id_equipo integer,
    active boolean,
    fecha_elim date,
    usr_id integer
);


ALTER TABLE public.reserva OWNER TO postgres;

--
-- TOC entry 3551 (class 0 OID 0)
-- Dependencies: 259
-- Name: TABLE reserva; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.reserva IS 'Tabla que registra las reservas de equipos, las mismas se realizan cuando no hay equipos disponibles al momento de la solicitud.';


--
-- TOC entry 3552 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN reserva.id_reserva; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reserva.id_reserva IS 'Campo clave de la tabla reserva';


--
-- TOC entry 3553 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN reserva.id_solicitud; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reserva.id_solicitud IS 'Campo que relaciona la tabla reserva con la tabla solicitud';


--
-- TOC entry 3554 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN reserva.fecha_reserva; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reserva.fecha_reserva IS 'Campo que registra la fecha de reserva del equipo';


--
-- TOC entry 3555 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN reserva.observacion; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reserva.observacion IS 'Campo que registra las observaciones al momento de realizar la reserva';


--
-- TOC entry 3556 (class 0 OID 0)
-- Dependencies: 259
-- Name: COLUMN reserva.id_equipo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.reserva.id_equipo IS 'Campo que relaciona la tabla reserva con la tabla equipo';


--
-- TOC entry 260 (class 1259 OID 200627)
-- Name: reserva_id_reserva_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.reserva_id_reserva_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.reserva_id_reserva_seq OWNER TO postgres;

--
-- TOC entry 3557 (class 0 OID 0)
-- Dependencies: 260
-- Name: reserva_id_reserva_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.reserva_id_reserva_seq OWNED BY public.reserva.id_reserva;


--
-- TOC entry 261 (class 1259 OID 200629)
-- Name: rol; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rol (
    id_rol integer NOT NULL,
    descripcion character varying(60),
    active boolean,
    fecha_elim date,
    usr_id integer
);


ALTER TABLE public.rol OWNER TO postgres;

--
-- TOC entry 262 (class 1259 OID 200632)
-- Name: role_perm_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.role_perm_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.role_perm_id_seq OWNER TO postgres;

--
-- TOC entry 263 (class 1259 OID 200634)
-- Name: role_perm; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.role_perm (
    role_id integer NOT NULL,
    perm_id integer NOT NULL,
    id integer DEFAULT nextval('public.role_perm_id_seq'::regclass) NOT NULL,
    active boolean,
    fecha_elim date,
    usr_id integer
);


ALTER TABLE public.role_perm OWNER TO postgres;

--
-- TOC entry 264 (class 1259 OID 200638)
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    role_id integer NOT NULL,
    role_name character varying(60),
    active boolean,
    fecha_elim date,
    usr_id integer
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- TOC entry 292 (class 1259 OID 200979)
-- Name: roles_permisos; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.roles_permisos AS
 SELECT role_perm.id,
    role_perm.role_id,
    roles.role_name,
    role_perm.perm_id,
    permissions.perm_desc,
    permissions.accion,
    role_perm.active,
    role_perm.fecha_elim,
    role_perm.usr_id
   FROM public.role_perm,
    public.roles,
    public.permissions
  WHERE ((role_perm.perm_id = permissions.perm_id) AND (role_perm.role_id = roles.role_id))
  ORDER BY role_perm.id;


ALTER TABLE public.roles_permisos OWNER TO postgres;

--
-- TOC entry 265 (class 1259 OID 200645)
-- Name: roles_role_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.roles_role_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.roles_role_id_seq OWNER TO postgres;

--
-- TOC entry 3558 (class 0 OID 0)
-- Dependencies: 265
-- Name: roles_role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.roles_role_id_seq OWNED BY public.roles.role_id;


--
-- TOC entry 266 (class 1259 OID 200647)
-- Name: solicitud_detalle_id_solicitud_detalle_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.solicitud_detalle_id_solicitud_detalle_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.solicitud_detalle_id_solicitud_detalle_seq OWNER TO postgres;

--
-- TOC entry 3559 (class 0 OID 0)
-- Dependencies: 266
-- Name: solicitud_detalle_id_solicitud_detalle_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.solicitud_detalle_id_solicitud_detalle_seq OWNED BY public.solicitud_detalle.id_solicitud_detalle;


--
-- TOC entry 267 (class 1259 OID 200649)
-- Name: solicitudes_canceladas; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.solicitudes_canceladas AS
 SELECT solicitudes.id_solicitud,
    solicitudes.empleado,
    solicitudes.funcionario,
    solicitudes.descripcion,
    solicitudes.fecha_solicitud,
    solicitudes.tipo_solicitud,
    solicitudes.estatus_solicitud,
    solicitudes.active,
    solicitudes.solicitados
   FROM public.solicitudes
  WHERE ((solicitudes.solicitados > 0) AND (solicitudes.id_estatus_solicitud = 4))
  ORDER BY solicitudes.id_solicitud DESC;


ALTER TABLE public.solicitudes_canceladas OWNER TO postgres;

--
-- TOC entry 268 (class 1259 OID 200653)
-- Name: solicitudes_detalles; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.solicitudes_detalles AS
 SELECT solicitud_detalle.id_solicitud_detalle,
    solicitud_detalle.id_solicitud,
    solicitud_detalle.id_equipo,
    equipo.cod_equipo,
    equipo.serial,
    equipo.num_bien_nac,
    equipo.descripcion,
    equipo.valor,
    solicitud_detalle.active,
    solicitud_detalle.fecha_elim,
    solicitud_detalle.usr_id,
    solicitud_detalle.asignado,
    solicitud.id_tipo_solicitud
   FROM public.solicitud_detalle,
    public.equipo,
    public.solicitud
  WHERE ((solicitud_detalle.id_equipo = equipo.id_equipo) AND (solicitud.id_solicitud = solicitud_detalle.id_solicitud))
  ORDER BY solicitud_detalle.id_solicitud_detalle;


ALTER TABLE public.solicitudes_detalles OWNER TO postgres;

--
-- TOC entry 269 (class 1259 OID 200657)
-- Name: solicitudes_parcialmente_procesadas; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.solicitudes_parcialmente_procesadas AS
 SELECT solicitudes.id_solicitud,
    solicitudes.empleado,
    solicitudes.funcionario,
    solicitudes.descripcion,
    solicitudes.fecha_solicitud,
    solicitudes.tipo_solicitud,
    solicitudes.estatus_solicitud,
    solicitudes.active,
    solicitudes.solicitados
   FROM public.solicitudes
  WHERE ((solicitudes.solicitados > 0) AND (solicitudes.id_estatus_solicitud = 2))
  ORDER BY solicitudes.id_solicitud DESC;


ALTER TABLE public.solicitudes_parcialmente_procesadas OWNER TO postgres;

--
-- TOC entry 270 (class 1259 OID 200661)
-- Name: solicitudes_pendientes; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.solicitudes_pendientes AS
 SELECT solicitudes.id_solicitud,
    solicitudes.empleado,
    solicitudes.funcionario,
    solicitudes.descripcion,
    solicitudes.fecha_solicitud,
    solicitudes.tipo_solicitud,
    solicitudes.estatus_solicitud,
    solicitudes.active,
    solicitudes.solicitados
   FROM public.solicitudes
  WHERE ((solicitudes.solicitados > 0) AND (solicitudes.id_estatus_solicitud = ANY (ARRAY[2, 3])))
  ORDER BY solicitudes.id_solicitud DESC;


ALTER TABLE public.solicitudes_pendientes OWNER TO postgres;

--
-- TOC entry 271 (class 1259 OID 200665)
-- Name: solicitudes_pendientes_sin_detalle; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.solicitudes_pendientes_sin_detalle AS
 SELECT solicitudes.id_solicitud,
    solicitudes.empleado,
    solicitudes.funcionario,
    solicitudes.descripcion,
    solicitudes.fecha_solicitud,
    solicitudes.tipo_solicitud,
    solicitudes.estatus_solicitud,
    solicitudes.active,
    solicitudes.solicitados
   FROM public.solicitudes
  WHERE ((solicitudes.solicitados = 0) AND (solicitudes.id_estatus_solicitud = 3))
  ORDER BY solicitudes.id_solicitud DESC;


ALTER TABLE public.solicitudes_pendientes_sin_detalle OWNER TO postgres;

--
-- TOC entry 272 (class 1259 OID 200669)
-- Name: solicitudes_procesadas; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.solicitudes_procesadas AS
 SELECT solicitudes.id_solicitud,
    solicitudes.empleado,
    solicitudes.funcionario,
    solicitudes.descripcion,
    solicitudes.fecha_solicitud,
    solicitudes.tipo_solicitud,
    solicitudes.estatus_solicitud,
    solicitudes.active,
    solicitudes.solicitados
   FROM public.solicitudes
  WHERE ((solicitudes.solicitados > 0) AND (solicitudes.id_estatus_solicitud = 1))
  ORDER BY solicitudes.id_solicitud DESC;


ALTER TABLE public.solicitudes_procesadas OWNER TO postgres;

--
-- TOC entry 273 (class 1259 OID 200673)
-- Name: solicitudes_sin_orden_salida; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.solicitudes_sin_orden_salida AS
 SELECT solicitudes.id_solicitud,
    solicitudes.empleado,
    solicitudes.funcionario,
    solicitudes.descripcion,
    solicitudes.fecha_solicitud,
    solicitudes.tipo_solicitud,
    solicitudes.estatus_solicitud,
    solicitudes.active,
    solicitudes.id_tipo_solicitud,
    solicitudes.id_estatus_solicitud,
    solicitudes.id_orden
   FROM public.solicitudes
  WHERE ((solicitudes.id_estatus_solicitud = ANY (ARRAY[1, 2])) AND (solicitudes.id_orden = 0));


ALTER TABLE public.solicitudes_sin_orden_salida OWNER TO postgres;

--
-- TOC entry 274 (class 1259 OID 200677)
-- Name: telefono; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.telefono (
    id_telefono integer NOT NULL,
    num_telefono integer,
    id_empleado integer,
    active boolean,
    fecha_elim date,
    usr_id integer
);


ALTER TABLE public.telefono OWNER TO postgres;

--
-- TOC entry 3560 (class 0 OID 0)
-- Dependencies: 274
-- Name: TABLE telefono; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.telefono IS 'Tabla que registra los distintos telefonos de los usuarios';


--
-- TOC entry 3561 (class 0 OID 0)
-- Dependencies: 274
-- Name: COLUMN telefono.id_telefono; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.telefono.id_telefono IS 'Clave primaria de la tabla telefono';


--
-- TOC entry 3562 (class 0 OID 0)
-- Dependencies: 274
-- Name: COLUMN telefono.num_telefono; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.telefono.num_telefono IS 'Numero de telefono de los usuarios';


--
-- TOC entry 275 (class 1259 OID 200680)
-- Name: telefono_id_telefono_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.telefono_id_telefono_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.telefono_id_telefono_seq OWNER TO postgres;

--
-- TOC entry 3563 (class 0 OID 0)
-- Dependencies: 275
-- Name: telefono_id_telefono_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.telefono_id_telefono_seq OWNED BY public.telefono.id_telefono;


--
-- TOC entry 276 (class 1259 OID 200682)
-- Name: ubicacion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ubicacion (
    id_ubicacion integer NOT NULL,
    ubicacion character varying(20),
    id_equipo integer,
    active boolean,
    fecha_elim date,
    usr_id integer
);


ALTER TABLE public.ubicacion OWNER TO postgres;

--
-- TOC entry 3564 (class 0 OID 0)
-- Dependencies: 276
-- Name: TABLE ubicacion; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.ubicacion IS 'Tabla que registra las distintas ubicaciones donde puede encontrarse el equipo';


--
-- TOC entry 3565 (class 0 OID 0)
-- Dependencies: 276
-- Name: COLUMN ubicacion.id_ubicacion; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.ubicacion.id_ubicacion IS 'Campo clave de la tabla ubicacion';


--
-- TOC entry 3566 (class 0 OID 0)
-- Dependencies: 276
-- Name: COLUMN ubicacion.ubicacion; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.ubicacion.ubicacion IS 'Campo que registra las distintas locaciones donde puede encontrarse el equipo';


--
-- TOC entry 277 (class 1259 OID 200685)
-- Name: ubicacion_id_ubicacion_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ubicacion_id_ubicacion_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ubicacion_id_ubicacion_seq OWNER TO postgres;

--
-- TOC entry 3567 (class 0 OID 0)
-- Dependencies: 277
-- Name: ubicacion_id_ubicacion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ubicacion_id_ubicacion_seq OWNED BY public.ubicacion.id_ubicacion;


--
-- TOC entry 278 (class 1259 OID 200687)
-- Name: ubicacion_v2_id_ubicacion_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ubicacion_v2_id_ubicacion_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ubicacion_v2_id_ubicacion_seq OWNER TO postgres;

--
-- TOC entry 3568 (class 0 OID 0)
-- Dependencies: 278
-- Name: ubicacion_v2_id_ubicacion_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ubicacion_v2_id_ubicacion_seq OWNED BY public.ubicacion_v2.id_ubicacion;


--
-- TOC entry 279 (class 1259 OID 200689)
-- Name: ult_orden_salida; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ult_orden_salida (
    ultima_orden integer
);


ALTER TABLE public.ult_orden_salida OWNER TO postgres;

--
-- TOC entry 280 (class 1259 OID 200692)
-- Name: user_rol_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_rol_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_rol_id_seq OWNER TO postgres;

--
-- TOC entry 281 (class 1259 OID 200694)
-- Name: user_role; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_role (
    user_id integer NOT NULL,
    role_id integer NOT NULL,
    id integer DEFAULT nextval('public.user_rol_id_seq'::regclass) NOT NULL,
    active boolean,
    fecha_elim date,
    usr_id integer
);


ALTER TABLE public.user_role OWNER TO postgres;

--
-- TOC entry 282 (class 1259 OID 200698)
-- Name: usuario_id_usuario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.usuario_id_usuario_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.usuario_id_usuario_seq OWNER TO postgres;

--
-- TOC entry 3569 (class 0 OID 0)
-- Dependencies: 282
-- Name: usuario_id_usuario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.usuario_id_usuario_seq OWNED BY public.empleado.id_empleado;


--
-- TOC entry 283 (class 1259 OID 200700)
-- Name: usuarios; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.usuarios AS
 SELECT usuario.id,
    usuario.alias,
    usuario.nombres,
    roles.role_id,
    roles.role_name,
    usuario.active,
    empleado.id_oficina,
    empleado.id_ubicacion,
    usuario.intentos,
    usuario.ingreso
   FROM public.usuario,
    public.roles,
    public.empleado
  WHERE ((usuario.id_rol = roles.role_id) AND (usuario.id = empleado.id_usuario))
  ORDER BY usuario.id;


ALTER TABLE public.usuarios OWNER TO postgres;

--
-- TOC entry 284 (class 1259 OID 200704)
-- Name: usuarios_permisos_asignados; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.usuarios_permisos_asignados AS
 SELECT usuarios.id,
    usuarios.alias,
    usuarios.nombres,
    usuarios.role_name,
    permissions.perm_id,
    permissions.perm_desc,
    permissions.accion
   FROM public.usuarios,
    public.role_perm,
    public.permissions
  WHERE ((usuarios.role_id = role_perm.role_id) AND (role_perm.perm_id = permissions.perm_id))
  ORDER BY usuarios.id, usuarios.role_id, role_perm.role_id;


ALTER TABLE public.usuarios_permisos_asignados OWNER TO postgres;

--
-- TOC entry 3012 (class 2604 OID 200708)
-- Name: almacen id_almacen; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.almacen ALTER COLUMN id_almacen SET DEFAULT nextval('public.almacen_id_almacen_seq'::regclass);


--
-- TOC entry 3013 (class 2604 OID 200709)
-- Name: articulo id_articulo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.articulo ALTER COLUMN id_articulo SET DEFAULT nextval('public.articulo_id_articulo_seq'::regclass);


--
-- TOC entry 3014 (class 2604 OID 200710)
-- Name: departamento id_departamento; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departamento ALTER COLUMN id_departamento SET DEFAULT nextval('public.departamento_id_departamento_seq'::regclass);


--
-- TOC entry 3015 (class 2604 OID 200711)
-- Name: devolucion id_devolucion; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.devolucion ALTER COLUMN id_devolucion SET DEFAULT nextval('public.devolucion_id_devolucion_seq'::regclass);


--
-- TOC entry 3017 (class 2604 OID 200712)
-- Name: empleado id_empleado; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.empleado ALTER COLUMN id_empleado SET DEFAULT nextval('public.usuario_id_usuario_seq'::regclass);


--
-- TOC entry 3024 (class 2604 OID 200713)
-- Name: equipo_marca id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipo_marca ALTER COLUMN id SET DEFAULT nextval('public.equipo_marca_id_seq'::regclass);


--
-- TOC entry 3021 (class 2604 OID 200714)
-- Name: equipo_old id_equipo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipo_old ALTER COLUMN id_equipo SET DEFAULT nextval('public.equipo_id_equipo_seq'::regclass);


--
-- TOC entry 3018 (class 2604 OID 200715)
-- Name: estatus_empleado id_estatus; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estatus_empleado ALTER COLUMN id_estatus SET DEFAULT nextval('public.estatus_empleado_id_estatus_seq'::regclass);


--
-- TOC entry 3034 (class 2604 OID 200716)
-- Name: estatus_equipo id_estatus_eq; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estatus_equipo ALTER COLUMN id_estatus_eq SET DEFAULT nextval('public.estatus_equipo_id_estatus_eq_seq'::regclass);


--
-- TOC entry 3025 (class 2604 OID 200717)
-- Name: estatus_equipo_v2 id_estatus_eq; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estatus_equipo_v2 ALTER COLUMN id_estatus_eq SET DEFAULT nextval('public.estatus_equipo_v2_id_estatus_eq_seq'::regclass);


--
-- TOC entry 3038 (class 2604 OID 200718)
-- Name: funcionario_old id_funcionario; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.funcionario_old ALTER COLUMN id_funcionario SET DEFAULT nextval('public.funcionario_id_funcionario_seq'::regclass);


--
-- TOC entry 3039 (class 2604 OID 200719)
-- Name: marca id_marca; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.marca ALTER COLUMN id_marca SET DEFAULT nextval('public.marca_id_marca_seq'::regclass);


--
-- TOC entry 3040 (class 2604 OID 200720)
-- Name: modelo id_modelo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modelo ALTER COLUMN id_modelo SET DEFAULT nextval('public.modelo_id_modelo_seq'::regclass);


--
-- TOC entry 3053 (class 2604 OID 200971)
-- Name: motivo id_motivo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motivo ALTER COLUMN id_motivo SET DEFAULT nextval('public.motivo_id_motivo_seq'::regclass);


--
-- TOC entry 3042 (class 2604 OID 200721)
-- Name: orden_salida id_orden; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orden_salida ALTER COLUMN id_orden SET DEFAULT nextval('public.orden_salida_id_orden_seq'::regclass);


--
-- TOC entry 3043 (class 2604 OID 200722)
-- Name: permissions perm_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissions ALTER COLUMN perm_id SET DEFAULT nextval('public.permissions_perm_id_seq'::regclass);


--
-- TOC entry 3026 (class 2604 OID 200723)
-- Name: proveedor id_proveedor; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.proveedor ALTER COLUMN id_proveedor SET DEFAULT nextval('public.proveedor_id_proveedor_seq'::regclass);


--
-- TOC entry 3045 (class 2604 OID 200724)
-- Name: reserva id_reserva; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserva ALTER COLUMN id_reserva SET DEFAULT nextval('public.reserva_id_reserva_seq'::regclass);


--
-- TOC entry 3047 (class 2604 OID 200725)
-- Name: roles role_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles ALTER COLUMN role_id SET DEFAULT nextval('public.roles_role_id_seq'::regclass);


--
-- TOC entry 3033 (class 2604 OID 200726)
-- Name: solicitud_detalle id_solicitud_detalle; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.solicitud_detalle ALTER COLUMN id_solicitud_detalle SET DEFAULT nextval('public.solicitud_detalle_id_solicitud_detalle_seq'::regclass);


--
-- TOC entry 3048 (class 2604 OID 200727)
-- Name: telefono id_telefono; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.telefono ALTER COLUMN id_telefono SET DEFAULT nextval('public.telefono_id_telefono_seq'::regclass);


--
-- TOC entry 3049 (class 2604 OID 200728)
-- Name: ubicacion id_ubicacion; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ubicacion ALTER COLUMN id_ubicacion SET DEFAULT nextval('public.ubicacion_id_ubicacion_seq'::regclass);


--
-- TOC entry 3020 (class 2604 OID 200729)
-- Name: ubicacion_v2 id_ubicacion; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ubicacion_v2 ALTER COLUMN id_ubicacion SET DEFAULT nextval('public.ubicacion_v2_id_ubicacion_seq'::regclass);


--
-- TOC entry 3426 (class 0 OID 208072)
-- Dependencies: 294
-- Data for Name: logged_actions; Type: TABLE DATA; Schema: auditoria; Owner: postgres
--

INSERT INTO auditoria.logged_actions (schema_name, table_name, user_name, action_tstamp, action, original_data, new_data, query) VALUES ('public', 'usuario', 'postgres', '2019-07-01 22:06:24.443089-04', 'U', '(mperez,mperez@saren.gob.ve,2,"Mirtha Perez",$2y$10$S1Bt3R4ZKxN2..y4pJC0Ie9SHqfJsb1HGzRgxUx.WRJyrENWdqpYm,1,,,,0,f)', '(mperez,mperez@saren.gob.ve,2,"Mirtha Perez",$2y$10$S1Bt3R4ZKxN2..y4pJC0Ie9SHqfJsb1HGzRgxUx.WRJyrENWdqpYm,1,,,,0,t)', 'UPDATE usuario SET ingreso=TRUE WHERE id = $1');
INSERT INTO auditoria.logged_actions (schema_name, table_name, user_name, action_tstamp, action, original_data, new_data, query) VALUES ('public', 'role_perm', 'postgres', '2019-07-01 22:07:37.33279-04', 'I', NULL, '(5,74,144,,,)', 'INSERT INTO role_perm(perm_id, role_id)
    			VALUES ($1, $2)');
INSERT INTO auditoria.logged_actions (schema_name, table_name, user_name, action_tstamp, action, original_data, new_data, query) VALUES ('public', 'usuario', 'postgres', '2019-07-01 22:19:54.714368-04', 'U', '(mperez,mperez@saren.gob.ve,2,"Mirtha Perez",$2y$10$S1Bt3R4ZKxN2..y4pJC0Ie9SHqfJsb1HGzRgxUx.WRJyrENWdqpYm,1,,,,0,t)', '(mperez,mperez@saren.gob.ve,2,"Mirtha Perez",$2y$10$S1Bt3R4ZKxN2..y4pJC0Ie9SHqfJsb1HGzRgxUx.WRJyrENWdqpYm,1,,,,0,f)', 'UPDATE usuario SET intentos=0,ingreso=FALSE  
			            	       WHERE id = $1');
INSERT INTO auditoria.logged_actions (schema_name, table_name, user_name, action_tstamp, action, original_data, new_data, query) VALUES ('public', 'usuario', 'postgres', '2019-07-01 22:20:08.521721-04', 'U', '(mperez,mperez@saren.gob.ve,2,"Mirtha Perez",$2y$10$S1Bt3R4ZKxN2..y4pJC0Ie9SHqfJsb1HGzRgxUx.WRJyrENWdqpYm,1,,,,0,f)', '(mperez,mperez@saren.gob.ve,2,"Mirtha Perez",$2y$10$S1Bt3R4ZKxN2..y4pJC0Ie9SHqfJsb1HGzRgxUx.WRJyrENWdqpYm,1,,,,0,t)', 'UPDATE usuario SET ingreso=TRUE WHERE id = $1');
INSERT INTO auditoria.logged_actions (schema_name, table_name, user_name, action_tstamp, action, original_data, new_data, query) VALUES ('public', 'usuario', 'postgres', '2019-07-01 22:21:12.627711-04', 'U', '(mperez,mperez@saren.gob.ve,2,"Mirtha Perez",$2y$10$S1Bt3R4ZKxN2..y4pJC0Ie9SHqfJsb1HGzRgxUx.WRJyrENWdqpYm,1,,,,0,t)', '(mperez,mperez@saren.gob.ve,2,"Mirtha Perez",$2y$10$S1Bt3R4ZKxN2..y4pJC0Ie9SHqfJsb1HGzRgxUx.WRJyrENWdqpYm,1,,,,0,f)', 'UPDATE usuario SET intentos=0,ingreso=FALSE  
			            	       WHERE id = $1');


--
-- TOC entry 3357 (class 0 OID 200399)
-- Dependencies: 197
-- Data for Name: almacen; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3359 (class 0 OID 200404)
-- Dependencies: 199
-- Data for Name: articulo; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (11913, 'HORNOS MICROONDAS DE USO COMERCIAL', '48101516', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (14616, 'HORNOS MICROONDAS DOMESTICOS', '52141502', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (7022, 'FILTROS DE AGUA', '40161502', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (12665, 'AGUA MINERAL', '50202310', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (15279, 'SILLAS', '56101504', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (15315, 'SILLAS PARA EL EXTERIOR', '56101602', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (15400, 'SILLAS, ASIENTOS DE AUDITORIO O ESTADIO DE USO GENERAL', '56112101', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (6464, 'ARTEFACTOS DE ESCRITORIO', '39111507', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (11044, 'CALCULADORAS CIENTIFICAS, PROFESIONALES O DE ESCRITORIO', '44101801', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (11149, 'ORGANIZADORES PARA CAJONES DE ESCRITORIO', '44111502', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (11156, 'LIBRERO, ESTANTE DE LIBROS, CARTAPACIO DE ESCRITORIO', '44111512', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (11236, 'ALMOHADILLAS DE ESCRITORIO O SUS ACCESORIOS', '44121621', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (11378, 'ATRILES DE ESCRITORIO', '45111502', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (15407, 'CONJUNTO DE ESCRITORIO Y SILLON', '56112108', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (15441, 'ESCRITORIOS PARA COMPUTADORAS DE ESTUDIANTES', '56121508', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (15015, 'MALETIN PARA COMPUTADORAS', '53121706', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (11150, 'BANDEJAS U ORGANIZADORES DE ESCRITORIO', '44111503', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (11957, 'DISPENSADORES DE AGUA EMBOTELLADA', '48101711', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (11960, 'DISPENSADORES DE AGUA CALIENTE', '48101714', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (15341, 'SILLAS ALTAS O ACCESORIOS', '56101806', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (15324, 'ESCRITORIOS', '56101703', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (15336, 'CUBICULOS DE ORGANIZACION DE ESCRITORIO', '56101716', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (15401, 'SILLAS, ASIENTOS DE TRABAJO', '56112102', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (15402, 'SILLAS, ASIENTOS DE ESPERA O DE HUESPEDES', '56112103', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (15403, 'SILLAS, ASIENTOS DE EJECUTIVO', '56112104', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (15404, 'SILLAS, ASIENTOS DE SALON', '56112105', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (15435, 'SILLAS DE AULA', '56121502', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (15376, 'ESCRITORIO NO MODULAR O MUEBLES', '56111701', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (15412, 'ESCRITORIOS DE BIBLIOTECARIO O DE CIRCULACION O COMPONENTES', '56121002', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (15396, 'MUEBLES PARA COMPUTADORA', '56112002', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (15397, 'MUEBLES PARA ALMACENAJE DE ACCESORIOS DE LA COMPUTADORA', '56112003', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (15398, 'MUEBLES DE APOYO PARA ORGANIZACION DE LA COMPUTADORA', '56112004', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (15399, 'PARTES O ACCESORIOS PARA MUEBLES DE SOPORTE DE LA COMPUTADORA', '56112005', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (15460, 'ESCRITORIO TECNICO DEL INSTRUCTOR', '56121804', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (15442, 'MESAS PARA COMPUTADORAS DE ESTUDIANTES', '56121509', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (14812, 'TELEVISORES', '52161505', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10776, 'EQUIPO BASICO DE MICROONDAS', '43221707', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10678, 'COMPUTADORAS DE ESCRITORIO', '43211507', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10813, 'EQUIPO DE RED DE VIDEO', '43222619', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10814, 'CONMUTADOR MULTISERVICIO', '43222620', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10815, 'CONMUTADOR DE CONTENIDOS', '43222621', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10547, 'CELULARES', '43191501', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10548, 'BUSCAPERSONAS', '43191502', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10549, 'TELEFONOS PUBLICOS DE PREVIO PAGO', '43191503', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10550, 'TELEFONOS FIJOS', '43191504', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10551, 'CONTESTADORES AUTOMATICOS', '43191505', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10552, 'TELEFONOS PARA USOS ESPECIALES', '43191507', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10553, 'TELEFONOS DIGITALES', '43191508', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10554, 'TELEFONOS ANALOGICOS', '43191509', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10555, 'RADIOS DE COMUNICACION', '43191510', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10556, 'CARCASAS DE TELEFONO MOVIL', '43191601', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10557, 'MARCADORES TELEFONICOS', '43191602', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10558, 'CORDONES EXTENSION DE TELEFONO', '43191603', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10559, 'CARCASAS DE TELEFONOS', '43191604', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10560, 'CORDONES DE MICROTELEFONO', '43191605', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10561, 'MICROTELEFONOS', '43191606', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10562, 'ALMOHADILLAS DE ALTAVOZ Y OIDOS DE AURICULARES TELEFONICOS', '43191607', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10563, 'TUBOS DE VOZ DE AURICULARES TELEFONICOS', '43191608', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10564, 'AURICULARES TELEFONICOS', '43191609', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10565, 'BASES, MONTURAS O APOYOS DE DISPOSITIVOS DE COMUNICACION PERSONAL', '43191610', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10566, 'PROTECTORES DE LINEAS TELEFONICAS', '43191611', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10567, 'BASES DE TELEFONOS', '43191612', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10568, 'CONVERTIDORES DE VOZ TELEFONICOS', '43191614', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10569, 'PACK DE TELEFONO MANOS LIBRES PARA EL AUTOMOVIL', '43191615', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10570, 'CONSOLAS PARA CENTREX', '43191616', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10571, 'UNIDADES DE GRABACION DE CONVERSACIONES', '43191618', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10572, 'DISPOSITIVOS DE SEÑALIZACION TELEFONICA', '43191619', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10573, 'ADAPTADORES DE MICROTELEFONOS', '43191621', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10574, 'MODULOS DE BUSCAPERSONAS O ACCESORIOS', '43191622', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10575, 'MECANISMOS DE MONEDAS DE TELEFONOS PUBLICOS DE PREVIO PAGO', '43191623', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10576, 'RANURAS DESLIZANTES DE MONEDAS DE TELEFONOS PUBLICOS DE PREVIO PAGO', '43191624', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10577, 'MONEDEROS DE TELEFONOS PUBLICOS DE PREVIO PAGO', '43191625', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10578, 'DEPOSITOS DE TELEFONOS PUBLICOS DE PREVIO PAGO', '43191626', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10579, 'PUERTA DEL DEPOSITO DE SEGURIDAD DEL MONEDERO DE TELEFONOS PUBLICOS DE PREVIO PAGO', '43191627', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10580, 'PROTECCIONES DEL MICROFONO DE TELEFONOS PUBLICOS DE PREVIO PAGO', '43191628', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10581, 'CARCASAS O MASCARAS PARA PALMTOP O NOTEBOOK', '43191629', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10582, 'PACKS DE INICIO DE TELEFONOS MOVILES', '43191630', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10583, 'JUEGOS (KITS) DE PIEZAS Y PARTES', '43191631', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10584, 'TARJETAS ACELERADORAS DE VIDEO O GRAFICOS', '43201401', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10585, 'TARJETAS DE MODULO DE MEMORIA', '43201402', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10586, 'TARJETAS DE MODEM', '43201403', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10587, 'TARJETAS DE INTERFAZ DE RED', '43201404', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10588, 'TARJETAS DE RECEPCION DE REDES OPTICAS', '43201405', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10589, 'TARJETAS DE TRANSMISION DE REDES OPTICAS', '43201406', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10590, 'TARJETAS CONTROLADORAS DE PERIFERICOS', '43201407', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10591, 'TARJETAS DE PUERTO EN SERIE', '43201408', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10592, 'CONTROLADOR LOGICO PROGRAMABLE  MODULO DE COMUNICACION', '43201409', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10593, 'TARJETAS O PUERTOS DE CONMUTACION', '43201410', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10594, 'TARJETAS DE INTERFAZ DE TELECOMUNICACIONES DE MODO DE TRANSFERENCIA ASINCRONO (ATM)', '43201501', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10595, 'TARJETAS ACELERADORAS DE SONIDO', '43201502', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10596, 'PROCESADORES DE UNIDAD CENTRAL DE PROCESAMIENTO (CPU)', '43201503', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10597, 'PLACAS HIJA', '43201507', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10598, 'MODULOS DCFM', '43201508', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10599, 'MODULOS TELEMATICOS DE INTERCAMBIO', '43201509', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10600, 'PLACAS BASE O TARJETA MADRE', '43201513', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10601, 'TARJETAS DE PUERTO EN PARALELO', '43201522', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10602, 'TARJETAS DE ENTRADA DE VIDEO', '43201531', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10603, 'INTERFACES MIDI', '43201533', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10604, 'INTERFACES CODEC DE COMPONENTES DE INTERCAMBIO', '43201534', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10605, 'PUERTOS INFRARROJOS EN SERIE', '43201535', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10606, 'SERVIDORES DE IMPRESORA', '43201537', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10607, 'VENTILADORES DE UNIDAD CENTRAL DE PROCESAMIENTO (CPU)', '43201538', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10608, 'UNIDAD CENTRAL DE CONTROLADOR DE CONSOLA', '43201539', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10609, 'CONVERTIDOR DE CANAL', '43201540', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10610, 'UNIDAD CENTRAL DE INTERFAZ DE CANAL  A CANAL', '43201541', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10611, 'UNIDAD DE CONTROL', '43201542', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10612, 'UNIDAD CENTRAL DE INSTALACION DE CONECTOR', '43201543', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10613, 'CONTROLADOR O CONVERTIDOR DE INTERFAZ BUS', '43201544', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10614, 'TARJETAS DE FAX', '43201545', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10615, 'TARJETAS DE AUDIOCONFERENCIA', '43201546', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10616, 'TARJETAS DE VOZ', '43201547', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10617, 'CONMUTADORES DE INTERFAZ BUS', '43201549', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10618, 'DISPOSITIVO DE SINCRONIZACION DE PAQUETES DE DATOS DE RED', '43201550', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10619, 'ADAPTADORES DE TELEFONIA O HARDWARE', '43201552', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10620, 'TRANSISTORES, RECEPTORES Y CONVERTIDORES DE SOPORTE', '43201553', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10621, 'CHASIS DE LA COMPUTADORA', '43201601', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10622, 'CHASIS DEL EQUIPO DE RED', '43201602', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10623, 'COMPONENTES DE APILAMIENTO DEL CHASIS', '43201603', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10624, 'BANDEJAS O MODULOS DE EQUIPO ELECTRONICO', '43201604', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10625, 'EXPANSORES', '43201605', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10626, 'UNIDADES DE DISCO EXTRAIBLES (DRIVES)', '43201608', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10627, 'CONJUNTOS O BANDEJAS DE DISPOSITIVOS DE ALMACENAMIENTO', '43201609', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10628, 'TARJETA MADRE POSTERIOR O PANELES O CONJUNTOS', '43201610', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10629, 'SOPORTES DE ORDENADOR', '43201611', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10630, 'PANELES FRONTALES DE ORDENADOR', '43201612', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10631, 'EXTENSORES DE CONSOLA', '43201614', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10632, 'KITS DE CUBIERTAS DE MODULOS DE DISCO', '43201615', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10633, 'TORRES DE DISPOSICION DE DISCOS DUROS', '43201616', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10634, 'UNIDADES DE DISCOS FLEXIBLES', '43201801', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10635, 'CONJUNTOS DE DISCOS DUROS', '43201802', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10636, 'DISCOS DUROS', '43201803', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10637, 'BLOQUES DE CINTAS', '43201806', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10638, 'UNIDADES DE CINTA MAGNETICA', '43201807', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10639, 'CD DE SOLO LECTURA', '43201808', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10640, 'CD DE LECTURA Y ESCRITURA', '43201809', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10641, 'DVD DE SOLO LECTURA', '43201810', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10642, 'DVD DE LECTURA Y ESCRITURA', '43201811', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10643, 'UNIDADES MAGNETOOPTICAS (MO)', '43201812', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10644, 'UNIDADES DE MEDIOS DESMONTABLES DE GRAN CAPACIDAD', '43201813', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10645, 'EQUIPO DE DUPLICACION DE DATOS O SOPORTES ELECTRONICOS', '43201814', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10646, 'UNIDADES DE ESCRITURA Y LECTURA DE ARQUITECTURA MICROCANAL DE  INTERCONEXION DE COMPONENTES PERIFERICOS', '43201815', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10647, 'CAMBIADORES DE DISCO OPTICO', '43201902', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10648, 'BIBLIOTECAS DE UNIDAD DE CINTA MAGNETICA', '43201903', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10649, 'DISCOS COMPACTOS (CD)', '43202001', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10650, 'CINTAS VIRGENES', '43202002', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10651, 'DISCOS VIDEO DIGITALES (DVD)', '43202003', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10652, 'DISQUETES', '43202004', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10653, 'DISPOSITIVOS DE ALMACENAMIENTO DE MEMORIA FLASH', '43202005', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10654, 'CAJAS, FUNDAS O ESTUCHES DE CD', '43202101', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10655, 'CAJAS DE DISQUETES', '43202102', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10656, 'CAJAS DE ALMACENAMIENTOS DE DIFERENTES SOPORTES', '43202103', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10657, 'ALMACENAMIENTO DE CINTAS DE VIDEO VHS O ACCESORIOS', '43202104', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10658, 'ARMARIOS PARA DIFERENTES SOPORTES', '43202105', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10659, 'PARTES DE LA PIEZA DE TELEFONO', '43202201', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10660, 'GENERADORES DE SEÑAL DE LLAMADA DEL TELEFONO', '43202202', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10661, 'LLAMADOR EXTERNO O SUS PIEZAS', '43202204', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10662, 'CAPUCHONES DEL TECLADO O TECLAS', '43202205', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10663, 'COMPONENTES DE DISPOSITIVO DE ENTRADA O UNIDAD DE ALMACENAMIENTO', '43202206', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10664, 'CONJUNTO Y BRAZOS DE VISOR', '43202207', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10665, 'CONJUNTOS DE CABLEADO', '43202208', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10666, 'CONJUNTOS DE CABEZAS (HSA)', '43202209', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10667, 'PARADAS POR FALLO', '43202210', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10668, 'PLATOS O DISCOS', '43202211', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10669, 'CONJUNTOS DE CABEZAS DE LECTURA/ESCRITURA', '43202212', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10670, 'DISPOSITIVOS DE MOTOR DE DISCO', '43202213', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10671, 'CONJUNTOS DE PEINES', '43202214', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10675, 'ORGANIZADORES O ASISTENTES PERSONALES DIGITALES (PDA)', '43211504', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10676, 'TERMINAL DE PUNTO DE VENTA (POS)', '43211505', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10681, 'TERMINALES ELEMENTALES O CONSOLAS DE GRAN SISTEMA (MAINFRAME)', '43211510', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10684, 'CONMUTADORES INFORMATICOS', '43211513', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10685, 'CAJAS DE CONMUTACION DE ORDENADORES', '43211601', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10686, 'PUESTOS DE AMARRE', '43211602', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10687, 'REPLICADORES DE PUERTOS', '43211603', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10688, 'CAJAS DE CONMUTACION DE PERIFERICOS', '43211604', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10689, 'AMPLIACIONES DE PROCESADOR DE SEÑALES', '43211605', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10690, 'EQUIPOS MULTIMEDIA', '43211606', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10691, 'ALTAVOCES DEL ORDENADOR', '43211607', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10692, 'EQUIPO CODIFICADOR-DECODIFICADOR', '43211608', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10693, 'CONECTORES O CONCENTRADORES DE BUS SERIE UNIVERSAL', '43211609', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10694, 'QUEMADOR DE DVD/CD INTERNO', '43211610', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10695, 'QUEMADOR DE DVD/CD EXTERNO', '43211611', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10696, 'UNIDADES DE SUMINISTRO DE ENERGIA, UPS', '43211612', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10697, 'REGULADORES ELECTRICOS O DE ENERGIA', '43211613', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10698, 'EQUIPO DE LECTOR DE CODIGO DE BARRAS', '43211701', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10699, 'LECTORES DE TARJETA MAGNETICA', '43211702', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10700, 'EQUIPO DE RECONOCIMIENTO DE MONEDA', '43211704', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10701, 'JOY STICKS O CONTROLADORES PARA JUEGOS', '43211705', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10702, 'TECLADOS', '43211706', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10703, 'LAPICES OPTICOS CON LED', '43211707', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10705, 'LAPIZ OPTICO DE PRESION', '43211709', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10706, 'DISPOSITIVOS DE IDENTIFICACION DE RADIOFRECUENCIAS', '43211710', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10707, 'ESCANERES', '43211711', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10708, 'TABLETAS GRAFICAS', '43211712', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10709, 'ALMOHADILLAS TACTILES', '43211713', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10710, 'EQUIPO DE IDENTIFICACION BIOMETRICA', '43211714', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10711, 'TERMINALES PORTATILES DE ENTRADA DE DATOS', '43211715', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10712, 'SISTEMAS DE RECONOCIMIENTO OPTICO DE CARACTERES', '43211717', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10713, 'SISTEMAS DE VISION BASADOS EN MAQUINAS FOTOGRAFICAS PARA COLECCION AUTOMATICA DE DATOS', '43211718', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10714, 'MICROFONOS DE VOZ PARA ORDENADOR', '43211719', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10715, 'KITS DE VERIFICACION DE TARJETAS DE CREDITO O DEBITO DE PUNTO DE VENTA', '43211720', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10716, 'LECTORES DE TARJETAS PERFORADAS', '43211721', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10717, 'CUBIERTAS DE DISPOSITIVOS DE ENTRADA DE DATOS DE ORDENADOR', '43211801', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10719, 'FORROS DE TECLADO', '43211803', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10720, 'EXTENSIONES O SOPORTES DE TECLADO', '43211804', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10721, 'KITS DE SERVICIO PARA DISPOSITIVOS DE ALMACENAMIENTO', '43211805', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10722, 'MONITORES DE TUBO DE RAYO CATODICO (CRT)', '43211901', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10723, 'MONITORES O PANTALLAS DE  VISUALIZACION EN CRISTAL LIQUIDO (LCD)', '43211902', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10724, 'MONITORES DE PANTALLA TACTIL', '43211903', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10725, 'PANTALLAS DE PLASMA (PDP)', '43211904', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10726, 'PANTALLAS EMISORAS DE LUZ ORGANICA', '43211905', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10727, 'FILTROS PARA PANTALLAS DE ORDENADOR', '43212001', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10728, 'SOPORTES PARA MONITOR', '43212002', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10729, 'IMPRESORAS DE BANDAS', '43212101', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10730, 'IMPRESORAS DE MATRIZ DE PUNTOS', '43212102', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10731, 'IMPRESORAS POR SUBLIMACION DE TINTA', '43212103', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10732, 'IMPRESORAS DE CHORRO DE TINTA', '43212104', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10733, 'IMPRESORAS DE LASER', '43212105', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10734, 'IMPRESORAS DE MATRIZ DE LINEAS', '43212106', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10735, 'IMPRESORA DE PLANOS, TRAZADORAS DE GRAFICOS (PLOTTER)', '43212107', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10736, 'IMPRESORAS DE CINTA TERMICA', '43212108', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10737, 'IMPRESORA DE ETIQUETAS DE BOLSA', '43212109', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10738, 'IMPRESORAS MULTIFUNCION', '43212110', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10739, 'IMPRESORAS DE BILLETES DE AVION O TARJETAS DE EMBARQUE (ATB)', '43212111', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10740, 'IMPRESORAS DE RECIBOS DE PUNTO DE VENTA (POS)', '43212112', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10741, 'IMPRESORAS DE ETIQUETAS O DISCOS COMPACTOS (CD)', '43212113', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10742, 'IMPRESORAS DE IMAGENES DIGITALES', '43212114', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10743, 'SISTEMAS AUTOMATIZADOS DE OPERADORA', '43221501', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10744, 'DISTRIBUIDOR AUTOMATICO DE LAS LLAMADAS (ACD)', '43221502', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10745, 'DISPOSITIVOS AUTOMATICOS DE LOCUCIONES', '43221503', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10674, 'COMPUTADORA PORTATIL', '43211503', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10677, 'COMPUTADORAS CLIENTE LIGERO', '43211506', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10679, 'COMPUTADORAS PERSONALES (PC)', '43211508', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10680, 'COMPUTADORAS PORTATILES TIPO TABLETA', '43211509', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10682, 'COMPUTADORAS VESTIBLES', '43211511', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10683, 'COMPUTADORAS CENTRALES', '43211512', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10672, 'SERVIDORES', '43211501', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10673, 'SERVIDORES DE GAMA ALTA', '43211502', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10746, 'SISTEMAS DE CENTRAL PRIVADA CONECTADA A LA RED PUBLICA (PBX)', '43221504', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10747, 'IDENTIFICADOR DE LLAMADA', '43221505', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10748, 'CONSOLA DE TELECONFERENCIA', '43221506', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10749, 'MARCADORES AUTOMATICOS', '43221507', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10750, 'PANELES DE LAMPARAS DE OCUPACION TELEFONICA', '43221508', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10751, 'SISTEMAS DE CONTABILIDAD DE LLAMADAS TELEFONICAS', '43221509', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10752, 'REENVIADOR O DESVIADOR DE  LLAMADAS TELEFONICAS', '43221510', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10753, 'SECUENCIADORES DE LLAMADAS TELEFONICAS', '43221513', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10754, 'UNIDADES DE SEGURIDAD DE MARCADO TELEFONICO', '43221514', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10755, 'DISPOSITIVOS DE LINEA TELEFONICA COMPARTIDA', '43221515', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10756, 'MONITORES DE ESTADO DE LINEA TELEFONICA', '43221516', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10757, 'UNIDADES DE OBSERVACION DEL SERVICIO DE EQUIPOS DE TELEFONIA', '43221517', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10758, 'DISPOSITIVOS DE RESTRICCION INTERURBANA DE EQUIPOS DE TELEFONIA', '43221518', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10759, 'SISTEMAS DE BUZON DE VOZ', '43221519', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10760, 'EQUIPO DE RECONOCIMIENTO DE VOZ INTERACTIVO', '43221520', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10761, 'UNIDAD DE ACCESO REMOTO DE TELECOMUNICACIONES', '43221521', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10762, 'EQUIPO DE TELECONFERENCIA', '43221522', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10763, 'REPRODUCTOR DE MUSICA O MENSAJE DE RETENCION DE LLAMADA', '43221523', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10764, 'ADAPTADOR DE MUSICA DE RETENCION DE LLAMADA', '43221524', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10765, 'SISTEMAS DE INTERCOMUNICADORES', '43221525', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10766, 'SISTEMA TELEFONICO DE ENTRADAS', '43221526', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10767, 'SPLITTER DE SISTEMA CAUTIVO DE SERVICIO TELEFONICO CONVENCIONAL (POTS) DE ABONADO DE LINEA DIGITAL (DSL)', '43221601', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10768, 'CUADRO DE SPLITTER CAUTIVO DE OFICINA DE ABONADO DE LINEA DIGITAL (DSL)', '43221602', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10769, 'SPLITTER DE SISTEMA DE SERVICIO TELEFONICO CONVENCIONAL (POTS) DE EQUIPO DE PREMISA DE CLIENTE (CPE) DE ABONADO DE LINEA DIGITAL (DSL)', '43221603', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10770, 'EQUIPO BASICO DE TELEVISION', '43221701', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10771, 'EQUIPO DE ACCESO DE TELEVISION', '43221702', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10772, 'ANTENAS DE TELEVISION', '43221703', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10773, 'EQUIPO BASICO DE RADIO', '43221704', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10718, 'ALMOHADILLAS DE RATON', '43211802', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10774, 'EQUIPO DE ACCESO DE RADIO', '43221705', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10775, 'ANTENAS DE RADIO', '43221706', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10777, 'EQUIPO DE ACCESO DE MICROONDAS', '43221708', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10778, 'ANTENAS DE MICROONDAS', '43221709', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10779, 'EQUIPO BASICO DE SATELITE', '43221710', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10780, 'EQUIPO DE ACCESO DE SATELITE', '43221711', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10781, 'ANTENAS DE SATELITE', '43221712', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10782, 'EQUIPO BASICO DE ONDA CORTA', '43221713', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10783, 'EQUIPO DE ACCESO DE ONDA CORTA', '43221714', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10784, 'ANTENAS DE ONDA CORTA', '43221715', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10785, 'EQUIPO BASICO DE BUSCAPERSONAS', '43221716', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10786, 'EQUIPO DE ACCESO DE BUSCAPERSONAS', '43221717', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10787, 'ANTENAS DE RADAR', '43221718', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10788, 'ANTENAS DE AVIACION', '43221719', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10789, 'ANTENAS DE AUTOMOCION', '43221720', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10790, 'EQUIPO DE COMUNICACION DE DATOS DE RADIOFRECUENCIA', '43221721', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10791, 'AMPLIFICADORES OPTICOS', '43221801', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10792, 'FILTROS DE COMUNICACIONES O REDES OPTICAS', '43221802', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10793, 'ADAPTADORES OPTICOS', '43221803', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10794, 'RAYOS LASER DE RED OPTICA', '43221804', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10795, 'EQUIPO DE RED DE MODO DE TRANSFERENCIA ASINCRONO (ATM)', '43221805', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10796, 'EQUIPO DE RED DE RED OPTICA  SINCRONA (SONET)', '43221806', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10797, 'FILTROS DE MULTIPLEXACION EN LONGITUDES DE ONDA DENSA (DWDM) DE TELECOMUNICACIONES', '43221807', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10798, 'EQUIPO DE TELECOMUNICACIONES DE  JERARQUIA DIGITAL SINCRONA (SDH)', '43221808', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10799, 'EQUIPO DE SEGURIDAD DE RED DE  FIREWALL', '43222501', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10800, 'EQUIPO DE SEGURIDAD DE RED VIRTUAL  (VPN)', '43222502', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10801, 'EQUIPO DE SEGURIDAD DE EVALUACION   DE VULNERABILIDAD', '43222503', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10802, 'EQUIPO DE CABECERA DE RED DE CABLE', '43222602', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10803, 'EQUIPO DE RED DE ENTREGA DE  CONTENIDOS', '43222604', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10804, 'PASARELA DE RED', '43222605', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10805, 'KITS DE INICIO DE NODO DE SERVICIO DE  INTERNET', '43222606', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10806, 'EQUIPO DE MOTOR DE MEMORIA CACHE', '43222607', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10807, 'REPETIDORES DE RED', '43222608', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10808, 'ROUTERS DE RED', '43222609', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10809, 'CONCENTRADORES DE SERVICIO DE RED', '43222610', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10810, 'UNIDADES DE SERVICIO DE DATOS O  CANALES DE RED', '43222611', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10811, 'INTERRUPTORES DE RED', '43222612', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10812, 'CONMUTADOR DE RED DE AREA DE ALMACENAMIENTO (SAN)', '43222615', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10817, 'EQUIPO DE INTERCONEXION DIGITAL (DCX)', '43222623', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10818, 'EQUIPO DE INTERCONEXION OPTICA', '43222624', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10820, 'DISPOSITIVOS MODEM POR CABLE', '43222626', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10821, 'DISPOSITIVOS DE ACCESO DE RED DIGITAL DE SERVICIOS INTEGRADOS (RDSI)', '43222627', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10822, 'MODEM', '43222628', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10823, 'BANCOS DE MODEM', '43222629', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10824, 'UNIDADES DE ACCESO MULTIPLE', '43222630', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10825, 'ESTACIONES DE BASE DE FIDELIDAD INALAMBRICA (WIFI)', '43222631', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10826, 'AGREGADORES DE BANDA ANCHA', '43222632', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10827, 'TELEGRAFOS', '43222701', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10828, 'ELECTROIMANES TELEGRAFICOS', '43222702', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10829, 'APARATOS DE REGISTRO TELEGRAFICO', '43222703', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10830, 'EQUIPO DE INTERCONEXION DIGITAL (DCX) DE BANDA ESTRECHA O BANDA ANCHA', '43222801', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10831, 'EQUIPO DE CIRCUITO DE CENTELLA TELEFONICA O CONMUTADOR', '43222802', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10832, 'PORTADORA DE BUCLE DIGITAL (DLC)', '43222803', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10833, 'EQUIPO DE CENTRAL PRIVADA CONECTADA A LA RED PUBLICA (PBX)', '43222805', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10834, 'BLOQUES DE PERFORACIONES', '43222806', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10835, 'UNIDADES DE ALARMA DE EQUIPO DE TELEFONIA', '43222811', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10836, 'KITS DE PIEZAS DE CUADRO DE CONMUTACION TELEFONICO', '43222813', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10816, 'EQUILIBRADOR DE CARGAS DE SERVIDOR', '43222622', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10819, 'SERVIDORES DE ACCESO', '43222625', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10837, 'KITS DE MODIFICACION O INSTALACION DE EQUIPO DE TELECOMUNICACIONES', '43222814', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10838, 'TERMINALES DE TELECOMUNICACIONES', '43222815', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10839, 'MODULADORES DE TELEFONIA', '43222816', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10840, 'REPETIDORES DE TELECOMUNICACIONES', '43222817', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10841, 'TRAMAS DE TERMINALES DE DISTRIBUCION TELEFONICA', '43222818', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10842, 'PANELES DE CONEXION DE PUERTOS', '43222819', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10843, 'COMPENSADORES DE ECO DE VOZ', '43222820', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10844, 'PANEL DE CONEXIONES', '43222821', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10845, 'MULTIPLEXADOR POR DIVISION DE TIEMPO (TDM)', '43222822', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10846, 'MULTIPLEXADOR POR DIVISION DE LONGITUD DE ONDA (WDM)', '43222823', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10847, 'RODILLOS DE CABLE AEREO', '43222824', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10848, 'KITS DE MODIFICACION TELEFONICA', '43222825', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10849, 'ACONDICIONADORES DE LINEA', '43222901', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10850, 'SECADORES DE AIRE DE CABLES DE TELEFONIA', '43222902', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10851, 'DISPOSITIVOS DE ENTRADA DE TELETIPO', '43223001', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10852, 'COMPONENTES Y EQUIPO DE RED DEL NUCLEO MOVIL GSM 2G', '43223101', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10853, 'COMPONENTES Y EQUIPO DE RED DE ACCESO INALAMBRICO GSM 2G', '43223102', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10854, 'COMPONENTES Y EQUIPO DE RED DEL NUCLEO MOVIL GPRS 2,5G', '43223103', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10855, 'COMPONENTES Y EQUIPO DE RED DE ACCESO INALAMBRICO GPRS 2,5G', '43223104', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10856, 'COMPONENTES Y EQUIPO DE RED DEL  NUCLEO MOVIL UMTS 3G', '43223105', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10857, 'COMPONENTES Y EQUIPO DE RED DE ACCESO INALAMBRICO UMTS 3G', '43223106', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10858, 'COMPONENTES Y EQUIPO DE RED DEL NUCLEO MOVIL WLAN', '43223107', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10859, 'COMPONENTES Y EQUIPO DE RED DE ACCESO INALAMBRICO WLAN', '43223108', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10860, 'EQUIPO DE CONMUTACION IN-SSP', '43223109', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10861, 'EQUIPO DEL NUCLEO MOVIL DE RED INTELIGENTE (IN)', '43223110', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10862, 'COMPONENTES Y EQUIPO DE RED DEL NUCLEO MOVIL OSS', '43223111', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10863, 'COMPONENTES Y EQUIPO DE RED DE ACCESO INALAMBRICO OSS', '43223112', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10864, 'ANTENA LAN UMTS GSM', '43223113', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10865, 'PORTAL DE MENSAJERIA POR VOZ', '43223201', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10866, 'CENTRO DE SERVICIO DE MENSAJES CORTOS', '43223202', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10867, 'CENTRO DE SERVICIOS MULTIMEDIA', '43223203', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10868, 'PLATAFORMA DE MENSAJERIA UNIFICADA', '43223204', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10869, 'PLATAFORMA DE MENSAJERIA INSTANTANEA', '43223205', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10870, 'PASARELA DE INTERNET INALAMBRICA', '43223206', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10871, 'SISTEMA DE TRANSMISION POR SECUENCIAS DE VIDEO', '43223207', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10872, 'PLATAFORMA DE JUEGOS O MENSAJERIA POR MOVIL', '43223208', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10873, 'PLATAFORMAS DE SERVICIO DE MENSAJERIA POR UBICACION', '43223209', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10874, 'SISTEMAS DE MENSAJERIA DE MICROPAGOS', '43223210', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10875, 'CONTROLADORES DE RADIOBUSQUEDA', '43223211', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10876, 'TERMINALES DE RADIOBUSQUEDA', '43223212', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10877, 'SOFTWARE, PROGRAMAS DE CENTRO DE LLAMADAS O SOPORTE TECNICO', '43231501', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10878, 'SOFTWARE, PROGRAMAS DE GESTION DE ADQUISICIONES', '43231503', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10879, 'SOFTWARE, PROGRAMAS DE GESTION DE RECURSOS HUMANOS', '43231505', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10880, 'SOFTWARE, PROGRAMAS DE CADENA DE SUMINISTRO Y LOGISTICA DE PLANIFICACION DE REQUISITOS DE MATERIALES', '43231506', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10881, 'SOFTWARE, PROGRAMAS DE GESTION DE PROYECTOS', '43231507', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10882, 'SOFTWARE, PROGRAMAS DE GESTION DE INVENTARIO', '43231508', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10883, 'SOFTWARE, PROGRAMAS DE CODIFICACION POR BARRAS', '43231509', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10884, 'SOFTWARE, PROGRAMAS PARA HACER ETIQUETAS', '43231510', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10885, 'SOFTWARE, PROGRAMAS DE SISTEMA EXPERTO', '43231511', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10886, 'SOFTWARE, PROGRAMAS DE GESTION DE LICENCIAS', '43231512', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10887, 'PAQUETES DE OFIMATICA', '43231513', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10888, 'SOFTWARE, PROGRAMAS DE CONTABILIDAD', '43231601', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10889, 'SOFTWARE, PROGRAMAS DE PLANIFICACION DE  RECURSOS EMPRESARIALES (ERP)', '43231602', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10890, 'SOFTWARE, PROGRAMAS DE TRAMITES FISCALES', '43231603', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10891, 'SOFTWARE, PROGRAMAS DE ANALISIS FINANCIERO', '43231604', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10892, 'SOFTWARE, PROGRAMAS DE CONTABILIDAD TEMPORAL', '43231605', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10893, 'JUEGOS DE ACCION', '43232001', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10894, 'JUEGOS DE AVENTURA', '43232002', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10895, 'JUEGOS DE DEPORTES', '43232003', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10896, 'SOFTWARE, PROGRAMAS DOMESTICO', '43232004', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10897, 'SOFTWARE, PROGRAMAS PARA EDICION DE MUSICA  O SONIDO', '43232005', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10898, 'SOFTWARE, PROGRAMAS DE DISEñO DE PATRONES', '43232101', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10899, 'SOFTWARE, PROGRAMAS DE RETOQUE FOTOGRAFICO O  GRAFICO', '43232102', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10900, 'SOFTWARE, PROGRAMAS DE EDICION Y CREACION DE VIDEO', '43232103', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10901, 'SOFTWARE, PROGRAMAS DE PROCESAMIENTO DE PALABRAS', '43232104', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10902, 'SOFTWARE, PROGRAMAS PARA TABULACION', '43232105', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10903, 'SOFTWARE, PROGRAMAS DE PRESENTACION', '43232106', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10904, 'SOFTWARE, PROGRAMAS DE EDICION Y CREACION DE PAGINAS WEB', '43232107', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10905, 'SOFTWARE, PROGRAMAS DE PROGRAMACION Y CALENDARIO', '43232108', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10906, 'SOFTWARE, PROGRAMAS PARA HOJAS DE CALCULO', '43232110', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10907, 'SOFTWARE, PROGRAMAS DE ESCANER O LECTOR OPTICO DE CARACTERES (OCR)', '43232111', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10908, 'SOFTWARE, PROGRAMAS PARA EDICION DE OFICINA', '43232112', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10909, 'SOFTWARE, PROGRAMAS DE FLUJO DE TRABAJO DE CONTENIDOS', '43232201', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10910, 'SOFTWARE, PROGRAMAS DE GESTION DE DOCUMENTOS', '43232202', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10911, 'SOFTWARE, PROGRAMAS DE VERSION DE ARCHIVO', '43232203', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10912, 'SOFTWARE, PROGRAMAS DE CLASIFICACION O CATEGORIZACION', '43232301', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10913, 'SOFTWARE, PROGRAMAS DE PARTICION', '43232302', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10914, 'SOFTWARE, PROGRAMAS DE GESTION DE RELACIONES CON EL CLIENTE (CRM)', '43232303', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10915, 'SOFTWARE, PROGRAMAS DE SISTEMA DE ADMINISTRACION DE BASES DE DATOS', '43232304', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10916, 'SOFTWARE, PROGRAMAS DE CREACION DE INFORMES DE BASES DE DATOS', '43232305', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10917, 'SOFTWARE, PROGRAMAS DE CONSULTAS E INTERFAZ DE USUARIO DE BASES DE DATOS', '43232306', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10918, 'SOFTWARE, PROGRAMAS DE EXTRACCION DE DATOS', '43232307', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10919, 'SOFTWARE, PROGRAMAS DE BUSQUEDA O RECUPERACION DE INFORMACION', '43232309', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10920, 'SOFTWARE, PROGRAMAS DE ADMINISTRACION DE METADATOS', '43232310', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10921, 'SOFTWARE, PROGRAMAS DE ADMINISTRACION DE BASES DE DATOS ORIENTADO A OBJETOS', '43232311', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10922, 'SOFTWARE, PROGRAMAS DE SERVIDOR DE PORTAL', '43232312', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10923, 'SOFTWARE, PROGRAMAS DE SERVIDOR DE TRANSACCION', '43232313', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10924, 'SOFTWARE, PROGRAMAS DE GESTION DE CONFIGURACION', '43232401', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10925, 'SOFTWARE, PROGRAMAS DE ENTORNO DE DESARROLLO', '43232402', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10926, 'SOFTWARE, PROGRAMAS DE INTEGRACION DE APLICACIONES DE EMPRESA', '43232403', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10927, 'SOFTWARE, PROGRAMAS DE DESARROLLO DE INTERFAZ GRAFICA DE USUARIO', '43232404', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10928, 'SOFTWARE, PROGRAMAS DE DESARROLLO ORIENTADO A OBJETOS O COMPONENTES', '43232405', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10929, 'SOFTWARE, PROGRAMAS PARA PROBAR PROGRAMAS', '43232406', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10930, 'SOFTWARE, PROGRAMAS DE ARQUITECTURA DEL SISTEMA Y ANALISIS DE REQUISITOS', '43232407', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10931, 'SOFTWARE, PROGRAMAS DE DESARROLLO DE PLATAFORMA WEB', '43232408', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10932, 'SOFTWARE, PROGRAMAS COMPILADOR Y DESCOMPILADOR', '43232409', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10933, 'SOFTWARE, PROGRAMAS DE IDIOMA EXTRANJERO', '43232501', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10934, 'SOFTWARE, PROGRAMAS DE FORMACION BASADA EN ORDENADOR', '43232502', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10935, 'CORRECTOR ORTOGRAFICO', '43232503', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10936, 'SOFTWARE, PROGRAMAS DE MAPA ELECTRONICO', '43232504', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10937, 'SOFTWARE, PROGRAMAS DE APOYO TERRESTRE PARA AVIACION', '43232601', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10938, 'SOFTWARE, PROGRAMAS DE ENSAYOS PARA AVIACION', '43232602', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10939, 'SOFTWARE, PROGRAMAS DE GESTION DE INSTALACIONES', '43232603', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10940, 'SOFTWARE, PROGRAMAS DE DISEñO ASISTIDO POR ORDENADOR (CAD)', '43232604', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10941, 'SOFTWARE, PROGRAMAS ANALITICO O CIENTIFICO', '43232605', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10942, 'SOFTWARE, PROGRAMAS DE COMPATIBILIDAD', '43232606', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10943, 'SOFTWARE, PROGRAMAS DE CONTROL DE VUELO', '43232607', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10944, 'LOGICAL DE CONTROL INDUSTRIAL', '43232608', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10945, 'SOFTWARE, PROGRAMAS DE BIBLIOTECA', '43232609', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10946, 'SOFTWARE, PROGRAMAS MEDICOS', '43232610', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10947, 'SOFTWARE, PROGRAMAS DE PUNTO DE VENTA (POS)', '43232611', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10948, 'SOFTWARE, PROGRAMAS DE FABRICACION ASISTIDA POR ORDENADOR (CAM)', '43232612', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10949, 'SOFTWARE, PROGRAMAS DE SERVIDOR DE APLICACIONES', '43232701', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10950, 'SOFTWARE, PROGRAMAS DE COMUNICACIONES PARA CONSOLA', '43232702', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10951, 'SOFTWARE, PROGRAMAS INTERACTIVOS DE RESPUESTA DE VOZ', '43232703', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10952, 'SOFTWARE, PROGRAMAS DE SERVICIOS DE DIRECTORIO DE INTERNET', '43232704', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10953, 'SOFTWARE, PROGRAMAS DE EXPLORADOR DE INTERNET', '43232705', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10954, 'SOFTWARE, PROGRAMAS DE VIGILANCIA DE REDES', '43232801', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10955, 'SOFTWARE, PROGRAMAS DE MEJORA DE SISTEMAS OPERATIVOS DE REDES', '43232802', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10956, 'SOFTWARE, PROGRAMAS DE ADMINISTRACION DE REDES OPTICAS', '43232803', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10957, 'SOFTWARE, PROGRAMAS DE ADMINISTRACION', '43232804', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10958, 'SOFTWARE, PROGRAMAS DE ACCESO', '43232901', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10959, 'SOFTWARE, PROGRAMAS DE SERVIDOR DE COMUNICACIONES', '43232902', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10960, 'SOFTWARE, PROGRAMAS DE CENTRO DE CONTACTO', '43232903', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10961, 'SOFTWARE, PROGRAMAS DE FAX', '43232904', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10962, 'SOFTWARE, PROGRAMAS DE LAN', '43232905', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10963, 'SOFTWARE, PROGRAMAS MULTIPLEXOR', '43232906', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10964, 'SOFTWARE, PROGRAMAS DE RED DE ALMACENAMIENTO', '43232907', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10965, 'SOFTWARE, PROGRAMAS DE DESVIO O CONMUTACION', '43232908', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10966, 'SOFTWARE, PROGRAMAS DE CONMUTACION DE WAN', '43232909', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10967, 'SOFTWARE, PROGRAMAS DE DISPOSITIVOS INALAMBRICOS', '43232910', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10968, 'PROGRAMAS PARA EMULACION DE TERMINAL DE CONECTIVIDAD DE RED', '43232911', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10969, 'SOFTWARE, PROGRAMAS DE ACCESO', '43232912', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10970, 'SOFTWARE, PROGRAMAS PUENTE', '43232913', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10971, 'SOFTWARE, PROGRAMAS DE MODEM', '43232914', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10972, 'SOFTWARE, PROGRAMAS DE INTERCONECTIVIDAD DE PLATAFORMAS', '43232915', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10973, 'SOFTWARE, PROGRAMAS DE SISTEMA DE ARCHIVOS', '43233001', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10974, 'SOFTWARE, PROGRAMAS DE SISTEMA OPERATIVO DE REDES', '43233002', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10975, 'SOFTWARE, PROGRAMAS DE SISTEMA OPERATIVO', '43233004', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10976, 'SOFTWARE, PROGRAMAS DE SERVIDOR DE AUTENTICACION', '43233201', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10977, 'SOFTWARE, PROGRAMAS DE ADMINISTRACION DE RED  PRIVADA VIRTUAL (VPN) O DE SEGURIDAD DE RED', '43233203', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10978, 'SOFTWARE, PROGRAMAS DE EQUIPOS DE RED PRIVADA VIRTUAL (VPN) O DE SEGURIDAD DE RED', '43233204', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10979, 'SOFTWARE, PROGRAMAS DE PROTECCION ANTIVIRUS Y DE SEGURIDAD DE TRANSACCIONES', '43233205', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10980, 'SOFTWARE, PROGRAMAS DE SERVIDOR DE DISCOS COMPACTOS (CD)', '43233401', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10981, 'SOFTWARE, PROGRAMAS DE CONVERSION DE DATOS', '43233402', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10982, 'SOFTWARE, PROGRAMAS DE COMPRESION DE DATOS', '43233403', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10983, 'SOFTWARE, PROGRAMAS DE TARJETA DE SONIDO DE DISCOS COMPACTOS (CD) O DVD', '43233404', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10984, 'SOFTWARE, PROGRAMAS DEL SISTEMA O DE CONTROLADORES DE DISPOSITIVOS', '43233405', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10985, 'SOFTWARE, PROGRAMAS DE CONTROLADOR DE ETHERNET', '43233406', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10986, 'SOFTWARE, PROGRAMAS DE CONTROLADOR DE TARJETA GRAFICA', '43233407', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10987, 'SOFTWARE, PROGRAMAS DE CONTROLADOR DE IMPRESORA', '43233410', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10988, 'SOFTWARE, PROGRAMAS DE SALVAPANTALLAS', '43233411', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10989, 'SOFTWARE, PROGRAMAS DE RECONOCIMIENTO DE VOZ', '43233413', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10990, 'SOFTWARE, PROGRAMAS DE CARGA PARA SOPORTE DE MEMORIA', '43233414', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10991, 'SOFTWARE, PROGRAMAS DE COPIAS DE SEGURIDAD O ARCHIVADO', '43233415', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10992, 'SOFTWARE, PROGRAMAS DE CORREO ELECTRONICO', '43233501', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10993, 'SOFTWARE, PROGRAMAS DE VIDEO CONFERENCIA', '43233502', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10994, 'SOFTWARE, PROGRAMAS DE CONFERENCIAS EN RED', '43233503', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10995, 'SOFTWARE, PROGRAMAS DE MENSAJERIA INSTANTANEA', '43233504', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10996, 'SOFTWARE, PROGRAMAS DE MENSAJERIA PUBLICITARIA O DE MUSICA AMBIENTAL', '43233505', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10997, 'SOFTWARE, PROGRAMAS DE CREACION DE MAPAS', '43233506', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10998, 'SOFTWARE, PROGRAMAS ESTANDAR ESPECIFICO DE OPERADOR DE MOVILES', '43233507', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10999, 'SOFTWARE, PROGRAMAS DE APLICACION ESPECIFICA DE OPERADOR DE MOVILES', '43233508', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (11000, 'SOFTWARE, PROGRAMAS DE SERVICIO DE MENSAJERIA POR MOVIL', '43233509', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (11001, 'SOFTWARE, PROGRAMAS DE SERVICIOS DE INTERNET POR MOVIL', '43233510', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (11002, 'SOFTWARE, PROGRAMAS DE SERVICIOS POR UBICACION DE MOVIL', '43233511', true, '2019-04-30', 15);
INSERT INTO public.articulo (id_articulo, articulo, codigo_snc, active, fecha_elim, usr_id) VALUES (10704, 'TRACKBALLS Y RATONES DE ORDENADOR', '43211708', true, '2019-04-30', 15);


--
-- TOC entry 3361 (class 0 OID 200409)
-- Dependencies: 201
-- Data for Name: cancelacion; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3362 (class 0 OID 200415)
-- Dependencies: 202
-- Data for Name: departamento; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.departamento (id_departamento, nombre, telf_departamento, active, fecha_elim, usr_id) VALUES (1, 'Direccion General', 2124512324, NULL, NULL, NULL);
INSERT INTO public.departamento (id_departamento, nombre, telf_departamento, active, fecha_elim, usr_id) VALUES (2, 'Adjunto(a) a la Direccion', NULL, NULL, NULL, NULL);
INSERT INTO public.departamento (id_departamento, nombre, telf_departamento, active, fecha_elim, usr_id) VALUES (3, 'Oficina de Planificacion Presupuesto Planificacion y Sistemas', NULL, NULL, NULL, NULL);
INSERT INTO public.departamento (id_departamento, nombre, telf_departamento, active, fecha_elim, usr_id) VALUES (4, 'Inspectoria General', NULL, NULL, NULL, NULL);
INSERT INTO public.departamento (id_departamento, nombre, telf_departamento, active, fecha_elim, usr_id) VALUES (5, 'Consultoria', NULL, NULL, NULL, NULL);
INSERT INTO public.departamento (id_departamento, nombre, telf_departamento, active, fecha_elim, usr_id) VALUES (6, 'Oficina de Tecnologia de la Informacion', NULL, NULL, NULL, NULL);
INSERT INTO public.departamento (id_departamento, nombre, telf_departamento, active, fecha_elim, usr_id) VALUES (7, 'Oficina de Recursos Humanos', NULL, NULL, NULL, NULL);
INSERT INTO public.departamento (id_departamento, nombre, telf_departamento, active, fecha_elim, usr_id) VALUES (8, 'Oficina de Asuntos Publicos', NULL, NULL, NULL, NULL);
INSERT INTO public.departamento (id_departamento, nombre, telf_departamento, active, fecha_elim, usr_id) VALUES (9, 'Oficina de Gestion Administrativa', NULL, NULL, NULL, NULL);
INSERT INTO public.departamento (id_departamento, nombre, telf_departamento, active, fecha_elim, usr_id) VALUES (10, 'Direccion del Sistema Registral', NULL, NULL, NULL, NULL);
INSERT INTO public.departamento (id_departamento, nombre, telf_departamento, active, fecha_elim, usr_id) VALUES (12, 'Direccion del Notariado', NULL, NULL, NULL, NULL);
INSERT INTO public.departamento (id_departamento, nombre, telf_departamento, active, fecha_elim, usr_id) VALUES (11, 'Direccion de Control Prevencion y Fiscalizacion de Legitimacion de Capitales', NULL, NULL, NULL, NULL);


--
-- TOC entry 3423 (class 0 OID 200956)
-- Dependencies: 288
-- Data for Name: desincorporacion; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.desincorporacion (id_desincorporacion, id_motivo, fecha_desincorporacion, id_funcionario, active, fecha_elim, usr_id, observacion, id_equipo, id_empleado_notifica) VALUES (1, 1, '2019-06-27', 2, NULL, NULL, NULL, 'Prueba de desincorporacion', 16, 14);


--
-- TOC entry 3364 (class 0 OID 200423)
-- Dependencies: 204
-- Data for Name: devolucion; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.devolucion (id_devolucion, id_solicitud_detalle, fecha_devolucion, id_funcionario, active, fecha_elim, usr_id, observacion, id_equipo, id_empleado_entrega) VALUES (41, 1, '2019-06-16', 2, NULL, NULL, NULL, 'prueba de devolucion', 9, 1);
INSERT INTO public.devolucion (id_devolucion, id_solicitud_detalle, fecha_devolucion, id_funcionario, active, fecha_elim, usr_id, observacion, id_equipo, id_empleado_entrega) VALUES (42, 1, '2019-06-16', 2, NULL, NULL, NULL, 'pkkh kjh kjh kjh kjh kjh kjh kjh kjh kjhk jh kjhkh ', 12, 1);
INSERT INTO public.devolucion (id_devolucion, id_solicitud_detalle, fecha_devolucion, id_funcionario, active, fecha_elim, usr_id, observacion, id_equipo, id_empleado_entrega) VALUES (43, 1, '2019-06-17', 2, NULL, NULL, NULL, 'Equipo reparado y devuelto al almacen', 13, 1);
INSERT INTO public.devolucion (id_devolucion, id_solicitud_detalle, fecha_devolucion, id_funcionario, active, fecha_elim, usr_id, observacion, id_equipo, id_empleado_entrega) VALUES (44, 1, '2019-06-22', 2, NULL, NULL, NULL, 'Regresa funcionario original', 9, 1);
INSERT INTO public.devolucion (id_devolucion, id_solicitud_detalle, fecha_devolucion, id_funcionario, active, fecha_elim, usr_id, observacion, id_equipo, id_empleado_entrega) VALUES (45, 1, '2019-06-22', 2, NULL, NULL, NULL, '', 10, 1);
INSERT INTO public.devolucion (id_devolucion, id_solicitud_detalle, fecha_devolucion, id_funcionario, active, fecha_elim, usr_id, observacion, id_equipo, id_empleado_entrega) VALUES (46, 1, '2019-06-22', 2, NULL, NULL, NULL, '', 16, 2);
INSERT INTO public.devolucion (id_devolucion, id_solicitud_detalle, fecha_devolucion, id_funcionario, active, fecha_elim, usr_id, observacion, id_equipo, id_empleado_entrega) VALUES (47, 1, '2019-06-22', 2, NULL, NULL, NULL, '', 17, 2);
INSERT INTO public.devolucion (id_devolucion, id_solicitud_detalle, fecha_devolucion, id_funcionario, active, fecha_elim, usr_id, observacion, id_equipo, id_empleado_entrega) VALUES (48, 1, '2019-06-22', 2, NULL, NULL, NULL, 'fd', 12, 1);
INSERT INTO public.devolucion (id_devolucion, id_solicitud_detalle, fecha_devolucion, id_funcionario, active, fecha_elim, usr_id, observacion, id_equipo, id_empleado_entrega) VALUES (49, 1, '2019-06-22', 2, NULL, NULL, NULL, 'fsddf', 9, 1);
INSERT INTO public.devolucion (id_devolucion, id_solicitud_detalle, fecha_devolucion, id_funcionario, active, fecha_elim, usr_id, observacion, id_equipo, id_empleado_entrega) VALUES (50, 1, '2019-06-23', 13, NULL, NULL, NULL, 'weqwe', 12, 1);
INSERT INTO public.devolucion (id_devolucion, id_solicitud_detalle, fecha_devolucion, id_funcionario, active, fecha_elim, usr_id, observacion, id_equipo, id_empleado_entrega) VALUES (51, 1, '2019-06-23', 13, NULL, NULL, NULL, 'dsfsdf', 9, 1);
INSERT INTO public.devolucion (id_devolucion, id_solicitud_detalle, fecha_devolucion, id_funcionario, active, fecha_elim, usr_id, observacion, id_equipo, id_empleado_entrega) VALUES (52, 1, '2019-06-24', 2, NULL, NULL, NULL, 'sadsad', 6, 1);
INSERT INTO public.devolucion (id_devolucion, id_solicitud_detalle, fecha_devolucion, id_funcionario, active, fecha_elim, usr_id, observacion, id_equipo, id_empleado_entrega) VALUES (53, 1, '2019-06-24', 2, NULL, NULL, NULL, 'dasdasd', 7, 1);
INSERT INTO public.devolucion (id_devolucion, id_solicitud_detalle, fecha_devolucion, id_funcionario, active, fecha_elim, usr_id, observacion, id_equipo, id_empleado_entrega) VALUES (54, 1, '2019-06-24', 2, NULL, NULL, NULL, 'sadasdasd', 9, 1);
INSERT INTO public.devolucion (id_devolucion, id_solicitud_detalle, fecha_devolucion, id_funcionario, active, fecha_elim, usr_id, observacion, id_equipo, id_empleado_entrega) VALUES (55, 1, '2019-06-24', 2, NULL, NULL, NULL, 'dsadasdas', 10, 1);
INSERT INTO public.devolucion (id_devolucion, id_solicitud_detalle, fecha_devolucion, id_funcionario, active, fecha_elim, usr_id, observacion, id_equipo, id_empleado_entrega) VALUES (56, 1, '2019-06-24', 2, NULL, NULL, NULL, 'sadasdasd', 16, 1);
INSERT INTO public.devolucion (id_devolucion, id_solicitud_detalle, fecha_devolucion, id_funcionario, active, fecha_elim, usr_id, observacion, id_equipo, id_empleado_entrega) VALUES (57, 1, '2019-06-26', 2, NULL, NULL, NULL, 'hgjhg', 9, 4);


--
-- TOC entry 3366 (class 0 OID 200431)
-- Dependencies: 206
-- Data for Name: dummy; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.dummy (id, text) VALUES (-1, NULL);


--
-- TOC entry 3367 (class 0 OID 200434)
-- Dependencies: 207
-- Data for Name: dummy2; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.dummy2 (id, text) VALUES (NULL, 'Seleccione una opción');


--
-- TOC entry 3368 (class 0 OID 200437)
-- Dependencies: 208
-- Data for Name: empleado; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.empleado (id_empleado, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, cedula, direccion, email, id_departamento, id_telefono, id_estatus, cargo, active, fecha_elim, usr_id, id_oficina, id_usuario, id_ubicacion, telefono) VALUES (2, 'Pedro', NULL, 'Peez', NULL, 654321, 'otra casa', NULL, 1, NULL, 1, NULL, NULL, NULL, NULL, 1, 0, 3, NULL);
INSERT INTO public.empleado (id_empleado, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, cedula, direccion, email, id_departamento, id_telefono, id_estatus, cargo, active, fecha_elim, usr_id, id_oficina, id_usuario, id_ubicacion, telefono) VALUES (3, 'Enrique', 'Jose', 'Mora', 'Rodriguez', 5676223, NULL, 'emora@saren.gob.ve', 9, NULL, 1, NULL, NULL, NULL, NULL, 1, 1, 3, NULL);
INSERT INTO public.empleado (id_empleado, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, cedula, direccion, email, id_departamento, id_telefono, id_estatus, cargo, active, fecha_elim, usr_id, id_oficina, id_usuario, id_ubicacion, telefono) VALUES (4, 'Mirtha', 'Zaida', 'Perez', 'Matamoros', 6345234, NULL, 'mperez@saren.gob.ve', 6, NULL, 1, NULL, NULL, NULL, NULL, 1, 2, 3, NULL);
INSERT INTO public.empleado (id_empleado, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, cedula, direccion, email, id_departamento, id_telefono, id_estatus, cargo, active, fecha_elim, usr_id, id_oficina, id_usuario, id_ubicacion, telefono) VALUES (5, 'Pedro', 'Jose', 'Perez', 'Perez', 7345678, NULL, 'pperez@saren.gob.ve', 9, NULL, 1, NULL, NULL, NULL, NULL, 1, 3, 3, NULL);
INSERT INTO public.empleado (id_empleado, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, cedula, direccion, email, id_departamento, id_telefono, id_estatus, cargo, active, fecha_elim, usr_id, id_oficina, id_usuario, id_ubicacion, telefono) VALUES (6, 'Hugo', 'Serafin', 'Hidalgo', 'Suarez', 2877142, NULL, 'hhidalgo@saren.gob.ve', 9, NULL, 1, NULL, NULL, NULL, NULL, 1, 4, 3, NULL);
INSERT INTO public.empleado (id_empleado, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, cedula, direccion, email, id_departamento, id_telefono, id_estatus, cargo, active, fecha_elim, usr_id, id_oficina, id_usuario, id_ubicacion, telefono) VALUES (7, 'Maria', 'Auxiliadora', 'Ortiz', 'Ostos', 9876554, NULL, 'mortiz@saren.gob.ve', 9, NULL, 1, NULL, NULL, NULL, NULL, 1, 5, 3, NULL);
INSERT INTO public.empleado (id_empleado, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, cedula, direccion, email, id_departamento, id_telefono, id_estatus, cargo, active, fecha_elim, usr_id, id_oficina, id_usuario, id_ubicacion, telefono) VALUES (8, 'Josefina', 'Teresa', 'Lopez', 'Perez', 7345112, NULL, 'jlopez@saren.gob.ve', 9, NULL, 1, NULL, NULL, NULL, NULL, 1, 6, 3, NULL);
INSERT INTO public.empleado (id_empleado, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, cedula, direccion, email, id_departamento, id_telefono, id_estatus, cargo, active, fecha_elim, usr_id, id_oficina, id_usuario, id_ubicacion, telefono) VALUES (9, 'Teresa', 'Del Valle', 'Carias', 'Colmenares', 10213993, NULL, 'tcarias@saren.gob.ve', 9, NULL, 1, NULL, NULL, NULL, NULL, 1, 7, 3, NULL);
INSERT INTO public.empleado (id_empleado, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, cedula, direccion, email, id_departamento, id_telefono, id_estatus, cargo, active, fecha_elim, usr_id, id_oficina, id_usuario, id_ubicacion, telefono) VALUES (10, 'Pedro', 'Luis', 'Vargas', '', 4234871, NULL, 'pvargas@saren.gob.ve', 9, NULL, 1, NULL, NULL, NULL, NULL, 1, 8, 3, NULL);
INSERT INTO public.empleado (id_empleado, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, cedula, direccion, email, id_departamento, id_telefono, id_estatus, cargo, active, fecha_elim, usr_id, id_oficina, id_usuario, id_ubicacion, telefono) VALUES (11, 'Yelitza', 'Elena', 'Contreras', 'Albornoz', 11234221, NULL, 'ycontreras@saren.gob.ve', 9, NULL, 1, NULL, NULL, NULL, NULL, 1, 9, 3, NULL);
INSERT INTO public.empleado (id_empleado, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, cedula, direccion, email, id_departamento, id_telefono, id_estatus, cargo, active, fecha_elim, usr_id, id_oficina, id_usuario, id_ubicacion, telefono) VALUES (12, 'Leonardo', 'Antonio', 'Juarez', 'Gomez', 12992114, NULL, 'ljuarez@saren.gob.ve', 9, NULL, 1, NULL, NULL, NULL, NULL, 1, 12, 3, NULL);
INSERT INTO public.empleado (id_empleado, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, cedula, direccion, email, id_departamento, id_telefono, id_estatus, cargo, active, fecha_elim, usr_id, id_oficina, id_usuario, id_ubicacion, telefono) VALUES (14, 'Juan', 'Carlos', 'Carrasco', 'Gonzalez', 6233990, NULL, 'jcarrasco@gmail.com', 9, NULL, 1, NULL, NULL, NULL, NULL, 1, 17, 3, NULL);
INSERT INTO public.empleado (id_empleado, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, cedula, direccion, email, id_departamento, id_telefono, id_estatus, cargo, active, fecha_elim, usr_id, id_oficina, id_usuario, id_ubicacion, telefono) VALUES (15, 'Ignacio', 'Jose', 'Amaral', 'Lopez', 7234006, NULL, 'nalmaro@gmail.com', 9, NULL, 1, NULL, NULL, NULL, NULL, 1, 18, 3, NULL);
INSERT INTO public.empleado (id_empleado, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, cedula, direccion, email, id_departamento, id_telefono, id_estatus, cargo, active, fecha_elim, usr_id, id_oficina, id_usuario, id_ubicacion, telefono) VALUES (16, 'Patricia', '', 'Perez', 'Palermo', 15992559, NULL, 'pperez@gmail.com', 9, NULL, 1, NULL, NULL, NULL, NULL, 1, 19, 3, NULL);
INSERT INTO public.empleado (id_empleado, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, cedula, direccion, email, id_departamento, id_telefono, id_estatus, cargo, active, fecha_elim, usr_id, id_oficina, id_usuario, id_ubicacion, telefono) VALUES (1, 'Empleado', NULL, 'Prueba', NULL, 123456, 'su casa', NULL, 1, NULL, 1, NULL, NULL, NULL, NULL, 1, 0, 3, NULL);
INSERT INTO public.empleado (id_empleado, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, cedula, direccion, email, id_departamento, id_telefono, id_estatus, cargo, active, fecha_elim, usr_id, id_oficina, id_usuario, id_ubicacion, telefono) VALUES (13, 'Luis', 'Alberto', 'Almaro', 'Salas', 9098342, NULL, 'lalmaros@gmail.com', 6, NULL, 1, NULL, NULL, NULL, NULL, 1, 13, 3, 4268336986);
INSERT INTO public.empleado (id_empleado, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, cedula, direccion, email, id_departamento, id_telefono, id_estatus, cargo, active, fecha_elim, usr_id, id_oficina, id_usuario, id_ubicacion, telefono) VALUES (18, 'Antonio', 'Jesus', 'Gallardo', '', 6259831, 'sadsadsad', 'agallardo@saren.gob.ve', 1, NULL, 1, 'sadsadf', NULL, NULL, NULL, 75, NULL, 2, 40235);


--
-- TOC entry 3375 (class 0 OID 200475)
-- Dependencies: 218
-- Data for Name: equipo; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.equipo (id_equipo, cod_equipo, serial, id_estatus, id_ubicacion, num_bien_nac, descripcion, num_factura, fecha_factura, id_proveedor, valor, id_articulo, active, fecha_elim, usr_id, id_marca, id_oficina, id_departamento, id_solicitud_detalle_reserva) VALUES (10, 104, 'SMS-123456', 5, 1, '1212', 'SILLA SECRETARIAL SERIAL SMS-123456', 56487, '2018-04-30', 1, 110800, 15279, NULL, NULL, NULL, 1, 1, 1, 0);
INSERT INTO public.equipo (id_equipo, cod_equipo, serial, id_estatus, id_ubicacion, num_bien_nac, descripcion, num_factura, fecha_factura, id_proveedor, valor, id_articulo, active, fecha_elim, usr_id, id_marca, id_oficina, id_departamento, id_solicitud_detalle_reserva) VALUES (11, 105, 'SMS-123457', 5, 1, '1213', 'SILLA SECRETARIAL SERIAL SMS-123457', 45874, '2018-04-30', 1, 110800, 15279, NULL, NULL, NULL, 1, 1, 1, 0);
INSERT INTO public.equipo (id_equipo, cod_equipo, serial, id_estatus, id_ubicacion, num_bien_nac, descripcion, num_factura, fecha_factura, id_proveedor, valor, id_articulo, active, fecha_elim, usr_id, id_marca, id_oficina, id_departamento, id_solicitud_detalle_reserva) VALUES (13, 107, '87744222', 5, 1, '9987554', 'PC VIT MODELO 2661 4 GIBABYTES RAM DD 320', 53762, '2019-05-01', 1, 6637266, 10679, NULL, NULL, NULL, 1, 1, 1, 0);
INSERT INTO public.equipo (id_equipo, cod_equipo, serial, id_estatus, id_ubicacion, num_bien_nac, descripcion, num_factura, fecha_factura, id_proveedor, valor, id_articulo, active, fecha_elim, usr_id, id_marca, id_oficina, id_departamento, id_solicitud_detalle_reserva) VALUES (15, 109, '65432174', 5, 1, '96322', 'MALETIN PARA LAPTOP VIT COLOR NEGRO DE TELA SINTETICA SERIAL 65432174', 6874, '2019-06-07', 1, 25000, 15015, NULL, NULL, NULL, 4, 1, 1, 0);
INSERT INTO public.equipo (id_equipo, cod_equipo, serial, id_estatus, id_ubicacion, num_bien_nac, descripcion, num_factura, fecha_factura, id_proveedor, valor, id_articulo, active, fecha_elim, usr_id, id_marca, id_oficina, id_departamento, id_solicitud_detalle_reserva) VALUES (17, 110, '7271901914', 5, 1, '23656', 'RATON OPTICO DE COMPURTADORA MARCA GENIUS SERIAL 7271901914', 5454, '2019-06-12', 1, 5200, 10704, true, NULL, NULL, 16, 1, 1, 0);
INSERT INTO public.equipo (id_equipo, cod_equipo, serial, id_estatus, id_ubicacion, num_bien_nac, descripcion, num_factura, fecha_factura, id_proveedor, valor, id_articulo, active, fecha_elim, usr_id, id_marca, id_oficina, id_departamento, id_solicitud_detalle_reserva) VALUES (12, 106, '19918081', 5, 1, '1213443', 'LAPTOP VIT MODELO LV-5354 SERIAL 3565828763-S', 423423, '2019-03-18', 1, 123124, 10674, NULL, NULL, NULL, 1, 1, 1, 31);
INSERT INTO public.equipo (id_equipo, cod_equipo, serial, id_estatus, id_ubicacion, num_bien_nac, descripcion, num_factura, fecha_factura, id_proveedor, valor, id_articulo, active, fecha_elim, usr_id, id_marca, id_oficina, id_departamento, id_solicitud_detalle_reserva) VALUES (7, 101, 'TM189E30140087', 2, 3, '46664', 'HORNO MICROONDAS MARCA DAEWOO MODELO KOR-760WES COLOR BLANCO SERIAL TM189E30140087', 3214, '2018-04-30', 1, 14650.5, 14616, NULL, NULL, NULL, 5, 1, 5, 30);
INSERT INTO public.equipo (id_equipo, cod_equipo, serial, id_estatus, id_ubicacion, num_bien_nac, descripcion, num_factura, fecha_factura, id_proveedor, valor, id_articulo, active, fecha_elim, usr_id, id_marca, id_oficina, id_departamento, id_solicitud_detalle_reserva) VALUES (8, 102, '5332196464652a', 2, 3, '41319', 'DISPENSADOR DE AGUA MARCA MUNDO BLANCO MODELO MBDA12B COLOR BLANCO SERIAL 5332196464652a', 45154, '2018-04-30', 1, 6500, 11957, NULL, NULL, NULL, 13, 1, 5, 28);
INSERT INTO public.equipo (id_equipo, cod_equipo, serial, id_estatus, id_ubicacion, num_bien_nac, descripcion, num_factura, fecha_factura, id_proveedor, valor, id_articulo, active, fecha_elim, usr_id, id_marca, id_oficina, id_departamento, id_solicitud_detalle_reserva) VALUES (9, 103, '150910P40311SP0278', 5, 1, '789951159', 'LAPTOP SIRAGON MODELO NB-3170 SERIAL 150910P40311SP0278', 852474, '2018-04-30', 1, 125000, 10674, NULL, NULL, NULL, 14, 1, 1, 0);
INSERT INTO public.equipo (id_equipo, cod_equipo, serial, id_estatus, id_ubicacion, num_bien_nac, descripcion, num_factura, fecha_factura, id_proveedor, valor, id_articulo, active, fecha_elim, usr_id, id_marca, id_oficina, id_departamento, id_solicitud_detalle_reserva) VALUES (14, 108, 'SC192357797', 1, 1, '85743', 'TELEVISOR 24 PULGADAS MARCA DAEWOOD COLOR PLATEADO SERIAL SC192357797', 542344, '2018-02-19', 1, 42000, 14812, NULL, NULL, NULL, 1, 1, 1, 32);
INSERT INTO public.equipo (id_equipo, cod_equipo, serial, id_estatus, id_ubicacion, num_bien_nac, descripcion, num_factura, fecha_factura, id_proveedor, valor, id_articulo, active, fecha_elim, usr_id, id_marca, id_oficina, id_departamento, id_solicitud_detalle_reserva) VALUES (16, 110, '765422', 5, 1, '236544', 'ESCRITORIO LIVIANO DE ESTRUCTURA METALICA COLOR PLATEADO MODELO AERON MARCA FANAMETAL SERIAL 765422', 8524, '2019-06-03', 1, 15000, 15324, false, '2019-06-27', 2, 1, 1, 1, 0);
INSERT INTO public.equipo (id_equipo, cod_equipo, serial, id_estatus, id_ubicacion, num_bien_nac, descripcion, num_factura, fecha_factura, id_proveedor, valor, id_articulo, active, fecha_elim, usr_id, id_marca, id_oficina, id_departamento, id_solicitud_detalle_reserva) VALUES (6, 100, 'TM175E49140036', 5, 1, '4135001', 'HORNO MICROONDAS MARCA DAEWOO MODELO KOR-760WES COLOR BLANCO SERIAL TM175E49140036', 3256, '2018-04-30', 1, 12500.75, 14616, NULL, NULL, NULL, 5, 1, 1, 29);


--
-- TOC entry 3376 (class 0 OID 200480)
-- Dependencies: 219
-- Data for Name: equipo_marca; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3373 (class 0 OID 200470)
-- Dependencies: 216
-- Data for Name: equipo_old; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3383 (class 0 OID 200539)
-- Dependencies: 233
-- Data for Name: estado; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.estado (id_estado, nombre_estado, active, fecha_elim, usr_id) VALUES ('01', 'DISTRITO CAPITAL', NULL, NULL, NULL);
INSERT INTO public.estado (id_estado, nombre_estado, active, fecha_elim, usr_id) VALUES ('02', 'AMAZONAS', NULL, NULL, NULL);
INSERT INTO public.estado (id_estado, nombre_estado, active, fecha_elim, usr_id) VALUES ('03', 'ANZOATEGUI', NULL, NULL, NULL);
INSERT INTO public.estado (id_estado, nombre_estado, active, fecha_elim, usr_id) VALUES ('04', 'APURE', NULL, NULL, NULL);
INSERT INTO public.estado (id_estado, nombre_estado, active, fecha_elim, usr_id) VALUES ('05', 'ARAGUA', NULL, NULL, NULL);
INSERT INTO public.estado (id_estado, nombre_estado, active, fecha_elim, usr_id) VALUES ('06', 'BARINAS', NULL, NULL, NULL);
INSERT INTO public.estado (id_estado, nombre_estado, active, fecha_elim, usr_id) VALUES ('07', 'BOLIVAR', NULL, NULL, NULL);
INSERT INTO public.estado (id_estado, nombre_estado, active, fecha_elim, usr_id) VALUES ('08', 'CARABOBO', NULL, NULL, NULL);
INSERT INTO public.estado (id_estado, nombre_estado, active, fecha_elim, usr_id) VALUES ('09', 'COJEDES', NULL, NULL, NULL);
INSERT INTO public.estado (id_estado, nombre_estado, active, fecha_elim, usr_id) VALUES ('10', 'DELTA AMACURO', NULL, NULL, NULL);
INSERT INTO public.estado (id_estado, nombre_estado, active, fecha_elim, usr_id) VALUES ('11', 'FALCON', NULL, NULL, NULL);
INSERT INTO public.estado (id_estado, nombre_estado, active, fecha_elim, usr_id) VALUES ('12', 'GUARICO', NULL, NULL, NULL);
INSERT INTO public.estado (id_estado, nombre_estado, active, fecha_elim, usr_id) VALUES ('13', 'LARA', NULL, NULL, NULL);
INSERT INTO public.estado (id_estado, nombre_estado, active, fecha_elim, usr_id) VALUES ('14', 'MERIDA', NULL, NULL, NULL);
INSERT INTO public.estado (id_estado, nombre_estado, active, fecha_elim, usr_id) VALUES ('15', 'BOLIVARIANO DE MIRANDA', NULL, NULL, NULL);
INSERT INTO public.estado (id_estado, nombre_estado, active, fecha_elim, usr_id) VALUES ('16', 'MONAGAS', NULL, NULL, NULL);
INSERT INTO public.estado (id_estado, nombre_estado, active, fecha_elim, usr_id) VALUES ('17', 'NUEVA ESPARTA', NULL, NULL, NULL);
INSERT INTO public.estado (id_estado, nombre_estado, active, fecha_elim, usr_id) VALUES ('18', 'PORTUGUESA', NULL, NULL, NULL);
INSERT INTO public.estado (id_estado, nombre_estado, active, fecha_elim, usr_id) VALUES ('19', 'SUCRE', NULL, NULL, NULL);
INSERT INTO public.estado (id_estado, nombre_estado, active, fecha_elim, usr_id) VALUES ('20', 'TACHIRA', NULL, NULL, NULL);
INSERT INTO public.estado (id_estado, nombre_estado, active, fecha_elim, usr_id) VALUES ('21', 'TRUJILLO', NULL, NULL, NULL);
INSERT INTO public.estado (id_estado, nombre_estado, active, fecha_elim, usr_id) VALUES ('22', 'YARACUY', NULL, NULL, NULL);
INSERT INTO public.estado (id_estado, nombre_estado, active, fecha_elim, usr_id) VALUES ('23', 'ZULIA', NULL, NULL, NULL);
INSERT INTO public.estado (id_estado, nombre_estado, active, fecha_elim, usr_id) VALUES ('24', 'VARGAS', NULL, NULL, NULL);
INSERT INTO public.estado (id_estado, nombre_estado, active, fecha_elim, usr_id) VALUES ('25', 'DEPENDENCIAS FEDERALES', NULL, NULL, NULL);


--
-- TOC entry 3369 (class 0 OID 200446)
-- Dependencies: 210
-- Data for Name: estatus_empleado; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.estatus_empleado (id_estatus, estatus, active, fecha_elim, usr_id) VALUES (1, 'Activo', NULL, NULL, NULL);
INSERT INTO public.estatus_empleado (id_estatus, estatus, active, fecha_elim, usr_id) VALUES (2, 'Inactivo', NULL, NULL, NULL);


--
-- TOC entry 3385 (class 0 OID 200545)
-- Dependencies: 235
-- Data for Name: estatus_equipo; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3378 (class 0 OID 200485)
-- Dependencies: 221
-- Data for Name: estatus_equipo_v2; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.estatus_equipo_v2 (id_estatus_eq, estatus, active, fecha_elim, usr_id) VALUES (1, 'Asignado', NULL, NULL, NULL);
INSERT INTO public.estatus_equipo_v2 (id_estatus_eq, estatus, active, fecha_elim, usr_id) VALUES (2, 'Prestado', NULL, NULL, NULL);
INSERT INTO public.estatus_equipo_v2 (id_estatus_eq, estatus, active, fecha_elim, usr_id) VALUES (3, 'Dañado', NULL, NULL, NULL);
INSERT INTO public.estatus_equipo_v2 (id_estatus_eq, estatus, active, fecha_elim, usr_id) VALUES (5, 'Resguardo', NULL, NULL, NULL);
INSERT INTO public.estatus_equipo_v2 (id_estatus_eq, estatus, active, fecha_elim, usr_id) VALUES (4, 'Prestado por Jornada', NULL, NULL, NULL);


--
-- TOC entry 3388 (class 0 OID 200552)
-- Dependencies: 238
-- Data for Name: estatus_solicitud; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.estatus_solicitud (id_estatus_solicitud, descripcion, active, fecha_elim, usr_id) VALUES (1, 'Procesada', NULL, NULL, NULL);
INSERT INTO public.estatus_solicitud (id_estatus_solicitud, descripcion, active, fecha_elim, usr_id) VALUES (2, 'Parcialmente Procesada', NULL, NULL, NULL);
INSERT INTO public.estatus_solicitud (id_estatus_solicitud, descripcion, active, fecha_elim, usr_id) VALUES (3, 'Pendiente', NULL, NULL, NULL);
INSERT INTO public.estatus_solicitud (id_estatus_solicitud, descripcion, active, fecha_elim, usr_id) VALUES (4, 'Cancelada', NULL, NULL, NULL);


--
-- TOC entry 3391 (class 0 OID 200570)
-- Dependencies: 242
-- Data for Name: funcionario_old; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.funcionario_old (id_funcionario, id_oficina, nombre, apellido, cedula, telefono, email, cargo, active, fecha_elim, usr_id) VALUES (1, 1, 'Funcionario', 'Prueba', 123456, NULL, NULL, 'Prueba', NULL, NULL, NULL);


--
-- TOC entry 3393 (class 0 OID 200575)
-- Dependencies: 244
-- Data for Name: marca; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.marca (id_marca, descripcion, active, fecha_elim, usr_id) VALUES (1, 'Generico', NULL, NULL, NULL);
INSERT INTO public.marca (id_marca, descripcion, active, fecha_elim, usr_id) VALUES (2, 'Toshiba', NULL, NULL, NULL);
INSERT INTO public.marca (id_marca, descripcion, active, fecha_elim, usr_id) VALUES (3, 'Lenovo', NULL, NULL, NULL);
INSERT INTO public.marca (id_marca, descripcion, active, fecha_elim, usr_id) VALUES (4, 'VIT', NULL, NULL, NULL);
INSERT INTO public.marca (id_marca, descripcion, active, fecha_elim, usr_id) VALUES (5, 'Daewoo', NULL, NULL, NULL);
INSERT INTO public.marca (id_marca, descripcion, active, fecha_elim, usr_id) VALUES (6, 'LG', NULL, NULL, NULL);
INSERT INTO public.marca (id_marca, descripcion, active, fecha_elim, usr_id) VALUES (7, 'Samsung', NULL, NULL, NULL);
INSERT INTO public.marca (id_marca, descripcion, active, fecha_elim, usr_id) VALUES (8, 'Nokia', NULL, NULL, NULL);
INSERT INTO public.marca (id_marca, descripcion, active, fecha_elim, usr_id) VALUES (9, 'IBM', NULL, NULL, NULL);
INSERT INTO public.marca (id_marca, descripcion, active, fecha_elim, usr_id) VALUES (10, 'HP', NULL, NULL, NULL);
INSERT INTO public.marca (id_marca, descripcion, active, fecha_elim, usr_id) VALUES (11, 'Huawei', NULL, NULL, NULL);
INSERT INTO public.marca (id_marca, descripcion, active, fecha_elim, usr_id) VALUES (12, 'Dell', NULL, NULL, NULL);
INSERT INTO public.marca (id_marca, descripcion, active, fecha_elim, usr_id) VALUES (13, 'Mundo Blanco', NULL, NULL, NULL);
INSERT INTO public.marca (id_marca, descripcion, active, fecha_elim, usr_id) VALUES (14, 'Siragon', NULL, NULL, NULL);
INSERT INTO public.marca (id_marca, descripcion, active, fecha_elim, usr_id) VALUES (15, 'Fanametal', NULL, NULL, NULL);
INSERT INTO public.marca (id_marca, descripcion, active, fecha_elim, usr_id) VALUES (16, 'Genius', NULL, NULL, NULL);
INSERT INTO public.marca (id_marca, descripcion, active, fecha_elim, usr_id) VALUES (17, 'Panasonic', NULL, NULL, NULL);
INSERT INTO public.marca (id_marca, descripcion, active, fecha_elim, usr_id) VALUES (18, 'Panduit', NULL, NULL, NULL);


--
-- TOC entry 3395 (class 0 OID 200580)
-- Dependencies: 246
-- Data for Name: modelo; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3425 (class 0 OID 200968)
-- Dependencies: 290
-- Data for Name: motivo; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.motivo (id_motivo, motivo, active, fecha_elim, usr_id) VALUES (1, 'Obsolescencia', NULL, NULL, NULL);
INSERT INTO public.motivo (id_motivo, motivo, active, fecha_elim, usr_id) VALUES (2, 'Inservibilidad', NULL, NULL, NULL);
INSERT INTO public.motivo (id_motivo, motivo, active, fecha_elim, usr_id) VALUES (4, 'Desuso', NULL, NULL, NULL);
INSERT INTO public.motivo (id_motivo, motivo, active, fecha_elim, usr_id) VALUES (5, 'Robo o Hurto', NULL, NULL, NULL);
INSERT INTO public.motivo (id_motivo, motivo, active, fecha_elim, usr_id) VALUES (3, 'Reparación antieconómica', NULL, NULL, NULL);


--
-- TOC entry 3397 (class 0 OID 200585)
-- Dependencies: 248
-- Data for Name: municipio; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0101', 'BOLIVARIANO LIBERTADOR', '01', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0201', 'AUTONOMO ALTO ORINOCO', '02', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0202', 'AUTONOMO ATABAPO', '02', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0203', 'AUTONOMO ATURES', '02', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0204', 'AUTONOMO AUTANA', '02', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0205', 'AUTONOMO MAROA', '02', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0206', 'AUTONOMO MANAPIARE', '02', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0207', 'AUTONOMO RIO NEGRO', '02', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0301', 'ANACO ANACO', '03', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0302', 'ARAGUA', '03', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0303', 'FERNANDO DE PEÑALVER', '03', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0304', 'FRANCISCO DEL CARMEN CARVAJAL', '03', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0305', 'FRANCISCO DE MIRANDA', '03', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0306', 'GUANTA', '03', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0307', 'INDEPENDENCIA', '03', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0308', 'JUAN ANTONIO SOTILLO', '03', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0309', 'JUAN MANUEL CAJIGAL', '03', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0310', 'JOSE GREGORIO MONAGAS', '03', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0311', 'LIBERTAD', '03', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0312', 'MANUEL EZEQUIEL BRUZUAL', '03', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0313', 'PEDRO MARIA FREITES', '03', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0314', 'PIRITU', '03', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0315', 'SAN JOSE DE GUANIPA', '03', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0316', 'SAN JUAN DE CAPISTRANO', '03', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0317', 'SANTA ANA', '03', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0318', 'SIMON BOLIVAR', '03', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0319', 'SIMON RODRIGUEZ', '03', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0320', 'SIR ARTHUR MC GREGOR', '03', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0321', 'TURISTICO DIEGO BAUTISTA URBANEJA', '03', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0401', 'ACHAGUAS', '04', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0402', 'BIRUACA', '04', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0403', 'MUÑOZ', '04', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0404', 'PAEZ', '04', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0405', 'PEDRO CAMEJO', '04', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0406', 'ROMULO GALLEGOS', '04', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0407', 'SAN FERNANDO', '04', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0501', 'BOLIVAR', '05', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0502', 'CAMATAGUA', '05', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0503', 'GIRARDOT', '05', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0504', 'JOSE ANGEL LAMAS', '05', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0505', 'JOSE FELIX RIBAS', '05', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0506', 'JOSE RAFAEL REVENGA', '05', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0507', 'LIBERTADOR', '05', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0508', 'MARIO BRICEÑO IRAGORRY', '05', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0509', 'SAN CASIMIRO', '05', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0510', 'SAN SEBASTIAN', '05', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0511', 'SANTIAGO MARIÑO', '05', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0512', 'SANTOS MICHELENA', '05', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0513', 'SUCRE', '05', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0514', 'TOVAR', '05', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0515', 'URDANETA', '05', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0516', 'ZAMORA', '05', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0517', 'FRANCISCO LINARES ALCANTARA', '05', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0518', 'OCUMARE DE LA COSTA DE ORO', '05', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0601', 'ALBERTO ARVELO TORREALBA', '06', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0602', 'ANTONIO JOSE DE SUCRE', '06', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0603', 'ARISMENDI', '06', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0604', 'BARINAS', '06', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0605', 'BOLIVAR', '06', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0606', 'CRUZ PAREDES', '06', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0607', 'EZEQUIEL ZAMORA', '06', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0608', 'OBISPOS', '06', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0609', 'PEDRAZA', '06', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0610', 'ROJAS', '06', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0611', 'SOSA', '06', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0612', 'ANDRES ELOY BLANCO', '06', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0701', 'CARONI', '07', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0702', 'CEDEÑO', '07', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0703', 'EL CALLAO', '07', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0704', 'GRAN SABANA', '07', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0705', 'HERES', '07', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0706', 'PIAR', '07', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0707', 'BOLIVARIANO ANGOSTURA', '07', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0708', 'ROSCIO', '07', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0709', 'SIFONTES', '07', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0710', 'SUCRE', '07', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0711', 'PADRE PEDRO CHIEN', '07', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0801', 'BEJUMA', '08', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0802', 'CARLOS ARVELO', '08', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0803', 'DIEGO IBARRA', '08', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0804', 'GUACARA', '08', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0805', 'JUAN JOSE MORA', '08', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0806', 'LIBERTADOR', '08', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0807', 'LOS GUAYOS', '08', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0808', 'MIRANDA', '08', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0809', 'MONTALBAN', '08', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0810', 'NAGUANAGUA', '08', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0811', 'PUERTO CABELLO', '08', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0812', 'SAN DIEGO', '08', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0813', 'SAN JOAQUIN', '08', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0814', 'VALENCIA', '08', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0901', 'ANZOATEGUI', '09', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0902', 'TINAQUILLO', '09', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0903', 'GIRARDOT', '09', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0904', 'LIMA BLANCO', '09', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0905', 'PAO DE SAN JUAN BAUTISTA', '09', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0906', 'RICAURTE', '09', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0907', 'ROMULO GALLEGOS', '09', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0908', 'EZEQUIEL ZAMORA', '09', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('0909', 'TINACO', '09', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1001', 'ANTONIO DIAZ', '10', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1002', 'CASACOIMA', '10', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1003', 'PEDERNALES', '10', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1004', 'TUCUPITA', '10', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1101', 'ACOSTA', '11', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1102', 'BOLIVAR', '11', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1103', 'BUCHIVACOA', '11', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1104', 'CACIQUE MANAURE', '11', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1105', 'CARIRUBANA', '11', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1106', 'COLINA', '11', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1107', 'DABAJURO', '11', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1108', 'DEMOCRACIA', '11', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1109', 'FALCON', '11', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1110', 'FEDERACION', '11', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1111', 'JACURA', '11', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1112', 'LOS TAQUES', '11', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1113', 'MAUROA', '11', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1114', 'MIRANDA', '11', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1115', 'MONSEÑOR ITURRIZA', '11', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1116', 'PALMASOLA', '11', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1117', 'PETIT', '11', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1118', 'PIRITU', '11', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1119', 'SAN FRANCISCO', '11', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1120', 'SILVA', '11', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1121', 'SUCRE', '11', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1122', 'TOCOPERO', '11', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1123', 'UNION', '11', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1124', 'URUMACO', '11', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1125', 'ZAMORA', '11', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1201', 'CAMAGUAN', '12', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1202', 'CHAGUARAMAS', '12', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1203', 'EL SOCORRO', '12', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1204', 'SAN GERONIMO DE GUAYABAL', '12', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1205', 'LEONARDO INFANTE', '12', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1206', 'LAS MERCEDES', '12', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1207', 'JULIAN MELLADO', '12', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1208', 'FRANCISCO DE MIRANDA', '12', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1209', 'JOSE TADEO MONAGAS', '12', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1210', 'ORTIZ', '12', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1211', 'JOSE FELIX RIBAS', '12', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1212', 'JUAN GERMAN ROSCIO', '12', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1213', 'SAN JOSE DE GUARIBE', '12', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1214', 'SANTA MARIA DE IPIRE', '12', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1215', 'PEDRO ZARAZA', '12', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1301', 'ANDRES ELOY BLANCO', '13', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1302', 'CRESPO', '13', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1303', 'IRIBARREN', '13', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1304', 'JIMENEZ', '13', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1305', 'MORAN', '13', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1306', 'PALAVECINO', '13', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1307', 'SIMON PLANAS', '13', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1308', 'TORRES', '13', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1309', 'URDANETA', '13', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1401', 'ALBERTO ADRIANI', '14', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1402', 'ANDRES BELLO', '14', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1403', 'ANTONIO PINTO SALINAS', '14', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1404', 'ARICAGUA', '14', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1405', 'ARZOBISPO CHACON', '14', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1406', 'CAMPO ELIAS', '14', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1407', 'CARACCIOLO PARRA OLMEDO', '14', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1408', 'CARDENAL QUINTERO', '14', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1409', 'GUARAQUE', '14', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1410', 'JULIO CESAR SALAS', '14', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1411', 'JUSTO BRICEÑO', '14', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1412', 'LIBERTADOR', '14', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1413', 'MIRANDA', '14', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1414', 'OBISPO RAMOS DE LORA', '14', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1415', 'PADRE NOGUERA', '14', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1416', 'PUEBLO LLANO', '14', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1417', 'RANGEL', '14', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1418', 'RIVAS DAVILA', '14', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1419', 'SANTOS MARQUINA', '14', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1420', 'SUCRE', '14', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1421', 'TOVAR', '14', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1422', 'TULIO FEBRES CORDERO', '14', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1423', 'ZEA', '14', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1501', 'ACEVEDO', '15', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1502', 'ANDRES BELLO', '15', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1503', 'BARUTA', '15', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1504', 'BRION', '15', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1505', 'BUROZ', '15', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1506', 'CARRIZAL', '15', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1507', 'CHACAO', '15', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1508', 'CRISTOBAL ROJAS', '15', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1509', 'EL HATILLO', '15', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1510', 'BOLIVARIANO GUAICAIPURO', '15', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1511', 'INDEPENDENCIA', '15', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1512', 'LANDER', '15', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1513', 'LOS SALIAS', '15', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1514', 'PAEZ', '15', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1515', 'PAZ CASTILLO', '15', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1516', 'PEDRO GUAL', '15', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1517', 'PLAZA', '15', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1518', 'SIMON BOLIVAR', '15', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1519', 'SUCRE', '15', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1520', 'URDANETA', '15', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1521', 'ZAMORA', '15', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1601', 'ACOSTA', '16', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1602', 'AGUASAY', '16', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1603', 'BOLIVAR', '16', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1604', 'CARIPE', '16', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1605', 'CEDEÑO', '16', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1606', 'EZEQUIEL ZAMORA', '16', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1607', 'LIBERTADOR', '16', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1608', 'MATURIN', '16', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1609', 'PIAR', '16', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1610', 'PUNCERES', '16', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1611', 'SANTA BARBARA', '16', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1612', 'SOTILLO', '16', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1613', 'URACOA', '16', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1701', 'ANTOLIN DEL CAMPO', '17', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1702', 'ARISMENDI', '17', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1703', 'DIAZ', '17', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1704', 'GARCIA', '17', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1705', 'GOMEZ', '17', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1706', 'MANEIRO', '17', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1707', 'MARCANO', '17', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1708', 'MARIÑO', '17', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1709', 'PENINSULA DE MACANAO', '17', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1710', 'TUBORES', '17', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1711', 'VILLALBA', '17', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1801', 'AGUA BLANCA', '18', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1802', 'ARAURE', '18', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1803', 'ESTELLER', '18', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1804', 'GUANARE', '18', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1805', 'GUANARITO', '18', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1806', 'MONSEÑOR JOSE VICENTE DE UNDA', '18', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1807', 'OSPINO', '18', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1808', 'PAEZ', '18', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1809', 'PAPELON', '18', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1810', 'SAN GENARO DE BOCONOITO', '18', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1811', 'SAN RAFAEL DE ONOTO', '18', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1812', 'SANTA ROSALIA', '18', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1813', 'SUCRE', '18', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1814', 'TUREN', '18', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1901', 'ANDRES ELOY BLANCO', '19', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1902', 'ANDRES MATA', '19', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1903', 'ARISMENDI', '19', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1904', 'BENITEZ', '19', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1905', 'BERMUDEZ', '19', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1906', 'BOLIVAR', '19', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1907', 'CAJIGAL', '19', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1908', 'CRUZ SALMERON ACOSTA', '19', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1909', 'LIBERTADOR', '19', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1910', 'MARIÑO', '19', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1911', 'MEJIA', '19', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1912', 'MONTES', '19', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1913', 'RIBERO', '19', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1914', 'SUCRE', '19', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('1915', 'VALDEZ', '19', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2001', 'ANDRES BELLO', '20', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2002', 'ANTONIO ROMULO COSTA', '20', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2003', 'AYACUCHO', '20', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2004', 'BOLIVAR', '20', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2005', 'CARDENAS', '20', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2006', 'CORDOBA', '20', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2007', 'FERNANDEZ FEO', '20', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2008', 'FRANCISCO DE MIRANDA', '20', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2009', 'GARCIA DE HEVIA', '20', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2010', 'GUASIMOS', '20', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2011', 'INDEPENDENCIA', '20', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2012', 'JAUREGUI', '20', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2013', 'JOSE MARIA VARGAS', '20', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2014', 'JUNIN', '20', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2015', 'LIBERTAD', '20', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2016', 'LIBERTADOR', '20', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2017', 'LOBATERA', '20', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2018', 'MICHELENA', '20', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2019', 'PANAMERICANO', '20', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2020', 'PEDRO MARIA UREÑA', '20', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2021', 'RAFAEL URDANETA', '20', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2022', 'SAMUEL DARIO MALDONADO', '20', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2023', 'SAN CRISTOBAL', '20', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2024', 'SEBORUCO', '20', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2025', 'SIMON RODRIGUEZ', '20', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2026', 'SUCRE', '20', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2027', 'TORBES', '20', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2028', 'URIBANTE', '20', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2029', 'SAN JUDAS TADEO', '20', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2101', 'ANDRES BELLO', '21', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2102', 'BOCONO', '21', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2103', 'BOLIVAR', '21', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2104', 'CANDELARIA', '21', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2105', 'CARACHE', '21', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2106', 'ESCUQUE', '21', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2107', 'JOSE FELIPE MARQUEZ CAÑIZALES', '21', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2108', 'JUAN VICENTE CAMPO ELIAS', '21', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2109', 'LA CEIBA', '21', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2110', 'MIRANDA', '21', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2111', 'MONTE CARMELO', '21', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2112', 'MOTATAN', '21', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2113', 'PAMPAN', '21', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2114', 'PAMPANITO', '21', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2115', 'RAFAEL RANGEL', '21', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2116', 'SAN RAFAEL DE CARVAJAL', '21', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2117', 'SUCRE', '21', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2118', 'TRUJILLO', '21', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2119', 'URDANETA', '21', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2120', 'VALERA', '21', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2201', 'ARISTIDES BASTIDAS', '22', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2202', 'BOLIVAR', '22', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2203', 'BRUZUAL', '22', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2204', 'COCOROTE', '22', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2205', 'INDEPENDENCIA', '22', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2206', 'JOSE ANTONIO PAEZ', '22', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2207', 'LA TRINIDAD', '22', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2208', 'MANUEL MONGE', '22', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2209', 'NIRGUA', '22', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2210', 'PEÑA', '22', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2211', 'SAN FELIPE', '22', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2212', 'SUCRE', '22', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2213', 'URACHICHE', '22', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2214', 'VEROES', '22', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2301', 'ALMIRANTE PADILLA', '23', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2302', 'BARALT', '23', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2303', 'CABIMAS', '23', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2304', 'CATATUMBO', '23', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2305', 'COLON', '23', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2306', 'FRANCISCO JAVIER PULGAR', '23', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2307', 'JESUS ENRIQUE LOSSADA', '23', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2308', 'JESUS MARIA SEMPRUN', '23', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2309', 'LA CAÑADA DE URDANETA', '23', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2310', 'LAGUNILLAS', '23', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2311', 'MACHIQUES DE PERIJA', '23', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2312', 'MARA', '23', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2313', 'MARACAIBO', '23', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2314', 'MIRANDA', '23', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2315', 'INDIGENA BOLIVARIANO GUAJIRA', '23', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2316', 'ROSARIO DE PERIJA', '23', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2317', 'SAN FRANCISCO', '23', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2318', 'SANTA RITA', '23', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2319', 'SIMON BOLIVAR', '23', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2320', 'SUCRE', '23', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2321', 'VALMORE RODRIGUEZ', '23', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2401', 'VARGAS', '24', NULL, NULL, NULL);
INSERT INTO public.municipio (id_municipio, nombre_municipio, id_estado, active, fecha_elim, usr_id) VALUES ('2501', 'DEPENDENCIAS FEDERALES', '25', NULL, NULL, NULL);


--
-- TOC entry 3371 (class 0 OID 200451)
-- Dependencies: 212
-- Data for Name: oficina; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (1, 'OFICINA NACIONAL SAREN', 'MIJ', '488', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (3, 'NOTARÍA PÚBLICA SEGUNDA DE CARACAS MUNICIPIO LIBERTADOR', 'Av. Vollmer, Edif. Normandie, Piso 1, Urb. San Bernardino', 'NP9', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (4, 'NOTARÍA PÚBLICA TERCERA DE CARACAS MUNICIPIO LIBERTADOR', 'Av. Francisco Solano con calle Pascual Navarro, Edificio San Germán, local Nº 8, PB, Sabana Grande.', 'NP10', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (5, 'NOTARÍA PÚBLICA CUARTA DE CARACAS MUNICIPIO LIBERTADOR', 'Av. Urdaneta con Av. El Parque, Torre Oficentro, piso 2, diagonal al C.C. Galerias Ávila, San Bernardino.', 'NP11', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (6, 'NOTARÍA PÚBLICA QUINTA DE CARACAS MUNICIPIO LIBERTADOR', 'Av. Urdaneta, Pelota a Punceres, Edif. El Mirador, Mezzanina I', 'NP12', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (7, 'NOTARÍA PÚBLICA SEXTA DE CARACAS MUNICIPIO LIBERTADOR', 'Chorro a Dr. Paúl, Edif. Plaza El Venezolano, Mezzanina, Ofic. 4,         ', 'NP13', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (8, 'NOTARÍA PÚBLICA SEPTIMA DE CARACAS MUNICIPIO LIBERTADOR', 'Cruz de Candelaria a Candilito, Res. La Candelaria, P.B., Local C, frente a la Plaza Candelaria', 'NP14', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (9, 'NOTARÍA PÚBLICA OCTAVA DE CARACAS MUNICIPIO LIBERTADOR', 'Cipreses a Santa Teresa, Res. Santa Teresa, P.B., Local 6', 'NP15', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (10, 'NOTARÍA PÚBLICA NOVENA. DE CARACAS MUNICIPIO LIBERTADOR', 'Av. Francisco Solano López, al lado del Hotel Tampa', 'NP16', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (11, 'NOTARÍA PÚBLICA DÉCIMA DE CARACAS MUNICIPIO LIBERTADOR', 'Av. Francisco Solano López, Edif. San Antonio, Local D, P.B., Sabana Grande', 'NP17', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (12, 'NOTARÍA PÚBLICA UNDÉCIMA DE CARACAS MUNICIPIO LIBERTADOR', 'Plaza Venezuela, Edif. Polar, Piso 1, Local MG1', 'NP18', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (13, 'NOTARÍA PÚBLICA DUODÉCIMA DE CARACAS MUNICIPIO LIBERTADOR', 'Av. Andrés Bello, Edif. Centro Andrés Bello, Sótano 1, Local 1', 'NP19', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (14, 'NOTARÍA PÚBLICA DECIMATERCERA DE CARACAS MUNICIPIO LIBERTADOR', 'Av. Los Samanes, Qta. Villa Olga, N° 39, La Florida', 'NP20', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (15, 'NOTARÍA PÚBLICA DECIMA CUARTA DE CARACAS MUNICIPIO LIBERTADOR', 'Av. Sucre, Conjunto Res. Sucre, Local 21, Mezzanina, frente al Metro de Agua Salud, Catia', 'NP21', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (16, 'NOTARÍA PÚBLICA DECIMA QUINTA DEL MUNICIPIO LIBERTADOR', 'Av. San Martín, Centro Comercial Los Molinos, 1er. Piso, Local 38', 'NP22', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (17, 'NOTARÍA PÚBLICA DECIMA SEXTA DE CARACAS MUNICIPIO LIBERTADOR', 'Av. Teresa de la Parra, Centro Comercial Santa Mónica, Locales 13 y 14', 'NP23', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (18, 'NOTARÍA PÚBLICA DECIMA SEPTIMA DE CARACAS MUNICIPIO LIBERTADOR', 'Av. Presidente Média, Edif. Pini, Piso 1, Urb. Las Acacias', 'NP24', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (19, 'NOTARÍA PÚBLICA DECIMA OCTAVA  DE CARACAS MUNICIPIO LIBERTADOR', 'Centro Comercial Plaza Páez,  Nivel Oficinas, Local Nº 3 Calle Madariaga, frente a la Universidad Santa María, El Paraíso', 'NP25', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (20, 'NOTARÍA PÚBLICA DECIMA NOVENA DE CARACAS MUNICIPIO LIBERTADOR', 'Padre Sierra a Conde, Edif. Bapgel, Piso 3, Oficinas 31 y 32', 'NP26', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (21, 'NOTARÍA PÚBLICA VIGÉSIMA DE CARACAS MUNICIPIO LIBERTADOR', 'Edif. Centro Mercantil, Piso 1, Ofic. 1-9, Av. Universidad entre las Esq. de San Francisco a Sociedad', 'NP27', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (22, 'NOTARÍA PÚBLICA VIGÉSIMA PRIMERA DE CARACAS MUNICIPIO LIBERTADOR', 'Av. Lecuna, Miracielos a Hospital, Edif. Sur 2, Piso 2, Ofic. 202, frente a Imgeve', 'NP28', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (23, 'NOTARÍA PÚBLICA VIGÉSIMA SEGUNDA DE CARACAS MUNICIPIO LIBERTADOR', 'Calle Villaflor con Av. Casanova, Edif. Boreal, Mezzanina, Sabana Grande', 'NP29', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (24, 'NOTARÍA PÚBLICA VIGÉSIMATERCERA DE CARACAS MUNICIPIO LIBERTADOR', 'Parque Central, Nivel Bolívar,  Edif. Catuche, Local 2CB-35', 'NP30', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (25, 'NOTARÍA PÚBLICA VIGÉSIMA CUARTA DE CARACAS MUNICIPIO LIBERTADOR', 'Av. Universidad, Urb. Los Chaguaramos, Edif. Odeón,     Piso 1, Ofic. 4, Pquia. Sta.   Rosalia', 'NP31', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (26, 'NOTARÍA PÚBLICA VIGÉSIMA QUINTA DE CARACAS MUNICIPIO LIBERTADOR', 'Av. Libertador, Esq. Calle Negrín, Centro Comercial Libertador, Nivel P2, Ofic. 29', 'NP32', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (27, 'NOTARÍA PÚBLICA VIGÉSIMA SEXTA DE CARACAS MUNICIPIO LIBERTADOR', 'Av. Este Seis, entre Ño Pastor y Puente Victoria, Edif. Centro  Pq.Carabobo, Nivel 1, Mezzanina, N° 102, Pquia. Candelaria', 'NP33', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (28, 'NOTARÍA PÚBLICA VIGÉSIMA SÉPTIMA DE CARACAS MUNICIPIO LIBERTADOR', 'Av. México, Centro Empresarial Bellas Artes, Edif. Los Ortega, Mezzanina, Local 26', 'NP34', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (29, 'NOTARÍA PÚBLICA VIGÉSIMA OCTAVA DE CARACAS MUNICIPIO LIBERTADOR', 'Av. Bolívar, Centro Comercial Propatria, Local E-8, Nivel 4, Propatria', 'NP35', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (30, 'NOTARÍA PÚBLICA VIGÉSIMA NOVENA DE CARACAS MUNICIPIO LIBERTADOR', 'Av. Urdaneta, Esq. de Urapal, Edif. Urimare, Piso 1 ', 'NP36', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (31, 'NOTARÍA PÚBLICA TRIGÉSIMA DE CARACAS MUNICIPIO LIBERTADOR', 'Av. Roosevelt entre  Calle Los Cortijos y Av. Nueva Granada, Centro Comercial Profesional "4G" Local 8, P.B., Los Rosales', 'NP37', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (32, 'NOTARÍA PÚBLICA TRIGÉSIMA PRIMERA DE CARACAS MUNICIPIO LIBERTADOR', 'Av. Urdaneta, Centro Financiero Latino, Piso 15, Oficina 8.', 'NP38', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (33, 'NOTARÍA PÚBLICA TRIGÉSIMA SEGUNDA DE CARACAS MUNICIPIO LIBERTADOR', 'Colón a Dr. Díaz, Edificio Oficentro Edal, Piso 2, Oficina 2-A, El Silencio.', 'NP39', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (34, 'NOTARÍA PÚBLICA TRIGÉSIMO TERCERA DE CARACAS MUNICIPIO LIBERTADOR', 'Calle El Recreo con Boulevard de Sabana Grande, Edificio  Estoril, Piso 1, Oficina 12.', 'NP40', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (35, 'NOTARÍA PÚBLICA TRIGÉSIMA CUARTA DE CARACAS MUNICIPIO LIBERTADOR', 'Esq. Padre Sierra a Muñoz, Edif. Oficentro, Mezzanina', 'NP41', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (36, 'NOTARÍA PÚBLICA TRIGÉSIMA QUINTA DE CARACAS MUNICIPIO LIBERTADOR', 'Av Universidad, Esquina de Coliseo a Peinero, Piso 2, Edf. Centro Ejecutivo, Ofi.25. La Hoyada ', 'NP42', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (37, 'NOTARÍA PÚBLICA TRIGÉSIMA SEXTA DE CARACAS MUNICIPIO LIBERTADOR', 'Av. Urdaneta, Esq. Ibarras a Pelota, Edf. Karam, Piso 6, Ofc. 625', 'NP43', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (38, 'NOTARÍA PÚBLICA TRIGÉSIMA SEPTIMA DE CARACAS MUNICIPIO LIBERTADOR', 'Av. Urdaneta, Esq. de Animas, Edif. Centro 63, Piso 1, Ofic. 1-E, diagonal al Edif. El Universal', 'NP44', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (39, 'NOTARÍA PÚBLICA TRIGÉSIMA OCTAVA DE CARACAS MUNICIPIO LIBERTADOR', 'Av. Casanova, Centro Comercial Cediaz, Torre Oeste, Local Comercial, PB-2, Sabana Grande', 'NP45', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (40, 'NOTARÍA PÚBLICA TRIGÉSIMA NOVENA DE CARACAS MUNICIPIO LIBERTADOR', 'Av. Santa Lucía, entre Avda. Ppal. El Bosque y Av. Santa Isabel, Minicentro Comercial Doral, P.B., Locales M25A, M27A, M27B y M29A (frente a Beco Chacaíto)', 'NP46', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (41, 'NOTARÍA PÚBLICA CUADRAGÉSIMA DE CARACAS MUNICIPIO LIBERTADOR', 'Av. Principal de Bella Vista, Edificio Ninoska, Piso 1, diagonal al antiguo Reloj.', 'NP47', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (42, 'NOTARÍA PÚBLICA CUADRAGÉSIMA PRIMERA DE CARACAS MUNICIPIO LIBERTADOR', 'Centro Comercial Los Chaguaramos  entre  Av.  Edison y Neverí, Planta Principal, Local 4, Colinas de Bello Monte.', 'NP48', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (43, 'NOTARÍA PÚBLICA CUADRAGÉSIMA SEGUNDA DE CARACAS MUNICIPIO LIBERTADOR', 'Centro Uslar, Torre Oficinas, Piso 2, Local N° 24, Sector B, Unidad Vecinal 1, Urb. Montalbán', 'NP49', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (44, 'NOTARÍA PÚBLICA CUADRAGÉSIMA TERCERA DE CARACAS MUNICIPIO LIBERTADOR', 'Av. Urdaneta de Marrón a Pelota, Edif. General Páez, Piso 6, Ofic. 606, frente a papeleria La Nacional, diagonal al Banco Provincial', 'NP50', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (45, 'NOTARÍA PÚBLICA CUADRAGÉSIMA CUARTA DE CARACAS MUNICIPIO LIBERTADOR', 'Parroquia Coche, Urbanización La Rinconada, Planta Baja, Edificio sede Instituto Nacional de Hipódromo.', 'NP51', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (46, 'NOTARÍA PÚBLICA CUADRAGÉSIMA QUINTA DE CARACAS MUNICIPIO LIBERTADOR', 'Av. Stadium, Esq. Calle Sanoja, Qta. Irene, Mezzanina, Local N° 5, Los Chaguaramos', 'NP52', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (47, 'NOTARÍA PÚBLICA PRIMERA DEL MUNICIPIO SUCRE ESTADO MIRANDA', 'Av. Francisco de Miranda, Edif. Centro Seguros La Paz, P.B., Local 20, Boleíta Sur', 'NP53', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (48, 'NOTARÍA PÚBLICA SEGUNDA  DEL MUNICIPIO SUCRE ESTADO MIRANDA', 'Edif. Centro Empresarial Parque del Este (C.E.P.E.) (Torre Ericsson),  Pasillo Banco Mercantil P.B., Locales 9 y 10, Av. Francisco de Miranda, Los dos Caminos', 'NP54', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (49, 'NOTARÍA PÚBLICA TERCERA DEL MUNICIPIO SUCRE ESTADO MIRANDA', 'Urb. Los Dos Caminos, Edificio Provincial, piso 1, oficina Nº 1.', 'NP55', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (50, 'NOTARÍA PÚBLICA CUARTA DEL MUNICIPIO SUCRE ESTADO MIRANDA', 'Av. Francisco de Miranda, con Av. Diego Cisneros, Centro Empresarial Miranda, Piso 4, Ofic. 4-A, Los Ruices', 'NP56', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (51, 'NOTARÍA PÚBLICA QUINTA DEL MUNICIPIO SUCRE ESTADO MIRANDA', 'Calle 13-1, Edif. Urbina Palace, P.B., frente a Disco Center, La Urbina Sur', 'NP57', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (52, 'NOTARÍA PÚBLICA SEXTA DEL MUNICIPIO SUCRE ESTADO MIRANDA', 'Av. Rómulo Gallegos, Urb. Horizonte, Centro Comercial Aloa, Torre C, P.P, Local L-5,    El  Marqués', 'NP58', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (53, 'NOTARÍA PÚBLICA SÉPTIMA DEL MUNICIPIO SUCRE ESTADO MIRANDA', 'Av. San Francisco, Centro Comercial Macaracuay, Nivel Mezzanina, Urb. Macaracuay', 'NP59', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (54, 'NOTARÍA PÚBLICA OCTAVA  DEL MUNICIPIO SUCRE ESTADO MIRANDA', 'Carretera Petare Santa Lucía, Km. 3, Centro Comercial TIABU, Local Nro. 2, 1er. Piso, Sector El Limoncito, Filas de Mariche', 'NP60', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (55, 'NOTARÍA PÚBLICA PRIMERA DEL MUNICIPIO CHACAO ESTADO MIRANDA', 'Centro Comercial Bello Campo, Mezzanina, Ofics. 48 y 49, Calle Independencia y José Félix Sosa, Bello Campo', 'NP63', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (56, 'NOTARÍA PÚBLICA SEGUNDA DEL MUNICIPIO CHACAO ESTADO MIRANDA', 'Av. Francisco de Miranda, Centro Perú, P.B., Local B7, al lado de la Estación del Metro, Chacao', 'NP64', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (57, 'NOTARÍA PÚBLICA TERCERA DEL MUNICIPIO CHACAO ESTADO MIRANDA', 'Av. Francisco de Miranda, Centro Plaza, Nivel 3, Local CC365,  al lado del Café La Margana, Los Palos Grandes', 'NP65', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (58, 'NOTARÍA PÚBLICA CUARTA DEL MUNICIPIO CHACAO ESTADO MIRANDA', 'Av. Venezuela con Calle Alameda, Quinta Cristina, Nro. 3, Urb. El Rosal, Chacao.', 'NP66', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (59, 'NOTARÍA PÚBLICA QUINTA DEL MUNICIPIO CHACAO ESTADO MIRANDA', 'Final de la Av. Casanova, entre Calles Guacaipuro y Tamanaco, Centro Comercial 777, Locales 14 y 14B, Piso 1, Chacaíto', 'NP67', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (60, 'NOTARÍA PÚBLICA SEXTA DEL MUNICIPIO CHACAO ESTADO MIRANDA', 'Av. Francisco de Miranda, Edif. Parque Cristal, Nivel Mezzanina 2, Local 12, Los Palos Grandes', 'NP68', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (61, 'NOTARÍA PÚBLICA SÉPTIMA DEL MUNICIPIO CHACAO ESTADO MIRANDA', 'Av. Venezuela, Torre Mariana, Piso 5, Oficina 5-A, Urb. El Rosal, Chacao.', 'NP69', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (62, 'NOTARÍA PÚBLICA OCTAVA DEL MUNICIPIO CHACAO ESTADO MIRANDA', 'Av. Francisco de Miranda, Edif. Mariscal Sucre, Mezzanina A, al lado de la CANTV, Chacao', 'NP70', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (63, 'NOTARÍA PÚBLICA NOVENA DEL MUNICIPIO CHACAO ESTADO MIRANDA', 'Av. Francisco de Miranda, curce con Av. Sur, Juan Bosco, Urb. Altamira, Edif. Seguros Adriática, Piso 10, PH-1, Chacao', 'NP71', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (64, 'NOTARÍA PÚBLICA PRIMERA DEL MUNICIPIO BARUTA DEL ESTADO MIRANDA', 'Urb. Chuao, Av. La Estancia, Edif. Centro Banaven, Cubo Negro, Local S-6, Nivel Sótano', 'NP72', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (65, 'NOTARÍA PÚBLICA SEGUNDA DEL MUNICIPIO BARUTA DEL ESTADO MIRANDA', 'Av. Río Caura, Centro Empresarial La Pirámide, Local 40, (Nivel Estacionamiento), Urb. Prados del Este', 'NP73', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (66, 'NOTARÍA PÚBLICA TERCERA DEL MUNICIPIO BARUTA DEL ESTADO MIRANDA', 'Centro Comercial Bello Monte, Av. Leonardo Da Vinci, Mezzanina, P.B., Local Nro. 3, Urb. Bello Monte', 'NP74', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (67, 'NOTARÍA PÚBLICA CUARTA DEL MUNICIPIO BARUTA DEL ESTADO MIRANDA', 'Av. Principal Las Mercedes, cruce con Calle New York, Edif. Barsa, Ofic. 1A, Urb. Las Mercedes', 'NP75', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (68, 'NOTARÍA PÚBLICA QUINTA DEL MUNICIPIO BARUTA DEL ESTADO MIRANDA', 'Calle San Rafael con Calle Urape, Centro Comercial Plaza La Trinidad, Piso 2, Ofic. 18, La Trinidad', 'NP76', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (69, 'NOTARÍA PÚBLICA SEXTA DEL MUNICIPIO BARUTA DEL ESTADO MIRANDA', 'Av. San Sebastián, Edificio Satélite 2000, Piso 2, La Trinidad.', 'NP77', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (70, 'NOTARÍA PÚBLICA SÉPTIMA DEL MUNICIPIO BARUTA DEL ESTADO MIRANDA', 'Centro Comercial Plaza Las Américas, Local 26-B, P.B. final del Boulevard Raúl Leoni, El Cafetal', 'NP78', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (71, 'NOTARÍA PÚBLICA OCTAVA DEL MUNICIPIO BARUTA DEL ESTADO MIRANDA', 'Centro Comercial Ciudad Tamanaco, Nivel C-1, Sector C.P.T., Mezzanina, Ofic. 46, Chuao', 'NP79', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (72, 'NOTARÍA PÚBLICA NOVENA.DEL MUNICIPIO BARUTA DEL ESTADO MIRANDA', 'Centro Comercial Parquez Humboltd, Nivel Mezzanina, al 13-B, al lado de Viajes Prado, Prados del Este', 'NP80', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (73, 'NOTARÍA PÚBLICA DEL MUNICIPIO GUAICAIPURO ESTADO MIRANDA', 'Final de la Av. Bermúdez, Centro Comercial Hito, Piso 4, Ofcs. Nros. 8 y 9, Los Teques', 'NP81', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (74, 'NOTARÍA PÚBLICA MUNICIPIO LOS SALIAS. S.A. LOS ALTOS ESTADO MIRANDA', 'Centro Comercial La Casona I, Nivel 2, Local N2-13, Kilometro 16 de la Carretera Panamericana   San                 Antonio de Los Altos                       ', 'NP82', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (75, 'NOTARÍA PÚBLICA MUNICIPIO PLAZA GUARENAS ESTADO MIRANDA', 'Av. Intercomunal Guarenas-Guatire, detrás de Arturos, Centro Comercial Aventura, Piso 3, Ofics.6 y 7. Guarenas.', 'NP83', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (76, 'NOTARÍA PÚBLICA MUNICIPIO ZAMORA GUATIRE ESTADO MIRANDA', 'Av. Bermúdez, Centro Comercial Guatiren Plaza, Nivel 2, Local Nro. 81, Guatire', 'NP84', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (77, 'NOTARÍA PÚBLICA MUNICIPIO BRION HIGUEROTE ESTADO MIRANDA', 'Tercera Av. antes Calle Barlovento, Minicentro Majafa, Piso 1, Ofic. 3, entre las Calles 8 y 10, Higuerote', 'NP85', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (78, 'NOTARÍA PÚBLICA MUNICIPIO CRISTOBAL ROJAS CHARALLAVE ESTADO MIRANDA', 'Avenida Bolivar, Edificio Santa Rosita. Piso 3. Locale 8 y 9. Charallave.', 'NP86', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (79, 'NOTARÍA PÚBLICA DE PUERTO AYACUCHO ESTADO AMAZONAS', 'Av. Amazonas, Locales Juncosa, N° 1, Puerto Ayacucho', 'NP87', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (80, 'NOTARÍA PÚBLICA PRIMERA DE BARCELONA ESTADO ANZOÁTEGUI', 'Av.   Monagas,   Edif.   María Auxiliadora, Local 2, frente al Parque de Los Enamorados, Barcelona', 'NP88', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (81, 'NOTARÍA PÚBLICA PRIMERA DE PUERTO LA CRUZ ESTADO ANZOÁTEGUI', 'Calle El Cementerio, Nro. 42, Edif. Elio, P.B., Puerto La Cruz', 'NP89', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (82, 'NOTARÍA PÚBLICA SEGUNDA DE PUERTO LA CRUZ ESTADO ANZOÁTEGUI', 'Av. 5 de Julio, Edif. Cupic, Local 43, P.B., al lado de Corp-Banca, Puerto La Cruz', 'NP90', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (83, 'NOTARÍA PÚBLICA TERCERA  DE PUERTO LA CRUZ ESTADO ANZOÁTEGUI', 'Centro Comercial Cristóforo Colombo, Piso 1, Local 24, entre Paseo Colón y Calle Bolívar, Puerto La Cruz', 'NP91', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (84, 'NOTARÍA PÚBLICA EL TIGRE ESTADO ANZOÁTEGUI', 'Av. Francisco de Miranda, Edif. El Coloso, Ofic. 102, Piso 1, El Tigre', 'NP92', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (85, 'NOTARÍA PÚBLICA DE ANACO ESTADO ANZOÁTEGUI', 'Calle Industria con Junín, Anaco.', 'NP93', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (86, 'NOTARÍA PÚBLICA DE LECHERÍAS ESTADO ANZOÁTEGUI', 'Av. Principal de Lecherías, Centro Comercial Mini Centro Principal, Piso 1, Locales 6 y 7, Lecherías.', 'NP94', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (87, 'NOTARÍA PÚBLICA DE SAN FERNANDO DE APURE ESTADO APURE', 'Calle 5 de Julio, Palacio Barbarito, P.B., San Fernando', 'NP95', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (88, 'NOTARÍA PÚBLICA DE GUASDUALITO ESTADO APURE', 'Calle Cedeño con Carrera Ricaurte, Edif. Nadea, Piso 1, Ofic. N° 2, Guasdualito', 'NP96', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (89, 'NOTARÍA PÚBLICA PRIMERA MARACAY ESTADO ARAGUA', 'Calle Rivas Oeste, entre Sánchez Carrero y Vargas, Nº 31. Maracay.', 'NP97', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (90, 'NOTARÍA PÚBLICA SEGUNDA MARACAY ESTADO ARAGUA', 'Calle Boyacá, cruce con Calle Vargas, Edif. Doraca, P.B., N° 54, Maracay.', 'NP98', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (91, 'NOTARÍA PÚBLICA TERCERA MARACAY ESTADO ARAGUA', 'Calle Los Tres Mosqueteros, Qta. Fanny, N° 1, Urb. La Esperanza, Maracay', 'NP99', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (92, 'NOTARÍA PÚBLICA CUARTA DE  MARACAY ESTADO ARAGUA', 'Av. Bolívar Este, Centro Comercial Parque Aragua, Nivel 4, Local 25-B, detrás del Restaurante Verde y Verde, Maracay', 'NP100', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (93, 'NOTARÍA PÚBLICA QUINTA DE  MARACAY ESTADO ARAGUA', 'Calle Santos Michelena y Av. 19 de Abril, cruce con Calle Mariño, Centro Comercial La Capilla, 1er. Nivel, Local 23, Maracay.', 'NP101', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (94, 'NOTARÍA PÚBLICA DE CAGUA ESTADO ARAGUA', 'Calle Cajigal , Centro Comercial Star Center, Piso 1, Locales 61 y 62,  Cagua', 'NP102', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (95, 'NOTARÍA PÚBLICA DE LA VICTORIA ESTADO ARAGUA', 'Av. Victoria, Centro Comercial Cilento, Piso 2, Locales 30 y 31, La Victoria.', 'NP103', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (96, 'NOTARÍA PÚBLICA DE TURMERO ESTADO ARAGUA', 'Av. Intercomunal General Santiago Mariño, Centro Comercial Coche Aragua, Local 102-103. Turmero', 'NP104', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (97, 'NOTARÍA PÚBLICA PRIMERA DE BARINAS ESTADO BARINAS', 'Calle Camejo entre Av. Libertad y Av. Montilla, Edif. Oporto, al lado de La Ferreteria Impacto, Barinas', 'NP105', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (98, 'NOTARÍA PÚBLICA SEGUNDA DE BARINAS ESTADO BARINAS', 'Calle Bolívar, cruce con Av. Medina Jiménez, Barinas', 'NP106', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (99, 'NOTARÍA PÚBLICA DE SOCOPO ESTADO BARINAS', 'Barrio Las Flores, Carrera 5, entre Calles 1 y 2, N° 5-13, Sopocó.', 'NP107', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (100, 'NOTARÍA PÚBLICA PRIMERA DE PUERTO ORDAZ ESTADO BOLÍVAR', 'Centro Comercial Villa Alianza, Locales Nos. 04 y 05, Nivel I, Calle Estados Unidos y Calle Filadelfia, Urb. Villa Alianza. Puerto Ordaz', 'NP108', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (101, 'NOTARÍA PÚBLICA SEGUNDA DE PUERTO ORDAZ ESTADO BOLÍVAR', 'Centro Comercial Caura, Carrera Tocoma, SEMISOTANO, locales 6 Y 7, Alta Vista, Puerto Ordaz', 'NP109', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (102, 'NOTARÍA PÚBLICA TERCERA DE SAN FELIX ESTADO BOLÍVAR', 'Av. Moreno de Mendoza, cruce con Av. Antonio de Berrío, Edif. Tamanaco, Piso 1, Ofic. N° 09, El Roble, San Félix', 'NP110', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (103, 'NOTARÍA PÚBLICA CUARTA DE PUERTO ORDAZ ESTADO BOLÍVAR', 'Centro Comercial Cristal, Piso 1, Locales 110 y 111, Alta Vista Sur, Puerto Ordaz', 'NP111', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (104, 'NOTARÍA PÚBLICA PRIMERA DE CIUDAD BOLÍVAR ESTADO BOLÍVAR', 'Paseo Heres, Edif. Lis, P.B., Locales 2 y 3, Ciudad Bolívar', 'NP112', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (105, 'NOTARÍA PÚBLICA SEGUNDA DE CIUDAD BOLÍVAR ESTADO BOLÍVAR', 'Av. Pichincha, con Calle Machado, Centro Comercial Don Chalo,  Locales 5 y 6, Ciudad Bolívar', 'NP113', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (106, 'NOTARÍA PÚBLICA DE UPATA ESTADO BOLÍVAR', 'Centro Comercial Anakaro, Piso 2, Local 21, Calle Bolívar, cruce con Calle Urdaneta, frente a la Plaza Bolívar. Upata', 'NP114', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (107, 'NOTARÍA PÚBLICA DE LA GRAN SABANA ESTADO BOLÍVAR', 'Calle Icabarú, Centro Comercial Lucy, Piso 1, Local E, Municipio La Gran Sabana, Santa Elena de Uairen', 'NP115', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (108, 'NOTARÍA PÚBLICA PRIMERA DE VALENCIA ESTADO CARABOBO', 'Calle Libertad, Nro. 97-37, entre  Av. Boyacá y Farriar, Valencia.', 'NP116', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (109, 'NOTARÍA PÚBLICA SEGUNDA DE VALENCIA ESTADO CARABOBO', 'Av. Montes de Oca, con Calle Independencia, Torre Araujo, P.B., Local N° 6, Valencia', 'NP117', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (110, 'NOTARÍA PÚBLICA TERCERA DE VALENCIA ESTADO CARABOBO', 'Calle Libertad con Calle Montes de Oca, Edif. San Francisco, Piso 1, Ofics. 1, 2 y 3, Valencia', 'NP118', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (111, 'NOTARÍA PÚBLICA CUARTA DE VALENCIA ESTADO CARABOBO', 'Av. Urdaneta, con Calle Arismendi, Edif. Oficentro El Quinteto, P.B., Local 1-A, Valencia', 'NP119', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (112, 'NOTARÍA PÚBLICA QUINTA DE VALENCIA ESTADO CARABOBO', 'Centro Comercial Trigal Sur, Piso 2, Locales 35, 36, 37 y 38, Valencia', 'NP120', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (113, 'NOTARÍA PÚBLICA SEXTA DE VALENCIA ESTADO CARABOBO', 'Urb. Prebo I, Calle 137 con Av. 107, Centro Comercial Prebo, P.B, Locales 11, 12, 13, y 14, Valencia', 'NP121', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (114, 'NOTARÍA PÚBLICA SÉPTIMA DE VALENCIA ESTADO CARABOBO', 'Av. Montes de Oca, entre Vargas y Rondón, Centro Comercial  Don Francisco, P.B., Locales 116 y 118, Valencia', 'NP122', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (115, 'NOTARÍA PÚBLICA DE GUACARA ESTADO CARABOBO', 'Centro Comercial Unicentro Guacara, P.B., Local 31, Sector Los Narajillos, Guacara', 'NP123', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (116, 'NOTARÍA PÚBLICA PRIMERA DE PUERTO CABELLO ESTADO CARABOBO', 'Urb. Cumboto Norte, Edif. Guaicamacuto,  Piso  2,  Locales M-16 y M-17, Pto. Cabello.', 'NP124', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (117, 'NOTARÍA PÚBLICA SEGUNDA DE PUERTO CABELLO ESTADO CARABOBO', 'Calle 1ra. de Segresta, cruce con  Av. Bolívar, Centro Comercial  Madefer, Piso 1, Ofic. 7, Puerto Cabello    ', 'NP125', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (118, 'NOTARÍA PÚBLICA DE BEJUMA  ESTADO CARABOBO', 'Av. Bolívar, Edif. América, Piso 1, Ofic. 131, frente a la Plaza Bolivar, Bejuma', 'NP126', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (119, 'NOTARÍA PÚBLICA DE SAN DIEGO ESTADO CARABOBO', 'Centro Comercial Big Low Center, Nave D, Local 20, San Diego.', 'NP127', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (120, 'NOTARÍA PÚBLICA DE SAN CARLOS ESTADO COJEDES', 'Av. Sucre, Edif. Manrique, P.B., Local 1, San Carlos', 'NP128', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (121, 'NOTARÍA PÚBLICA DE TINAQUILLO ESTADO COJEDES', 'Cruce de la Av. Miranda con Calle Colina, Centro Comercial San Jorge, Piso 1, Ofic. Nro. 3, Tinaquillo', 'NP129', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (122, 'NOTARÍA PÚBLICA DE TUCUPITA ESTADO DELTA AMACURO', 'Calle Dalla Costa con Calle Amacuro, Edif. Arcangel Piso 1, Ofic. 01, Tucupita', 'NP130', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (123, 'NOTARÍA PÚBLICA DE CORO ESTADO FALCÓN', 'Calle Domino Entre Democracia y Jabonería Coro, Edo. Falcón.', 'NP131', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (124, 'NOTARÍA PÚBLICA PRIMERA DE PUNTO FIJO ESTADO FALCÓN', 'Calle Monagas, entre Comercio y Acueducto   Edif. Coromoto, Planta Alta de Repuestos El Gigante,  Caja de Agua.  Punto Fijo.', 'NP132', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (125, 'NOTARÍA PÚBLICA SEGUNDA DE PUNTO FIJO ESTADO FALCÓN', 'Calle Panamá entre Garcés y Mariño, diangonal a la Clínica Falcón. Punto Fijo', 'NP133', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (126, 'NOTARÍA PÚBLICA DE PUEBLO NUEVO  ESTADO FALCÓN', 'Callejón Los Reyes, Detrás de la Iglesia Entre Calle Bolívar y Falcón.', 'NP134', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (127, 'NOTARÍA PÚBLICA DE SAN JUAN DE LOS MORROS ESTADO GUÁRICO', 'Av. Bolívar, C.C. Vía Venetton, Piso 2, Oficina 47, San Juan De Los Morros.', 'NP135', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (128, 'NOTARÍA PÚBLICA DE VALLE DE LA PASCUA ESTADO GUÁRICO', 'Calles Atarraya y González Padrón, (con acceso por ambas Calles), Centro Comercial "Sabana", Piso 3, Locales 18 y 19, Valle de La Pascua', 'NP136', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (129, 'NOTARÍA PÚBLICA DE CALABOZO ESTADO GUÁRICO', 'Calle 4, Carreras 8 y 9, N° 8-50, Calabozo', 'NP137', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (130, 'NOTARÍA PÚBLICA PRIMERA DE BARQUISIMETO ESTADO LARA', 'Av. 20, entre Calles 22 y 23, Edif. Centro Comercial Barquicenter, Mezzanina, M-10, Barquisimeto', 'NP138', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (131, 'NOTARÍA PÚBLICA SEGUNDA DE BARQUISIMETO ESTADO LARA', 'Carrera 17, Esquina Calle 26, Edif. "Centro Plaza" Nivel Mezzanina, M-01 Barquisimeto', 'NP139', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (132, 'NOTARÍA PÚBLICA TERCERA DE BARQUISIMETO ESTADO LARA', 'Calle 26, entre Carreras 16 y 17, Torre Ejecutiva, Piso 1, Ofic. 22, Barquisimeto', 'NP140', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (133, 'NOTARÍA PÚBLICA CUARTA DE BARQUISIMETO ESTADO LARA', 'Av. Lara con Calle 8, Urb. Nueva Segovia, Centro Comercial  Churun Meru, Piso 1, Local  B-10 y B-11, Barquisimeto', 'NP141', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (134, 'NOTARÍA PÚBLICA QUINTA DE BARQUISIMETO ESTADO LARA', 'Centro Empresarial Torre David, Semi-sótano, Ofic. 10, Carrera 26, entre Calles 15 y 16, Barquisimeto', 'NP142', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (135, 'NOTARÍA PÚBLICA DE EL TOCUYO ESTADO LARA', 'Av. Lisandro Alvarado, Esq. Calle 18, Centro Comercial Franca, P.B., Ofic. Nro. 4, El Tocuyo', 'NP143', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (136, 'NOTARÍA PÚBLICA DE CARORA ESTADO LARA', 'Av. Francisco de Miranda con Av. Rotaria, Centro Comercial Ciudad del Sol, Piso 2, Ofic. 6 y 7. Carora', 'NP144', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (137, 'NOTARÍA PÚBLICA DE QUIBOR ESTADO LARA', 'Av. Florencio Jiménez, Edif. Bicentenario, Pb. Local 2-1, Quibor, Estado Lara.', 'NP145', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (138, 'NOTARÍA PÚBLICA DE CABUDARE  ESTADO LARA', 'Calle Domingo Méndez, entre Urb. Los Cedros, C.C. San Antonio, Local Nº 08, Cabudare', 'NP146', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (139, 'NOTARÍA PÚBLICA PRIMERA DE MÉRIDA ESTADO MÉRIDA', 'Av. 4, "Simón Bolívar", Esq. Calle 25, Nro. 24-72, frente al Banco de Occidente. Mérida.', 'NP147', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (140, 'NOTARÍA PÚBLICA SEGUNDA DE MÉRIDA ESTADO MÉRIDA', 'Av. Las Américas, Centro Comercial Mayeya, Mezzanina, Local 20, Mérida.', 'NP148', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (141, 'NOTARÍA PÚBLICA TERCERA DE MÉRIDA ESTADO MÉRIDA', 'Av. 3 Independencia, entre Boulevard Los Obispos, (antes Calle 22), y Boulevard Los Pintores, (antes Calle 23), Centro Comercial Cultural "El Fortin", Local N° 4. Mérida', 'NP149', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (142, 'NOTARÍA PÚBLICA CUARTA DE MÉRIDA ESTADO MÉRIDA', 'Av. Andrés Bello, Urb. Las Tapias, Centro Comercial Las Tapias, Piso 1, Local 50. Mérida', 'NP150', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (143, 'NOTARÍA PÚBLICA DE EL VIGIA ESTADO MÉRIDA', 'Av. 14 entre Calles 4 y 5, El Vigía', 'NP151', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (144, 'NOTARÍA PÚBLICA DE EJIDO ESTADO MÉRIDA', 'Centro Comercial Centenario, Núcleo Norte, Local 60, Ejido', 'NP152', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (145, 'NOTARÍA PÚBLICA DE TOVAR ESTADO MÉRIDA', 'Carrera 3a. Nº 4-41 Planta Alta entre calle 4 y 5, El Añil.', 'NP153', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (146, 'NOTARÍA PÚBLICA DE SANTO DOMINGO ESTADO MÉRIDA', 'Calle Sucre, Nro. 7, Santo Domingo', 'NP154', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (147, 'NOTARÍA PÚBLICA PRIMERA DE MATURÍN ESTADO MONAGAS', 'Calle Nº 17 con Carrera Nº 7, Nro. 55-1, Calle Mariño, cruce con Monagas, detrás del Banco Unión, Maturín', 'NP155', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (148, 'NOTARÍA PÚBLICA SEGUNDA DE MATURÍN ESTADO MONAGAS', 'Calle 10 Antigua Calle Barreto Local 1, Maturín.', 'NP156', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (149, 'NOTARÍA PÚBLICA DE PUNTA DE MATA ESTADO MONAGAS', 'Av. Bolívar, Centro Comercial Júpiter Center, Planta Baja, Oficina Nº 10. Punta de Mata.', 'NP157', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (150, 'NOTARÍA PÚBLICA PRIMERA DE PORLAMAR ESTADO NUEVA ESPARTA', 'Av. Santiago Mariño, Edif. Santa Cruz III, Mezzanina, Porlamar', 'NP158', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (151, 'NOTARÍA PÚBLICA SEGUNDA DE PORLAMAR ESTADO NUEVA. ESPARTA', 'Av. 4 de Mayo, con Calle Milano, Centro Comercial Guaiquerí, Piso 1, Porlamar', 'NP159', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (152, 'NOTARÍA PÚBLICA DE JUAN GRIEGO ESTADO NUEVA ESPARTA', 'Calle La Marina, Edif. Francisco Antonio, Piso 2, oficina B, Al lado de Corp Banca.   Juan Griego.', 'NP160', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (153, 'NOTARÍA PÚBLICA DE LA ASUNCION ESTADO NUEVA ESPARTA', 'Centro Empresarial Plaza Bolívar,  P.B., Ofic. D y E. La  Asunción', 'NP161', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (154, 'NOTARÍA PÚBLICA DE PAMPATAR ESTADO NUEVA ESPARTA', 'Av. Bolívar con Aldonza Manrique, Centro Empresarial AB, Nivel Mezzanina, Local 61, Urb. Playas del Angel, Pampatar', 'NP162', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (155, 'NOTARÍA PÚBLICA PRIMERA DE ACARIGUA ESTADO PORTUGUESA', 'Calle 30 con Av. 34, frente al antiguo Banco Metropolitano, Acarigua.', 'NP163', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (156, 'NOTARÍA PÚBLICA SEGUNDA DE ACARIGUA ESTADO PORTUGUESA', 'Av. 33, entre Calles 30 y 31, Centro Comercial "Latin Center", 1er. Piso, Local Nro. 17, (frente al Banco Fondo Común), Acarigua', 'NP164', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (157, 'NOTARÍA PÚBLICA DE ARAURE ESTADO PORTUGUESA', 'Calle 6, Edif. Bella Vista, Piso 2, Ofic. Nro. 9, Araure', 'NP166', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (158, 'NOTARÍA PÚBLICA DE TUREN ESTADO PORTUGUESA', 'Av. Raúl Leoni con Av. 5, Edif. De Santolo, Local 1, P.A., Turén', 'NP167', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (159, 'NOTARÍA PÚBLICA DE CUMANA ESTADO SUCRE', 'AV. MIRANDA, QTA. MARE-MARE, CERCA DE TELESOL. Cumaná', 'NP168', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (160, 'NOTARÍA PÚBLICA DE CARUPANO ESTADO SUCRE', 'Callejón Santa Rosa, Nº 05, Plaza Santa Rosa (al lado de la Catedral Santa Rosa), Carupano.', 'NP169', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (161, 'NOTARÍA PÚBLICA PRIMERA DE SAN CRISTOBAL ESTADO TACHIRA', 'Carrera 9, Esq. Calle 3/4, Edif. Martimar, Locales del 1 al 3, San Cristóbal.', 'NP170', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (162, 'NOTARÍA PÚBLICA SEGUNDA DE SAN CRISTOBAL ESTADO TACHIRA', 'Carrera 3 con esq. Calle 6, Edif. Santa Cecilia, P.B. San Cristóbal', 'NP171', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (163, 'NOTARÍA PÚBLICA TERCERA DE SAN CRISTOBAL ESTADO TACHIRA', 'Carrera 9 entre Calles 3 y 4,  detrás del Stadium Táchira La Concordia  San Cristóbal                             ', 'NP172', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (164, 'NOTARÍA PÚBLICA CUARTA DE SAN CRISTOBAL ESTADO TACHIRA', '7ma. Av. Con Calle 13, Edif. Olimport Center, San Cristóbal', 'NP173', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (165, 'NOTARÍA PÚBLICA QUINTA DE SAN CRISTOBAL ESTADO TACHIRA', 'Carrera 24, con Esq. Calle 12,    Edif. AMATXU, Barrio Obrero,  San Cristóbal', 'NP174', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (166, 'NOTARÍA PÚBLICA DE SAN ANTONIO ESTADO TACHIRA', 'Calle 8 Carrera  7,Edif. Gilmar, Nro. 7-28, Ofic. 1, Barrio Pueblo Nuevo, San Antonio', 'NP175', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (253, 'REGISTRO MERCANTIL PRIMERO DEL ESTADO ANZOÁTEGUI', 'Urb. Urdaneta, Calle Colón, Quinta Teresa, Nº 14-21. Barcelona.', 'RM262', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (167, 'NOTARÍA PÚBLICA MUNICIPIO SAMUEL DARIO MALDONADO ESTADO TACHIRA', 'Av. Simón Bolívar, Calle 1, Centro Comercial La Tendida, P.A., Locales 22 y 23, La Tendida', 'NP176', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (168, 'NOTARÍA PÚBLICA DE COLON ESTADO TACHIRA', 'Carrera 6, Nro. 7-76, Edif. Santa Eduvigis, entre Calles 7 y 8, San Juan de Colón', 'NP177', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (169, 'NOTARÍA PÚBLICA DE LA FRIA ESTADO TACHIRA', 'Calle 5 Con Carrera 9 Nº 8-73, La Fría.', 'NP178', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (170, 'NOTARÍA PÚBLICA DE SEBORUCO ESTADO TÁCHIRA', 'Mercado Principal de Seboruco, entre calles 2 y 3, diagonal a la Plaza Bolívar, locales 61 y 67, Municipio Seboruco, Estado Táchira.', 'NP179', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (171, 'NOTARÍA PÚBLICA DE UREÑA ESTADO TÁCHIRA', 'Av. Intercomunal Simón Bolívar, Centro Comercial Textimoda, piso 1 Locales 105 al 107. Ureña', 'NP180', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (172, 'NOTARÍA PÚBLICA PRIMERA DE VALERA ESTADO TRUJILLO', 'Av. 9 con Calle 8, Edif. Greven, Piso 1, Apto. C-1, Valera.', 'NP181', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (173, 'NOTARÍA PÚBLICA SEGUNDA DE VALERA ESTADO TRUJILLO', 'Centro Comercial Edivica II, Segundo Nivel, Local 42, Valera.', 'NP182', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (174, 'NOTARÍA PÚBLICA DE BOCONÓ ESTADO TRUJILLO', 'Calle Bolívar, entre Avs. Independencia y 5 de julio, N° 4-39, Piso 2, Boconó.', 'NP183', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (175, 'NOTARÍA PÚBLICA DE SABANA DE MENDOZA ESTADO TRUJILLO', 'Calle Bermúdez, Edif. Roberto Manuel, Planta baja, diagonal a la Plaza Bolívar, Sabana de Mendoza.', 'NP184', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (176, 'NOTARÍA PÚBLICA DE TRUJILLO ESTADO TRUJILLO', 'Av. Cruz Carrillo, Res. Balcones  del  Country,  Local        L- 5, Trujillo', 'NP185', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (177, 'NOTARÍA PÚBLICA PRIMERA DEL ESTADO VARGAS', 'Av. Soublette, Edif. Márquez Yánez, Piso 1, Nro. 18-20, altos del Banco Unión, La Guaira', 'NP186', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (178, 'NOTARÍA PÚBLICA SEGUNDA  DEL ESTADO VARGAS', '2da. Transversal, Barrio Vargas, Edificio Nº 16, Planta Baja, Pariata, Maiquetía.', 'NP187', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (179, 'NOTARÍA PÚBLICA TERCERA DEL ESTADO VARGAS', 'Av. El Ejercito, Edificio Santa María, Piso 1, Oficina Nro. 1, Catia La Mar.', 'NP188', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (180, 'NOTARÍA PÚBLICA DE SAN FELIPE ESTADO YARACUY', 'Av. Caracas  con Avs.  4 y 5, Edif. Stémica, San Felipe', 'NP189', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (181, 'NOTARÍA PÚBLICA DE YARITAGUA ESTADO YARACUY', 'Av. Padre Torres, entre Carreras  13 y 14, Edif. Padre Torres, Ofic. A-1. Yaritagua', 'NP190', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (182, 'NOTARÍA PÚBLICA DE NIRGUA ESTADO YARACUY', 'Av. 5ta. entre Calles 8 y 7, a una cuadra a la Plaza Bolívar, Edificio Casa Vieja, local Nº 3, Nirgua.', 'NP191', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (183, 'NOTARÍA PÚBLICA PRIMERA DE MARACAIBO ESTADO ZULIA', 'Av.  22  Esq.  Calle  70, diagonal al Centro Comercial Indio Mara, Maracaibo', 'NP192', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (184, 'NOTARÍA PÚBLICA SEGUNDA DE MARACAIBO ESTADO ZULIA', 'Calle 81, con Av. Bella Vista, Centro  Comercial  Villa Inés, Local 23, P.B., Maracaibo', 'NP193', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (185, 'NOTARÍA PÚBLICA TERCERA DE MARACAIBO ESTADO ZULIA', 'Av.  4, (Bella Vista), Esq. con Calle  76,  Edif.  Don   Matias, Local 14, P.B., Maracaibo', 'NP194', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (186, 'NOTARÍA PÚBLICA CUARTA DE MARACAIBO ESTADO ZULIA', 'Centro Comercial Socuy, Mezzanina,  Locales  13  y  14, Av.  4, (Bella  Vista), con  Calle 67, (Cecilio Acosta), Maracaibo.', 'NP195', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (187, 'NOTARÍA PÚBLICA QUINTA DE MARACAIBO ESTADO ZULIA', 'Centro Comercial Palaima, Locales 6 y 11, Av. 16, (Goajira) entre Colegio de Médico y Colegio de Abogados, Maracaibo', 'NP196', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (188, 'NOTARÍA PÚBLICA SEXTA DE MARACAIBO ESTADO ZULIA', 'Casco Central Av. 8 con Calle 95 C.C. Santa Barbara P.B. LC13 Maracaibo.', 'NP197', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (189, 'NOTARÍA PÚBLICA SÉPTIMA DE MARACAIBO ESTADO ZULIA', 'Centro Comercial Puente Cristal, Local 82, Piso 2, Calle 95, (antes Venezuela), con Av. 14-A, (antes Navarro), Maracaibo.', 'NP198', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (190, 'NOTARÍA PÚBLICA OCTAVA DE MARACAIBO ESTADO ZULIA', 'Av. 3 con Calle 74, Nº 74-11, Sector La Lago, Parroquia Olegario Villalobos, Maracaibo', 'NP199', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (191, 'NOTARÍA PÚBLICA NOVENA DE MARACAIBO ESTADO ZULIA', 'Centro Comercial Juana de Avila, Av. 15, (Delicias), cruce con Av. 67, (Cecilio Acosta), Local Nro. 8, Maracaibo', 'NP200', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (192, 'NOTARÍA PÚBLICA DÉCIMA DE MARACAIBO ESTADO ZULIA', 'Av. Las Delicias, Centro Comercial  Las Delicias, Local Nro. 7, P.A., Maracaibo.', 'NP201', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (193, 'NOTARÍA PÚBLICA DÉCIMA PRIMERA DE MARACAIBO ESTADO ZULIA', 'Urb. La Trinidad, Calle 52-B, Nro. 155-55, Maracaibo', 'NP202', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (194, 'NOTARÍA PÚBLICA PRIMERA DE CABIMAS ESTADO ZULIA', 'Calle El Rosario, Centro Empresarial Longimar, Local 4, Cabimas.', 'NP203', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (195, 'NOTARÍA PÚBLICA SEGUNDA DE CABIMAS ESTADO ZULIA', 'Av. Principal, Urb. Buena Vista, Centro Comercial Costa Este, Local Nro. 3, P.B., Cabimas.', 'NP204', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (196, 'NOTARÍA PÚBLICA PRIMERA CIUDAD OJEDA ESTADO ZULIA', 'Av. Bolívar, Esq. con Calle Mérida,  Edif.  Laika,  Piso  1, Local 4, Ciudad Ojeda', 'NP205', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (197, 'NOTARÍA PÚBLICA SEGUNDA CIUDAD OJEDA ESTADO ZULIA', 'Av. Intercomunal, Calle La Ceiba, Centro Comercial La Carreta, Local 14, Ciudad Ojeda', 'NP206', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (198, 'NOTARÍA PÚBLICA DE CAJA SECA ESTADO ZULIA', 'Av. El Terminal, Centro Comercial Don Quijote, Piso 1, Local 4, Caja Seca', 'NP207', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (199, 'NOTARÍA PÚBLICA DE VILLA DEL ROSARIO ESTADO ZULIA', 'Calle  Donaldo García López, sede  de La Alcaldía, P.B., Villa del Rosario.', 'NP208', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (200, 'NOTARÍA PÚBLICA DE MENEGRANDE ESTADO ZULIA', 'Av. Alberto Carnevalli, Centro Comercial España, P.B., Local 4-A, Mene Grande.', 'NP209', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (201, 'NOTARÍA PÚBLICA MUNICIPIO JESUS ENRIQUE LOZADA ESTADO ZULIA', 'Av. Principal de la Concepción, Edif.  Nasa,  1er.  Piso, Local  2, La Concepción ', 'NP210', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (202, 'NOTARÍA PÚBLICA DE LA CAÑADA ESTADO ZULIA', 'Av. Dr. Olegario Hernández, Sector Bella Vista, Sede del Registro Civil de la Parroquia Concepción, al lado de la Alcaldía Bolivariana del Municipio la Cañada de Urdaneta.', 'NP211', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (203, 'NOTARÍA PÚBLICA DE SAN FRANCISCO ESTADO ZULIA', 'AV. 5 PRINCIPAL DE SAN FRANCISCO C.C.GASA LOCAL 01', 'NP212', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (204, 'REGISTRO PRINCIPAL DISTRITO CAPITAL', 'Av. Urdaneta, Esq. de Pelota a Punceres,  Edif. 30, frente al CICPC', 'RCP213', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (205, 'REGISTRO PÚBLICO DEL PRIMER CIRCUITO MUNICIPIO LIBERTADOR DISTRITO CAPITAL', 'Av. Urdaneta con Av. El Parque, Torre Oficentro, Planta Baja, diagonal al C.C. Galerías Ávila, San Bernardino.', 'RP214', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (206, 'REGISTRO PÚBLICO DEL SEGUNDO CIRCUITO MUNICIPIO LIBERTADOR DISTRITO CAPITAL', 'Av.Universidad,entre las Esquinas,de Monrroy a  Misericordia Edif.centro Parque Carabobo,Nivel 1 Oficinas 114 y 115.', 'RP215', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (207, 'REGISTRO PÚBLICO DEL TERCER CIRCUITO MUNICIPIO LIBERTADOR DISTRITO CAPITAL', 'Matrices a Ibarra Edif. González Gorrondona. Piso 1. Al lado de Mango Bajito.', 'RP216', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (208, 'REGISTRO PÚBLICO DEL CUARTO  CIRCUITO MUNICIPIO LIBERTADOR DISTRITO CAPITAL', 'Av. Urdaneta, Esq. de Pelota a Ibarras, Edif. Caoma, Piso 1.', 'RP217', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (209, 'REGISTRO PÚBLICO DEL QUINTO CIRCUITO MUNICIPIO LIBERTADOR DISTRITO CAPITAL', 'Av. Este 2, con Sur 25, Edificio José Vargas, 5to piso (Edificio CTV).', 'RP218', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (210, 'REGISTRO PÚBLICO DEL SEXTO CIRCUITO MUNICIPIO LIBERTADOR DISTRITO CAPITAL', 'Av. Urdaneta, Punceres a Plaza España, Edif. Nº. 37 (Distromédica) Piso 7.', 'RP219', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (211, 'REGISTRO MERCANTIL PRIMERO DEL DISTRITO CAPITAL', 'Av. Andrés Bello, Centro Andrés Bello, Sótano 1.', 'RM220', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (212, 'REGISTRO MERCANTIL SEGUNDO DEL DISTRITO CAPITAL', 'Av. Andrés Bello Centro Andrés Bello Sótano 1 Local 02.', 'RM221', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (213, 'REGISTRO MERCANTIL TERCERO DE LA CIRCUNSCRIPCION JUDICIAL DEL DISTRITO CAPITAL Y ESTADO BOLIVARIANO DE MIRANDA.', 'Carretera Panamericana, Km. 21, Centro Empresarial La Cascada, Piso 4, ofic. 4-4, Sector Corralito, Carrizal.', 'RM222', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (214, 'REGISTRO MERCANTIL CUARTO DEL DISTRITO CAPITAL', 'Plaza Venezuela, Av. La Salle Torre Capriles Mezanina 1.  Local 33c y 34c.', 'RM223', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (215, 'REGISTRO MERCANTIL QUINTO DEL DISTRITO CAPITAL', 'Urbanización Chuao, Calle Roraima, Quinta Adelita, PB.', 'RM224', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (216, 'REGISTRO MERCANTIL SEPTIMO DEL DISTRITO CAPITAL', 'Av. Este, Esq. Cruz Verde, Edif. Sur,  1era.  Etapa,P.B., Locales B-7, B-8 y B-9, nuevo Palacio de Justicia.', 'RM225', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (217, 'REGISTRO PRINCIPAL DEL ESTADO MIRANDA', 'Centro Comercial La Ponderosa, Pisos 3 y 4, Sector El Tambor, Los Teques.', 'RCP226', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (218, 'REGISTRO PÚBLICO DEL MUNICIPIO ACEVEDO ESTADO MIRANDA', 'Calle Real de Caucagua, Centro Cívico, Piso 3, Caucagua.', 'RP227', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (219, 'REGISTRO PÚBLICO DEL MUNICIPIO BRIÓN Y BUROZ ESTADO MIRANDA', 'Calle 12, Edif. Valle de Curiepe, PB,  1ra. y 2da. Planta, Higuerote.', 'RP228', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (220, 'REGISTRO PÚBLICO DEL MUNICIPIO GUAICAIPURO ESTADO MIRANDA', 'Carretera Panamericana-Carrizal, Centro Profesional La Cascada, Piso 2, Ofics. 2-8, a la 2-13, Los Teques', 'RP229', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (221, 'REGISTRO PÚBLICO DEL MUNICIPIO INDEPENDIENCIA ESTADO MIRANDA', 'Centro Comercial las flores, piso 2  calle las margaritas las flores, Santa Teresa del Tuy. ', 'RP230', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (222, 'REGISTRO PÚBLICO DEL MUNICIPIO LANDER ESTADO MIRANDA', 'Av. Miranda, Edif. San Miguel, Piso 1, Ofic. 1, frente a la Plaza del Estudiante, Ocumare del Tuy.', 'RP231', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (223, 'REGISTRO PÚBLICO DEL MUNICIPIO LOS SALIAS ESTADO MIRANDA', 'Carretera Panamericana km14 Centro Empresarial Panamericano Cepan piso 3 local A, San Antonio de los Altos, Municpio Los Salias, Estado de Miranda.', 'RP232', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (224, 'REGISTRO PÚBLICO DEL MUNICIPIO PÁEZ ESTADO MIRANDA', 'Calle Páez, Nro. 96, Río Chico. ', 'RP233', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (225, 'REGISTRO PÚBLICO DEL MUNICIPIO PAZ CASTILLO ESTADO MIRANDA', 'Calle Sucre, Transversal 11, Casa No. 24, Santa Lucia.', 'RP234', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (226, 'REGISTRO PÚBLICO DEL MUNICIPIO PLAZA ESTADO MIRANDA', 'Centro Comercial Aventura, Piso 2, 0fic. 205, Guarenas. ', 'RP235', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (227, 'REGISTRO PÚBLICO DE LOS MUNICIPIOS URDANETA Y CRISTÓBAL ROJAS ESTADO MIRANDA', 'Av. Los Próceres de Cúa, Sector  Aparay, Centro Comercial e  Industrial Cúa, Piso 2, Ofic. 12, Cúa.  ', 'RP236', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (228, 'REGISTRO PÚBLICO DEL MUNICIPIO ZAMORA ESTADO MIRANDA', 'Av. Íntercomunal Guarenas-Guatire Centro Comercial OASIS, Piso 2, Local 10, Guatire.', 'RP237', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (229, 'REGISTRO PÚBLICO DEL PRIMER CIRCUITO DEL MUNICIPIO SUCRE ESTADO MIRANDA', 'Calle Santa Ana, Edif. Centro Peña Friel, P.B., Urb. Boleíta Sur.', 'RP238', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (230, 'REGISTRO PÚBLICO DEL SEGUNDO CIRCUITO DEL MUNICIPIO SUCRE ESTADO MIRANDA', 'Av.  Principal  de  Los  Ruices,  Res.  Los  Almendros,    Mezzanina  2,  al   lado  del   Canal 8. ', 'RP239', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (231, 'REGISTRO PÚBLICO DEL MUNICIPIO CHACAO DEL ESTADO MIRANDA', 'Av. Libertador, Multicentro Empresarial del Este, Conjunto  Libertador,  Planta  Ingreso,   Local PII, frente al Sambil  Chacao ', 'RP240', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (232, 'REGISTRO PÚBLICO DEL PRIMER CIRCUITO DEL MUNICIPIO BARUTA ESTADO MIRANDA', 'Final de la Av. Miguel Ángel, entre Calle Don Bosco y Calle Bucare,   (antigua  sede  del  Banco Maracaibo), Colinas Bello Monte, Baruta.', 'RP241', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (233, 'REGISTRO PÚBLICO DEL SEGUNDO CIRCUITO DEL MUNICIPIO BARUTA ESTADO MIRANDA', 'Calle Roraima, Urb. Chuao, Casa Adelita, P.A Baruta ', 'RP242', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (234, 'REGISTRO PÚBLICO DEL MUNICIPIO EL HATILLO DEL ESTADO MIRANDA', 'Calle 1ro. De Mayo, Centro Somager, P.A.,  El Hatillo.', 'RP243', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (235, 'REGISTRO PÚBLICO DE PUERTO AYACUCHO ESTADO AMAZONAS', 'Av. Rio Negro #9. Puerto Ayacucho.', 'RP244', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (236, 'REGISTRO PRINCIPAL DE BARCELONA ESTADO ANZOATEGUI', 'Calle Freites con Calle Maturín, Nros.  5-8 y 5-14, Barcelona', 'RCP245', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (237, 'REGISTRO PÚBLICO DEL MUNICIPIO ANACO ESTADO ANZOÁTEGUI', 'Av. Zulia, Centro Profesionales Anaco, 2do piso, Local 2-1. Anaco.', 'RP246', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (238, 'REGISTRO PÚBLICO DEL MUNICIPIO ARAGUA ESTADO ANZOÁTEGUI', 'Calle Anzóategui s/n frente al Mercado Municipal', 'RP247', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (239, 'REGISTRO PÚBLICO DEL MUNICIPIO SIMÓN BOLÍVAR ESTADO ANZOÁTEGUI', 'Av. Fuerzas Armadas Centro Comercial Nevera Plaza, Piso 1. Barcelona.', 'RP248', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (240, 'REGISTRO PÚBLICO DEL MUNICIPIO MANUEL EZEQUIEL BRUZUAL ESTADO ANZOÁTEGUI', 'Av. Fernández Padilla, C.C. Zamira Center, Piso 1, Oficina 3. Clarines.', 'RP249', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (241, 'REGISTRO PÚBLICO DEL MUNICIPIO DIEGO BAUTISTA URBANEJA ESTADO ANZOÁTEGUI', 'Av. Principal de lecherias CC Morro Mar Piso 2 Oficina 5,6,7 y 8', 'RP250', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (242, 'REGISTRO PÚBLICO DEL MUNICIPIO JUAN MANUEL CAJIGAL ESTADO ANZOÁTEGUI', 'Calle Comercio # 1 Onoto, al frente de la clínica municipal.', 'RP251', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (243, 'REGISTRO PÚBLICO DEL MUNICIPIO PEDRO MARÍA FREITES ESTADO ANZOÁTEGUI', 'Av. Carabobo cruce con calle Páez, Edificio Santa Elena, planta alta, Cantaura.', 'RP252', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (244, 'REGISTRO PÚBLICO DEL MUNICIPIO SAN JOSÉ DE GUANIPA ESTADO ANZOÁTEGUI', 'Av.Fernández Padilla Quinta La Muralla. El Tigrito', 'RP253', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (245, 'REGISTRO PÚBLICO DEL MUNICIPIO INDEPENDENCIA ESTADO ANZOÁTEGUI', 'Calle Boyaca s/n.Soledad', 'RP254', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (246, 'REGISTRO PÚBLICO DEL MUNICIPIO LIBERTAD ESTADO ANZOÁTEGUI', 'Calle Maturín,Qta. Sin Número, San Mateo.', 'RP255', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (247, 'REGISTRO PÚBLICO DEL MUNICIPIO FRANCISCO DE MIRANDA  ESTADO ANZOÁTEGUI', 'Calle Sucre, nro.27, Sector Centro de Pariaguan a una cuadra de la Plaza Bolívar.', 'RP256', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (248, 'REGISTRO PÚBLICO DEL MUNICIPIO  JOSÉ GREGORIO MONAGAS  ESTADO ANZOÁTEGUI', 'Calle Boyacá, casa N° 04, entre Calle Madariaga y Av. Ppal. Mapire.', 'RP257', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (249, 'REGISTRO PÚBLICO DEL MUNICIPIO FERNANDO PEÑALVER  ESTADO ANZOÁTEGUI', 'Calle Bolívar CC Yorcenter C.A. Planta Baja Local 19 y 20.Puerto Píritu', 'RP258', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (250, 'REGISTRO PÚBLICO DE LOS MUNICIPIOS PÍRITU Y SAN JUAN DE CAPISTRANO ESTADO ANZOÁTEGUI', 'Av. Peñalver, C.C. Las Palmeras. Piso 1, oficina F. Píritu.', 'RP259', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (251, 'REGISTRO PÚBLICO DEL MUNICIPIO SIMÓN RODRIGUEZ ESTADO ANZOÁTEGUI', 'Av. Fernando Peñalver, C.C. Plaza Medina, Local 67, 1er piso, Sector San Francisco de Asís. El Tigre.', 'RP260', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (252, 'REGISTRO PÚBLICO DEL MUNICIPIO JUAN ANTONIO SOTILLO ESTADO ANZOÁTEGUI', 'Centro Comercial Amana, C/C Amaneiro, Oficina A-7, Planta Baja, Puerto La Cruz.', 'RP261', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (254, 'REGISTRO MERCANTIL SEGUNDO DEL  ESTADO ANZOÁTEGUI', ' Avenida Peñalver, C.C. Plaza Medina, Piso 1, Locales 60, 61, 62  El Tigre.', 'RM263', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (255, 'REGISTRO MERCANTIL TERCERO DEL ESTADO ANZOÁTEGUI', 'Urb. Urdaneta, Calle Cristóbal Colón C/C Av. Country Club, Qta. Adriana P.B.', 'RM264', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (256, 'REGISTRO PRINCIPAL DEL ESTADO APURE', 'Av. Caracas, Nro. 21, Urb. Cerafín Cedeño, San Fernando.', 'RCP265', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (257, 'REGISTRO PÚBLICO DEL MUNICIPIO ACHAGUAS DEL ESTADO APURE', 'Calle Caujarito, Cruce con Av. El Puente, Achaguas.', 'RP266', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (258, 'REGISTRO PÚBLICO DEL MUNICIPIO MUÑOZ ESTADO APURE', 'Calle Bolívar, casa sin número, frente a la Plaza Bolívar, Brusual.', 'RP267', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (259, 'REGISTRO PÚBLICO DEL MUNICIPIO PÁEZ  ESTADO APURE', 'Calle Ricaurte, Edif. Navea, Piso 1, Local N° 4, Guasdualito.', 'RP268', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (260, 'REGISTRO PÚBLICO DEL MUNICIPIO PEDRO CAMEJO ESTADO APURE', 'Av. Negro Primero Local S/N Al Lado De Inversiones Lugui More.', 'RP269', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (261, 'REGISTRO PÚBLICO DEL MUNICIPIO RÓMULO GALLEGOS ESTADO APURE', 'Calle José Archila, Al Frente Del Antiguo Hotel La Estrella, s/n Elorza', 'RP270', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (262, 'REGISTRO PÚBLICO DEL MUNICIPIO SAN FERNANDO ESTADO APURE', 'Paseo Libertador. Palacio de Barbarito.', 'RP271', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (263, 'REGISTRO MERCANTIL DEL ESTADO APURE', 'Calle Sucre, N° 57, frente al Policlínico José María Vargas, San Fernando', 'RM272', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (264, 'REGISTRO PRINCIPAL DEL ESTADO ARAGUA', 'Avenida Bolívar Cruce Con Junín-Edificio Registro Principal, Maracay.', 'RCP273', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (265, 'REGISTRO PÚBLICO DE LOS MUNICIPIOS SANTIAGO MARIÑO, LIBERTADOR Y LINARES ALCANTARA DEL  ESTADO ARAGUA', 'Centro Comercial Los Laureles, Local 69, Sector la Encrucijada. Av. Intercomunal. Cagua - Turmero', 'RP274', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (266, 'REGISTRO PÚBLICO DE LOS MUNICIPIOS JOSÉ FÉLIX RIBAS, J. R. REVENGA, SANTOS MICHELENA, BOLIVAR Y TOVAR ESTADO ARAGUA', 'Urbanización Nueva Victoria, Av. Victoria, Centro Comercial Cilento, Piso 4, Oficina 01,35 Y 36, La Victoria.', 'RP275', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (267, 'REGISTRO PÚBLICO DEL MUNICIPIO SAN CASIMIRO ESTADO ARAGUA', 'Calle San Antonio casa S/N, detrás de la bomba. Sector Barrancón.', 'RP276', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (268, 'REGISTRO PÚBLICO DEL MUNICIPIO SAN SEBASTIÁN ESTADO ARAGUA', 'Calle Paúl Edificio Blanco Local 2, Diagonal al Hospital. Ntra. Sra. de la Caridad.', 'RP277', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (269, 'REGISTRO PÚBLICO DE LOS MUNICIPIOS SUCRE Y JOSÉ ANGEL LAMAS DEL  ESTADO ARAGUA', 'Calle Miranda C/C Independencia y Froilán Correa, C.C.E. Fórum Plaza, Piso 4, Oficina 16,17 y 18. Pueblo De Cagua.', 'RP278', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (270, 'REGISTRO PÚBLICO DE LOS MUNICIPIOS URDANETA Y CAMATAGUA DEL ESTADO ARAGUA', 'Calle El Carmen, Edificio Rosaelena, 1er piso, Apto 1 Barbacoas.', 'RP279', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (271, 'REGISTRO PÚBLICO DEL MUNICIPIO ZAMORA ESTADO ARAGUA', 'Av. Lisandro Hernández, Edificio Ricci, Piso 1, Locales 3, 4 y5. Villa de Cura.', 'RP280', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (272, 'REGISTRO PÚBLICO DEL PRIMER CIRCUITO DEL MUNICIPIO GIRARDOT ESTADO ARAGUA', 'Barrió santa Ana, Calle Independencia, Edif. Socimar, P.B #68-70. Maracay.', 'RP281', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (273, 'REGISTRO PÚBLICO DEL SEGUNDO CIRCUITO DE LOS MUNICIPIOS GIRARDOT Y MARIO BRICEÑO IRAGORRI ESTADO ARAGUA', 'Av. Bolívar Oeste, C.C. Galerías Plaza, Nivel 2, Local 96. Maracay.', 'RP282', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (274, 'REGISTRO MERCANTIL PRIMERO DEL ESTADO ARAGUA', 'Av. Miranda Este, Edificio Avior/Hotel Princesa Plaza, piso 1. Maracay.', 'RM283', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (275, 'REGISTRO MERCANTIL SEGUNDO DEL ESTADO ARAGUA', 'Av. Bolívar Oeste, C.C. Tiuna, Local 3, PB. Maracay.', 'RM284', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (276, 'REGISTRO PRINCIPAL DEL ESTADO BARINAS', 'Calle Camejo, Nro. 15-95, entre Av. Olímpica y Av. Andrés Varela, Qta. Silvana. Barinas.', 'RCP285', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (277, 'REGISTRO PÚBLICO DEL MUNICIPIO ALBERTO ARVELO TORREALBA  ESTADO BARINAS', 'Av. Obispo con cruce Calle 7, Edificio Sistema Solar, Piso 1, Oficina 16 a la 19.', 'RP286', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (278, 'REGISTRO PÚBLICO DEL MUNICIPIO ARISMENDI ESTADO BARINAS', 'Avenida 8 de Diciembre, Talleres de la Iglesia, Plaza Bolívar de Arismendi.', 'RP287', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (279, 'REGISTRO PÚBLICO DEL MUNICIPIO BARINAS ESTADO BARINAS', 'Av. 23 De Enero, Centro Comercial Siglo XXI, Local PB 2, Sector El Cambio.', 'RP288', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (280, 'REGISTRO PÚBLICO DEL MUNICIPIO BOLÍVAR  ESTADO BARINAS', 'Av. 6 con Calle 5, Locales 8 y 9, Piso-1, Edif. Don Carmelo, frente a la Plaza Bolívar, Barinitas.', 'RP289', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (281, 'REGISTRO PÚBLICO DE LOS MUNICIPIOS EZEQUIEL ZAMORA Y ANDRÉS ELOY BLANCO ESTADO BARINAS', 'Carrera 5 entre Calles 16 y 17 Nro. 16-60, Santa Barbará.', 'RP290', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (282, 'REGISTRO PÚBLICO DE LOS MUNICIPIOS OBISPOS Y CRUZ PAREDES DEL ESTADO BARINAS', 'Av. Arismendi, Nº 14, cerca de la Alcaldía.', 'RP291', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (283, 'REGISTRO PÚBLICO DE LOS MUNICIPIOS PEDRAZA Y SUCRE DEL ESTADO BARINAS', 'Av. 5ta., Esq. Calle 19, P.A. Edif. de Agrofepa, Ciudad Bolivia.', 'RP292', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (284, 'REGISTRO PÚBLICO DEL MUNICIPIO ROJAS ESTADO BARINAS', 'Av. Bolívar Cruce con Calle Esteban Terán, Casa Nº 23, Sector el Cementerio.', 'RP293', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (285, 'REGISTRO PÚBLICO DEL MUNICIPIO SOSA ESTADO BARINAS', 'Calle Martin Lazo, Nro B224, Ciudad de Nutrias', 'RP294', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (286, 'REGISTRO MERCANTIL PRIMERO DEL ESTADO BARINAS', 'Calle Camejo, con Av. Montilla, Edif. María, Mezzanina, oficina 1, Barinas.', 'RM295', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (287, 'REGISTRO PRINCIPAL DEL ESTADO BOLIVAR', 'Av. Táchira, Nro. 19, Qta. Isanilda, Ciudad Bolívar', 'RCP296', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (288, 'REGISTRO PÚBLICO DEL MUNICIPIO CARONÍ ESTADO BOLÍVAR', 'C.C. Orinokía, Plaza Santo Tome IV, Piso 02, Locales 5, 6 y 7, Sector Alta Vista,  Puerto Ordaz De Ciudad Guayana. ', 'RP297', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (289, 'REGISTRO PÚBLICO DEL MUNICIPIO CEDEÑO ESTADO BOLÍVAR', 'Av. Libertador casa Nº 24. Caicara del Orinoco', 'RP298', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (290, 'REGISTRO PÚBLICO DEL MUNICIPIO HERES ESTADO BOLÍVAR', 'Calle Vidal C.C. Progreso, Planta Alta. Ciudad Bolívar.', 'RP299', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (291, 'REGISTRO PÚBLICO DEL MUNICIPIO PIAR ESTADO BOLÍVAR', 'Av. Raúl Leoni, cruce con Calle Ruiz Pineda, Edif. Antonelli, Local C. Upata.', 'RP300', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (292, 'REGISTRO PÚBLICO DEL MUNICIPIO ROSCIO ESTADO BOLÍVAR', 'Calle Ibarra, Entre Avenida Urdaneta y Calle Juncal, Sector Dalla Costa, Centro Comercial Chepina, Oficina 1,.2,.3 y 4, Guasipati.', 'RP301', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (293, 'REGISTRO PÚBLICO DEL MUNICIPIO SUCRE ESTADO BOLÍVAR', 'Calle Bolívar, s/n. frente a la Plaza Sucre, Maripa.', 'RP302', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (294, 'REGISTRO MERCANTIL PRIMERO DEL ESTADO BOLÍVAR', 'Urb. Alta Vista, Centro Comercial Santo Tomé IV, Piso 2,ofic.13 puerto ordaz.', 'RM303', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (295, 'REGISTRO MERCANTIL SEGUNDO DEL ESTADO BOLÍVAR', 'Av. Rotaria, Centro Comercial Walter. Piso 1 local 2 , Sector Vista Hermosa, Ciudad Bolívar.', 'RM304', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (296, 'REGISTRO PRINCIPAL DEL ESTADO CARABOBO', 'Calle Soublette, entre Calle Colombia con Libertad, Nro. 100-55, Valencia.', 'RCP305', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (297, 'REGISTRO PÚBLICO DEL MUNICIPIO BEJUMA ESTADO CARABOBO', 'Av. Bolívar, Edificio Santa Rita, segundo piso.', 'RP306', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (298, 'REGISTRO PÚBLICO DEL MUNICIPIO CARLOS ARVELO ESTADO CARABOBO', 'Calle Ávila c/c Av. Bolívar local 29-1, Gûigûe.', 'RP307', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (299, 'REGISTRO PÚBLICO DE LOS MUNICIPIOS GUACARA, SAN JOAQUIN Y DIEGO IBARRA DEL ESTADO CARABOBO', 'C.C.P. Guácara Plaza PB-54, Calle Piar C/C Negro Primero. Guácara.', 'RP308', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (300, 'REGISTRO PÚBLICO DEL MUNICIPIO MONTALBÁN ESTADO CARABOBO', 'Av. Ricaurte #10-37 entre Calle El Sol y Calle Sucre . Montalbán.', 'RP309', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (301, 'REGISTRO PÚBLICO DEL MUNICIPIO PUERTO CABELLO ESTADO CARABOBO', 'Calle Segrestaa cruce con Av. Bolívar, C.C.P. Madefer Piso 2, Oficina 6 y 7. Puerto Cabello.', 'RP310', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (302, 'REGISTRO PÚBLICO DEL MUNICIPIO NAGUANAGUA DEL ESTADO CARABOBO', 'C.C. Paseo La Granja Piso 1 Oficina  # 101-102-103 y 110.', 'RP311', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (303, 'REGISTRO PÚBLICO DEL PRIMER CIRCUITO DEL MUNICIPIO  VALENCIA ESTADO CARABOBO', 'Callejón Mujica # 127-19. Sector Aguas Blancas.', 'RP312', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (304, 'REGISTRO PÚBLICO DEL SEGUNDO CIRCUITO DEL MUNICIPIO VALENCIA ESTADO CARABOBO', 'C.C. Big Low Center. Nave L, Locales 13 al 19. Valencia.', 'RP313', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (305, 'REGISTRO MERCANTIL PRIMERO DEL ESTADO CARABOBO', 'Calle Independencia, entre Av. Bolívar y Díaz Moreno, Edif. Ariza, piso 7.', 'RM314', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (306, 'REGISTRO MERCANTIL SEGUNDO DEL ESTADO CARABOBO', 'Av. Montes de Oca c/c calle Independencia, Edif. Torre Araujo, Piso 1, Oficina 1-1 a la 1-5 y 3-7.', 'RM315', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (307, 'REGISTRO MERCANTIL TERCERO DEL ESTADO CARABOBO', 'Calle 1era de Segrestán C/c  Carabobo, Edificio Inllasa II, planta baja, locales 3 y 4.', 'RM316', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (308, 'REGISTRO PRINCIPAL DEL ESTADO COJEDES', 'Calle Ayacucho, N° 7-88, entre  las Avs. Sucre y Páez, San  Carlos.', 'RCP317', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (309, 'REGISTRO PÚBLICO DEL MUNICIPIO ANZOÁTEGUI ESTADO COJEDES', 'Av. Bolívar, Nro. 27, Cojeditos', 'RP318', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (310, 'REGISTRO PÚBLICO DEL MUNICIPIO TINAQUILLO ESTADO  COJEDES', 'Avenida Bolívar Cruce Con Calle Colina, Local 10-77, Sector Centro. Tinaquillo A 20mts De Banesco.', 'RP319', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (311, 'REGISTRO PÚBLICO DEL MUNICIPIO GIRARDOT ESTADO COJEDES', 'Calle Páez, Diagonal A La Plaza Bolívar, El Baúl.', 'RP320', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (312, 'REGISTRO PÚBLICO DEL MUNICIPIO PAO DE SAN JUAN BAUTISTA ESTADO COJEDES', 'Calle Constitución frente a la Plaza Bolívar al lado de la alcaldía, El Pao.', 'RP321', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (313, 'REGISTRO PÚBLICO DEL MUNICIPIO RICAURTE ESTADO COJEDES', 'Calle Principal, Edif. Municipal, s/n., Libertad.', 'RP322', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (314, 'REGISTRO PÚBLICO DEL MUNICIPIO SAN CARLOS ESTADO COJEDES', 'Calle Ayacucho entre Sucre y Páez, casa Nº 7-73.', 'RP323', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (315, 'REGISTRO PÚBLICO DEL MUNICIPIO TINACO ESTADO COJEDES', 'Av. Urdaneta, frente a la Plaza  Bolívar, Tinaco.', 'RP324', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (316, 'REGISTRO MERCANTIL DEL  ESTADO COJEDES', 'Calle Figueredo entre Av. Bolívar y Sucre, Casa # 8-43 San Carlos.', 'RM325', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (317, 'REGISTRO PÚBLICO DEL MUNICIPIO TUCUPITA ESTADO DELTA AMACURO', 'Calle Bolívar. Edificio Rasmy Nº 52. Tucupita.', 'RP326', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (318, 'REGISTRO MERCANTIL DEL  ESTADO DELTA AMACURO', 'Calle Bolívar. Edificio Rasmy Nº52. Tucupita.', 'RM327', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (319, 'REGISTRO PRINCIPAL DEL ESTADO FALCON', 'Pasaje Gutiérrez con Calle Bolívar y Comercio, Edifico Mazloum, Primer Nivel de la Ciudad de Coro, Municipio Miranda.', 'RCP328', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (320, 'REGISTRO PÚBLICO DEL MUNICIPIO ACOSTA ESTADO FALCÓN', 'Calle Bolívar, Frente a La CANTV, Casa S/N, San Juan De Los Cayos, Municipio Acosta.', 'RP329', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (321, 'REGISTRO PÚBLICO DEL MUNICIPIO BOLÍVAR ESTADO FALCÓN', 'Calle Principal, N° 57, San Luís.', 'RP330', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (322, 'REGISTRO PÚBLICO DE LOS MUNICIPIOS BUCHIVACOA Y DABAJURO ESTADO FALCÓN', 'Calle Bruzual, Edificio Antigua Alcaldía, Sector Centro de Capatárida, Parroquia Capatárida, Municipio Buchivacoa.', 'RP331', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (323, 'REGISTRO PÚBLICO DEL MUNICIPIO CARIRUBANA ESTADO FALCÓN', 'Calle Comercio de Caja de Agua, Edificio Don Fernando Planta Baja; Punto Fijo.', 'RP332', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (324, 'REGISTRO PÚBLICO DEL MUNICIPIO COLINA  ESTADO FALCÓN', 'Calle 5 de Julio, entre Calles 20 de Febrero y Talavera, detrás del Supermercado  San Antonio, La Vela de Coro.', 'RP333', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (325, 'REGISTRO PÚBLICO DEL MUNICIPIO DEMOCRACIA ESTADO FALCÓN', 'Calle Sucre casa de la cultura.', 'RP334', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (326, 'REGISTRO PÚBLICO DE LOS MUNICIPIOS FALCÓN Y LOS TAQUES ESTADO FALCÓN', 'Av. Falcón de Pueblo Nuevo de Paraguaná diagonal a la cooperativa de ahorro y préstamo, Pueblo Nuevo.', 'RP335', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (327, 'REGISTRO PÚBLICO DEL MUNICIPIO FEDERACIÓN Y UNIÓN ESTADO FALCÓN', 'Calle Municipal. Sede De La Alcaldía Del Municipio Federación. Piso 01. Churuguara.', 'RP336', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (328, 'REGISTRO PÚBLICO DEL MUNICIPIO MAUROA ESTADO FALCÓN', 'Calle Comercio, Nro. 112, Mene de Mauroa . ', 'RP337', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (329, 'REGISTRO PÚBLICO DEL MUNICIPIO MIRANDA ESTADO FALCÓN', 'Calle Mapari, entre Calles Colón y Federación, N° 117, Coro.', 'RP338', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (330, 'REGISTRO PÚBLICO DEL MUNICIPIO PETIT ESTADO FALCÓN', 'Prolongación Calle Bolívar, s/n, Cabure', 'RP339', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (331, 'REGISTRO PÚBLICO DE LOS MUNICIPIOS LORENZO SILVA,  MONSEÑOR ITURRIZA Y PALMAZOLA  ESTADO FALCÓN', 'C.C. Morrocoy Plaza, Nivel Feria, Locales F-21 Y F-22, Carretera Nacional Morón Coro, Tucacas.', 'RP340', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (332, 'REGISTRO PÚBLICO DEL MUNICIPIO ZAMORA  ESTADO FALCÓN', 'Centro Comercial las Delicias; local 7 carretera de Morón  Puerto Cumarebo. ', 'RP341', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (333, 'REGISTRO MERCANTIL PRIMERO DEL ESTADO FALCÓN', 'Av. Manaure Edif. Doña Antoanet 1er. piso locales del 11 al 16, Coro.', 'RM342', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (334, 'REGISTRO MERCANTIL SEGUNDO DEL  ESTADO FALCÓN', 'Calle Sucre, entre Av. Bolívar y Calle Perú, Edif. de la Cámara de Comercio, P.B., Punto Fijo. ', 'RM343', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (335, 'REGISTRO PRINCIPAL DEL ESTADO GUARICO', 'Calle Salas, Qta. Carmen Ofelia, Urb. Antonio Miguel Martínez, San Juan de Los Morros.', 'RCP344', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (336, 'REGISTRO PÚBLICO DEL MUNICIPIO LEONARDO INFANTE  ESTADO GUÁRICO', 'Calle Leonardo Infante entre Providencia y 19 de Abril, Edif Aldo IV. Planta Baja. Valle de la Pascua.', 'RP345', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (337, 'REGISTRO PÚBLICO DEL MUNICIPIO JULIÁN MELLADO ESTADO GUÁRICO', 'Calle La Alegría, Quinta Aleska, Nro. 13, El Sombrero.', 'RP346', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (338, 'REGISTRO PÚBLICO DEL MUNICIPIO FRANCISCO DE MIRANDA ESTADO GUÁRICO', 'Carrera 12, Esq. Calle 5, Centro Comercial Profesional "Coromoto", P.A., frente a la Plaza Bolívar, Calabozo.', 'RP347', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (339, 'REGISTRO PÚBLICO DE LOS MUNICIPIOS  JOSÉ TADEO MONAGAS Y SAN JOSE DE GUARIBE  ESTADO GUÁRICO', 'Calle Rondón, cruce con Calle Gil Púlido, Edif. El Parque, Altagracia de Orituco.', 'RP348', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (340, 'REGISTRO PÚBLICO DEL MUNICIPIO JOSÉ FÉLIX RIBAS ESTADO GUÁRICO', 'Calle Zaraza C/C Pariaguan, Sector El Tranquero, Centro Comercial Del Sur, Joao Ferreira, Local Nº 03.', 'RP349', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (341, 'REGISTRO PÚBLICO DEL MUNICIPIO JUAN GERMÁN ROSCIO Y ORTIZ ESTADO GUÁRICO', 'Av. Miranda, cruce con Calle Salía, Edif. Los Blascos, Piso 2, San Juan de Los Morros.', 'RP350', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (342, 'REGISTRO PÚBLICO DEL MUNICIPIO PEDRO ZARAZA  ESTADO GUÁRICO', 'Calle Las Flores cruce con Higuerote, Edificio HidroPáez Planta Alta.  Zaraza.', 'RP351', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (343, 'REGISTRO MERCANTIL PRIMERO DEL ESTADO GUÁRICO', 'Calle Farriar con Av. Fermín Toro, C.C. Don Salvador, Local Nivel 1, Ofic. 104, San Juan de Los Morros.', 'RM352', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (344, 'REGISTRO MERCANTIL SEGUNDO DEL ESTADO GUÁRICO', 'Av. Rómulo Gallegos,entre Calle Atarraya y Retumbo, Edif. Aldo, Piso 1, al lado del Banesco. Valle de La Pascua.', 'RM353', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (345, 'REGISTRO MERCANTIL TERCERO DEL  ESTADO GUÁRICO', 'Calle 5, Esq. Carrera 10, Edif. Colonial, Piso 1, Ofic. N° 15-B, Calabozo.', 'RM354', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (346, 'REGISTRO PRINCIPAL DEL ESTADO LARA', 'Urb. Antonio Miguel Martínez Calle Salas, Qta. Carmen Ofelia. Barquisimeto.', 'RCP355', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (347, 'REGISTRO PÚBLICO DEL MUNICIPIO CRESPO ESTADO LARA', 'Av. 11 entre carreras 11 y 12,  C.C. MAGGIS local  02, diagonal a la sede Corpoelec .', 'RP356', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (348, 'REGISTRO PÚBLICO DEL MUNICIPIO JIMÉNEZ Y ANDRÉS ELOY BLANCO ESTADO LARA', 'Av. Florencio Jiménez, cruce con Av. Rotaria, al lado del Concesionario Ford, C.C. BEL Planta Alta. Quibor.', 'RP357', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (349, 'REGISTRO PÚBLICO DEL MUNICIPIO MORÁN ESTADO LARA', 'Av. Lisandro Alvarado, Edif. Administrativo, entre Calles 15 y 16, El Tocuyo.', 'RP358', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (350, 'REGISTRO PÚBLICO DEL MUNICIPIO PALAVECINO ESTADO LARA', 'Av. Río Claro, Centro Comercial  El Palmar, Piso 1, Locales 1, 2 y 5, Cabudare.', 'RP359', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (351, 'REGISTRO PÚBLICO DEL MUNICIPIO TORRES ESTADO LARA', 'Calle San Juan, Esquina a calle Carabobo, Diagonal al Club Torres, Zona colonial, Carora.', 'RP360', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (352, 'REGISTRO PÚBLICO DEL MUNICIPIO URDANETA ESTADO LARA', 'Av. Urdaneta entre calles 5 y 6. Diagonal consultorio Robinson Urbina.', 'RP361', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (353, 'REGISTRO PÚBLICO DEL PRIMER CIRCUITO DEL MUNICIPIO IRIBARREN  ESTADO LARA', 'Calle 26 con Carreras 15 y 16,  Torre David, mezanina, Barquisimeto.', 'RP362', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (354, 'REGISTRO PÚBLICO DEL SEGUNDO CIRCUITO DEL MUNICIPIO IRIBARREN  ESTADO LARA', 'Calle 26 con Carreras 15 y 16,  Torre David, mezanina,  Barquisimeto.', 'RP363', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (355, 'REGISTRO MERCANTIL PRIMERO DEL ESTADO LARA', 'Calle 26 entre Carreras 15 y 16, Torre David, Nivel Semi-Sótano, Barquisimeto.', 'RM364', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (356, 'REGISTRO MERCANTIL SEGUNDO DEL ESTADO LARA', 'Esq. Calle 26, entre Carreras 15 y 16, Torre David, Semi-Sótano, Local SS, Barquisimeto.', 'RM365', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (357, 'REGISTRO PRINCIPAL DEL ESTADO MERIDA', 'Av. 2  Lora, Qta.Capaya, Nro. 38-2, Mérida.', 'RCP366', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (358, 'REGISTRO PÚBLICO DEL MUNICIPIO ALBERTO ADRIANI ESTADO MÉRIDA', 'Calle Principal, Urb. Buenos Aires # 2-74, El Vigia.', 'RP367', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (359, 'REGISTRO PÚBLICO DEL MUNICIPIO ANDRÉS BELLO ESTADO MÉRIDA', 'Av. Chipia entre Calles 5ta y 6ta, # 5-35 La Azulita.', 'RP368', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (360, 'REGISTRO PÚBLICO DEL MUNICIPIO ANTONIO PINTO SALINAS ESTADO MÉRIDA', 'Calle Ayacucho, Edif. Municipal, Piso 3, Santa Cruz de Mora', 'RP369', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (361, 'REGISTRO PÚBLICO DEL MUNICIPIO ARZOBISPO CHACÓN ESTADO MÉRIDA', 'Calle Bolívar de la población de Canagua, casa Nº 4-88, al lado de la Distribuidora Moraca.', 'RP370', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (362, 'REGISTRO PÚBLICO DEL MUNICIPIO CAMPO ELÍAS ESTADO MÉRIDA', 'Centro Comercial Centenario, Local  Nro. 73, Núcleo Sur, Av. Centenario. Ejido.', 'RP371', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (363, 'REGISTRO PÚBLICO DEL MUNICIPIO JUSTO BRICEÑO ESTADO MÉRIDA', 'Av. Justo Briseño con Calle Sucre, Edificio Nacional, planta baja.Torondoy.', 'RP372', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (364, 'REGISTRO PÚBLICO DEL MUNICIPIO LIBERTADOR ESTADO MÉRIDA', 'Av. Urdaneta con Av. Gonzalo Picón Calle 42, Casa N° 3-90, Urb. Para profesores, Merida.', 'RP373', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (365, 'REGISTRO PÚBLICO DEL MUNICIPIO MIRANDA ESTADO MÉRIDA', 'Av. Bolivar entre calle Varga y Rondon C.C. Isabela N° 10-17.', 'RP374', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (366, 'REGISTRO PÚBLICO DEL MUNICIPIO RANGEL ESTADO MÉRIDA', 'Av. Carabobo al lado del Restauran Carillon.', 'RP375', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (367, 'REGISTRO PÚBLICO DEL MUNICIPIO RIVAS DÁVILA  ESTADO MÉRIDA', 'Av. Bolívar, calle 6, Casa 3-85   Bailadores', 'RP376', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (368, 'REGISTRO PÚBLICO DEL MUNICIPIO SUCRE  ESTADO MÉRIDA', 'Calle El Almacén, frente a la Plaza Sucre, Local N 2. Lagunillas.', 'RP377', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (369, 'REGISTRO PÚBLICO DEL MUNICIPIO TOVAR ESTADO MÉRIDA', 'Calle José María Méndez C.C. el Arado II local 5, planta baja, Tovar Estado Mérida. ', 'RP378', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (370, 'REGISTRO MERCANTIL PRIMERO DEL ESTADO MÉRIDA', 'Avenida 4 Bolívar, Calle 23 (Vargas), Edificio Hermes (Palacio de Justicia),  Planta Baja Local No. 4. Parroquia El Sagrario.', 'RM379', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (371, 'REGISTRO MERCANTIL SEGUNDO DEL ESTADO MÉRIDA', 'Calle 3, entre las Avs. 14 y 15, Edif. Santana, N° 14-14, Piso 2, El Vigia.', 'RM380', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (372, 'REGISTRO PRINCIPAL DEL ESTADO MONAGAS', 'Carrera 7, Nro. 106, Edif. Rufino González, Maturín.', 'RCP381', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (373, 'REGISTRO PÚBLICO DEL MUNICIPIO ACOSTA ESTADO MONAGAS', 'Edificio casa de la Cultura Av. Bolívar frente a la plaza Bolívar. San Antonio de Capayaguar.', 'RP382', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (374, 'REGISTRO PÚBLICO DEL MUNICIPIO BOLÍVAR  ESTADO MONAGAS', 'Calle Piar Nº 10. Caripito Arriba.', 'RP383', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (375, 'REGISTRO PÚBLICO DEL MUNICIPIO CARIPE ESTADO MONAGAS', 'Avenida Libertador Casa S/N al lado de CORPOELEC,Municipio Caripe - Monagas.', 'RP384', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (376, 'REGISTRO PÚBLICO DEL MUNICIPIO CEDEÑO ESTADO MONAGAS', 'Calle Bermúdez # 28. Caicara. ', 'RP385', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (377, 'REGISTRO PÚBLICO DEL PRIMER CIRCUITO DEL MUNICIPIO MATURÍN ESTADO MONAGAS', 'Calle Chimborazo Av. Bolívar Edificio Galería Mi suerte Piso1. Oficina 7,8 y 9.', 'RP386', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (378, 'REGISTRO PÚBLICO DEL SEGUNDO CIRCUITO DEL MUNICIPIO MATURÍN ESTADO MONAGAS', 'Av. Miranda C/C Barreto, Edificio Ofinabil, piso 1, frente al C.C. Alex.', 'RP387', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (379, 'REGISTRO PÚBLICO DEL MUNICIPIO PIAR  ESTADO MONAGAS', 'Calle Rivas # 29. Aragua de Maturin', 'RP388', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (380, 'REGISTRO PÚBLICO DEL MUNICIPIO SOTILLO ESTADO MONAGAS', 'Calle Carabobo# 19. Barrancas del Orinoco', 'RP389', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (381, 'REGISTRO PÚBLICO DEL MUNICIPIO EZEQUIEL ZAMORA ESTADO MONAGAS.', 'Calle Andrés Bello, casa S/N, al lado del cuerpo de bombeos. Punta de Mata.', 'RP390', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (382, 'REGISTRO MERCANTIL DEL ESTADO MONAGAS', 'Calle Chimborazo c/c Av. Bolívar, Edif. Galería Mi Suerte Piso 2. Maturín.', 'RM391', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (383, 'REGISTRO PRINCIPAL DE NUEVA ESPARTA', 'Boulevard 5 de Julio, Nro. 13-13, La Asunción.', 'RCP392', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (384, 'REGISTRO PÚBLICO DE LOS MUNICIPIOS ARISMENDI Y ANTOLIN DEL CAMPO ESTADO NUEVA ESPARTA', 'Calle Independencia, Casa Nº 11-32, Diagonal A La Casa De La Cultura La Asunción.', 'RP393', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (385, 'REGISTRO PÚBLICO DEL MUNICIPIO DÍAZ ESTADO NUEVA ESPARTA', 'Calle Sucre Centro Cívico Juan de Castellanos 1er piso. San Juan Bautista.', 'RP394', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (386, 'REGISTRO PÚBLICO DEL MUNICIPIO GÓMEZ ESTADO NUEVA ESPARTA', 'Calle Libertador #63B Quinta Carmencita. Santa Ana.', 'RP395', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (387, 'REGISTRO PÚBLICO DEL MUNICIPIO MANEIRO ESTADO NUEVA ESPARTA', 'Avenida Bolívar, Centro Comercial Ab, II Etapa Mezanine, Local 70, Sector Playa El Ángel, Pampatar.', 'RP396', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (388, 'REGISTRO PÚBLICO DEL MUNICIPIO MARCANO ESTADO NUEVA ESPARTA', 'Calle La Marina, Nº 49, Frente a la Bahía de Juan Griego.', 'RP397', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (389, 'REGISTRO PÚBLICO DEL MUNICIPIO MARIÑO ESTADO NUEVA ESPARTA', 'Urb. Sabana mar, Av. Rómulo Betancourt, al lado de INTT y CICPC.', 'RP398', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (390, 'REGISTRO MERCANTIL PRIMERO DEL ESTADO NUEVA ESPARTA', 'Calle La Juventud, frente a la Plaza la Juventud, Casa Nº 1-82, diagonal a la Estación de Servicio BP. La Asunción.', 'RM399', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (391, 'REGISTRO MERCANTIL SEGUNDO DEL ESTADO NUEVA ESPARTA', 'Av. Rómulo Betancourt, C.C. Sabanamar, oficinas de la 6 a la 9. Porlamar.', 'RM400', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (392, 'REGISTRO PRINCIPAL DEL ESTADO PORTUGUESA', 'Carrera 11, entre Calles 15 y 16,  Edif. Teo, Diagonal a Ipostel,  Barrio La Arenosa, Guanare.', 'RCP401', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (393, 'REGISTRO PÚBLICO DE LOS MUNICIPIOS ARAURE, AGUA BLANCA Y SAN RAFAEL DE ONOTO  ESTADO PORTUGUESA', 'Calle 6 entre Av. 26 y 27, Edif. Vicente Padilla Apto. 1. Araure.', 'RP402', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (394, 'REGISTRO PÚBLICO DEL MUNICIPIO ESTELLER ESTADO PORTUGUESA', 'Carrera 9 Entre Calles 3 y 4 frente a la estación de servicios El Progreso, Piritu.', 'RP403', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (395, 'REGISTRO PÚBLICO DEL MUNICIPIO GUANARE ESTADO PORTUGUESA', 'Carrera 6 Entre Calles 6 y Corredor Vial Tomas Montilla Edif. S/N Piso Pb Of S/N Barrio Coromoto.', 'RP404', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (396, 'REGISTRO PÚBLICO DEL MUNICIPIO GUANARITO ESTADO PORTUGUESA', 'Calle 4, Barrio la Plaza, Guanarito.', 'RP405', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (397, 'REGISTRO PÚBLICO DEL MUNICIPIO OSPINO ESTADO PORTUGUESA', 'Av. Libertador con Calle Lisandro Alvarado, diagonal a la Iglesia Cristo Rey, Local 1 Centro Cívico, Ospino.', 'RP406', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (398, 'REGISTRO PÚBLICO DEL MUNICIPIO PÁEZ ESTADO PORTUGUESA', 'Av. 30 e/n 29 y 31, C.C. Mini Centro Acarigua, PA, Acariga', 'RP407', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (399, 'REGISTRO PÚBLICO DEL MUNICIPIO SUCRE  ESTADO PORTUGUESA', 'Carrera 4 entre calles Páez y Urdaneta Edif. S/N piso 1, Biscucuy.', 'RP408', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (400, 'REGISTRO PÚBLICO DEL MUNICIPIO TURÉN  ESTADO PORTUGUESA', 'Av. 5 cruce con Av. Raúl Leoni, Edificio D` Santolo, piso 1 Apartamento 2, Turen.', 'RP409', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (401, 'REGISTRO MERCANTIL PRIMERO DEL ESTADO PORTUGUESA', 'Carrera 6ta, entre calles 17 y 18, sector Centro. Edificio Ruvenga, Piso 01, oficina 08.', 'RM410', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (402, 'REGISTRO MERCANTIL SEGUNDO DEL  ESTADO PORTUGUESA', 'Av. 33, entre calles 30 y 31, locales 10 y 11, CC. Latín Center. Acarigua.', 'RM411', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (403, 'REGISTRO MERCANTIL SEGUNDO DEL ESTADO BARINAS', 'Av. San Luis con Av. Cruz Paredes y Calle Camejo, Edificio el trigal PB, Oficina # 5, Barinas.', 'RM412', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (404, 'REGISTRO PRINCIPAL DEL ESTADO SUCRE', 'Calle Mariño, antigua sede del Banco La Construcción, Cumaná.', 'RCP413', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (405, 'REGISTRO PÚBLICO DEL MUNICIPIO ARISMENDI ESTADO SUCRE', 'Calle Zea con Calle Mariño, s/n. Río Caribe. (Frente a la Escuela Artesanal).', 'RP414', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (406, 'REGISTRO PÚBLICO DEL MUNICIPIO BENITEZ ESTADO SUCRE', 'Calle del Valle Nº 9, El Pilar.', 'RP415', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (407, 'REGISTRO PÚBLICO DEL MUNICIPIO BERMUDEZ  ESTADO SUCRE', 'Calle Independencia, Edif. Funda Bermúdez, Piso 2, Locales 1, 2, 11 y 12. Carúpano.', 'RP416', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (408, 'REGISTRO PÚBLICO DEL MUNICIPIO CAJIGAL ESTADO SUCRE', 'Calle Sucre N. 14. Cercano a la alcaldía . Yaguaraparo.', 'RP417', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (409, 'REGISTRO PÚBLICO DEL MUNICIPIO MARIÑO ESTADO SUCRE', 'Calle Sucre s/n a una cuadra de la Cooperativa los Pinos, Irapa.', 'RP418', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (410, 'REGISTRO PÚBLICO DEL MUNICIPIO MEJÍAS ESTADO SUCRE', 'Calle Santa Teresa s/n, Al lado de la Alcaldía San Antonio del Golfo.', 'RP419', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (411, 'REGISTRO PÚBLICO DEL MUNICIPIO MONTES ESTADO SUCRE', 'Calle Las Flores Casa # 16. Cerca de la Casa Parroquial Cumanacoa.', 'RP420', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (412, 'REGISTRO PÚBLICO DEL MUNICIPIO RIBERO ESTADO SUCRE', 'calle Sucre casa Nº 38, frente al Tribunal. Caicaro.', 'RP421', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (413, 'REGISTRO PÚBLICO DEL MUNICIPIO SUCRE ESTADO SUCRE', 'Calle Mariño, C.C Ciudad Cumaná, 2do piso, Local 5-C. Cumaná.', 'RP422', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (414, 'REGISTRO PÚBLICO DEL MUNICIPIO VALDEZ ESTADO SUCRE', 'Calle Concepción # 33. Frente a la Plaza Bolívar. Guiria.', 'RP423', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (415, 'REGISTRO MERCANTIL PRIMERO DEL ESTADO SUCRE', 'Calle Mariño, C.C. Ciudad Cumaná, 2do piso, Locales 11-A 11-C y 1-C. Cumaná.', 'RM424', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (416, 'REGISTRO PRINCIPAL DEL ESTADO TACHIRA', 'Prolongación de la 5ta. Av. Edif. ETNA, N° 4-117, La Concordia, San Cristóbal.', 'RCP425', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (417, 'REGISTRO PÚBLICO DEL MUNICIPIO AYACUCHO ESTADO TACHIRA', 'Carrera  5, entre calles 6 y7,  casa N° 6-65, planta baja, San Juan de Colón. ', 'RP426', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (418, 'REGISTRO PÚBLICO DEL MUNICIPIO BOLÍVAR ESTADO TACHIRA', 'Carrera 10, Calles 9 y 10, Barrio La Popa, N° 9-35, San Antonio del Táchira.', 'RP427', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (419, 'REGISTRO PÚBLICO DEL MUNICIPIO INDEPENDENCIA ESTADO TACHIRA', 'Carrera 7 Con Calle 10 casa #5-10, Capacho Nuevo.', 'RP428', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (420, 'REGISTRO PÚBLICO DE LOS MUNICIPIOS CÁRDENAS, GUASIMOS Y ANDRÉS BELLO ESTADO TACHIRA', 'Carrera  7, entre 2 y 3. Nº 2-25, Quinta Doña Elvira. Táriba', 'RP429', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (421, 'REGISTRO PÚBLICO DEL MUNICIPIO CÓRDOBA ESTADO TACHIRA', 'Carrera  5,  entre 11 y 12  Nro. 101, Santa Ana.', 'RP430', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (422, 'REGISTRO PÚBLICO DEL MUNICIPIO GARCÍA DE HEVIA ESTADO TACHIRA', 'Calle  3, N° 3-35, Piso 1,  Casco Central, La Fría.', 'RP431', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (423, 'REGISTRO PÚBLICO DE LOS MUNICIPIOS JÁUREGUI, SEBORUCO Y  ANTONIO ROMULO COSTA  ESTADO TÁCHIRA', 'Calle 2, Centro Empresarial, piso 3, Frente a la Iglesia Nuestra Señora de los Ángeles, la Grita.', 'RP432', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (424, 'REGISTRO PÚBLICO DEL MUNICIPIO JUNÍN Y RAFAEL URDANETA  ESTADO TACHIRA', 'Av.11, Nº 10-41, frente a la Plaza Bolívar, Rubio.', 'RP433', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (425, 'REGISTRO PÚBLICO DEL MUNICIPIO LIBERTADOR ESTADO TACHIRA', 'Calle 3 entre Carreras 1 y 2 casa 1-61 diagonal a la casa parroquial de Abejales.', 'RP434', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (426, 'REGISTRO PÚBLICO DEL MUNICIPIO LOBATERA ESTADO TÁCHIRA', 'Calle 4 Entre Carrera 4 Y 5 Nro. 4-35, Lobatera.', 'RP435', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (427, 'REGISTRO PÚBLICO DEL MUNICIPIO MICHELENA ESTADO TÁCHIRA', 'Calle 1, entre Carreras 4 y 5, No. 4-55. Michelena.', 'RP436', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (428, 'REGISTRO PÚBLICO DE LOS MUNICIPIOS PANAMERICANO Y SAMUEL DARÍO MALDONADO ESTADO TÁCHIRA', 'Calle 8 entre carreras 4 y 4 bis. Local Nº 4-48. Coloncito.', 'RP437', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (429, 'REGISTRO PÚBLICO DEL MUNICIPIO PEDRO MARÍA UREÑA  ESTADO TÁCHIRA', 'Calle 4 entre carreras 3 y4, Nro. 3-41, Barrio El Centro, Ureña.', 'RP438', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (430, 'REGISTRO PÚBLICO DEL PRIMER CIRCUITO DEL MUNICIPIO SAN CRISTÓBAL ESTADO TÁCHIRA', 'Av. Principal de la Urbanización Mérida. Esquina Calle 6 Quinta Arvez Nº 0-21.', 'RP439', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (431, 'REGISTRO PÚBLICO DEL SEGUNDO CIRCUITO DEL MUNICIPIO SAN CRISTÓBAL ESTADO TÁCHIRA', 'Avenida Libertador, Edificio Verdi, diagonal a la Casa Sindical.', 'RP440', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (432, 'REGISTRO PÚBLICO DEL MUNICIPIO SUCRE ESTADO TÁCHIRA', 'Carrera 5 entre calle 2 y 3 casa Registro Público de Queniquea.', 'RP441', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (433, 'REGISTRO PÚBLICO DEL MUNICIPIO URIBANTE ESTADO TÁCHIRA', 'Carrera 3, Centro Cívico, Locales 7, 8 y 9, frente a la Plaza Bolívar, Pregonero.', 'RP442', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (434, 'REGISTRO MERCANTIL PRIMERO DEL ESTADO TÁCHIRA', 'Av. 5ta. Edif. Don Antonio, piso 2., Locales 6, 7, 8, 9, 10 y 11, Esq. Calle 15, frente a la Sanidad, San Cristóbal. San Cristóbal.', 'RM443', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (435, 'REGISTRO MERCANTIL SEGUNDO DEL ESTADO TÁCHIRA', 'Av. Luis Hurtado Iguera, Nº13 -168, San Juan de Colón.', 'RM444', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (436, 'REGISTRO MERCANTIL TERCERO DEL ESTADO TÁCHIRA', 'Calle 4 Bis Entre Carreras 8 Y 9, Planta Baja Del Edificio La Concordia, Locales 1 Y 5.', 'RM445', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (437, 'REGISTRO PRINCIPAL DEL ESTADO TRUJILLO', 'Av.  Diego García  de  Paredes,  Nro. 10-120, San Jacinto.', 'RCP446', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (438, 'REGISTRO PÚBLICO DEL MUNICIPIO BOCONÓ ESTADO TRUJILLO', 'Av. Independencia entre calles Bolívar y Vargas Edif. Calderón, PB.', 'RP447', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (439, 'REGISTRO PÚBLICO DEL MUNICIPIO CARACHE ESTADO TRUJILLO', 'Av. 3 Libertad, entre calles 7 y 8, Casa N° 7,  al lado de la Farmacia Las 3 R, C.A. ', 'RP448', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (440, 'REGISTRO PÚBLICO DE LOS MUNICIPIOS ESCUQUE Y MONTE CARMELO ESTADO TRUJILLO', 'Calle Miranda, Nro. 59, Escuque.', 'RP449', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (441, 'REGISTRO PÚBLICO DE LOS MUNICIPIOS RAFAEL RANGEL, SUCRE, MIRANDA, ANDRÉS BELLO, BOLÍVAR Y LA CEIBA DEL ESTADO TRUJILLO', 'Av. 5ta. Edif. Petijoc, Aptos. 3 y 4, Betijoque.', 'RP450', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (442, 'REGISTRO PÚBLICO DE LOS MUNICIPIOS TRUJILLO, PAMPAN Y PAMPANITO  ESTADO TRUJILLO', 'Calle Carrillo, entre Avenidas Independencia y Bolívar, Edificio Las Adjuntas, Locales 1-0 y 1-1, Sector Centro, Frente a Almacenes Maldonado, Municipio Trujillo, Estado Trujillo.', 'RP451', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (443, 'REGISTRO PÚBLICO DEL MUNICIPIO URDANETA ESTADO TRUJILLO', 'Calle Páez, frente a la Plaza Bolívar, La Quebrada.', 'RP452', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (444, 'REGISTRO PÚBLICO DE LOS MUNICIPIOS VALERA, MOTATAN Y SAN RAFAEL DE CARVAJAL  ESTADO TRUJILLO', 'Av. Bolívar, Sector Las Acacias, Centro Comercial Las Acacias, Oficina 20 y 21 Piso 1, Valera.', 'RP453', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (445, 'REGISTRO MERCANTIL PRIMERO DEL ESTADO TRUJILLO', 'Avenida Bolívar entre calles 18 y 19 Edificio Ferdinando nivel Planta Baja, Local 02, Municipio Valera, Estado Trujillo.', 'RM454', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (446, 'REGISTRO PÚBLICO DEL PRIMER CIRCUITO MUNICIPIO VARGAS ESTADO VARGAS', 'Av. Principal la Costanera. Urb. Los Corales Calle 7 con Av. 5, Manzana Nº 8, Qta. Madrigal, Parroquia Caraballeda.', 'RP455', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (447, 'REGISTRO PÚBLICO DEL SEGUNDO CIRCUITO MUNICIPIO VARGAS ESTADO VARGAS', 'Urb. La Atlántida, Calle 12, Detrás Del Banco De Venezuela, Edif. Registro Público, Catia La Mar.', 'RP456', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (448, 'REGISTRO MERCANTIL DEL ESTADO VARGAS', 'Av. Principal del Atlántida, Qta. Mary primer piso frente al C.C. El Prado, Catia la Mar.', 'RM457', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (449, 'REGISTRO PRINCIPAL DEL ESTADO YARACUY', 'Calle 13, entre 5ta. y 6ta., Av. Edificio Strazzeri, Oficina Nº 15, San Felipe.', 'RCP458', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (450, 'REGISTRO PÚBLICO DEL MUNICIPIO  BOLÍVAR ESTADO YARACUY', 'Calle Páez,  S/N,   Centro, Aroa.', 'RP459', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (451, 'REGISTRO PÚBLICO DEL MUNICIPIO BRUZUAL ESTADO YARACUY', 'Av. 9, Esq. de la Calle 11, Edif. América, frente a la Plaza Bruzual, Chivacoa.    ', 'RP460', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (452, 'REGISTRO PÚBLICO DEL MUNICIPIO NIRGUA ESTADO YARACUY', 'Calle 8, entre Av. 4ta. y 5ta. Edif. Zorlay, Apto. 3, Piso 1, Nirgua.', 'RP461', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (453, 'REGISTRO PÚBLICO DE LOS MUNICIPIOS SAN FELIPE, INDEPENDENCIA, COCOROTE Y VEROES ESTADO YARACUY', 'Av. 7, entre Calles 11 y 12, Edif. Rental, Piso 1, San Felipe.', 'RP462', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (454, 'REGISTRO PÚBLICO DE LOS MUNICIPIOS SUCRE, LA TRINIDAD Y ARISTIDES BASTIDAS ESTADO YARACUY', 'Calle Occidente Nro 35 a lado de la UNEY Universidad Experimental.', 'RP463', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (455, 'REGISTRO PÚBLICO DEL MUNICIPIO URACHICHE ESTADO YARACUY', 'Av. 2, Nro.  5-53, entre  Calles 5 y 6, Urachiche.', 'RP464', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (456, 'REGISTRO PÚBLICO DEL MUNICIPIO YARITAGUA ESTADO YARACUY', 'Av. Padre Torres con Esq. de la Carrera 15,  Primer Piso .Yaritagua. ', 'RP465', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (457, 'REGISTRO MERCANTIL DEL ESTADO YARACUY', 'Av. Caracas, Esq. de la 5ta. Av. Edif. Stemica, Piso 2, San Felipe.', 'RM466', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (458, 'REGISTRO PRINCIPAL DEL ESTADO ZULIA', 'Calle 96, Nro. 3-67, Local 3, Maracaibo.', 'RCP467', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (459, 'REGISTRO PÚBLICO DEL MUNICIPIO BARALT ESTADO ZULIA', 'Av. del Lago, Casa s/n., San Timoteo.', 'RP468', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (460, 'REGISTRO PÚBLICO DE LOS MUNICIPIOS SANTA RITA, CABIMAS Y SIMÓN BOLÍVAR  ESTADO ZULIA', 'Av. Pedro Lucas Urribarri, Nro. 99, Santa Rita.', 'RP469', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (461, 'REGISTRO PÚBLICO DE LOS MUNICIPIOS COLÓN, CATATUMBO Y JESÚS MARÍA SEMPRUM  ESTADO ZULIA', 'Av. Bolívar antes Calle 4, Nro. 4-144, Sector San Carlos Norte, Santa Bárbara.', 'RP470', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (462, 'REGISTRO PÚBLICO DE LOS MUNICIPIOS  LAGUNILLAS Y VALMORE RODRIGUEZ  ESTADO ZULIA', 'Calle Vargas, Centro Comercial Calandriello, Piso 2, Oficina 5C. Ciudad Ojeda.', 'RP471', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (463, 'REGISTRO PÚBLICO DE LOS MUNICIPIOS  MARA E INSULAR ALMIRANTE PADILLA ESTADO ZULIA', 'Av. 4,El Moján, entre Calles 23 y 24, San Rafael', 'RP472', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (464, 'REGISTRO PÚBLICO DEL MUNICIPIO MIRANDA ESTADO ZULIA', 'Avenida 05, Centro Comercial Carlota, Planta Baja, Local 19-43, Los Puertos De Altagracia.', 'RP473', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (465, 'REGISTRO PÚBLICO DEL MUNICIPIO PAÉZ  ESTADO ZULIA', 'Calle 14, Nro. 12-45, Sinamaica.', 'RP474', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (466, 'REGISTRO PÚBLICO DEL MUNICIPIO PERIJÁ ESTADO ZULIA', 'Av. Artes con Calle La Marina, Machiques.', 'RP475', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (467, 'REGISTRO PÚBLICO DEL MUNICIPIO JESÚS ENRIQUE LOSSADA ESTADO ZULIA', 'Av. Bolívar, Centro Comercial La Foca, planta alta, local 2-B, La Concepción.', 'RP476', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (468, 'REGISTRO PÚBLICO DEL MUNICIPIO SUCRE ESTADO ZULIA', 'Edificio Ateneo Olimpiades Pulgar, Local A-7, Calle Las 3 Av. Bobures.', 'RP477', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (469, 'REGISTRO PÚBLICO DEL MUNICIPIO LA CAÑADA DE URDANETA ESTADO ZULIA', 'Calle 14 este Av. 3 y 4 Nº 25-27, Corredor vial Olegario Hernández, vía al Topito.', 'RP478', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (470, 'REGISTRO PÚBLICO DEL PRIMER CIRCUITO DEL MUNICIPIO MARACAIBO ESTADO ZULIA', 'Av. 8 (Páez) con Calle 95 (antigua Venezuela), Centro Comercial Santa Bárbara Alu, Locales 39, 40, 41, 42, 43, 44 y 45, Parroquia Bolívar, Maracaibo.  ', 'RP479', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (471, 'REGISTRO PÚBLICO DEL SEGUNDO CIRCUITO DEL MUNICIPIO MARACAIBO ESTADO ZULIA', 'Calle 74 y 75 con Av. 12 y 13, Centro Comercial Aventura, Local A-1, Piso 1, Sector Tierra Negra, Maracaibo.', 'RP480', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (472, 'REGISTRO PÚBLICO DEL TERCER CIRCUITO DEL MUNICIPIO  MARACAIBO ESTADO ZULIA', 'Av. 4 Bella Vista, Calle 67, C.C. Socuy, Local 15 Y 16, Maracaibo.', 'RP481', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (473, 'REGISTRO PÚBLICO DEL MUNICIPIO SAN FRANCISCO ESTADO ZULIA', 'Sector Sierra Maestra, calle 19, Av. 05, Nº20-05, San Francisco.', 'RP482', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (474, 'REGISTRO MERCANTIL PRIMERO DEL ESTADO ZULIA', 'Parroquia Olegario Villalobos, Sector Tierra Negra, entre avenidas 12 y 13 con calles 74 y 75, Centro Comercial Aventura, Planta Alta, Local A-2. Maracaibo.', 'RM483', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (475, 'REGISTRO MERCANTIL SEGUNDO DEL ESTADO ZULIA', 'Av. Cristóbal Colón, (arterial 7) Nº 49, diagonal a la Unidad Educativa Privada Don Bosco,  Ciudad Ojeda.', 'RM484', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (476, 'REGISTRO MERCANTIL TERCERO DEL ESTADO ZULIA', 'Av. 72 con Av. Bella Vista, C.C. Clodomira, Piso 2, Oficina 304-305-306, Frente al Club Comercio.', 'RM485', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (477, 'REGISTRO MERCANTIL CUARTO DEL ESTADO ZULIA', 'Av. Bella Vista, Calle 76, Edificio Don Matías, Local 20, Maracaibo.', 'RM486', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (478, 'REGISTRO MERCANTIL QUINTO DEL ESTADO ZULIA', 'Centro Comercial Campo Sur, local 08, PB. KM 1 ½, Vía Perija, Frente Al Club El Tablazo. San Francisco.', 'RM487', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (479, 'REGISTRO MERCANTIL SEGUNDO DE LA CIRCUNSCRIPCIÓN JUDICIAL DEL DISTRITO ALTO APURE', 'Avenida Acueducto, Sector Los Corrales, Frente a la Escuela Bolivariana de Guasdualito.', 'RM490', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (480, 'NOTARÍA PÚBLICA DE SANTA BARBARA', 'Av. 3(Antes Sucre), Centro Comercial Lina, Local Nro. 3-B, P.A., Santa Bárbara.', 'NP677', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (481, 'NOTARÍA PÚBLICA CUADRAGÉSIMA SEXTA DE CARACAS MUNICIPIO LIBERTADOR', 'Kilómetro 13 de la carretera al Junquito Centro Comercial El Castillo Nivel mezzanina local 37. Parroquia el Junquito.', 'NP678', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (482, 'NOTARÍA PÚBLICA SEGUNDA DE BARCELONA ESTADO ANZOANTEGUI', 'Av. 5 de Julio, Centro Comercial Los Ángeles, Piso 1,Locales 23 y 24, frente al Estadium Venezuela, Barcelona.', 'NP679', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (483, 'NOTARÍA PÚBLICA SEGUNDA DEL TIGRE ESTADO ANZOATEGUI', 'Sexta Calle Norte, entre 2da. y 3ra. Carrera Norte, P.A., s/n., frente a la Plaza Miranda, El Tigre', 'NP680', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (484, 'NOTARÍA PÚBLICA DE PARIAGUAN ESTADO ANZOATEGUI', 'Av. Libertador, Sector Aguas Claritas, 3er. Nivel del Centro Comercial Paraíso Plaza, Local Nº A-03-03, Pariaguán.', 'NP681', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (485, 'NOTARÍA PÚBLICA DE GUANARE ESTADO PORTUGUESA', 'Carrera 6, entre Calles 17 y 18, Edif. Ruvenga, Piso 1, Guanare.', 'NP682', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (486, 'NOTARÍA PÚBLICA ANDRES BELLO DEL ESTADO TACHIRA', 'Urb. La Pradera, Calle 11 Nº 6-53 entre Av. Páez y Sucre, Cordero.', 'NP683', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (487, 'NOTARÍA PÚBLICA EL PIÑAL', 'Calle Principal, San Rafael del Piñal, Edif. Expresos Barinas, 2do. Piso, Local 1,  El Piñal.', 'NP684', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (488, 'REGISTRO PÚBLICO DEL TERCER CIRCUITO MUNICIPIO SUCRE ESTADO MIRANDA', '', 'RP900', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (489, 'REGISTRO PÚBLICO DEL CUARTO CIRCUITO MUNICIPIO SUCRE ESTADO MIRANDA', '', 'RP901', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (490, 'REGISTRO PÚBLICO DEL QUINTO CIRCUITO MUNICIPIO SUCRE ESTADO MIRANDA', '', 'RP902', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (491, 'REGISTRO PÚBLICO DEL TERCER CIRCUITO MUNICIPIO CHACAO ESTADO MIRANDA', '', 'RP903', NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.oficina (id_oficina, nombre_oficina, direccion, codigo, telefono, id_parroquia, active, fecha_elim, usr_id) VALUES (2, 'NOTARÍA PÚBLICA PRIMERA DE CARACAS MUNICIPIO LIBERTADOR', 'Av. Lecuna, entre las Esquinas de Velásquez y Miseria, Edificio Torre Profesional del Centro, Plata baja, local 3.', 'NP8', '', NULL, NULL, NULL, NULL);


--
-- TOC entry 3398 (class 0 OID 200588)
-- Dependencies: 249
-- Data for Name: orden_salida; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.orden_salida (id_orden, num_orden, id_solicitud, observacionx, id_emp, id_funcionario, id_equipo, active, fecha_elim, usr_id, fecha_generacion, id_empleado_retira, observacion) VALUES (10016, 2029167, 1, 'lkjh dsljkh ldkj lkjh lkjhsd ljkh sdlhldjh ', 1, 1, NULL, NULL, NULL, NULL, '2019-06-01', NULL, NULL);
INSERT INTO public.orden_salida (id_orden, num_orden, id_solicitud, observacionx, id_emp, id_funcionario, id_equipo, active, fecha_elim, usr_id, fecha_generacion, id_empleado_retira, observacion) VALUES (10017, 2029169, 2, 'jhsdlkhdflkjhdflkjhfd', 2, 1, NULL, NULL, NULL, NULL, '2019-06-01', NULL, NULL);
INSERT INTO public.orden_salida (id_orden, num_orden, id_solicitud, observacionx, id_emp, id_funcionario, id_equipo, active, fecha_elim, usr_id, fecha_generacion, id_empleado_retira, observacion) VALUES (10018, 2029170, 10, 'f34terter ert eergt trytr y', 1, 1, NULL, NULL, NULL, NULL, '2019-06-01', NULL, NULL);
INSERT INTO public.orden_salida (id_orden, num_orden, id_solicitud, observacionx, id_emp, id_funcionario, id_equipo, active, fecha_elim, usr_id, fecha_generacion, id_empleado_retira, observacion) VALUES (10029, 2029189, 9, 'Prueba TRES', 2, 3, NULL, NULL, NULL, NULL, '2019-06-09', NULL, NULL);
INSERT INTO public.orden_salida (id_orden, num_orden, id_solicitud, observacionx, id_emp, id_funcionario, id_equipo, active, fecha_elim, usr_id, fecha_generacion, id_empleado_retira, observacion) VALUES (10030, 2029192, 11, 'Salida de equipos para reparacion en taller Centronix del Centro Sambil', 2, 6, NULL, NULL, NULL, NULL, '2019-06-10', NULL, NULL);
INSERT INTO public.orden_salida (id_orden, num_orden, id_solicitud, observacionx, id_emp, id_funcionario, id_equipo, active, fecha_elim, usr_id, fecha_generacion, id_empleado_retira, observacion) VALUES (10031, 2029193, 12, 'Reparacion de ruedas', 1, 9, NULL, NULL, NULL, NULL, '2019-06-10', NULL, NULL);
INSERT INTO public.orden_salida (id_orden, num_orden, id_solicitud, observacionx, id_emp, id_funcionario, id_equipo, active, fecha_elim, usr_id, fecha_generacion, id_empleado_retira, observacion) VALUES (10032, 2029195, 13, 'hggfjhf', 1, 5, NULL, NULL, NULL, NULL, '2019-06-12', NULL, NULL);
INSERT INTO public.orden_salida (id_orden, num_orden, id_solicitud, observacionx, id_emp, id_funcionario, id_equipo, active, fecha_elim, usr_id, fecha_generacion, id_empleado_retira, observacion) VALUES (10033, 2029196, 14, 'poipoi poi pujgjhg ', 1, 13, NULL, NULL, NULL, NULL, '2019-06-12', NULL, NULL);
INSERT INTO public.orden_salida (id_orden, num_orden, id_solicitud, observacionx, id_emp, id_funcionario, id_equipo, active, fecha_elim, usr_id, fecha_generacion, id_empleado_retira, observacion) VALUES (10034, 2029197, 15, 'Jornada Extendida', 1, 13, NULL, NULL, NULL, NULL, '2019-06-12', NULL, NULL);
INSERT INTO public.orden_salida (id_orden, num_orden, id_solicitud, observacionx, id_emp, id_funcionario, id_equipo, active, fecha_elim, usr_id, fecha_generacion, id_empleado_retira, observacion) VALUES (10035, 2029198, 16, 'Unificacion de jornadas', 2, 13, NULL, NULL, NULL, NULL, '2019-06-12', NULL, NULL);
INSERT INTO public.orden_salida (id_orden, num_orden, id_solicitud, observacionx, id_emp, id_funcionario, id_equipo, active, fecha_elim, usr_id, fecha_generacion, id_empleado_retira, observacion) VALUES (10036, 2029201, 19, 'Retira el mismo funcionario', 1, 13, NULL, NULL, NULL, NULL, '2019-06-14', NULL, NULL);
INSERT INTO public.orden_salida (id_orden, num_orden, id_solicitud, observacionx, id_emp, id_funcionario, id_equipo, active, fecha_elim, usr_id, fecha_generacion, id_empleado_retira, observacion) VALUES (10037, 2029203, 17, NULL, 1, 13, NULL, NULL, NULL, NULL, '2019-06-15', NULL, 'jb  kj zlkj xlkjg zlkj zclkjh zkjh xkjh lzkxjh lkjh lkjzh ');
INSERT INTO public.orden_salida (id_orden, num_orden, id_solicitud, observacionx, id_emp, id_funcionario, id_equipo, active, fecha_elim, usr_id, fecha_generacion, id_empleado_retira, observacion) VALUES (10038, 2029204, 18, NULL, 1, 13, NULL, NULL, NULL, NULL, '2019-06-15', 2, 'ksd hf sdlhsdk lsdk jflkj dlkjh slkj hdslkjhdsa lkj');
INSERT INTO public.orden_salida (id_orden, num_orden, id_solicitud, observacionx, id_emp, id_funcionario, id_equipo, active, fecha_elim, usr_id, fecha_generacion, id_empleado_retira, observacion) VALUES (10039, 2029205, 6, NULL, 1, 3, NULL, NULL, NULL, NULL, '2019-06-15', 1, 'prueba de retiro');
INSERT INTO public.orden_salida (id_orden, num_orden, id_solicitud, observacionx, id_emp, id_funcionario, id_equipo, active, fecha_elim, usr_id, fecha_generacion, id_empleado_retira, observacion) VALUES (10040, 2029206, 7, NULL, 2, 3, NULL, NULL, NULL, NULL, '2019-06-15', 2, 'jg jh kjhg kg kjgkjhg g kjg lkjlkjhs ljkhd ljkh sdlkjhd kjh sfljkhf l jkdh  ljkh lkj h lkjh dlkjdh lkjsdh lkjdf lkjdh lkjh lkjh lkjhd slkjhd lkjh dlkjhf dlkjh ddlkjd lkjdh lkjsdh lkjsdh lkjh dlkjdh lkjd lkjdhlkjdh lkj hlkj hlkjdhlkjhd lkjhd lkjh lkjdh lkjhflkjhf glkjfh lkjh lkjhljkdhsljhflkjdhljkhljfhlfjhlfdjh ldskjh ldjkh ljkdh  lkj ljkh lkjhlkjdhdf');
INSERT INTO public.orden_salida (id_orden, num_orden, id_solicitud, observacionx, id_emp, id_funcionario, id_equipo, active, fecha_elim, usr_id, fecha_generacion, id_empleado_retira, observacion) VALUES (10041, 2029207, 8, NULL, 2, 3, NULL, NULL, NULL, NULL, '2019-06-15', 1, 'What is Lorem Ipsum?

Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry''s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.
Why do we use it?

It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout. The point of using Lorem Ipsum is that it has a more-or-less normal distribution of letters, as opposed to using ''Content here, content here'', making it look like readable English. Many desktop publishing packages and web page editors now use Lorem Ipsum as their default model text, and a search for ''lorem ipsum'' will uncover many web sites still in their infancy. Various versions have evolved over the years, sometimes by accident, sometimes on purpose (injected humour and the like).

Where does it come from?

Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum comes from sections 1.10.32 and 1.10.33 of "de Finibus Bonorum et Malorum" (The Extremes of Good and Evil) by Cicero, written in 45 BC. This book is a treatise on the theory of ethics, very popular during the Renaissance. The first line of Lorem Ipsum, "Lorem ipsum dolor sit amet..", comes from a line in section 1.10.32.

The standard chunk of Lorem Ipsum used since the 1500s is reproduced below for those interested. Sections 1.10.32 and 1.10.33 from "de Finibus Bonorum et Malorum" by Cicero are also reproduced in their exact original form, accompanied by English versions from the 1914 translation by H. Rackham.
Where can I get some?

There are many variations of passages of Lorem Ipsum available, but the majority have suffered alteration in some form, by injected humour, or randomised words which don''t look even slightly believable. If you are going to use a passage of Lorem Ipsum, you need to be sure there isn''t anything embarrassing hidden in the middle of text. All the Lorem Ipsum generators on the Internet tend to repeat predefined chunks as necessary, making this the first true generator on the Internet. It uses a dictionary of over 200 Latin words, combined with a handful of model sentence structures, to generate Lorem Ipsum which looks reasonable. The generated Lorem Ipsum is therefore always free from repetition, injected humour, or non-characteristic words etc.');
INSERT INTO public.orden_salida (id_orden, num_orden, id_solicitud, observacionx, id_emp, id_funcionario, id_equipo, active, fecha_elim, usr_id, fecha_generacion, id_empleado_retira, observacion) VALUES (10042, 2029208, 20, NULL, 1, 4, NULL, NULL, NULL, NULL, '2019-06-15', 2, 'On the other hand, we denounce with righteous indignation and dislike men who are so beguiled and demoralized by the charms of pleasure of the moment, so blinded by desire, that they cannot foresee the pain and trouble that are bound to ensue; and equal blame belongs to those who fail in their duty through weakness of will, which is the same as saying through shrinking from toil and pain. These cases are perfectly simple and easy to distinguish. In a free hour, when our power of choice is untrammelled and when nothing prevents our being able to do what we like best, every pleasure is to be welcomed and every pain avoided. But in certain circumstances and owing to the claims of duty or the obligations of business it will frequently occur that pleasures have to be repudiated and annoyances accepted. The wise man therefore always holds in these matters to this principle of selection: he rejects pleasures to secure other greater pleasures, or else he endures pains to avoid worse pains');
INSERT INTO public.orden_salida (id_orden, num_orden, id_solicitud, observacionx, id_emp, id_funcionario, id_equipo, active, fecha_elim, usr_id, fecha_generacion, id_empleado_retira, observacion) VALUES (10043, 2029209, 21, NULL, 1, 4, NULL, NULL, NULL, NULL, '2019-06-15', 1, 'Retira el mismo funcionario solicitante');
INSERT INTO public.orden_salida (id_orden, num_orden, id_solicitud, observacionx, id_emp, id_funcionario, id_equipo, active, fecha_elim, usr_id, fecha_generacion, id_empleado_retira, observacion) VALUES (10044, 2029217, 24, NULL, 1, 4, NULL, NULL, NULL, NULL, '2019-06-22', 2, 'Retira funcionario adscrito a otra dependencia');
INSERT INTO public.orden_salida (id_orden, num_orden, id_solicitud, observacionx, id_emp, id_funcionario, id_equipo, active, fecha_elim, usr_id, fecha_generacion, id_empleado_retira, observacion) VALUES (10045, 2029218, 25, NULL, 1, 4, NULL, NULL, NULL, NULL, '2019-06-22', 1, 'weqr');
INSERT INTO public.orden_salida (id_orden, num_orden, id_solicitud, observacionx, id_emp, id_funcionario, id_equipo, active, fecha_elim, usr_id, fecha_generacion, id_empleado_retira, observacion) VALUES (10046, 2029219, 26, NULL, 2, 4, NULL, NULL, NULL, NULL, '2019-06-22', 1, 'asdsad');
INSERT INTO public.orden_salida (id_orden, num_orden, id_solicitud, observacionx, id_emp, id_funcionario, id_equipo, active, fecha_elim, usr_id, fecha_generacion, id_empleado_retira, observacion) VALUES (10047, 2029222, 27, NULL, 1, 4, NULL, NULL, NULL, NULL, '2019-06-24', 1, 'sdfsdfsd ');
INSERT INTO public.orden_salida (id_orden, num_orden, id_solicitud, observacionx, id_emp, id_funcionario, id_equipo, active, fecha_elim, usr_id, fecha_generacion, id_empleado_retira, observacion) VALUES (10048, 2029225, 28, NULL, 1, 4, NULL, NULL, NULL, NULL, '2019-06-26', 15, 'Prueba');


--
-- TOC entry 3401 (class 0 OID 200613)
-- Dependencies: 255
-- Data for Name: parroquia; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0101.01', 'ALTAGRACIA', '0101', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0101.02', 'ANTIMANO', '0101', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0101.03', 'CANDELARIA', '0101', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0101.04', 'CARICUAO', '0101', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0101.05', 'CATEDRAL', '0101', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0101.06', 'COCHE', '0101', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0101.07', 'EL JUNQUITO', '0101', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0101.08', 'EL PARAISO', '0101', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0101.09', 'EL RECREO', '0101', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0101.10', 'EL VALLE', '0101', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0101.11', 'LA PASTORA', '0101', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0101.12', 'LA VEGA', '0101', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0101.13', 'MACARAO', '0101', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0101.14', 'SAN AGUSTÍN', '0101', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0101.15', 'SAN BERNARDINO', '0101', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0101.16', 'SAN JOSÉ', '0101', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0101.17', 'SAN JUAN', '0101', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0101.18', 'SAN PEDRO', '0101', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0101.19', 'SANTA ROSALÍA', '0101', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0101.20', 'SANTA TERESA', '0101', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0101.21', 'SUCRE', '0101', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0101.22', '23 DE ENERO', '0101', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0201.01', 'HUACHAMACARE', '0201', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0201.02', 'MARAWAKA', '0201', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0201.03', 'MAVACA', '0201', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0201.04', 'SIERRA PARIMA', '0201', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0202.01', 'UCATA', '0202', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0202.02', 'YAPACANA', '0202', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0202.03', 'CANAME', '0202', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0203.01', 'FERNANDO GIRÓN TOVAR', '0203', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0203.02', 'LUIS ALBERTO GÓMEZ', '0203', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0203.03', 'PARHUEÑA', '0203', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0203.04', 'PLATANILLAL', '0203', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0204.01', 'SAMARIAPO', '0204', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0204.02', 'SIPAPO', '0204', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0204.03', 'MUNDUAPO', '0204', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0204.04', 'GUAYAPO', '0204', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0205.01', 'VICTORINO', '0205', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0205.02', 'COMUNIDAD', '0205', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0206.01', 'ALTO VENTUARI', '0206', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0206.02', 'MEDIO VENTUARI', '0206', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0206.03', 'BAJO VENTUARI', '0206', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0207.01', 'SOLANO', '0207', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0207.02', 'CASIQUIARE', '0207', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0207.03', 'COCUY', '0207', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0301.01', 'CAPITAL ANACO', '0301', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0301.02', 'SAN JOAQUÍN', '0301', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0301.03', 'BUENA VISTA', '0301', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0302.01', 'CAPITAL ARAGUA', '0302', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0302.02', 'CACHIPO', '0302', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0303.01', 'CAPITAL FERNANDO DE PEÑALVER', '0303', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0303.02', 'SAN MIGUEL', '0303', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0303.03', 'SUCRE', '0303', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0304.01', 'CAPITAL FRANCISCO DEL CARMEN CARVAJAL', '0304', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0304.02', 'SANTA BÁRBARA', '0304', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0305.01', 'CAPITAL FRANCISCO DE MIRANDA', '0305', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0305.02', 'ATAPIRIRE', '0305', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0305.03', 'BOCA DEL PAO', '0305', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0305.04', 'EL PAO', '0305', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0305.05', 'MÚCURA', '0305', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0306.01', 'CAPITAL GUANTA', '0306', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0306.02', 'CHORRERÓN', '0306', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0307.01', 'CAPITAL INDEPENDENCIA', '0307', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0307.02', 'MAMO', '0307', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0308.01', 'CAPITAL PUERTO LA CRUZ', '0308', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0308.02', 'POZUELOS', '0308', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0309.01', 'CAPITAL JUAN MANUEL CAJIGAL', '0309', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0309.02', 'SAN PABLO', '0309', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0310.01', 'CAPITAL JOSÉ GREGORIO MONAGAS', '0310', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0310.02', 'PIAR', '0310', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0310.03', 'SAN DIEGO DE CABRUTICA', '0310', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0310.04', 'SANTA CLARA', '0310', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0310.05', 'UVERITO', '0310', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0310.06', 'ZUATA', '0310', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0311.01', 'CAPITAL LIBERTAD', '0311', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0311.02', 'EL CARITO', '0311', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0311.03', 'SANTA INÉS', '0311', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0312.01', 'CAPITAL MANUEL EZEQUIEL BRUZUAL', '0312', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0312.02', 'GUANAPE', '0312', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0312.03', 'SABANA DE UCHIRE', '0312', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0313.01', 'CAPITAL PEDRO MARÍA FRÉITES', '0313', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0313.02', 'LIBERTADOR', '0313', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0313.03', 'SANTA ROSA', '0313', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0313.04', 'URICA', '0313', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0314.01', 'CAPITAL PÍRITU', '0314', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0314.02', 'SAN FRANCISCO', '0314', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0315.01', 'NO TIENE PARROQUIA', '0315', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0316.01', 'CAPITAL SAN JUAN DE CAPISTRANO', '0316', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0316.02', 'BOCA DE CHÁVEZ', '0316', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0317.01', 'CAPITAL SANTA ANA', '0317', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0317.02', 'PUEBLO NUEVO', '0317', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0318.01', 'EL CARMEN', '0318', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0318.02', 'SAN CRISTÓBAL', '0318', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0318.03', 'BERGANTÍN', '0318', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0318.04', 'CAIGUA', '0318', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0318.05', 'EL PILAR', '0318', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0318.06', 'NARICUAL', '0318', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0319.01', 'EDMUNDO BARRIOS', '0319', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0319.02', 'MIGUEL OTERO SILVA', '0319', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0320.01', 'CAPITAL SIR ARTHUR MC GREGOR', '0320', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0320.02', 'TOMÁS ALFARO CALATRAVA', '0320', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0321.01', 'CAPITAL DIEGO BAUTISTA URBANEJA', '0321', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0321.02', 'EL MORRO', '0321', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0401.01', 'URBANA ACHAGUAS', '0401', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0401.02', 'APURITO', '0401', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0401.03', 'EL YAGUAL', '0401', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0401.04', 'GUACHARA', '0401', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0401.05', 'MUCURITAS EL', '0401', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0401.06', 'QUESERAS DEL MEDIO', '0401', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0402.01', 'URBANA BIRUACA', '0402', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0403.01', 'URBANA BRUZUAL', '0403', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0403.02', 'MANTECAL', '0403', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0403.03', 'QUINTERO', '0403', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0403.04', 'RINCÓN HONDO', '0403', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0403.05', 'SAN VICENTE', '0403', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0404.01', 'URBANA GUASDUALITO', '0404', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0404.02', 'ARAMENDI', '0404', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0404.03', 'EL AMPARO', '0404', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0404.04', 'SAN CAMILO', '0404', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0404.05', 'URDANETA', '0404', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0405.01', 'URBANA SAN JUAN DE PAYARA', '0405', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0405.02', 'CODAZZI', '0405', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0405.03', 'CUNAVICHE', '0405', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0406.01', 'URBANA ELORZA', '0406', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0406.02', 'LA TRINIDAD', '0406', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0407.01', 'URBANA SAN FERNANDO', '0407', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0407.02', 'EL RECREO', '0407', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0407.03', 'PEÑALVER', '0407', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0407.04', 'SAN RAFAEL DE ATAMAICA', '0407', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0501.01', 'NO TIENE PARROQUIA', '0501', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0502.01', 'CAMATAGUA', '0502', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0502.02', 'NO URBANA CARMEN DE CURA', '0502', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0503.02', 'NO URBANA CHORONÍ', '0503', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0503.03', 'URBANA LAS DELICIAS', '0503', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0503.04', 'URBANA MADRE MARÍA DE SAN JOSÉ', '0503', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0503.05', 'URBANA JOAQUÍN CRESPO', '0503', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0503.06', 'URBANA PEDRO JOSÉ OVALLES', '0503', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0503.07', 'URBANA JOSÉ CASANOVA GODOY', '0503', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0503.08', 'URBANA ANDRÉS ELOY BLANCO', '0503', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0503.09', 'URBANA LOS TACARIGUAS', '0503', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0504.01', 'NO TIENE PARROQUIA', '0504', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0505.01', 'URBANA JUAN VICENTE BOLÍVAR Y PONTE', '0505', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0505.02', 'URBANA CASTOR NIEVES RÍOS', '0505', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0505.03', 'NO URBANA LAS GUACAMAYAS', '0505', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0505.04', 'NO URBANA PAO DE ZÁRATE', '0505', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0505.05', 'NO URBANA ZUATA', '0505', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0506.01', 'NO TIENE PARROQUIA', '0506', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0507.01', 'LIBERTADOR', '0507', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0507.02', 'NO URBANA SAN MARTÍN DE PORRES', '0507', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0508.01', 'MARIO BRICEÑO IRAGORRY', '0508', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0508.02', 'URBANA CAÑA DE AZÚCAR', '0508', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0509.01', 'SAN CASIMIRO', '0509', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0509.02', 'NO URBANA', '0509', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0509.03', 'NO URBANA OLLAS DE CARAMACATE', '0509', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0509.04', 'NO URBANA VALLE MORÍN', '0509', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0510.01', 'NO TIENE PARROQUIA', '0510', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0511.01', 'SANTIAGO MARIÑO', '0511', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0511.02', 'NO URBANA ARÉVALO APONTE', '0511', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0511.03', 'NO URBANA CHUAO', '0511', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0511.04', 'NO URBANA SAMÁN DE GÜERE', '0511', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0511.05', 'NO URBANA ALFREDO PACHECO MIRANDA', '0511', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0512.01', 'SANTOS MICHELENA', '0512', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0512.02', 'NO URBANA TIARA', '0512', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0513.01', 'SUCRE', '0513', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0513.02', 'NO URBANA BELLA VISTA', '0513', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0514.01', 'NO TIENE PARROQUIA', '0514', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0515.01', 'URDANETA', '0515', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0515.02', 'NO URBANA LAS PEÑITAS', '0515', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0515.03', 'NO URBANA SAN FRANCISCO DE CARA', '0515', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0515.04', 'NO URBANA TAGUAY', '0515', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0516.01', 'ZAMORA', '0516', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0516.02', 'NO URBANA MAGDALENO', '0516', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0516.03', 'NO URBANA SAN FRANCISCO DE ASÍS', '0516', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0516.04', 'NO URBANA VALLES DE TUCUTUNEMO', '0516', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0516.05', 'NO URBANA AUGUSTO MIJARES', '0516', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0517.01', 'FRANCISCO LINARES ALCÁNTARA', '0517', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0517.02', 'NO URBANA FRANCISCO DE MIRANDA', '0517', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0517.03', 'NO URBANA MONSEÑOR FELICIANO GONZÁLEZ', '0517', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0518.01', 'NO TIENE PARROQUIA', '0518', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0601.01', 'SABANETA', '0601', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0601.02', 'RODRÍGUEZ DOMÍNGUEZ', '0601', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0602.01', 'TICOPORO', '0602', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0602.02', 'ANDRÉS BELLO', '0602', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0602.03', 'NICOLÁS PULIDO', '0602', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0603.01', 'ARISMENDI', '0603', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0603.02', 'GUADARRAMA', '0603', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0603.03', 'LA UNIÓN', '0603', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0603.04', 'SAN ANTONIO', '0603', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0604.01', 'BARINAS', '0604', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0604.02', 'ALFREDO ARVELO LARRIVA', '0604', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0604.03', 'SAN SILVESTRE', '0604', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0604.04', 'SANTA INÉS', '0604', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0604.05', 'SANTA LUCÍA', '0604', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0604.06', 'TORUNOS', '0604', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0604.07', 'EL CARMEN', '0604', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0604.08', 'DON RÓMULO BETANCOURT', '0604', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0604.09', 'CORAZÓN DE JESÚS', '0604', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0604.10', 'RAMÓN IGNACIO MÉNDEZ', '0604', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0604.11', 'ALTO BARINAS', '0604', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0604.12', 'MANUEL PALACIO FAJARDO', '0604', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0604.13', 'JUAN ANTONIO RODRÍGUEZ DOMÍNGUEZ', '0604', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0604.14', 'DOMINGA ORTIZ DE PÁEZ', '0604', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0605.01', 'BARINITAS', '0605', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0605.02', 'ALTAMIRA', '0605', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0605.03', 'CALDERAS', '0605', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0606.01', 'BARRANCAS', '0606', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0606.02', 'EL SOCORRO', '0606', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0606.03', 'MASPARRITO', '0606', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0607.01', 'SANTA BÁRBARA', '0607', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0607.02', 'JOSÉ IGNACIO DEL PUMAR', '0607', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0607.03', 'PEDRO BRICEÑO MÉNDEZ', '0607', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0607.04', 'RAMÓN IGNACIO MÉNDEZ', '0607', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0608.01', 'OBISPOS', '0608', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0608.02', 'EL REAL', '0608', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0608.03', 'LA LUZ', '0608', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0608.04', 'LOS GUASIMITOS', '0608', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0609.01', 'CIUDAD BOLIVIA', '0609', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0609.02', 'IGNACIO BRICEÑO', '0609', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0609.03', 'JOSÉ FÉLIX RIBAS', '0609', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0609.04', 'PÁEZ', '0609', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0610.01', 'LIBERTAD', '0610', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0610.02', 'DOLORES', '0610', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0610.03', 'PALACIOS FAJARDO', '0610', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0610.04', 'SANTA ROSA', '0610', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0610.05', 'SIMÓN RODRÍGUEZ', '0610', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0611.01', 'CIUDAD DE NUTRIAS', '0611', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0611.02', 'EL REGALO', '0611', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0611.03', 'PUERTO DE NUTRIAS', '0611', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0611.04', 'SANTA CATALINA', '0611', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0611.05', 'SIMÓN BOLÍVAR', '0611', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0612.01', 'EL CANTÓN', '0612', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0612.02', 'SANTA CRUZ DE GUACAS', '0612', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0612.03', 'PUERTO VIVAS', '0612', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0701.01', 'CACHAMAY', '0701', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0701.02', 'CHIRICA', '0701', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0701.03', 'DALLA COSTA', '0701', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0701.04', 'ONCE DE ABRIL', '0701', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0701.05', 'SIMÓN BOLÍVAR', '0701', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0701.06', 'UNARE', '0701', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0701.07', 'UNIVERSIDAD', '0701', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0701.08', 'VISTA AL SOL', '0701', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0701.09', 'POZO VERDE', '0701', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0701.10', 'YOCOIMA', '0701', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0701.11', 'CINCO DE JULIO', '0701', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0702.01', 'SECCIÓN CAPITAL CEDEÑO', '0702', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0702.02', 'ALTAGRACIA', '0702', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0702.03', 'ASCENSIÓN FARRERAS', '0702', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0702.04', 'GUANIAMO', '0702', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0702.05', 'LA URBANA', '0702', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0702.06', 'PIJIGUAOS', '0702', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0703.01', 'NO TIENE PARROQUIA', '0703', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0704.01', 'SECCIÓN CAPITAL GRAN SABANA', '0704', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0704.02', 'IKABARÚ', '0704', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0705.01', 'AGUA SALADA', '0705', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0705.02', 'CATEDRAL', '0705', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0705.03', 'JOSÉ ANTONIO PÁEZ', '0705', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0705.04', 'LA SABANITA', '0705', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0705.05', 'MARHUANTA', '0705', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0705.06', 'VISTA HERMOSA', '0705', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0705.07', 'ORINOCO', '0705', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0705.08', 'PANAPANA', '0705', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0705.09', 'ZEA', '0705', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0706.01', 'SECCIÓN CAPITAL PIAR', '0706', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0706.02', 'ANDRÉS ELOY BLANCO', '0706', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0706.03', 'PEDRO COVA', '0706', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0707.01', 'SECCIÓN CAPITAL ANGOSTURA', '0707', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0707.02', 'BARCELONETA', '0707', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0707.03', 'SAN FRANCISCO', '0707', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0707.04', 'SANTA BÁRBARA', '0707', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0708.01', 'SECCIÓN CAPITAL ROSCIO', '0708', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0708.02', 'SALOM', '0708', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0709.01', 'SECCIÓN CAPITAL SIFONTES', '0709', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0709.02', 'DALLA COSTA', '0709', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0709.03', 'SAN ISIDRO', '0709', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0710.01', 'SECCIÓN CAPITAL SUCRE', '0710', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0710.02', 'ARIPAO', '0710', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0710.03', 'GUARATARO', '0710', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0710.04', 'LAS MAJADAS', '0710', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0710.05', 'MOITACO', '0710', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0711.01', 'NO TIENE PARROQUIA', '0711', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0801.01', 'URBANA BEJUMA', '0801', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0801.02', 'NO URBANA CANOABO', '0801', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0801.03', 'NO URBANA SIMÓN BOLÍVAR', '0801', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0802.01', 'URBANA GÜIGÜE', '0802', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0802.02', 'NO URBANA BELÉN', '0802', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0802.03', 'NO URBANA TACARIGUA', '0802', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0803.01', 'URBANA AGUAS CALIENTES', '0803', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0803.02', 'URBANA MARIARA', '0803', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0804.01', 'URBANA CIUDAD ALIANZA', '0804', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0804.02', 'URBANA GUACARA', '0804', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0804.03', 'NO URBANA YAGUA', '0804', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0805.01', 'URBANA MORÓN', '0805', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0805.02', 'NO URBANA URAMA', '0805', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0806.01', 'URBANA TOCUYITO', '0806', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0806.02', 'URBANA INDEPENDENCIA', '0806', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0807.01', 'URBANA LOS GUAYOS', '0807', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0808.01', 'URBANA MIRANDA', '0808', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0809.01', 'URBANA MONTALBÁN', '0809', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0810.01', 'URBANA NAGUANAGUA', '0810', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0811.01', 'URBANA BARTOLOMÉ SALOM', '0811', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0811.02', 'URBANA DEMOCRACIA', '0811', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0811.03', 'URBANA FRATERNIDAD', '0811', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0811.04', 'URBANA GOAIGOAZA', '0811', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0811.05', 'URBANA JUAN JOSÉ FLORES', '0811', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0811.06', 'URBANA UNIÓN', '0811', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0811.07', 'NO URBANA BORBURATA', '0811', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0811.08', 'NO URBANA PATANEMO', '0811', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0812.01', 'URBANA SAN DIEGO', '0812', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0813.01', 'URBANA SAN JOAQUÍN', '0813', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0814.01', 'URBANA CANDELARIA', '0814', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0814.02', 'URBANA CATEDRAL', '0814', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0814.03', 'URBANA EL SOCORRO', '0814', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0814.04', 'URBANA MIGUEL PEÑA', '0814', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0814.05', 'URBANA RAFAEL URDANETA', '0814', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0814.06', 'URBANA SAN BLAS', '0814', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0814.07', 'URBANA SAN JOSÉ', '0814', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0814.08', 'URBANA SANTA ROSA', '0814', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0814.09', 'NO URBANA NEGRO PRIMERO', '0814', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0901.01', 'COJEDES', '0901', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0901.02', 'JUAN DE MATA SUÁREZ', '0901', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0902.01', 'TINAQUILLO', '0902', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0903.01', 'EL BAÚL', '0903', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0903.02', 'SUCRE', '0903', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0904.01', 'MACAPO', '0904', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0904.02', 'LA AGUADITA', '0904', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0905.01', 'EL PAO', '0905', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0906.01', 'LIBERTAD DE COJEDES', '0906', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0906.02', 'EL AMPARO', '0906', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0907.01', 'RÓMULO GALLEGOS', '0907', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0908.01', 'SAN CARLOS DE AUSTRIA', '0908', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0908.02', 'JUAN ÁNGEL BRAVO', '0908', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0908.03', 'MANUEL MANRIQUE', '0908', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('0909.01', 'GENERAL EN JEFE JOSÉ LAURENCIO SILVA', '0909', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1001.01', 'CURIAPO', '1001', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1001.02', 'ALMIRANTE LUIS BRIÓN', '1001', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1001.03', 'FRANCISCO ANICETO LUGO', '1001', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1001.04', 'MANUEL RENAUD', '1001', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1001.05', 'PADRE BARRAL', '1001', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1001.06', 'SANTOS DE ABELGAS', '1001', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1002.01', 'IMATACA', '1002', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1002.02', 'CINCO DE JULIO', '1002', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1002.03', 'JUAN BAUTISTA ARISMENDI', '1002', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1002.04', 'MANUEL PIAR', '1002', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1002.05', 'RÓMULO GALLEGOS', '1002', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1003.01', 'PEDERNALES', '1003', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1003.02', 'LUIS BELTRÁN PRIETO FIGUEROA', '1003', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1004.01', 'SAN JOSÉ', '1004', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1004.02', 'JOSÉ VIDAL MARCANO', '1004', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1004.03', 'JUAN MILLÁN', '1004', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1004.04', 'LEONARDO RUÍZ PINEDA', '1004', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1004.05', 'MARISCAL ANTONIO JOSÉ DE SUCRE', '1004', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1004.06', 'MONSEÑOR ARGIMIRO GARCÍA', '1004', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1004.07', 'SAN RAFAEL', '1004', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1004.08', 'VIRGEN DEL VALLE', '1004', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1101.01', 'SAN JUAN DE LOS CAYOS', '1101', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1101.02', 'CAPADARE', '1101', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1101.03', 'LA PASTORA', '1101', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1101.04', 'LIBERTADOR', '1101', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1102.01', 'SAN LUIS', '1102', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1102.02', 'ARACUA', '1102', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1102.03', 'LA PEÑA', '1102', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1103.01', 'CAPATÁRIDA', '1103', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1103.02', 'BARIRO', '1103', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1103.03', 'BOROJÓ', '1103', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1103.04', 'GUAJIRO', '1103', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1103.05', 'SEQUE', '1103', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1103.06', 'ZAZÁRIDA', '1103', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1104.01', 'NO TIENE PARROQUIA', '1104', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1105.01', 'CARIRUBANA', '1105', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1105.02', 'NORTE', '1105', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1105.03', 'PUNTA CARDÓN', '1105', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1105.04', 'SANTA ANA', '1105', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1106.01', 'LA VELA DE CORO', '1106', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1106.02', 'ACURIGUA', '1106', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1106.03', 'GUAIBACOA', '1106', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1106.04', 'LAS CALDERAS', '1106', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1106.05', 'MACORUCA', '1106', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1107.01', 'NO TIENE PARROQUIA', '1107', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1108.01', 'PEDREGAL', '1108', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1108.02', 'AGUA CLARA', '1108', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1108.03', 'AVARIA', '1108', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1108.04', 'PIEDRA GRANDE', '1108', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1108.05', 'PURURECHE', '1108', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1109.01', 'PUEBLO NUEVO', '1109', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1109.02', 'ADÍCORA', '1109', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1109.03', 'BARAIVED', '1109', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1109.04', 'BUENA VISTA', '1109', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1109.05', 'JADACAQUIVA', '1109', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1109.06', 'MORUY', '1109', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1109.07', 'ADAURE', '1109', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1109.08', 'EL HATO', '1109', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1109.09', 'EL VÍNCULO', '1109', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1110.01', 'CHURUGUARA', '1110', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1110.02', 'AGUA LARGA', '1110', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1110.03', 'EL PAUJÍ', '1110', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1110.04', 'INDEPENDENCIA', '1110', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1110.05', 'MAPARARÍ', '1110', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1111.01', 'JACURA', '1111', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1111.02', 'AGUA LINDA', '1111', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1111.03', 'ARAURIMA', '1111', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1112.01', 'LOS TAQUES', '1112', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1112.02', 'JUDIBANA', '1112', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1113.01', 'MENE DE MAUROA', '1113', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1113.02', 'CASIGUA', '1113', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1113.03', 'SAN FÉLIX', '1113', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1114.01', 'SAN ANTONIO', '1114', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1114.02', 'SAN GABRIEL', '1114', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1114.03', 'SANTA ANA', '1114', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1114.04', 'GUZMÁN GUILLERMO', '1114', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1114.05', 'MITARE', '1114', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1114.06', 'RÍO SECO', '1114', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1114.07', 'SABANETA', '1114', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1115.01', 'CHICHIRIVICHE', '1115', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1115.02', 'BOCA DE TOCUYO', '1115', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1115.03', 'TOCUYO DE LA COSTA', '1115', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1116.01', 'NO TIENE PARROQUIA', '1116', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1117.01', 'CABURE', '1117', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1117.02', 'COLINA', '1117', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1117.03', 'CURIMAGUA', '1117', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1118.01', 'PÍRITU', '1118', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1118.02', 'SAN JOSÉ DE LA COSTA', '1118', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1119.01', 'NO TIENE PARROQUIA', '1119', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1120.01', 'TUCACAS', '1120', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1120.02', 'BOCA DE AROA', '1120', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1121.01', 'SUCRE', '1121', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1121.02', 'PECAYA', '1121', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1122.01', 'NO TIENE PARROQUIA', '1122', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1123.01', 'SANTA CRUZ DE BUCARAL', '1123', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1123.02', 'EL CHARAL', '1123', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1123.03', 'LAS VEGAS DEL TUY', '1123', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1124.01', 'URUMACO', '1124', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1124.02', 'BRUZUAL', '1124', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1125.01', 'PUERTO CUMAREBO', '1125', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1125.02', 'LA CIÉNAGA', '1125', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1125.03', 'LA SOLEDAD', '1125', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1125.04', 'PUEBLO CUMAREBO', '1125', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1125.05', 'ZAZÁRIDA', '1125', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1201.01', 'CAPITAL CAMAGUÁN', '1201', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1201.02', 'PUERTO MIRANDA', '1201', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1201.03', 'UVERITO', '1201', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1202.01', 'CHAGUARAMAS', '1202', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1203.01', 'EL SOCORRO', '1203', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1204.01', 'CAPITAL SAN GERÓNIMO DE GUAYABAL', '1204', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1204.02', 'CAZORLA', '1204', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1205.01', 'CAPITAL VALLE DE LA PASCUA', '1205', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1205.02', 'ESPINO', '1205', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1206.01', 'CAPITAL LAS MERCEDES', '1206', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1206.02', 'CABRUTA', '1206', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1206.03', 'SANTA RITA DE MANAPIRE', '1206', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1207.01', 'CAPITAL EL SOMBRERO', '1207', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1207.02', 'SOSA', '1207', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1208.01', 'CAPITAL CALABOZO', '1208', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1208.02', 'EL CALVARIO', '1208', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1208.03', 'EL RASTRO', '1208', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1208.04', 'GUARDATINAJAS', '1208', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1209.01', 'CAPITAL ALTAGRACIA DE ORITUCO', '1209', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1209.02', 'LEZAMA', '1209', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1209.03', 'LIBERTAD DE ORITUCO', '1209', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1209.04', 'PASO REAL DE MACAIRA', '1209', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1209.05', 'SAN FRANCISCO DE MACAIRA', '1209', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1209.06', 'SAN RAFAEL DE ORITUCO', '1209', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1209.07', 'SOUBLETTE', '1209', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1210.01', 'CAPITAL ORTIZ', '1210', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1210.02', 'SAN FRANCISCO DE TIZNADO', '1210', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1210.03', 'SAN JOSÉ DE TIZNADO', '1210', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1210.04', 'SAN LORENZO DE TIZNADO', '1210', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1211.01', 'CAPITAL TUCUPIDO', '1211', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1211.02', 'SAN RAFAEL DE LAYA', '1211', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1212.01', 'CAPITAL SAN JUAN DE LOS MORROS', '1212', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1212.02', 'CANTAGALLO', '1212', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1212.03', 'PARAPARA', '1212', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1213.01', 'SAN JOSÉ DE GUARIBE', '1213', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1214.01', 'CAPITAL SANTA MARÍA DE IPIRE', '1214', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1214.02', 'ALTAMIRA', '1214', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1215.01', 'CAPITAL ZARAZA', '1215', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1215.02', 'SAN JOSÉ DE UNARE', '1215', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1301.01', 'PÍO TAMAYO', '1301', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1301.02', 'QUEBRADA HONDA DE GUACHE', '1301', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1301.03', 'YACAMBÚ', '1301', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1302.01', 'FRÉITEZ', '1302', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1302.02', 'JOSÉ MARÍA BLANCO', '1302', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1303.01', 'CATEDRAL', '1303', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1303.02', 'CONCEPCIÓN', '1303', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1303.03', 'EL CUJÍ', '1303', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1303.04', 'JUAN DE VILLEGAS', '1303', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1303.05', 'SANTA ROSA', '1303', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1303.06', 'TAMACA', '1303', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1303.07', 'UNIÓN', '1303', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1303.08', 'AGUEDO FELIPE ALVARADO', '1303', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1303.09', 'BUENA VISTA', '1303', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1303.10', 'JUÁREZ', '1303', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1304.01', 'JUAN BAUTISTA RODRÍGUEZ', '1304', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1304.02', 'CUARA', '1304', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1304.03', 'DIEGO DE LOZADA', '1304', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1304.04', 'PARAÍSO DE SAN JOSÉ', '1304', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1304.05', 'SAN MIGUEL', '1304', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1304.06', 'TINTORERO', '1304', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1304.07', 'JOSÉ BERNARDO DORANTE', '1304', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1304.08', 'CORONEL MARIANO PERAZA', '1304', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1305.01', 'BOLÍVAR', '1305', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1305.02', 'ANZOÁTEGUI', '1305', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1305.03', 'GUARICO', '1305', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1305.04', 'HILARIO LUNA Y LUNA', '1305', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1305.05', 'HUMOCARO ALTO', '1305', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1305.06', 'HUMOCARO BAJO', '1305', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1305.07', 'LA CANDELARIA', '1305', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1305.08', 'MORÁN', '1305', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1306.01', 'CABUDARE', '1306', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1306.02', 'JOSÉ GREGORIO BASTIDAS', '1306', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1306.03', 'AGUA VIVA', '1306', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1307.01', 'SARARE', '1307', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1307.02', 'BURÍA', '1307', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1307.03', 'GUSTAVO VEGAS LEÓN', '1307', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1308.01', 'TRINIDAD SAMUEL', '1308', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1308.02', 'ANTONIO DÍAZ', '1308', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1308.03', 'CAMACARO', '1308', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1308.04', 'CASTAÑEDA', '1308', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1308.05', 'CECILIO ZUBILLAGA', '1308', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1308.06', 'CHIQUINQUIRÁ', '1308', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1308.07', 'EL BLANCO', '1308', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1308.08', 'ESPINOZA DE LOS MONTEROS', '1308', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1308.09', 'LARA', '1308', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1308.10', 'LAS MERCEDES', '1308', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1308.11', 'MANUEL MORILLO', '1308', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1308.12', 'MONTAÑA VERDE', '1308', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1308.13', 'MONTES DE OCA', '1308', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1308.14', 'TORRES', '1308', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1308.15', 'HERIBERTO ARROYO', '1308', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1308.16', 'REYES VARGAS', '1308', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1308.17', 'ALTAGRACIA', '1308', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1309.01', 'SIQUISIQUE', '1309', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1309.02', 'MOROTURO', '1309', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1309.03', 'SAN MIGUEL', '1309', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1309.04', 'XAGUAS', '1309', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1401.01', 'PRESIDENTE BETANCOURT', '1401', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1401.02', 'PRESIDENTE PÁEZ', '1401', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1401.03', 'PRESIDENTE RÓMULO GALLEGOS', '1401', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1401.04', 'GABRIEL PICÓN GONZÁLEZ', '1401', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1401.05', 'HÉCTOR AMABLE MORA', '1401', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1401.06', 'JOSÉ NUCETE SARDI', '1401', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1401.07', 'PULIDO MÉNDEZ', '1401', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1402.01', 'NO TIENE PARROQUIA', '1402', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1403.01', 'CAPITAL ANTONIO PINTO SALINAS', '1403', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1403.02', 'MESA BOLÍVAR', '1403', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1403.03', 'MESA DE LAS PALMAS', '1403', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1404.01', 'CAPITAL ARICAGUA', '1404', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1404.02', 'SAN ANTONIO', '1404', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1405.01', 'CAPITAL ARZOBISPO CHACÓN', '1405', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1405.02', 'CAPURÍ', '1405', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1405.03', 'CHACANTÁ', '1405', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1405.04', 'EL MOLINO', '1405', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1405.05', 'GUAIMARAL', '1405', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1405.06', 'MUCUTUY', '1405', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1405.07', 'MUCUCHACHÍ', '1405', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1406.01', 'FERNÁNDEZ PEÑA', '1406', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1406.02', 'MATRIZ', '1406', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1406.03', 'MONTALBÁN', '1406', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1406.04', 'ACEQUIAS', '1406', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1406.05', 'JAJÍ', '1406', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1406.06', 'LA MESA', '1406', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1406.07', 'SAN JOSÉ DEL SUR', '1406', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1407.01', 'CAPITAL CARACCIOLO PARRA OLMEDO', '1407', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1407.02', 'FLORENCIO RAMÍREZ EL PINAR', '1407', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1408.01', 'CAPITAL CARDENAL QUINTERO', '1408', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1408.02', 'LAS PIEDRAS', '1408', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1409.01', 'CAPITAL GUARAQUE', '1409', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1409.02', 'MESA DE QUINTERO', '1409', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1409.03', 'RÍO NEGRO', '1409', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1410.01', 'CAPITAL JULIO CÉSAR SALAS', '1410', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1410.02', 'PALMIRA', '1410', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1411.01', 'CAPITAL JUSTO BRICEÑO', '1411', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1411.02', 'SAN CRISTÓBAL DE TORONDOY', '1411', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1412.01', 'ANTONIO SPINETTI DINI', '1412', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1412.02', 'ARIAS', '1412', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1412.03', 'CARACCIOLO PARRA PÉREZ', '1412', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1412.04', 'DOMINGO PEÑA', '1412', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1412.05', 'EL LLANO', '1412', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1412.06', 'GONZALO PICÓN FEBRES', '1412', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1412.07', 'JACINTO PLAZA', '1412', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1412.08', 'JUAN RODRÍGUEZ SUÁREZ', '1412', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1412.09', 'LASSO DE LA VEGA', '1412', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1412.10', 'MARIANO PICÓN SALAS', '1412', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1412.11', 'MILLA', '1412', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1412.12', 'OSUNA RODRÍGUEZ', '1412', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1412.13', 'SAGRARIO', '1412', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1412.14', 'EL MORRO', '1412', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1412.15', 'LOS NEVADOS', '1412', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1413.01', 'CAPITAL MIRANDA', '1413', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1413.02', 'ANDRÉS ELOY BLANCO', '1413', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1413.03', 'LA VENTA', '1413', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1413.04', 'PIÑANGO', '1413', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1414.01', 'CAPITAL OBISPO RAMOS DE LORA', '1414', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1414.02', 'ELOY PAREDES', '1414', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1414.03', 'SAN RAFAEL DE ALCÁZAR', '1414', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1415.01', 'NO TIENE PARROQUIA', '1415', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1416.01', 'NO TIENE PARROQUIA', '1416', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1417.01', 'CAPITAL RANGEL', '1417', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1417.02', 'CACUTE', '1417', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1417.03', 'LA TOMA', '1417', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1417.04', 'MUCURUBÁ', '1417', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1417.05', 'SAN RAFAEL', '1417', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1418.01', 'CAPITAL RIVAS DÁVILA', '1418', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1418.02', 'GERÓNIMO MALDONADO', '1418', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1419.01', 'NO TIENE PARROQUIA', '1419', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1420.01', 'CAPITAL SUCRE', '1420', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1420.02', 'CHIGUARÁ', '1420', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1420.03', 'ESTÁNQUES', '1420', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1420.04', 'LA TRAMPA', '1420', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1420.05', 'PUEBLO NUEVO DEL SUR', '1420', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1420.06', 'SAN JUAN', '1420', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1421.01', 'EL AMPARO', '1421', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1421.02', 'EL LLANO', '1421', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1421.03', 'SAN FRANCISCO', '1421', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1421.04', 'TOVAR', '1421', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1422.01', 'CAPITAL TULIO FEBRES CORDERO', '1422', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1422.02', 'INDEPENDENCIA', '1422', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1422.03', 'MARÍA DE LA CONCEPCIÓN PALACIOS BLANCO', '1422', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1422.04', 'SANTA APOLONIA', '1422', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1423.01', 'CAPITAL ZEA', '1423', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1423.02', 'CAÑO EL TIGRE', '1423', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1501.01', 'CAUCAGUA', '1501', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1501.02', 'ARAGÜITA', '1501', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1501.03', 'ARÉVALO GONZÁLEZ', '1501', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1501.04', 'CAPAYA', '1501', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1501.05', 'EL CAFÉ', '1501', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1501.06', 'MARIZAPA', '1501', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1501.07', 'PANAQUIRE', '1501', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1501.08', 'RIBAS', '1501', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1502.01', 'SAN JOSÉ DE BARLOVENTO', '1502', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1502.02', 'CUMBO', '1502', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1503.01', 'NUESTRA SEÑORA DEL ROSARIO DE BARUTA', '1503', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1503.02', 'EL CAFETAL', '1503', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1503.03', 'LAS MINAS DE BARUTA', '1503', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1504.01', 'HIGUEROTE', '1504', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1504.02', 'CURIEPE', '1504', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1504.03', 'TACARIGUA', '1504', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1505.01', 'MAMPORAL', '1505', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1506.01', 'CARRIZAL', '1506', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1507.01', 'CHACAO', '1507', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1508.01', 'CHARALLAVE', '1508', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1508.02', 'LAS BRISAS', '1508', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1509.01', 'EL HATILLO', '1509', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1510.01', 'LOS TEQUES', '1510', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1510.02', 'ALTAGRACIA DE LA MONTAÑA', '1510', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1510.03', 'CECILIO ACOSTA', '1510', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1510.04', 'EL JARILLO', '1510', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1510.05', 'PARACOTOS', '1510', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1510.06', 'SAN PEDRO', '1510', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1510.07', 'TÁCATA', '1510', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1511.01', 'SANTA TERESA DEL TUY', '1511', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1511.02', 'EL CARTANAL', '1511', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1512.01', 'OCUMARE DEL TUY', '1512', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1512.02', 'LA DEMOCRACIA', '1512', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1512.03', 'SANTA BÁRBARA', '1512', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1513.01', 'SAN ANTONIO DE LOS ALTOS', '1513', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1514.01', 'RÍO CHICO', '1514', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1514.02', 'EL GUAPO', '1514', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1514.03', 'TACARIGUA DE LA LAGUNA', '1514', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1514.04', 'PAPARO', '1514', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1514.05', 'SAN FERNANDO DEL GUAPO', '1514', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1515.01', 'SANTA LUCÍA', '1515', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1516.01', 'CÚPIRA', '1516', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1516.02', 'MACHURUCUTO', '1516', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1517.01', 'GUARENAS', '1517', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1518.01', 'SAN FRANCISCO DE YARE', '1518', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1518.02', 'SAN ANTONIO DE YARE', '1518', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1519.01', 'PETARE', '1519', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1519.02', 'CAUCAGÜITA', '1519', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1519.03', 'FILA DE MARICHE', '1519', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1519.04', 'LA DOLORITA', '1519', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1519.05', 'LEONCIO MARTÍNEZ', '1519', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1520.01', 'CÚA', '1520', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1520.02', 'NUEVA CÚA', '1520', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1521.01', 'GUATIRE', '1521', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1521.02', 'BOLÍVAR', '1521', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1601.01', 'CAPITAL ACOSTA', '1601', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1601.02', 'SAN FRANCISCO', '1601', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1602.01', 'NO TIENE PARROQUIA', '1602', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1603.01', 'NO TIENE PARROQUIA', '1603', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1604.01', 'CAPITAL CARIPE', '1604', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1604.02', 'EL GUÁCHARO', '1604', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1604.03', 'LA GUANOTA', '1604', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1604.04', 'SABANA DE PIEDRA', '1604', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1604.05', 'SAN AGUSTÍN', '1604', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1604.06', 'TERESÉN', '1604', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1605.01', 'CAPITAL CEDEÑO', '1605', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1605.02', 'AREO', '1605', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1605.03', 'SAN FÉLIX', '1605', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1605.04', 'VIENTO FRESCO', '1605', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1606.01', 'CAPITAL EZEQUIEL ZAMORA', '1606', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1606.02', 'EL TEJERO', '1606', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1607.01', 'CAPITAL LIBERTADOR', '1607', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1607.02', 'CHAGUARAMAS', '1607', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1607.03', 'LAS ALHUACAS', '1607', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1607.04', 'TABASCA', '1607', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1608.01', 'CAPITAL MATURÍN', '1608', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1608.02', 'ALTO DE LOS GODOS', '1608', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1608.03', 'BOQUERÓN', '1608', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1608.04', 'LAS COCUIZAS', '1608', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1608.05', 'SAN SIMÓN', '1608', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1608.06', 'SANTA CRUZ', '1608', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1608.07', 'EL COROZO', '1608', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1608.08', 'EL FURRIAL', '1608', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1608.09', 'JUSEPÍN', '1608', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1608.10', 'LA PICA', '1608', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1608.11', 'SAN VICENTE', '1608', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1609.01', 'CAPITAL PIAR', '1609', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1609.02', 'APARICIO', '1609', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1609.03', 'CHAGUARAMAL', '1609', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1609.04', 'EL PINTO', '1609', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1609.05', 'GUANAGUANA', '1609', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1609.06', 'LA TOSCANA', '1609', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1609.07', 'TAGUAYA', '1609', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1610.01', 'CAPITAL PUNCERES', '1610', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1610.02', 'CACHIPO', '1610', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1611.01', 'NO TIENE PARROQUIA', '1611', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1612.01', 'CAPITAL SOTILLO', '1612', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1612.02', 'LOS BARRANCOS DE FAJARDO', '1612', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1613.01', 'NO TIENE PARROQUIA', '1613', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1701.01', 'NO TIENE PARROQUIA', '1701', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1702.01', 'NO TIENE PARROQUIA', '1702', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1703.01', 'CAPITAL DÍAZ', '1703', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1703.02', 'ZABALA', '1703', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1704.01', 'CAPITAL GARCÍA', '1704', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1704.02', 'FRANCISCO FAJARDO', '1704', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1705.01', 'CAPITAL GÓMEZ', '1705', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1705.02', 'BOLÍVAR', '1705', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1705.03', 'GUEVARA', '1705', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1705.04', 'MATASIETE', '1705', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1705.05', 'SUCRE', '1705', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1706.01', 'CAPITAL MANEIRO', '1706', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1706.02', 'AGUIRRE', '1706', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1707.01', 'CAPITAL MARCANO', '1707', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1707.02', 'ADRIÁN', '1707', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1708.01', 'NO TIENE PARROQUIA', '1708', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1709.01', 'CAPITAL PENÍNSULA DE MACANAO', '1709', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1709.02', 'SAN FRANCISCO', '1709', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1710.01', 'CAPITAL TUBORES', '1710', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1710.02', 'LOS BARALES', '1710', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1711.01', 'CAPITAL VILLALBA', '1711', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1711.02', 'VICENTE FUENTES', '1711', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1801.01', 'NO TIENE PARROQUIA', '1801', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1802.01', 'CAPITAL ARAURE', '1802', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1802.02', 'RÍO ACARIGUA', '1802', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1803.01', 'CAPITAL ESTELLER', '1803', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1803.02', 'UVERAL', '1803', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1804.01', 'CAPITAL GUANARE', '1804', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1804.02', 'CÓRDOBA', '1804', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1804.03', 'SAN JOSÉ DE LA MONTAÑA', '1804', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1804.04', 'SAN JUAN DE GUANAGUANARE', '1804', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1804.05', 'VIRGEN DE LA COROMOTO', '1804', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1805.01', 'CAPITAL GUANARITO', '1805', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1805.02', 'TRINIDAD DE LA CAPILLA', '1805', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1805.03', 'DIVINA PASTORA', '1805', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1806.01', 'CAPITAL MONS. JOSÉ VICENTE DE UNDA', '1806', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1806.02', 'PEÑA BLANCA', '1806', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1807.01', 'CAPITAL OSPINO', '1807', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1807.02', 'APARICIÓN', '1807', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1807.03', 'LA ESTACIÓN', '1807', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1808.01', 'CAPITAL PÁEZ', '1808', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1808.02', 'PAYARA', '1808', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1808.03', 'PIMPINELA', '1808', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1808.04', 'RAMÓN PERAZA', '1808', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1809.01', 'CAPITAL PAPELÓN', '1809', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1809.02', 'CAÑO DELGADITO', '1809', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1810.01', 'CAPITAL SAN GENARO DE BOCONOITO', '1810', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1810.02', 'ANTOLÍN TOVAR', '1810', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1811.01', 'CAPITAL SAN RAFAEL DE ONOTO', '1811', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1811.02', 'SANTA FE', '1811', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1811.03', 'THERMO MORLES', '1811', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1812.01', 'CAPITAL SANTA ROSALÍA', '1812', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1812.02', 'FLORIDA', '1812', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1813.01', 'CAPITAL SUCRE', '1813', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1813.02', 'CONCEPCIÓN', '1813', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1813.03', 'SAN RAFAEL DE PALO ALZADO', '1813', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1813.04', 'UVENCIO ANTONIO VELÁSQUEZ', '1813', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1813.05', 'SAN JOSÉ DE SAGUAZ', '1813', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1813.06', 'VILLA ROSA', '1813', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1814.01', 'CAPITAL TURÉN', '1814', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1814.02', 'CANELONES', '1814', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1814.03', 'SANTA CRUZ', '1814', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1814.04', 'SAN ISIDRO LABRADOR', '1814', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1901.01', 'MARIÑO', '1901', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1901.02', 'RÓMULO GALLEGOS', '1901', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1902.01', 'SAN JOSÉ DE AEROCUAR', '1902', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1902.02', 'TAVERA ACOSTA', '1902', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1903.01', 'RÍO CARIBE', '1903', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1903.02', 'ANTONIO JOSÉ DE SUCRE', '1903', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1903.03', 'EL MORRO DE PUERTO SANTO', '1903', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1903.04', 'PUERTO SANTO', '1903', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1903.05', 'SAN JUAN DE LAS GALDONAS', '1903', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1904.01', 'EL PILAR', '1904', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1904.02', 'EL RINCÓN', '1904', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1904.03', 'GENERAL FRANCISCO ANTONIO VÁSQUEZ', '1904', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1904.04', 'GUARAÚNOS', '1904', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1904.05', 'TUNAPUICITO', '1904', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1904.06', 'UNIÓN', '1904', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1905.01', 'BOLÍVAR', '1905', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1905.02', 'MACARAPANA', '1905', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1905.03', 'SANTA CATALINA', '1905', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1905.04', 'SANTA ROSA', '1905', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1905.05', 'SANTA TERESA', '1905', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1906.01', 'NO TIENE PARROQUIA', '1906', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1907.01', 'YAGUARAPARO', '1907', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1907.02', 'EL PAUJIL', '1907', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1907.03', 'LIBERTAD', '1907', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1908.01', 'ARAYA', '1908', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1908.02', 'CHACOPATA', '1908', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1908.03', 'MANICUARE', '1908', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1909.01', 'TUNAPUY', '1909', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1909.02', 'CAMPO ELÍAS', '1909', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1910.01', 'IRAPA', '1910', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1910.02', 'CAMPO CLARO', '1910', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1910.03', 'MARABAL', '1910', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1910.04', 'SAN ANTONIO DE IRAPA', '1910', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1910.05', 'SORO', '1910', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1911.01', 'NO TIENE PARROQUIA', '1911', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1912.01', 'CUMANACOA', '1912', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1912.02', 'ARENAS', '1912', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1912.03', 'ARICAGUA', '1912', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1912.04', 'COCOLLAR', '1912', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1912.05', 'SAN FERNANDO', '1912', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1912.06', 'SAN LORENZO', '1912', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1913.01', 'CARIACO', '1913', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1913.02', 'CATUARO', '1913', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1913.03', 'RENDÓN VILLA FRONTADO', '1913', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1913.04', 'SANTA CRUZ', '1913', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1913.05', 'SANTA MARÍA', '1913', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1914.01', 'ALTAGRACIA', '1914', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1914.02', 'AYACUCHO', '1914', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1914.03', 'SANTA INÉS', '1914', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1914.04', 'VALENTÍN VALIENTE', '1914', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1914.05', 'SAN JUAN', '1914', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1914.06', 'RAÚL LEONI', '1914', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1914.07', 'GRAN MARISCAL', '1914', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1915.01', 'GÜIRIA', '1915', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1915.02', 'BIDEAU', '1915', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1915.03', 'CRISTÓBAL COLÓN', '1915', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('1915.04', 'PUNTA DE PIEDRAS', '1915', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2001.01', 'NO TIENE PARROQUIA', '2001', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2002.01', 'NO TIENE PARROQUIA', '2002', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2003.01', 'AYACUCHO', '2003', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2003.02', 'RIVAS BERTI', '2003', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2003.03', 'SAN PEDRO DEL RÍO', '2003', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2004.01', 'BOLÍVAR', '2004', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2004.02', 'PALOTAL', '2004', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2004.03', 'JUAN VICENTE GÓMEZ', '2004', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2004.04', 'ISAÍAS MEDINA ANGARITA', '2004', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2005.01', 'CÁRDENAS', '2005', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2005.02', 'AMENODORO RANGEL LAMÚS', '2005', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2005.03', 'LA FLORIDA', '2005', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2006.01', 'NO TIENE PARROQUIA', '2006', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2007.01', 'FERNÁNDEZ FEO', '2007', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2007.02', 'ALBERTO ADRIANI', '2007', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2007.03', 'SANTO DOMINGO', '2007', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2008.01', 'NO TIENE PARROQUIA', '2008', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2009.01', 'GARCÍA DE HEVIA', '2009', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2009.02', 'BOCA DE GRITA', '2009', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2009.03', 'JOSÉ ANTONIO PÁEZ', '2009', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2010.01', 'NO TIENE PARROQUIA', '2010', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2011.01', 'INDEPENDENCIA', '2011', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2011.02', 'JUAN GERMÁN ROSCIO', '2011', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2011.03', 'ROMÁN CÁRDENAS', '2011', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2012.01', 'JÁUREGUI', '2012', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2012.02', 'EMILIO CONSTANTINO GUERRERO', '2012', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2012.03', 'MONSEÑOR MIGUEL ANTONIO SALAS', '2012', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2013.01', 'NO TIENE PARROQUIA', '2013', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2014.01', 'JUNÍN', '2014', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2014.02', 'LA PETRÓLEA', '2014', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2014.03', 'QUINIMARÍ', '2014', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2014.04', 'BRAMÓN', '2014', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2015.01', 'LIBERTAD', '2015', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2015.02', 'CIPRIANO CASTRO', '2015', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2015.03', 'MANUEL FELIPE RUGELES', '2015', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2016.01', 'LIBERTADOR', '2016', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2016.02', 'DON EMETERIO OCHOA', '2016', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2016.03', 'DORADAS', '2016', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2016.04', 'SAN JOAQUÍN DE NAVAY', '2016', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2017.01', 'LOBATERA', '2017', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2017.02', 'CONSTITUCIÓN', '2017', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2018.01', 'NO TIENE PARROQUIA', '2018', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2019.01', 'PANAMERICANO', '2019', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2019.02', 'LA PALMITA', '2019', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2020.01', 'PEDRO MARÍA UREÑA', '2020', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2020.02', 'NUEVA ARCADIA', '2020', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2021.01', 'NO TIENE PARROQUIA', '2021', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2022.01', 'SAMUEL DARÍO MALDONADO', '2022', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2022.02', 'BOCONÓ', '2022', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2022.03', 'HERNÁNDEZ', '2022', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2023.01', 'LA CONCORDIA', '2023', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2023.02', 'PEDRO MARÍA MORANTES', '2023', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2023.03', 'SAN JUAN BAUTISTA', '2023', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2023.04', 'SAN SEBASTIÁN', '2023', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2023.05', 'DR. FRANCISCO ROMERO', '2023', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2024.01', 'NO TIENE PARROQUIA', '2024', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2025.01', 'NO TIENE PARROQUIA', '2025', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2026.01', 'SUCRE', '2026', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2026.02', 'ELEAZAR LÓPEZ CONTRERAS', '2026', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2026.03', 'SAN PABLO', '2026', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2027.01', 'NO TIENE PARROQUIA', '2027', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2028.01', 'URIBANTE', '2028', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2028.02', 'CÁRDENAS', '2028', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2028.03', 'JUAN PABLO PEÑALOZA', '2028', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2028.04', 'POTOSÍ', '2028', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2029.01', 'NO TIENE PARROQUIA', '2029', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2101.01', 'SANTA ISABEL', '2101', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2101.02', 'ARAGUANEY', '2101', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2101.03', 'EL JAGÜITO', '2101', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2101.04', 'LA ESPERANZA', '2101', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2102.01', 'BOCONÓ', '2102', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2102.02', 'EL CARMEN', '2102', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2102.03', 'MOSQUEY', '2102', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2102.04', 'AYACUCHO', '2102', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2102.05', 'BURBUSAY', '2102', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2102.06', 'GENERAL RIVAS', '2102', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2102.07', 'GUARAMACAL', '2102', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2102.08', 'VEGA DE GUARAMACAL', '2102', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2102.09', 'MONSEÑOR JÁUREGUI', '2102', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2102.10', 'RAFAEL RANGEL', '2102', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2102.11', 'SAN MIGUEL', '2102', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2102.12', 'SAN JOSÉ', '2102', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2103.01', 'SABANA GRANDE', '2103', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2103.02', 'CHEREGÜÉ', '2103', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2103.03', 'GRANADOS', '2103', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2104.01', 'CHEJENDÉ', '2104', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2104.02', 'ARNOLDO GABALDÓN', '2104', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2104.03', 'BOLIVIA', '2104', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2104.04', 'CARRILLO', '2104', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2104.05', 'CEGARRA', '2104', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2104.06', 'MANUEL SALVADOR ULLOA', '2104', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2104.07', 'SAN JOSÉ', '2104', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2105.01', 'CARACHE', '2105', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2105.02', 'CUICAS', '2105', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2105.03', 'LA CONCEPCIÓN', '2105', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2105.04', 'PANAMERICANA', '2105', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2105.05', 'SANTA CRUZ', '2105', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2106.01', 'ESCUQUE', '2106', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2106.02', 'LA UNIÓN', '2106', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2106.03', 'SABANA LIBRE', '2106', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2106.04', 'SANTA RITA', '2106', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2107.01', 'EL SOCORRO', '2107', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2107.02', 'ANTONIO JOSÉ DE SUCRE', '2107', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2107.03', 'LOS CAPRICHOS', '2107', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2108.01', 'CAMPO ELÍAS', '2108', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2108.02', 'ARNOLDO GABALDÓN', '2108', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2109.01', 'SANTA APOLONIA', '2109', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2109.02', 'EL PROGRESO', '2109', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2109.03', 'LA CEIBA', '2109', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2109.04', 'TRES DE FEBRERO', '2109', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2110.01', 'EL DIVIDIVE', '2110', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2110.02', 'AGUA SANTA', '2110', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2110.03', 'AGUA CALIENTE', '2110', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2110.04', 'EL CENIZO', '2110', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2110.05', 'VALERITA', '2110', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2111.01', 'MONTE CARMELO', '2111', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2111.02', 'BUENA VISTA', '2111', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2111.03', 'SANTA MARÍA DEL HORCÓN', '2111', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2112.01', 'MOTATÁN', '2112', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2112.02', 'EL BAÑO', '2112', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2112.03', 'JALISCO', '2112', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2113.01', 'PAMPÁN', '2113', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2113.02', 'FLOR DE PATRIA', '2113', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2113.03', 'LA PAZ', '2113', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2113.04', 'SANTA ANA', '2113', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2114.01', 'PAMPANITO', '2114', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2114.02', 'LA CONCEPCIÓN', '2114', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2114.03', 'PAMPANITO II', '2114', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2115.01', 'BETIJOQUE', '2115', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2115.02', 'LA PUEBLITA', '2115', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2115.03', 'LOS CEDROS', '2115', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2115.04', 'JOSÉ GREGORIO HERNÁNDEZ', '2115', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2116.01', 'CARVAJAL', '2116', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2116.02', 'ANTONIO NICOLÁS BRICEÑO', '2116', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2116.03', 'CAMPO ALEGRE', '2116', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2116.04', 'JOSÉ LEONARDO SUÁREZ', '2116', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2117.01', 'SABANA DE MENDOZA', '2117', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2117.02', 'EL PARAISO', '2117', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2117.03', 'JUNÍN', '2117', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2117.04', 'VALMORE RODRÍGUEZ', '2117', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2118.01', 'ANDRÉS LINARES', '2118', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2118.02', 'CHIQUINQUIRÁ', '2118', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2118.03', 'CRISTÓBAL MENDOZA', '2118', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2118.04', 'CRUZ CARRILLO', '2118', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2118.05', 'MATRIZ', '2118', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2118.06', 'MONSEÑOR CARRILLO', '2118', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2118.07', 'TRES ESQUINAS', '2118', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2119.01', 'LA QUEBRADA', '2119', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2119.02', 'CABIMBÚ', '2119', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2119.03', 'JAJÓ', '2119', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2119.04', 'LA MESA', '2119', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2119.05', 'SANTIAGO', '2119', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2119.06', 'TUÑAME', '2119', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2120.01', 'JUAN IGNACIO MONTILLA', '2120', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2120.02', 'LA BEATRIZ', '2120', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2120.03', 'MERCEDES DÍAZ', '2120', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2120.04', 'SAN LUIS', '2120', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2120.05', 'LA PUERTA', '2120', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2120.06', 'MENDOZA', '2120', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2201.01', 'NO TIENE PARROQUIA', '2201', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2202.01', 'NO TIENE PARROQUIA', '2202', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2203.01', 'CAPITAL BRUZUAL 2/ CHIVACOA', '2203', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2203.02', 'CAMPO ELÍAS', '2203', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2204.01', 'NO TIENE PARROQUIA', '2204', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2205.01', 'NO TIENE PARROQUIA', '2205', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2206.01', 'NO TIENE PARROQUIA', '2206', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2207.01', 'NO TIENE PARROQUIA', '2207', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2208.01', 'NO TIENE PARROQUIA', '2208', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2209.01', 'CAPITAL NIRGUA', '2209', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2209.02', 'SALOM', '2209', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2209.03', 'TEMERLA', '2209', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2210.01', 'CAPITAL PEÑA', '2210', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2210.02', 'SAN ANDRÉS', '2210', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2211.01', 'CAPITAL SAN FELIPE', '2211', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2211.02', 'ALBARICO', '2211', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2211.03', 'SAN JAVIER', '2211', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2212.01', 'NO TIENE PARROQUIA', '2212', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2213.01', 'NO TIENE PARROQUIA', '2213', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2214.01', 'CAPITAL VEROES', '2214', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2214.02', 'EL GUAYABO', '2214', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2301.01', 'ISLA DE TOAS', '2301', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2301.02', 'MONAGAS', '2301', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2302.01', 'SAN TIMOTEO', '2302', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2302.02', 'GENERAL URDANETA', '2302', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2302.03', 'LIBERTADOR', '2302', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2302.04', 'MANUEL GUANIPA MATOS', '2302', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2302.05', 'MARCELINO BRICEÑO', '2302', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2302.06', 'PUEBLO NUEVO', '2302', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2303.01', 'AMBROSIO', '2303', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2303.02', 'CARMEN HERRERA', '2303', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2303.03', 'GERMÁN RÍOS LINARES', '2303', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2303.04', 'LA ROSA', '2303', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2303.05', 'JORGE HERNÁNDEZ', '2303', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2303.06', 'RÓMULO BETANCOURT', '2303', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2303.07', 'SAN BENITO', '2303', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2303.08', 'ARÍSTIDES CALVANI', '2303', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2303.09', 'PUNTA GORDA', '2303', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2304.01', 'ENCONTRADOS', '2304', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2304.02', 'UDÓN PÉREZ', '2304', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2305.01', 'SAN CARLOS DEL ZULIA', '2305', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2305.02', 'MORALITO', '2305', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2305.03', 'SANTA BÁRBARA', '2305', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2305.04', 'SANTA CRUZ DEL ZULIA', '2305', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2305.05', 'URRIBARRI', '2305', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2306.01', 'SIMÓN RODRÍGUEZ', '2306', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2306.02', 'CARLOS QUEVEDO', '2306', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2306.03', 'FRANCISCO JAVIER PULGAR', '2306', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2306.04', 'AGUSTÍN CODAZZI', '2306', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2307.01', 'LA CONCEPCIÓN', '2307', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2307.02', 'JOSÉ RAMÓN YEPES', '2307', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2307.03', 'MARIANO PARRA LEÓN', '2307', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2307.04', 'SAN JOSÉ', '2307', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2308.01', 'JESÚS MARÍA SEMPRÚN', '2308', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2308.02', 'BARÍ', '2308', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2309.01', 'CONCEPCIÓN', '2309', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2309.02', 'ANDRÉS BELLO', '2309', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2309.03', 'CHIQUINQUIRÁ', '2309', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2309.04', 'EL CARMELO', '2309', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2309.05', 'POTRERITOS', '2309', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2310.01', 'ALONSO DE OJEDA', '2310', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2310.02', 'LIBERTAD', '2310', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2310.03', 'CAMPO LARA', '2310', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2310.04', 'ELEAZAR LÓPEZ CONTRERAS', '2310', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2310.05', 'VENEZUELA', '2310', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2310.06', 'EL DANTO', '2310', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2311.01', 'LIBERTAD', '2311', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2311.02', 'BARTOLOMÉ DE LAS CASAS', '2311', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2311.03', 'RÍO NEGRO', '2311', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2311.04', 'SAN JOSÉ DE PERIJÁ', '2311', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2312.01', 'SAN RAFAEL', '2312', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2312.02', 'LA SIERRITA', '2312', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2312.03', 'LAS PARCELAS', '2312', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2312.04', 'LUIS DE VICENTE', '2312', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2312.05', 'MONSEÑOR MARCOS SERGIO GODOY', '2312', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2312.06', 'RICAURTE', '2312', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2312.07', 'TAMARE', '2312', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2313.01', 'ANTONIO BORJAS ROMERO', '2313', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2313.02', 'BOLÍVAR', '2313', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2313.03', 'CACIQUE MARA', '2313', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2313.04', 'CARACCIOLO PARRA PÉREZ', '2313', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2313.05', 'CECILIO ACOSTA', '2313', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2313.06', 'CRISTO DE ARANZA', '2313', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2313.07', 'COQUIVACOA', '2313', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2313.08', 'CHIQUINQUIRÁ', '2313', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2313.09', 'FRANCISCO EUGENIO BUSTAMANTE', '2313', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2313.10', 'IDELFONSO VÁSQUEZ', '2313', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2313.11', 'JUANA DE ÁVILA', '2313', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2313.12', 'LUIS HURTADO HIGUERA', '2313', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2313.13', 'MANUEL DAGNINO', '2313', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2313.14', 'OLEGARIO VILLALOBOS', '2313', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2313.15', 'RAÚL LEONI', '2313', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2313.16', 'SANTA LUCÍA', '2313', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2313.17', 'VENANCIO PULGAR', '2313', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2313.18', 'SAN ISIDRO', '2313', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2314.01', 'ALTAGRACIA', '2314', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2314.02', 'ANA MARÍA CAMPOS', '2314', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2314.03', 'FARÍA', '2314', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2314.04', 'SAN ANTONIO', '2314', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2314.05', 'SAN JOSÉ', '2314', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2314.06', 'JOSÉ ANTONIO CHAVES', '2314', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2315.01', 'SINAMAICA', '2315', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2315.02', 'ALTA GUAJIRA', '2315', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2315.03', 'ELÍAS SÁNCHEZ RUBIO', '2315', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2315.04', 'GUAJIRA', '2315', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2316.01', 'EL ROSARIO', '2316', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2316.02', 'DONALDO GARCÍA', '2316', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2316.03', 'SIXTO ZAMBRANO', '2316', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2317.01', 'SAN FRANCISCO', '2317', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2317.02', 'EL BAJO', '2317', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2317.03', 'DOMITILA FLORES', '2317', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2317.04', 'FRANCISCO OCHOA', '2317', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2317.05', 'LOS CORTIJOS', '2317', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2317.06', 'MARCIAL HERNÁNDEZ', '2317', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2317.07', 'JOSÉ DOMINGO RUS', '2317', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2318.01', 'SANTA RITA', '2318', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2318.02', 'EL MENE', '2318', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2318.03', 'JOSÉ CENOVIO URRIBARRI', '2318', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2318.04', 'PEDRO LUCAS URRIBARRI', '2318', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2319.01', 'MANUEL MANRIQUE', '2319', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2319.02', 'RAFAEL MARÍA BARALT', '2319', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2319.03', 'RAFAEL URDANETA', '2319', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2320.01', 'BOBURES', '2320', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2320.02', 'EL BATEY', '2320', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2320.03', 'GIBRALTAR', '2320', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2320.04', 'HERAS', '2320', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2320.05', 'MONSEÑOR ARTURO CELESTINO ÁLVAREZ', '2320', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2320.06', 'RÓMULO GALLEGOS', '2320', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2321.01', 'LA VICTORIA', '2321', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2321.02', 'RAFAEL URDANETA', '2321', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2321.03', 'RAÚL CUENCA', '2321', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2401.01', 'CARABALLEDA', '2401', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2401.02', 'CARAYACA', '2401', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2401.03', 'CARUAO', '2401', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2401.04', 'CATIA LA MAR', '2401', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2401.05', 'EL JUNKO', '2401', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2401.06', 'LA GUAIRA', '2401', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2401.07', 'MACUTO', '2401', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2401.08', 'MAIQUETÍA', '2401', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2401.09', 'NAIGUATÁ', '2401', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2401.10', 'URIMARE', '2401', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2401.11', 'CARLOS SOUBLETTE', '2401', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2501.01', 'GRAN ROQUE', '2501', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2501.02', 'LOS TESTIGOS', '2501', NULL, NULL, NULL);
INSERT INTO public.parroquia (id_parroquia, nombre_parroquia, id_municipio, active, fecha_elim, usr_id) VALUES ('2501.03', 'CHIMANAS', '2501', NULL, NULL, NULL);


--
-- TOC entry 3402 (class 0 OID 200616)
-- Dependencies: 256
-- Data for Name: permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (1, 'site', 'Index', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (2, 'site', 'Cerrarsesion', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (3, 'articulo', 'Index', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (4, 'articulo', 'Crud', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (5, 'articulo', 'Guardar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (6, 'articulo', 'Eliminar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (7, 'cancelacion', 'Index', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (8, 'cancelacion', 'Crud', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (9, 'cancelacion', 'Guardar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (10, 'cancelacion', 'Eliminar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (11, 'cancelacion', 'Cancelar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (12, 'departamento', 'Index', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (13, 'departamento', 'Crud', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (14, 'departamento', 'Guardar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (15, 'departamento', 'Eliminar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (16, 'desincorporacion', 'Index', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (17, 'desincorporacion', 'Crud', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (18, 'desincorporacion', 'Guardar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (19, 'desincorporacion', 'Eliminar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (20, 'desincorporacion', 'Desincorporar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (21, 'devolucion', 'Index', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (22, 'devolucion', 'Crud', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (23, 'devolucion', 'Guardar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (24, 'devolucion', 'Eliminar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (25, 'devolucion', 'Devolver', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (26, 'empleado', 'Index', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (27, 'empleado', 'Crud', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (28, 'empleado', 'Cuerpo_modal', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (29, 'empleado', 'Local', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (30, 'empleado', 'Obtener_json', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (31, 'empleado', 'Guardar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (32, 'empleado', 'Eliminar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (33, 'equipo', 'Index', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (34, 'equipo', 'View', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (35, 'equipo', 'View_sbn', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (36, 'equipo', 'View_disp', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (37, 'equipo', 'Valida_serial', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (38, 'equipo', 'Crud', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (39, 'equipo', 'Sbn', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (40, 'equipo', 'Asignabn', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (41, 'equipo', 'Guardar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (42, 'equipo', 'Guardarbn', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (43, 'equipo', 'Eliminar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (44, 'equipo', 'ListarJSON2', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (45, 'funcionario', 'Index', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (46, 'funcionario', 'Crud', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (47, 'funcionario', 'Guardar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (48, 'funcionario', 'Eliminar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (49, 'login', 'Index', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (50, 'marca', 'Index', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (51, 'marca', 'Crud', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (52, 'marca', 'Guardar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (53, 'marca', 'Eliminar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (54, 'oficina', 'Index', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (55, 'oficina', 'Crud', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (56, 'oficina', 'Guardar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (57, 'oficina', 'Eliminar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (58, 'orden_salida', 'Index', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (59, 'orden_salida', 'Crud', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (60, 'orden_salida', 'Guardar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (61, 'orden_salida', 'Eliminar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (62, 'permissions', 'Index', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (63, 'permissions', 'Crud', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (64, 'permissions', 'Guardar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (65, 'permissions', 'Eliminar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (66, 'proveedor', 'Index', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (67, 'proveedor', 'Crud', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (68, 'proveedor', 'Guardar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (69, 'proveedor', 'Eliminar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (70, 'reportes', 'Solicitud', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (71, 'reportes', 'Orden_salida', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (72, 'reportes', 'Ordenes_salida', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (73, 'reportes', 'Equipos_general', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (74, 'reportes', 'Equipos_sbn', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (75, 'reportes', 'Equipos_disponibles', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (76, 'reportes', 'Equipos_itinerantes', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (77, 'reportes', 'Equipos_reservados', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (78, 'reportes', 'Solicitudes', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (79, 'reportes', 'Solicitudes_pendientes', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (80, 'reportes', 'Solicitudes_pendientes_sin_detalle', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (81, 'reportes', 'Solicitudes_pendientes_sin_orden', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (82, 'reportes', 'Solicitudes_parcialmente_procesadas', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (83, 'reportes', 'Solicitudes_procesadas', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (84, 'reportes', 'Solicitudes_canceladas', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (85, 'reportes', 'Empleados', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (86, 'reportes', 'Oficinas', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (87, 'reportes', 'Departamentos', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (88, 'reportes', 'Marcas', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (89, 'reportes', 'Articulos', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (90, 'reportes', 'Proveedores', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (91, 'reportes', 'Usuario', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (92, 'reserva', 'Index', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (93, 'reserva', 'Crud', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (94, 'reserva', 'Guardar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (95, 'reserva', 'Eliminar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (96, 'role_perm', 'Index', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (97, 'role_perm', 'Crud', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (98, 'role_perm', 'Guardar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (99, 'role_perm', 'Eliminar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (100, 'roles', 'Index', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (101, 'roles', 'Crud', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (102, 'roles', 'Guardar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (103, 'roles', 'Eliminar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (104, 'saime', 'Crud', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (105, 'solicitud', 'Index', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (106, 'solicitud', 'View', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (107, 'solicitud', 'View_pend', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (108, 'solicitud', 'View_canc', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (109, 'solicitud', 'View_orden', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (110, 'solicitud', 'Crud', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (111, 'solicitud', 'Guardar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (112, 'solicitud', 'Eliminar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (113, 'solicitud', 'Cancelar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (114, 'solicitud_detalle', 'Index', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (115, 'solicitud_detalle', 'Crud', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (116, 'solicitud_detalle', 'Guardar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (117, 'solicitud_detalle', 'Eliminar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (118, 'solicitud_detalle', 'Asignar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (119, 'telefono', 'Index', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (120, 'telefono', 'Crud', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (121, 'telefono', 'Guardar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (122, 'telefono', 'Eliminar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (123, 'ubicacion', 'Index', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (124, 'ubicacion', 'Crud', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (125, 'ubicacion', 'Guardar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (126, 'ubicacion', 'Eliminar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (127, 'user_role', 'Index', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (128, 'user_role', 'Crud', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (129, 'user_role', 'Guardar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (130, 'user_role', 'Eliminar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (131, 'usuario', 'Index', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (132, 'usuario', 'Crud', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (133, 'usuario', 'Guardar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (134, 'usuario', 'Eliminar', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (135, 'usuario', 'Desbloquear', NULL, NULL, NULL);
INSERT INTO public.permissions (perm_id, perm_desc, accion, active, fecha_elim, usr_id) VALUES (136, 'usuario', 'Listar', NULL, NULL, NULL);


--
-- TOC entry 3379 (class 0 OID 200488)
-- Dependencies: 222
-- Data for Name: proveedor; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.proveedor (id_proveedor, nombre_prov, direccion, telefono, apellido_prov, active, fecha_elim, usr_id) VALUES (1, 'PROVEEDOR', NULL, NULL, 'PRUEBA', NULL, NULL, NULL);


--
-- TOC entry 3405 (class 0 OID 200623)
-- Dependencies: 259
-- Data for Name: reserva; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.reserva (id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo, active, fecha_elim, usr_id) VALUES (1, 14, '2019-06-12', 'Equipo Reservado en Solicitud Nro:14', 10, NULL, NULL, NULL);
INSERT INTO public.reserva (id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo, active, fecha_elim, usr_id) VALUES (2, 15, '2019-06-12', 'Equipo Reservado en Solicitud Nro:15', 9, NULL, NULL, NULL);
INSERT INTO public.reserva (id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo, active, fecha_elim, usr_id) VALUES (3, 15, '2019-06-12', 'Equipo Reservado en Solicitud Nro:15', 12, NULL, NULL, NULL);
INSERT INTO public.reserva (id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo, active, fecha_elim, usr_id) VALUES (4, 16, '2019-06-12', 'Equipo Reservado en Solicitud Nro:16', 17, NULL, NULL, NULL);
INSERT INTO public.reserva (id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo, active, fecha_elim, usr_id) VALUES (5, 16, '2019-06-12', 'Equipo Reservado en Solicitud Nro:16', 15, NULL, NULL, NULL);
INSERT INTO public.reserva (id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo, active, fecha_elim, usr_id) VALUES (6, 16, '2019-06-12', 'Equipo Reservado en Solicitud Nro:16', 16, NULL, NULL, NULL);
INSERT INTO public.reserva (id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo, active, fecha_elim, usr_id) VALUES (7, 19, '2019-06-14', 'Equipo Reservado en Solicitud Nro:19', 8, NULL, NULL, NULL);
INSERT INTO public.reserva (id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo, active, fecha_elim, usr_id) VALUES (8, 17, '2019-06-15', 'Equipo Reservado en Solicitud Nro:17', 14, NULL, NULL, NULL);
INSERT INTO public.reserva (id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo, active, fecha_elim, usr_id) VALUES (9, 18, '2019-06-15', 'Equipo Reservado en Solicitud Nro:18', 13, NULL, NULL, NULL);
INSERT INTO public.reserva (id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo, active, fecha_elim, usr_id) VALUES (10, 6, '2019-06-15', 'Equipo Reservado en Solicitud Nro:6', 10, NULL, NULL, NULL);
INSERT INTO public.reserva (id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo, active, fecha_elim, usr_id) VALUES (11, 7, '2019-06-15', 'Equipo Reservado en Solicitud Nro:7', 8, NULL, NULL, NULL);
INSERT INTO public.reserva (id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo, active, fecha_elim, usr_id) VALUES (12, 8, '2019-06-15', 'Equipo Reservado en Solicitud Nro:8', 6, NULL, NULL, NULL);
INSERT INTO public.reserva (id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo, active, fecha_elim, usr_id) VALUES (13, 20, '2019-06-15', 'Equipo Reservado en Solicitud Nro:20', 9, NULL, NULL, NULL);
INSERT INTO public.reserva (id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo, active, fecha_elim, usr_id) VALUES (14, 20, '2019-06-15', 'Equipo Reservado en Solicitud Nro:20', 12, NULL, NULL, NULL);
INSERT INTO public.reserva (id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo, active, fecha_elim, usr_id) VALUES (15, 21, '2019-06-15', 'Equipo Reservado en Solicitud Nro:21', 12, NULL, NULL, NULL);
INSERT INTO public.reserva (id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo, active, fecha_elim, usr_id) VALUES (16, 24, '2019-06-22', 'Equipo Reservado en Solicitud Nro:24', 9, NULL, NULL, NULL);
INSERT INTO public.reserva (id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo, active, fecha_elim, usr_id) VALUES (17, 24, '2019-06-22', 'Equipo Reservado en Solicitud Nro:24', 17, NULL, NULL, NULL);
INSERT INTO public.reserva (id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo, active, fecha_elim, usr_id) VALUES (18, 24, '2019-06-22', 'Equipo Reservado en Solicitud Nro:24', 16, NULL, NULL, NULL);
INSERT INTO public.reserva (id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo, active, fecha_elim, usr_id) VALUES (19, 24, '2019-06-22', 'Equipo Reservado en Solicitud Nro:24', 10, NULL, NULL, NULL);
INSERT INTO public.reserva (id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo, active, fecha_elim, usr_id) VALUES (20, 25, '2019-06-22', 'Equipo Reservado en Solicitud Nro:25', 9, NULL, NULL, NULL);
INSERT INTO public.reserva (id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo, active, fecha_elim, usr_id) VALUES (21, 25, '2019-06-22', 'Equipo Reservado en Solicitud Nro:25', 12, NULL, NULL, NULL);
INSERT INTO public.reserva (id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo, active, fecha_elim, usr_id) VALUES (22, 26, '2019-06-22', 'Equipo Reservado en Solicitud Nro:26', 9, NULL, NULL, NULL);
INSERT INTO public.reserva (id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo, active, fecha_elim, usr_id) VALUES (23, 26, '2019-06-22', 'Equipo Reservado en Solicitud Nro:26', 12, NULL, NULL, NULL);
INSERT INTO public.reserva (id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo, active, fecha_elim, usr_id) VALUES (24, 27, '2019-06-24', 'Equipo Reservado en Solicitud Nro:27', 6, NULL, NULL, NULL);
INSERT INTO public.reserva (id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo, active, fecha_elim, usr_id) VALUES (25, 27, '2019-06-24', 'Equipo Reservado en Solicitud Nro:27', 10, NULL, NULL, NULL);
INSERT INTO public.reserva (id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo, active, fecha_elim, usr_id) VALUES (26, 27, '2019-06-24', 'Equipo Reservado en Solicitud Nro:27', 16, NULL, NULL, NULL);
INSERT INTO public.reserva (id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo, active, fecha_elim, usr_id) VALUES (27, 28, '2019-06-24', 'Equipo Reservado en Solicitud Nro:28', 7, NULL, NULL, NULL);
INSERT INTO public.reserva (id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo, active, fecha_elim, usr_id) VALUES (28, 28, '2019-06-24', 'Equipo Reservado en Solicitud Nro:28', 9, NULL, NULL, NULL);
INSERT INTO public.reserva (id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo, active, fecha_elim, usr_id) VALUES (29, 28, '2019-06-26', 'Equipo Reservado en Solicitud Nro:28', 8, NULL, NULL, NULL);
INSERT INTO public.reserva (id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo, active, fecha_elim, usr_id) VALUES (30, 32, '2019-06-26', 'Equipo Reservado en Solicitud Nro:32', 14, NULL, NULL, NULL);


--
-- TOC entry 3407 (class 0 OID 200629)
-- Dependencies: 261
-- Data for Name: rol; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.rol (id_rol, descripcion, active, fecha_elim, usr_id) VALUES (1, 'Administrador', NULL, NULL, NULL);
INSERT INTO public.rol (id_rol, descripcion, active, fecha_elim, usr_id) VALUES (2, 'Soporte', NULL, NULL, NULL);
INSERT INTO public.rol (id_rol, descripcion, active, fecha_elim, usr_id) VALUES (3, 'Almacen', NULL, NULL, NULL);
INSERT INTO public.rol (id_rol, descripcion, active, fecha_elim, usr_id) VALUES (4, 'Contrataciones', NULL, NULL, NULL);
INSERT INTO public.rol (id_rol, descripcion, active, fecha_elim, usr_id) VALUES (5, 'Bienes Nacionales', NULL, NULL, NULL);


--
-- TOC entry 3409 (class 0 OID 200634)
-- Dependencies: 263
-- Data for Name: role_perm; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 1, 1, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 2, 2, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 3, 3, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 4, 4, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 5, 5, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 6, 6, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 7, 7, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 8, 8, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 9, 9, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 10, 10, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 11, 11, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 12, 12, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 13, 13, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 14, 14, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 15, 15, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 16, 16, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 17, 17, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 18, 18, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 19, 19, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 20, 20, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 21, 21, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 22, 22, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 23, 23, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 24, 24, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 25, 25, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 26, 26, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 27, 27, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 28, 28, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 29, 29, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 30, 30, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 31, 31, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 32, 32, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 33, 33, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 34, 34, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 35, 35, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 36, 36, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 37, 37, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 38, 38, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 39, 39, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 40, 40, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 41, 41, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 42, 42, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 43, 43, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 44, 44, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 45, 45, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 46, 46, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 47, 47, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 48, 48, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 49, 49, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 50, 50, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 51, 51, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 52, 52, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 53, 53, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 54, 54, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 55, 55, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 56, 56, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 57, 57, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 58, 58, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 59, 59, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 60, 60, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 61, 61, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 62, 62, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 63, 63, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 64, 64, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 65, 65, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 66, 66, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 67, 67, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 68, 68, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 69, 69, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 70, 70, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 71, 71, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 72, 72, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 73, 73, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 74, 74, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 75, 75, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 76, 76, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 77, 77, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 78, 78, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 79, 79, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 80, 80, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 81, 81, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 82, 82, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 83, 83, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 84, 84, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 85, 85, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 86, 86, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 87, 87, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 88, 88, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 89, 89, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 90, 90, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 91, 91, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 92, 92, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 93, 93, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 94, 94, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 95, 95, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 96, 96, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 97, 97, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 98, 98, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 99, 99, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 100, 100, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 101, 101, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 102, 102, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 103, 103, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 104, 104, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 105, 105, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 106, 106, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 107, 107, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 108, 108, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 109, 109, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 110, 110, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 111, 111, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 112, 112, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 113, 113, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 114, 114, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 115, 115, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 116, 116, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 117, 117, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 118, 118, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 119, 119, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 120, 120, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 121, 121, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 122, 122, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 123, 123, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 124, 124, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 125, 125, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 126, 126, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 127, 127, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 128, 128, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 129, 129, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 130, 130, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 131, 131, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 132, 132, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 133, 133, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 134, 134, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 135, 135, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (1, 136, 136, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (5, 1, 137, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (5, 2, 138, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (5, 33, 139, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (5, 39, 140, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (5, 40, 141, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (5, 42, 142, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (5, 35, 143, NULL, NULL, NULL);
INSERT INTO public.role_perm (role_id, perm_id, id, active, fecha_elim, usr_id) VALUES (5, 74, 144, NULL, NULL, NULL);


--
-- TOC entry 3410 (class 0 OID 200638)
-- Dependencies: 264
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.roles (role_id, role_name, active, fecha_elim, usr_id) VALUES (1, 'Administrador', NULL, NULL, NULL);
INSERT INTO public.roles (role_id, role_name, active, fecha_elim, usr_id) VALUES (3, 'Almacen', NULL, NULL, NULL);
INSERT INTO public.roles (role_id, role_name, active, fecha_elim, usr_id) VALUES (4, 'Contrataciones', NULL, NULL, NULL);
INSERT INTO public.roles (role_id, role_name, active, fecha_elim, usr_id) VALUES (5, 'Bienes Nacionales', NULL, NULL, NULL);
INSERT INTO public.roles (role_id, role_name, active, fecha_elim, usr_id) VALUES (2, 'Soporte', NULL, NULL, NULL);


--
-- TOC entry 3381 (class 0 OID 200512)
-- Dependencies: 228
-- Data for Name: solicitud; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (1, NULL, 3, 1, 'Solicitud de equipos para auditoria ', '2019-04-01', 4, 1, NULL, NULL, NULL, 10016, 1, 0, 0);
INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (2, NULL, 3, 2, 'Otra prueba', '2019-04-01', 2, 1, NULL, NULL, NULL, 10017, 1, 0, 0);
INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (3, NULL, 3, 1, 'Prueba otra vez', '2019-04-01', 1, 4, NULL, NULL, NULL, 0, 1, 0, 0);
INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (5, 0, 3, 1, 'Prueba otra vez', '2019-05-21', 3, 4, NULL, NULL, NULL, 0, 1, 0, 0);
INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (10, 0, 3, 1, 'Megajornada El 25', '2019-05-20', 2, 1, NULL, NULL, NULL, 10018, 1, 0, 0);
INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (9, 0, 3, 2, 'Megajornada El 24', '2019-05-20', 4, 1, NULL, NULL, NULL, 10029, 1, 0, 0);
INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (11, 0, 6, 2, 'Salida de equipo para reparacion en taller externo', '2019-10-06', 3, 1, NULL, NULL, NULL, 10030, 1, 0, 0);
INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (12, 0, 9, 1, 'Salida de equipo para reparacion en taller externo', '2019-10-06', 3, 1, NULL, NULL, NULL, 10031, 2, 5, 1);
INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (13, 0, 5, 1, 'Prueba de secuencia 2', '2019-10-06', 1, 4, NULL, NULL, NULL, 10032, 3, 1, 12);
INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (14, 0, 13, 1, 'otra prueba mas de hoy', '2019-12-06', 4, 1, NULL, NULL, NULL, 10033, 2, 92, 1);
INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (15, 0, 13, 1, 'Jornada en Sarria', '2019-12-06', 4, 1, NULL, NULL, NULL, 10034, 3, 1, 10);
INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (16, 0, 13, 2, 'Jornada de Emision de Certificados de Nacimiento Maternidad Hugo Chavez', '2019-12-06', 4, 1, NULL, NULL, NULL, 10035, 2, 21, 1);
INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (19, 0, 13, 1, 'Prueba de ajuste', '2019-06-14', 1, 1, NULL, NULL, NULL, 10036, 2, 161, 1);
INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (17, 0, 13, 1, 'prueba x', '2019-06-13', 2, 1, NULL, NULL, NULL, 10037, 3, 1, 5);
INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (18, 0, 13, 1, 'Prueba de secuencia 2223', '2019-06-13', 3, 1, NULL, NULL, NULL, 10038, 3, 1, 6);
INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (6, 0, 3, 1, 'Prueba otra vez', '2019-05-21', 3, 1, NULL, NULL, NULL, 10039, 1, 0, 0);
INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (7, 0, 3, 2, 'Megajornada El 23', '2019-05-21', 4, 1, NULL, NULL, NULL, 10040, 1, 0, 0);
INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (8, 0, 3, 2, 'Megajornada El 24', '2019-05-20', 4, 1, NULL, NULL, NULL, 10041, 1, 0, 0);
INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (20, 0, 4, 1, 'Solicitud de equipos para jornada de emision de certificados de nacimiento', '2019-06-14', 2, 1, NULL, NULL, NULL, 10042, 2, 137, 1);
INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (21, 0, 4, 1, 'Auditoria de Sistemas en la Oficina NP10', '2019-06-14', 2, 1, NULL, NULL, NULL, 10043, 2, 4, 1);
INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (22, 0, 4, 1, 'jornada especial nro 233', '2019-06-14', 4, 4, NULL, NULL, NULL, 0, 2, 74, NULL);
INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (23, 0, 4, 1, 'prueba suprema', '2019-06-17', 3, 4, NULL, NULL, NULL, 0, 2, 6, 1);
INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (24, 0, 4, 1, 'Equipamiento para jornada de salud', '2019-06-21', 4, 1, NULL, NULL, NULL, 10044, 3, 1, 8);
INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (25, 0, 4, 1, 'prueba mirtha 3', '2019-06-22', 1, 4, NULL, NULL, NULL, 10045, 3, 1, 6);
INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (26, 0, 4, 2, 'prueba mirtha 4', '2019-06-22', 3, 4, NULL, NULL, NULL, 10046, 3, 1, 6);
INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (27, 0, 4, 1, 'Prueba numero 40982309823 de generacion de solicitud de equipos para jornadas dsjkjsdlkjsdlkjsdlsdlk', '2019-06-24', 4, 1, NULL, NULL, NULL, 10047, 2, 195, 1);
INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (29, 0, 4, 12, 'fsdfsfsdfd', '2019-06-25', 2, 3, NULL, NULL, NULL, 0, 3, 1, 4);
INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (30, 0, 4, 4, 'rrtyrtyrty', '2019-06-25', 1, 3, NULL, NULL, NULL, 0, 2, 2, -1);
INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (31, 0, 4, 16, 'iyiiyiyiyiyoiyo', '2019-06-25', 4, 3, NULL, NULL, NULL, 0, 2, 18, -1);
INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (28, 0, 4, 1, 'Prueba de Procesamiento PArcial de Solicitud', '2019-06-24', 2, 1, NULL, NULL, NULL, 10048, 3, 1, 5);
INSERT INTO public.solicitud (id_solicitud, id_equipo, id_funcionario, id_empleado, descripcion, fecha_solicitud, id_tipo_solicitud, id_estatus_solicitud, active, fecha_elim, usr_id, id_orden, id_ubicacion, id_oficina, id_departamento) VALUES (32, 0, 4, 9, 'Prueba de secuencia 22266666', '2019-06-26', 1, 1, NULL, NULL, NULL, 0, 3, -1, 4);


--
-- TOC entry 3382 (class 0 OID 200520)
-- Dependencies: 229
-- Data for Name: solicitud_detalle; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (6, 3, 10, NULL, NULL, NULL, NULL);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (7, 3, 6, NULL, NULL, NULL, NULL);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (8, 3, 6, NULL, NULL, NULL, NULL);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (9, 3, 9, NULL, NULL, NULL, NULL);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (10, 3, 8, NULL, NULL, NULL, NULL);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (5, 1, 8, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (1, 2, 8, NULL, NULL, NULL, NULL);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (2, 1, 10, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (3, 1, 6, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (4, 1, 7, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (14, 5, 12, NULL, NULL, NULL, false);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (15, 5, 13, NULL, NULL, NULL, false);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (13, 10, 8, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (11, 9, 6, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (12, 9, 7, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (16, 11, 9, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (17, 11, 12, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (18, 12, 10, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (19, 13, 14, false, '2019-06-12', 15, false);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (20, 13, 13, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (21, 14, 10, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (22, 15, 9, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (23, 15, 12, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (24, 16, 9, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (25, 16, 17, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (26, 16, 15, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (27, 16, 16, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (30, 19, 8, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (28, 17, 14, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (29, 18, 13, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (31, 6, 10, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (32, 7, 8, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (33, 8, 6, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (34, 20, 9, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (35, 20, 12, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (36, 21, 12, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (38, 22, 10, NULL, NULL, NULL, false);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (37, 22, 14, false, '2019-06-17', 2, false);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (42, 23, 9, NULL, NULL, NULL, false);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (43, 23, 10, NULL, NULL, NULL, false);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (44, 23, 11, NULL, NULL, NULL, false);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (45, 23, 12, NULL, NULL, NULL, false);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (46, 23, 14, false, '2019-06-17', 2, false);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (39, 23, 6, false, '2019-06-17', 2, false);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (40, 23, 7, false, '2019-06-17', 2, false);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (41, 23, 8, false, '2019-06-17', 2, false);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (47, 24, 9, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (48, 24, 17, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (49, 24, 16, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (50, 24, 10, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (53, 25, 10, NULL, NULL, NULL, false);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (51, 25, 9, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (52, 25, 12, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (56, 26, 13, NULL, NULL, NULL, false);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (54, 26, 9, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (55, 26, 12, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (57, 27, 6, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (58, 27, 10, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (59, 27, 16, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (60, 28, 7, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (62, 28, 9, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (63, 29, 6, NULL, NULL, NULL, false);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (64, 30, 7, NULL, NULL, NULL, false);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (65, 31, 12, NULL, NULL, NULL, false);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (61, 28, 8, NULL, NULL, NULL, true);
INSERT INTO public.solicitud_detalle (id_solicitud_detalle, id_solicitud, id_equipo, active, fecha_elim, usr_id, asignado) VALUES (66, 32, 14, NULL, NULL, NULL, true);


--
-- TOC entry 3413 (class 0 OID 200677)
-- Dependencies: 274
-- Data for Name: telefono; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3400 (class 0 OID 200597)
-- Dependencies: 251
-- Data for Name: tipo_solicitud; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.tipo_solicitud (id_tipo_solicitud, descripcion, active, fecha_elim, usr_id) VALUES (1, 'Asignacion', NULL, NULL, NULL);
INSERT INTO public.tipo_solicitud (id_tipo_solicitud, descripcion, active, fecha_elim, usr_id) VALUES (2, 'Prestamo Especial', NULL, NULL, NULL);
INSERT INTO public.tipo_solicitud (id_tipo_solicitud, descripcion, active, fecha_elim, usr_id) VALUES (3, 'Reparacion', NULL, NULL, NULL);
INSERT INTO public.tipo_solicitud (id_tipo_solicitud, descripcion, active, fecha_elim, usr_id) VALUES (4, 'Prestamo por Jornada', NULL, NULL, NULL);


--
-- TOC entry 3415 (class 0 OID 200682)
-- Dependencies: 276
-- Data for Name: ubicacion; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 3372 (class 0 OID 200458)
-- Dependencies: 213
-- Data for Name: ubicacion_v2; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.ubicacion_v2 (id_ubicacion, ubicacion, active, fecha_elim, usr_id) VALUES (1, 'Almacen', NULL, NULL, NULL);
INSERT INTO public.ubicacion_v2 (id_ubicacion, ubicacion, active, fecha_elim, usr_id) VALUES (2, 'Oficina', NULL, NULL, NULL);
INSERT INTO public.ubicacion_v2 (id_ubicacion, ubicacion, active, fecha_elim, usr_id) VALUES (3, 'Departamento', NULL, NULL, NULL);


--
-- TOC entry 3418 (class 0 OID 200689)
-- Dependencies: 279
-- Data for Name: ult_orden_salida; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.ult_orden_salida (ultima_orden) VALUES (20190000);


--
-- TOC entry 3420 (class 0 OID 200694)
-- Dependencies: 281
-- Data for Name: user_role; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.user_role (user_id, role_id, id, active, fecha_elim, usr_id) VALUES (2, 1, 1, NULL, NULL, NULL);
INSERT INTO public.user_role (user_id, role_id, id, active, fecha_elim, usr_id) VALUES (3, 2, 2, NULL, NULL, NULL);
INSERT INTO public.user_role (user_id, role_id, id, active, fecha_elim, usr_id) VALUES (12, 5, 3, NULL, NULL, NULL);
INSERT INTO public.user_role (user_id, role_id, id, active, fecha_elim, usr_id) VALUES (13, 1, 4, NULL, NULL, NULL);
INSERT INTO public.user_role (user_id, role_id, id, active, fecha_elim, usr_id) VALUES (5, 3, 5, NULL, NULL, NULL);
INSERT INTO public.user_role (user_id, role_id, id, active, fecha_elim, usr_id) VALUES (7, 4, 6, NULL, NULL, NULL);
INSERT INTO public.user_role (user_id, role_id, id, active, fecha_elim, usr_id) VALUES (9, 5, 7, NULL, NULL, NULL);
INSERT INTO public.user_role (user_id, role_id, id, active, fecha_elim, usr_id) VALUES (8, 4, 8, NULL, NULL, NULL);
INSERT INTO public.user_role (user_id, role_id, id, active, fecha_elim, usr_id) VALUES (6, 3, 9, NULL, NULL, NULL);
INSERT INTO public.user_role (user_id, role_id, id, active, fecha_elim, usr_id) VALUES (15, 1, 10, NULL, NULL, NULL);
INSERT INTO public.user_role (user_id, role_id, id, active, fecha_elim, usr_id) VALUES (4, 2, 11, NULL, NULL, NULL);
INSERT INTO public.user_role (user_id, role_id, id, active, fecha_elim, usr_id) VALUES (1, 2, 12, NULL, NULL, NULL);
INSERT INTO public.user_role (user_id, role_id, id, active, fecha_elim, usr_id) VALUES (18, 5, 13, NULL, NULL, NULL);
INSERT INTO public.user_role (user_id, role_id, id, active, fecha_elim, usr_id) VALUES (19, 3, 14, NULL, NULL, NULL);
INSERT INTO public.user_role (user_id, role_id, id, active, fecha_elim, usr_id) VALUES (17, 2, 15, NULL, NULL, NULL);


--
-- TOC entry 3390 (class 0 OID 200557)
-- Dependencies: 240
-- Data for Name: usuario; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.usuario (alias, email, id, nombres, password, id_rol, active, fecha_elim, usr_id, intentos, ingreso) VALUES ('pperez', 'pperez@saren.gob.ve', 3, 'Pedro Perez', '$2y$10$sZtKCyUtoELGIpr78eK0FOjo/YoaBPWr0nKKNW7bGd2txdH7e5uMO', 2, NULL, NULL, NULL, 0, false);
INSERT INTO public.usuario (alias, email, id, nombres, password, id_rol, active, fecha_elim, usr_id, intentos, ingreso) VALUES ('ljuarez', 'ljuarez@saren.gob.ve', 12, 'Leonardo Juarez', '$2y$10$N3cewqwWAOqsC76ZP72LzexWgflGI2Gh6dgjyGRz6gC7p436sHzGK', 5, NULL, NULL, NULL, 0, false);
INSERT INTO public.usuario (alias, email, id, nombres, password, id_rol, active, fecha_elim, usr_id, intentos, ingreso) VALUES ('mortiz', 'mortiz@saren.gob.ve', 5, 'Maria Ortiz', '$2y$10$S1Bt3R4ZKxN2..y4pJC0Ie9SHqfJsb1HGzRgxUx.WRJyrENWdqpYm', 3, NULL, NULL, NULL, 0, false);
INSERT INTO public.usuario (alias, email, id, nombres, password, id_rol, active, fecha_elim, usr_id, intentos, ingreso) VALUES ('tcarias', 'tcarias@saren.gob.ve', 7, 'Teresa Carias', '$2y$10$S1Bt3R4ZKxN2..y4pJC0Ie9SHqfJsb1HGzRgxUx.WRJyrENWdqpYm', 4, NULL, NULL, NULL, 0, false);
INSERT INTO public.usuario (alias, email, id, nombres, password, id_rol, active, fecha_elim, usr_id, intentos, ingreso) VALUES ('pvargas', 'pvargas@saren.gob.ve', 8, 'Pedro Vargas', '$2y$10$S1Bt3R4ZKxN2..y4pJC0Ie9SHqfJsb1HGzRgxUx.WRJyrENWdqpYm', 4, NULL, NULL, NULL, 0, false);
INSERT INTO public.usuario (alias, email, id, nombres, password, id_rol, active, fecha_elim, usr_id, intentos, ingreso) VALUES ('hhidalgo', 'hhidalgo@saren.gob.ve', 4, 'Hugo Hidalgo', '$2y$10$TQh0VvtcQynLte0Ky8RW.uL1KCuEdeMvm9DQK1.Me6n5I5cJBOxLO', 2, NULL, NULL, NULL, 0, false);
INSERT INTO public.usuario (alias, email, id, nombres, password, id_rol, active, fecha_elim, usr_id, intentos, ingreso) VALUES ('nalmaro', 'nalmaro@gmail.com', 18, 'Nacho Almaro', '$2y$10$24ADH7fDlmcddkBHNr5GZueJpzmKuZT0Hd/Ql8RcqyrvK9pwSn.D.', 5, false, '2019-04-29', 15, 0, false);
INSERT INTO public.usuario (alias, email, id, nombres, password, id_rol, active, fecha_elim, usr_id, intentos, ingreso) VALUES ('pperez', 'pperez@gmail.com', 19, 'Patricia Perez', '$2y$10$ADvuyQdvglBZdgkU.KWcLOWv78yFz.G82XA/yp4os6v/nWfig4fle', 3, false, '2019-04-29', 15, 0, false);
INSERT INTO public.usuario (alias, email, id, nombres, password, id_rol, active, fecha_elim, usr_id, intentos, ingreso) VALUES ('jcarrasco', 'jcarrasco@gmail.com', 17, 'Juan Carrasco', '$2y$10$S1Bt3R4ZKxN2..y4pJC0Ie9SHqfJsb1HGzRgxUx.WRJyrENWdqpYm', 2, false, '2019-04-29', 15, 0, false);
INSERT INTO public.usuario (alias, email, id, nombres, password, id_rol, active, fecha_elim, usr_id, intentos, ingreso) VALUES ('admin', 'admin@gmail.com', 15, 'Administrador', '$2y$10$JSWErHMjNlv8dWKkPBxcW.yB8rzAd3n7qhh4ag0sL0tIcW1SraYvm', 1, false, '2019-06-13', 13, 0, false);
INSERT INTO public.usuario (alias, email, id, nombres, password, id_rol, active, fecha_elim, usr_id, intentos, ingreso) VALUES ('agallardo', 'agallardo@saren.gob.ve', 20, 'Antonio Gallardo', '$2y$10$NPNAZdqrLlKruLnayK8XtehZHTHLzxABPkZ9EEXTn4tEIvTvubw5i', 2, NULL, NULL, NULL, 0, false);
INSERT INTO public.usuario (alias, email, id, nombres, password, id_rol, active, fecha_elim, usr_id, intentos, ingreso) VALUES ('jlopez', 'jlopez@saren.gob.ve', 6, 'Josefina Lopez', '$2y$10$S1Bt3R4ZKxN2..y4pJC0Ie9SHqfJsb1HGzRgxUx.WRJyrENWdqpYm', 3, NULL, NULL, NULL, 0, false);
INSERT INTO public.usuario (alias, email, id, nombres, password, id_rol, active, fecha_elim, usr_id, intentos, ingreso) VALUES ('lalmaro', 'lalmaros@gmail.com', 13, 'Luis Almaro', '$2y$10$C/R/TlObLQ8L0CPSbzWV0eVgRZcgEqHa7KOL9CjIE2J7VYfp8LIY2', 1, NULL, NULL, NULL, 0, false);
INSERT INTO public.usuario (alias, email, id, nombres, password, id_rol, active, fecha_elim, usr_id, intentos, ingreso) VALUES ('emora', 'emora@saren.gob.ve', 1, 'Enrique Mora', '$2y$10$6FgINsUoONgY1.HQkADPlu/YTcp3dPrM42wGTMrSQkJHkiSg7SzCu', 2, NULL, NULL, NULL, 0, false);
INSERT INTO public.usuario (alias, email, id, nombres, password, id_rol, active, fecha_elim, usr_id, intentos, ingreso) VALUES ('ycontreras', 'ycontreras@saren.gob.ve', 9, 'Yelitza Contreras', '$2y$10$S1Bt3R4ZKxN2..y4pJC0Ie9SHqfJsb1HGzRgxUx.WRJyrENWdqpYm', 5, NULL, NULL, NULL, 0, false);
INSERT INTO public.usuario (alias, email, id, nombres, password, id_rol, active, fecha_elim, usr_id, intentos, ingreso) VALUES ('mperez', 'mperez@saren.gob.ve', 2, 'Mirtha Perez', '$2y$10$S1Bt3R4ZKxN2..y4pJC0Ie9SHqfJsb1HGzRgxUx.WRJyrENWdqpYm', 1, NULL, NULL, NULL, 0, false);


--
-- TOC entry 3570 (class 0 OID 0)
-- Dependencies: 198
-- Name: almacen_id_almacen_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.almacen_id_almacen_seq', 1, true);


--
-- TOC entry 3571 (class 0 OID 0)
-- Dependencies: 200
-- Name: articulo_id_articulo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.articulo_id_articulo_seq', 19475, true);


--
-- TOC entry 3572 (class 0 OID 0)
-- Dependencies: 203
-- Name: departamento_id_departamento_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.departamento_id_departamento_seq', 12, true);


--
-- TOC entry 3573 (class 0 OID 0)
-- Dependencies: 287
-- Name: desincorporacion_id_desincorporacion_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.desincorporacion_id_desincorporacion_seq', 1, true);


--
-- TOC entry 3574 (class 0 OID 0)
-- Dependencies: 205
-- Name: devolucion_id_devolucion_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.devolucion_id_devolucion_seq', 57, true);


--
-- TOC entry 3575 (class 0 OID 0)
-- Dependencies: 217
-- Name: equipo_id_equipo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.equipo_id_equipo_seq', 18, true);


--
-- TOC entry 3576 (class 0 OID 0)
-- Dependencies: 220
-- Name: equipo_marca_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.equipo_marca_id_seq', 1, false);


--
-- TOC entry 3577 (class 0 OID 0)
-- Dependencies: 234
-- Name: estatus_empleado_id_estatus_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.estatus_empleado_id_estatus_seq', 1, false);


--
-- TOC entry 3578 (class 0 OID 0)
-- Dependencies: 236
-- Name: estatus_equipo_id_estatus_eq_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.estatus_equipo_id_estatus_eq_seq', 1, false);


--
-- TOC entry 3579 (class 0 OID 0)
-- Dependencies: 237
-- Name: estatus_equipo_v2_id_estatus_eq_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.estatus_equipo_v2_id_estatus_eq_seq', 1, false);


--
-- TOC entry 3580 (class 0 OID 0)
-- Dependencies: 243
-- Name: funcionario_id_funcionario_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.funcionario_id_funcionario_seq', 1, true);


--
-- TOC entry 3581 (class 0 OID 0)
-- Dependencies: 245
-- Name: marca_id_marca_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.marca_id_marca_seq', 18, true);


--
-- TOC entry 3582 (class 0 OID 0)
-- Dependencies: 247
-- Name: modelo_id_modelo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.modelo_id_modelo_seq', 1, false);


--
-- TOC entry 3583 (class 0 OID 0)
-- Dependencies: 289
-- Name: motivo_id_motivo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.motivo_id_motivo_seq', 5, true);


--
-- TOC entry 3584 (class 0 OID 0)
-- Dependencies: 211
-- Name: oficina_id_oficina_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.oficina_id_oficina_seq', 492, true);


--
-- TOC entry 3585 (class 0 OID 0)
-- Dependencies: 250
-- Name: orden_salida_id_orden_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.orden_salida_id_orden_seq', 10048, true);


--
-- TOC entry 3586 (class 0 OID 0)
-- Dependencies: 257
-- Name: permissions_perm_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.permissions_perm_id_seq', 1, true);


--
-- TOC entry 3587 (class 0 OID 0)
-- Dependencies: 258
-- Name: proveedor_id_proveedor_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.proveedor_id_proveedor_seq', 1, true);


--
-- TOC entry 3588 (class 0 OID 0)
-- Dependencies: 260
-- Name: reserva_id_reserva_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reserva_id_reserva_seq', 30, true);


--
-- TOC entry 3589 (class 0 OID 0)
-- Dependencies: 262
-- Name: role_perm_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.role_perm_id_seq', 144, true);


--
-- TOC entry 3590 (class 0 OID 0)
-- Dependencies: 265
-- Name: roles_role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.roles_role_id_seq', 6, true);


--
-- TOC entry 3591 (class 0 OID 0)
-- Dependencies: 266
-- Name: solicitud_detalle_id_solicitud_detalle_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.solicitud_detalle_id_solicitud_detalle_seq', 66, true);


--
-- TOC entry 3592 (class 0 OID 0)
-- Dependencies: 227
-- Name: solicitud_solicitud_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.solicitud_solicitud_id_seq', 32, true);


--
-- TOC entry 3593 (class 0 OID 0)
-- Dependencies: 275
-- Name: telefono_id_telefono_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.telefono_id_telefono_seq', 1, false);


--
-- TOC entry 3594 (class 0 OID 0)
-- Dependencies: 277
-- Name: ubicacion_id_ubicacion_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ubicacion_id_ubicacion_seq', 1, false);


--
-- TOC entry 3595 (class 0 OID 0)
-- Dependencies: 278
-- Name: ubicacion_v2_id_ubicacion_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ubicacion_v2_id_ubicacion_seq', 1, false);


--
-- TOC entry 3596 (class 0 OID 0)
-- Dependencies: 280
-- Name: user_rol_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_rol_id_seq', 15, true);


--
-- TOC entry 3597 (class 0 OID 0)
-- Dependencies: 282
-- Name: usuario_id_usuario_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.usuario_id_usuario_seq', 19, true);


--
-- TOC entry 3598 (class 0 OID 0)
-- Dependencies: 239
-- Name: usuario_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.usuario_seq', 20, true);


--
-- TOC entry 3059 (class 2606 OID 200738)
-- Name: articulo articulo_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.articulo
    ADD CONSTRAINT articulo_pk PRIMARY KEY (id_articulo);


--
-- TOC entry 3062 (class 2606 OID 200740)
-- Name: cancelacion cancelacion_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cancelacion
    ADD CONSTRAINT cancelacion_pk PRIMARY KEY (id_cancelacion);


--
-- TOC entry 3068 (class 2606 OID 200742)
-- Name: empleado cedula_unica; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.empleado
    ADD CONSTRAINT cedula_unica UNIQUE (cedula);


--
-- TOC entry 3137 (class 2606 OID 200964)
-- Name: desincorporacion desincorporacion_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.desincorporacion
    ADD CONSTRAINT desincorporacion_pk PRIMARY KEY (id_desincorporacion);


--
-- TOC entry 3066 (class 2606 OID 200744)
-- Name: devolucion devolucion_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.devolucion
    ADD CONSTRAINT devolucion_pk PRIMARY KEY (id_devolucion);


--
-- TOC entry 3097 (class 2606 OID 200746)
-- Name: estado estado_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estado
    ADD CONSTRAINT estado_pk PRIMARY KEY (id_estado);


--
-- TOC entry 3101 (class 2606 OID 200748)
-- Name: estatus_solicitud estatus_solicitud_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estatus_solicitud
    ADD CONSTRAINT estatus_solicitud_pk PRIMARY KEY (id_estatus_solicitud);


--
-- TOC entry 3112 (class 2606 OID 200750)
-- Name: municipio municipio_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.municipio
    ADD CONSTRAINT municipio_pk PRIMARY KEY (id_municipio);


--
-- TOC entry 3118 (class 2606 OID 200752)
-- Name: parroquia parroquia_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parroquia
    ADD CONSTRAINT parroquia_pk PRIMARY KEY (id_parroquia);


--
-- TOC entry 3120 (class 2606 OID 200754)
-- Name: permissions permissions_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pk PRIMARY KEY (perm_id);


--
-- TOC entry 3099 (class 2606 OID 200756)
-- Name: estatus_equipo pk_estatus_eq; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estatus_equipo
    ADD CONSTRAINT pk_estatus_eq PRIMARY KEY (id_estatus_eq);


--
-- TOC entry 3085 (class 2606 OID 200758)
-- Name: estatus_equipo_v2 pk_estatus_eq_v2; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estatus_equipo_v2
    ADD CONSTRAINT pk_estatus_eq_v2 PRIMARY KEY (id_estatus_eq);


--
-- TOC entry 3083 (class 2606 OID 200760)
-- Name: equipo_marca pk_id; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipo_marca
    ADD CONSTRAINT pk_id PRIMARY KEY (id);


--
-- TOC entry 3057 (class 2606 OID 200762)
-- Name: almacen pk_id_almacen; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.almacen
    ADD CONSTRAINT pk_id_almacen PRIMARY KEY (id_almacen, id_equipo);


--
-- TOC entry 3064 (class 2606 OID 200764)
-- Name: departamento pk_id_depto; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departamento
    ADD CONSTRAINT pk_id_depto PRIMARY KEY (id_departamento);


--
-- TOC entry 3070 (class 2606 OID 200766)
-- Name: empleado pk_id_empleado; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.empleado
    ADD CONSTRAINT pk_id_empleado PRIMARY KEY (id_empleado);


--
-- TOC entry 3078 (class 2606 OID 200768)
-- Name: equipo_old pk_id_equipo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipo_old
    ADD CONSTRAINT pk_id_equipo PRIMARY KEY (id_equipo);


--
-- TOC entry 3081 (class 2606 OID 200770)
-- Name: equipo pk_id_equipo_v2; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipo
    ADD CONSTRAINT pk_id_equipo_v2 PRIMARY KEY (id_equipo);


--
-- TOC entry 3072 (class 2606 OID 200772)
-- Name: estatus_empleado pk_id_estatus; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estatus_empleado
    ADD CONSTRAINT pk_id_estatus PRIMARY KEY (id_estatus);


--
-- TOC entry 3106 (class 2606 OID 200774)
-- Name: funcionario_old pk_id_funcionario; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.funcionario_old
    ADD CONSTRAINT pk_id_funcionario PRIMARY KEY (id_funcionario);


--
-- TOC entry 3108 (class 2606 OID 200776)
-- Name: marca pk_id_marca; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.marca
    ADD CONSTRAINT pk_id_marca PRIMARY KEY (id_marca);


--
-- TOC entry 3110 (class 2606 OID 200778)
-- Name: modelo pk_id_modelo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modelo
    ADD CONSTRAINT pk_id_modelo PRIMARY KEY (id_modelo);


--
-- TOC entry 3074 (class 2606 OID 200780)
-- Name: oficina pk_id_oficina; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oficina
    ADD CONSTRAINT pk_id_oficina PRIMARY KEY (id_oficina);


--
-- TOC entry 3114 (class 2606 OID 200782)
-- Name: orden_salida pk_id_orden; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orden_salida
    ADD CONSTRAINT pk_id_orden PRIMARY KEY (id_orden);


--
-- TOC entry 3087 (class 2606 OID 200784)
-- Name: proveedor pk_id_proveedor; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.proveedor
    ADD CONSTRAINT pk_id_proveedor PRIMARY KEY (id_proveedor);


--
-- TOC entry 3123 (class 2606 OID 200786)
-- Name: reserva pk_id_reserva; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserva
    ADD CONSTRAINT pk_id_reserva PRIMARY KEY (id_reserva);


--
-- TOC entry 3090 (class 2606 OID 200788)
-- Name: solicitud pk_id_solicitud; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.solicitud
    ADD CONSTRAINT pk_id_solicitud PRIMARY KEY (id_solicitud);


--
-- TOC entry 3131 (class 2606 OID 200790)
-- Name: telefono pk_id_telefono; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.telefono
    ADD CONSTRAINT pk_id_telefono PRIMARY KEY (id_telefono);


--
-- TOC entry 3139 (class 2606 OID 200973)
-- Name: motivo pk_motivo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.motivo
    ADD CONSTRAINT pk_motivo PRIMARY KEY (id_motivo);


--
-- TOC entry 3133 (class 2606 OID 200792)
-- Name: ubicacion pk_ubicacion; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ubicacion
    ADD CONSTRAINT pk_ubicacion PRIMARY KEY (id_ubicacion);


--
-- TOC entry 3076 (class 2606 OID 200794)
-- Name: ubicacion_v2 pk_ubicacion_v2; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ubicacion_v2
    ADD CONSTRAINT pk_ubicacion_v2 PRIMARY KEY (id_ubicacion);


--
-- TOC entry 3125 (class 2606 OID 200796)
-- Name: rol rol_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rol
    ADD CONSTRAINT rol_pk PRIMARY KEY (id_rol);


--
-- TOC entry 3127 (class 2606 OID 200798)
-- Name: role_perm role_perm_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_perm
    ADD CONSTRAINT role_perm_pk PRIMARY KEY (id);


--
-- TOC entry 3129 (class 2606 OID 200800)
-- Name: roles role_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT role_pk PRIMARY KEY (role_id);


--
-- TOC entry 3093 (class 2606 OID 200802)
-- Name: solicitud_detalle solicitud_detalle_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.solicitud_detalle
    ADD CONSTRAINT solicitud_detalle_pk PRIMARY KEY (id_solicitud_detalle);


--
-- TOC entry 3116 (class 2606 OID 200804)
-- Name: tipo_solicitud tipo_solicitud_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_solicitud
    ADD CONSTRAINT tipo_solicitud_pk PRIMARY KEY (id_tipo_solicitud);


--
-- TOC entry 3135 (class 2606 OID 200806)
-- Name: user_role user_role_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_role
    ADD CONSTRAINT user_role_pk PRIMARY KEY (id);


--
-- TOC entry 3104 (class 2606 OID 200808)
-- Name: usuario usuario_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_pk PRIMARY KEY (id);


--
-- TOC entry 3140 (class 1259 OID 208082)
-- Name: logged_actions_action_idx; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX logged_actions_action_idx ON auditoria.logged_actions USING btree (action);


--
-- TOC entry 3141 (class 1259 OID 208081)
-- Name: logged_actions_action_tstamp_idx; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX logged_actions_action_tstamp_idx ON auditoria.logged_actions USING btree (action_tstamp);


--
-- TOC entry 3142 (class 1259 OID 208080)
-- Name: logged_actions_schema_table_idx; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX logged_actions_schema_table_idx ON auditoria.logged_actions USING btree ((((schema_name || '.'::text) || table_name)));


--
-- TOC entry 3060 (class 1259 OID 200809)
-- Name: articulo_pk_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX articulo_pk_index ON public.articulo USING btree (id_articulo);


--
-- TOC entry 3079 (class 1259 OID 200810)
-- Name: equipo_pk_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX equipo_pk_index ON public.equipo USING btree (id_equipo);


--
-- TOC entry 3121 (class 1259 OID 200811)
-- Name: fki_id_equipo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_id_equipo ON public.reserva USING btree (id_equipo);


--
-- TOC entry 3088 (class 1259 OID 200812)
-- Name: fki_id_funcionario; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_id_funcionario ON public.solicitud USING btree (id_funcionario);


--
-- TOC entry 3102 (class 1259 OID 200813)
-- Name: fki_usuario_rol_fk; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_usuario_rol_fk ON public.usuario USING btree (id_rol);


--
-- TOC entry 3094 (class 1259 OID 200814)
-- Name: solicitud_detalle_pk_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX solicitud_detalle_pk_index ON public.solicitud_detalle USING btree (id_solicitud_detalle);


--
-- TOC entry 3091 (class 1259 OID 200815)
-- Name: solicitud_pk_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX solicitud_pk_index ON public.solicitud USING btree (id_solicitud);


--
-- TOC entry 3095 (class 1259 OID 200816)
-- Name: solicitud_slicitud_detalle_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX solicitud_slicitud_detalle_index ON public.solicitud_detalle USING btree (id_solicitud_detalle, id_solicitud);


--
-- TOC entry 3168 (class 2620 OID 208084)
-- Name: almacen t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.almacen FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3169 (class 2620 OID 208085)
-- Name: articulo t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.articulo FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3170 (class 2620 OID 208086)
-- Name: cancelacion t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.cancelacion FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3171 (class 2620 OID 208087)
-- Name: departamento t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.departamento FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3206 (class 2620 OID 208088)
-- Name: desincorporacion t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.desincorporacion FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3172 (class 2620 OID 208089)
-- Name: devolucion t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.devolucion FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3173 (class 2620 OID 208090)
-- Name: dummy t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.dummy FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3174 (class 2620 OID 208091)
-- Name: dummy2 t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.dummy2 FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3175 (class 2620 OID 208092)
-- Name: empleado t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.empleado FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3180 (class 2620 OID 208093)
-- Name: equipo t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.equipo FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3181 (class 2620 OID 208094)
-- Name: equipo_marca t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.equipo_marca FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3179 (class 2620 OID 208095)
-- Name: equipo_old t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.equipo_old FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3186 (class 2620 OID 208096)
-- Name: estado t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.estado FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3176 (class 2620 OID 208097)
-- Name: estatus_empleado t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.estatus_empleado FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3187 (class 2620 OID 208098)
-- Name: estatus_equipo t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.estatus_equipo FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3182 (class 2620 OID 208099)
-- Name: estatus_equipo_v2 t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.estatus_equipo_v2 FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3188 (class 2620 OID 208100)
-- Name: estatus_solicitud t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.estatus_solicitud FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3190 (class 2620 OID 208101)
-- Name: funcionario_old t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.funcionario_old FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3191 (class 2620 OID 208102)
-- Name: marca t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.marca FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3192 (class 2620 OID 208103)
-- Name: modelo t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.modelo FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3207 (class 2620 OID 208104)
-- Name: motivo t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.motivo FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3193 (class 2620 OID 208105)
-- Name: municipio t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.municipio FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3177 (class 2620 OID 208106)
-- Name: oficina t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.oficina FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3194 (class 2620 OID 208107)
-- Name: orden_salida t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.orden_salida FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3196 (class 2620 OID 208108)
-- Name: parroquia t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.parroquia FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3197 (class 2620 OID 208109)
-- Name: permissions t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.permissions FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3183 (class 2620 OID 208110)
-- Name: proveedor t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.proveedor FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3198 (class 2620 OID 208111)
-- Name: reserva t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.reserva FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3199 (class 2620 OID 208112)
-- Name: rol t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.rol FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3200 (class 2620 OID 208113)
-- Name: role_perm t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.role_perm FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3201 (class 2620 OID 208114)
-- Name: roles t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.roles FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3184 (class 2620 OID 208115)
-- Name: solicitud t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.solicitud FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3185 (class 2620 OID 208116)
-- Name: solicitud_detalle t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.solicitud_detalle FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3202 (class 2620 OID 208117)
-- Name: telefono t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.telefono FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3195 (class 2620 OID 208118)
-- Name: tipo_solicitud t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.tipo_solicitud FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3203 (class 2620 OID 208119)
-- Name: ubicacion t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.ubicacion FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3178 (class 2620 OID 208120)
-- Name: ubicacion_v2 t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.ubicacion_v2 FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3204 (class 2620 OID 208121)
-- Name: ult_orden_salida t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.ult_orden_salida FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3205 (class 2620 OID 208122)
-- Name: user_role t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.user_role FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3189 (class 2620 OID 208123)
-- Name: usuario t_if_modified_trg; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER t_if_modified_trg AFTER INSERT OR DELETE OR UPDATE ON public.usuario FOR EACH ROW EXECUTE PROCEDURE auditoria.if_modified_func();


--
-- TOC entry 3150 (class 2606 OID 200817)
-- Name: equipo fk_articulo; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipo
    ADD CONSTRAINT fk_articulo FOREIGN KEY (id_articulo) REFERENCES public.articulo(id_articulo);


--
-- TOC entry 3158 (class 2606 OID 200822)
-- Name: orden_salida fk_eq; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orden_salida
    ADD CONSTRAINT fk_eq FOREIGN KEY (id_equipo) REFERENCES public.equipo_old(id_equipo);


--
-- TOC entry 3151 (class 2606 OID 200827)
-- Name: equipo_marca fk_equipo; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipo_marca
    ADD CONSTRAINT fk_equipo FOREIGN KEY (id_equipo) REFERENCES public.equipo_old(id_equipo);


--
-- TOC entry 3144 (class 2606 OID 200832)
-- Name: empleado fk_id_depto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.empleado
    ADD CONSTRAINT fk_id_depto FOREIGN KEY (id_departamento) REFERENCES public.departamento(id_departamento);


--
-- TOC entry 3159 (class 2606 OID 200837)
-- Name: orden_salida fk_id_emp; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orden_salida
    ADD CONSTRAINT fk_id_emp FOREIGN KEY (id_emp) REFERENCES public.empleado(id_empleado);


--
-- TOC entry 3164 (class 2606 OID 200842)
-- Name: telefono fk_id_empl; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.telefono
    ADD CONSTRAINT fk_id_empl FOREIGN KEY (id_empleado) REFERENCES public.empleado(id_empleado);


--
-- TOC entry 3153 (class 2606 OID 200847)
-- Name: solicitud fk_id_empleado; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.solicitud
    ADD CONSTRAINT fk_id_empleado FOREIGN KEY (id_empleado) REFERENCES public.empleado(id_empleado);


--
-- TOC entry 3165 (class 2606 OID 200852)
-- Name: ubicacion fk_id_eqpo; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ubicacion
    ADD CONSTRAINT fk_id_eqpo FOREIGN KEY (id_equipo) REFERENCES public.equipo_old(id_equipo);


--
-- TOC entry 3143 (class 2606 OID 200857)
-- Name: almacen fk_id_equipo; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.almacen
    ADD CONSTRAINT fk_id_equipo FOREIGN KEY (id_equipo) REFERENCES public.equipo_old(id_equipo);


--
-- TOC entry 3161 (class 2606 OID 200862)
-- Name: reserva fk_id_equipo; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserva
    ADD CONSTRAINT fk_id_equipo FOREIGN KEY (id_equipo) REFERENCES public.equipo(id_equipo);


--
-- TOC entry 3148 (class 2606 OID 200867)
-- Name: equipo_old fk_id_estatus; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipo_old
    ADD CONSTRAINT fk_id_estatus FOREIGN KEY (id_estatus) REFERENCES public.estatus_equipo(id_estatus_eq);


--
-- TOC entry 3145 (class 2606 OID 200872)
-- Name: empleado fk_id_estatus; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.empleado
    ADD CONSTRAINT fk_id_estatus FOREIGN KEY (id_estatus) REFERENCES public.estatus_empleado(id_estatus);


--
-- TOC entry 3154 (class 2606 OID 200877)
-- Name: solicitud fk_id_funcionario; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.solicitud
    ADD CONSTRAINT fk_id_funcionario FOREIGN KEY (id_funcionario) REFERENCES public.empleado(id_empleado);


--
-- TOC entry 3156 (class 2606 OID 200882)
-- Name: modelo fk_id_marca; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modelo
    ADD CONSTRAINT fk_id_marca FOREIGN KEY (id_marca) REFERENCES public.marca(id_marca);


--
-- TOC entry 3147 (class 2606 OID 200887)
-- Name: oficina fk_id_parroquia; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oficina
    ADD CONSTRAINT fk_id_parroquia FOREIGN KEY (id_parroquia) REFERENCES public.parroquia(id_parroquia);


--
-- TOC entry 3146 (class 2606 OID 200892)
-- Name: empleado fk_id_tlf; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.empleado
    ADD CONSTRAINT fk_id_tlf FOREIGN KEY (id_telefono) REFERENCES public.telefono(id_telefono);


--
-- TOC entry 3152 (class 2606 OID 200897)
-- Name: equipo_marca fk_marca; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipo_marca
    ADD CONSTRAINT fk_marca FOREIGN KEY (id_marca) REFERENCES public.marca(id_marca);


--
-- TOC entry 3162 (class 2606 OID 200902)
-- Name: role_perm fk_perm_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_perm
    ADD CONSTRAINT fk_perm_id FOREIGN KEY (perm_id) REFERENCES public.permissions(perm_id);


--
-- TOC entry 3163 (class 2606 OID 200907)
-- Name: role_perm fk_role_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_perm
    ADD CONSTRAINT fk_role_id FOREIGN KEY (role_id) REFERENCES public.roles(role_id);


--
-- TOC entry 3166 (class 2606 OID 200912)
-- Name: user_role fk_role_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_role
    ADD CONSTRAINT fk_role_id FOREIGN KEY (role_id) REFERENCES public.roles(role_id);


--
-- TOC entry 3149 (class 2606 OID 200917)
-- Name: equipo_old fk_ubicacion; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipo_old
    ADD CONSTRAINT fk_ubicacion FOREIGN KEY (id_ubicacion) REFERENCES public.ubicacion(id_ubicacion);


--
-- TOC entry 3167 (class 2606 OID 200922)
-- Name: user_role fk_user_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_role
    ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES public.usuario(id);


--
-- TOC entry 3157 (class 2606 OID 200927)
-- Name: municipio municipio_id_estado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.municipio
    ADD CONSTRAINT municipio_id_estado_fkey FOREIGN KEY (id_estado) REFERENCES public.estado(id_estado);


--
-- TOC entry 3160 (class 2606 OID 200932)
-- Name: parroquia parroquia_id_municipio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parroquia
    ADD CONSTRAINT parroquia_id_municipio_fkey FOREIGN KEY (id_municipio) REFERENCES public.municipio(id_municipio);


--
-- TOC entry 3155 (class 2606 OID 200937)
-- Name: usuario usuario_rol_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_rol_fk FOREIGN KEY (id_rol) REFERENCES public.rol(id_rol);


--
-- TOC entry 3432 (class 0 OID 0)
-- Dependencies: 294
-- Name: TABLE logged_actions; Type: ACL; Schema: auditoria; Owner: postgres
--

GRANT SELECT ON TABLE auditoria.logged_actions TO PUBLIC;


-- Completed on 2019-07-01 22:24:58

--
-- PostgreSQL database dump complete
--

