<?php
session_start();
//require_once 'model/sesion.php';
require_once 'model/equipo_disponible.php';
require_once 'model/desincorporacion.php';

class DesincorporacionController{
    
    private $model;
    
    public function __CONSTRUCT(){
        $this->model = new Equipo_disponible();
    }
    
    public function Index(){
        require_once 'view/header.php';
        require_once 'view/desincorporacion/desincorporacion.php';
        require_once 'view/footer.php';
    }
    
    public function Crud(){
        $des = new Desincorporacion();
        
        if(isset($_REQUEST['id_desincorporacion'])){
            $des = $this->model->Obtener($_REQUEST['id_desincorporacion']);
        }
        
        require_once 'view/header.php';
        require_once 'view/desincorporacion/desincorporacion-editar.php';
        require_once 'view/footer.php';
    }
    
    public function Guardar(){
        $des = new Desincorporacion();
        $des->id_desincorporacion = $_REQUEST['id_desincorporacion'];
        $des->id_motivo = $_REQUEST['id_motivo'];
        //$des->fecha_desincorporacion = $_REQUEST['fecha_desincorporacion'];
        //$des->id_funcionario = $_REQUEST['id_funcionario'];
        $des->observacion = $_REQUEST['observacion'];
        $des->id_equipo = $_REQUEST['id_equipo'];
        $des->id_empleado_notifica = $_REQUEST['id_empleado_notifica'];


        $des->id_desincorporacion > 0 
            ? $this->model->Actualizar($des)
            : $this->model->Registrar($des);
        
        header('Location: index.php?c=equipos');
    }
    
    public function Eliminar(){
        $this->model->Eliminar($_REQUEST['id_desincorporacion']);
        header('Location: index.php?c=equipo');
    }
 
    public function Desincorporar(){
        $dev = new Desincorporacion();
        $dev->Desincorporar($_REQUEST['id_motivo'],$_REQUEST['observacion'],$_REQUEST['id_equipo'],$_REQUEST['id_empleado_notifica']);
        header('Location: index.php?c=equipo');
    }

}