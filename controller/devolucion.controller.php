<?php
session_start();
//require_once 'model/sesion.php';
require_once 'model/equipos_itinerantes.php';
require_once 'model/devolucion.php';

class DevolucionController{
    
    private $model;
    
    public function __CONSTRUCT(){
        $this->model = new Equipos_itinerantes();
    }
    
    public function Index(){
        require_once 'view/header.php';
        require_once 'view/devolucion/devolucion.php';
        require_once 'view/footer.php';
    }

    public function Devoluciones(){
        require_once 'view/header.php';
        require_once 'view/devolucion/devoluciones.php';
        require_once 'view/footer.php';
    }


    
    public function Crud(){
        $equ = new Equipo();
        
        if(isset($_REQUEST['id_equipo'])){
            $equ = $this->model->Obtener($_REQUEST['id_equipo']);
        }
        
        require_once 'view/header.php';
        require_once 'view/devolucion/devolucion-editar.php';
        require_once 'view/footer.php';
    }
    
    public function Guardar(){
        $equ = new Equipos_itinerantes();

        $equ->id_equipo = $_REQUEST['id_equipo']; 
        $equ->cod_equipo = $_REQUEST['cod_equipo']; 
        $equ->serial = $_REQUEST['serial'];
        $equ->num_bien_nac = $_REQUEST['num_bien_nac']; 
        $equ->descripcion_equipo = $_REQUEST['descripcion_equipo']; 
        $equ->articulo = $_REQUEST['articulo'];
        $equ->id_solicitud = $_REQUEST['id_solicitud']; 
        $equ->id_funcionario = $_REQUEST['id_funcionario']; 
        $equ->id_empleado = $_REQUEST['id_empleado'];
        $equ->descripcion_solicitud = $_REQUEST['descripcion_solicitud']; 
        $equ->fecha_solicitud = $_REQUEST['fecha_solicitud'];
        $equ->primer_apellido = $_REQUEST['primer_apellido']; 
        $equ->segundo_apellido = $_REQUEST['segundo_apellido']; 
        $equ->primer_nombre = $_REQUEST['primer_nombre'];
        $equ->segundo_nombre = $_REQUEST['segundo_nombre']; 
        $equ->apellido = $_REQUEST['apellido'];
        $equ->nombre = $_REQUEST['nombre']; 
        $equ->estatus = $_REQUEST['estatus'];
        $equ->id_solicitud_detalle_reserva = $_REQUEST['id_solicitud_detalle_reserva'];

        $equ->id_equipo > 0 
            ? $this->model->Actualizar($equ)
            : $this->model->Registrar($equ);
        
        header('Location: index.php?c=equipos_itinerantes');
    }
    
    public function Eliminar(){
        $this->model->Eliminar($_REQUEST['id_equipo']);
        header('Location: index.php?c=equipo');
    }
 
    public function Devolver(){
        $dev = new Devolucion();
        $dev->Devolver($_REQUEST['id_empleado_entrega'],$_REQUEST['id_equipo'],$_REQUEST['observacion']);
        header('Location: index.php?c=devolucion');
    }

}