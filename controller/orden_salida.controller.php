<?php
session_start();
//require_once 'model/sesion.php';
require_once 'model/orden_salida.php';

class Orden_salidaController{
    
    private $model;
    
    public function __CONSTRUCT(){
        $this->model = new Orden_salida();
    }
    
    public function Index(){
        require_once 'view/header.php';
        require_once 'view/orden_salida/orden_salida.php';
        require_once 'view/footer.php';
    }
    
    public function Crud(){
        $ord = new Orden_salida();
        
        if(isset($_REQUEST['id_orden_salida'])){
            $ord = $this->model->Obtener($_REQUEST['id_orden_salida']);
        }
        
        require_once 'view/header.php';
        require_once 'view/orden_salida/orden_salida-editar.php';
        require_once 'view/footer.php';
    }
    
    public function Guardar(){
        $ord = new Orden_salida();
       
        $ord->id_orden_salida = $_REQUEST['id_orden_salida'];
        $ord->num_orden = $_REQUEST['num_orden'];
        $ord->id_solicitud = $_REQUEST['id_solicitud'];
        $ord->observacion = $_REQUEST['observacion'];
        $ord->id_emp = $_REQUEST['id_emp'];
        $ord->id_funcionario = $_REQUEST['id_funcionario'];
        $ord->id_equipo = $_REQUEST['id_equipo'];        
        

        $ord->id_orden_salida > 0 
            ? $this->model->Actualizar($ord)
            : $this->model->Registrar($ord);
        
        header('Location: index.php?c=Orden_salida');
    }
    
    public function Eliminar(){
        $this->model->Eliminar($_REQUEST['id_orden_salida']);
        header('Location: index.php?c=Orden_salida');
    }
}