<?php
session_start();
require_once 'model/estatus_equipo.php';

class Estatus_equipoController{
    
    private $model;
    
    public function __CONSTRUCT(){
        $this->model = new Estatus_equipo();
    }
    
    public function Index(){
        require_once 'view/header.php';
        require_once 'view/estatus_equipo/estatus_equipo.php';
        require_once 'view/footer.php';
    }
    
    public function Crud(){
        $esteq = new Estatus_equipo();
        
        if(isset($_REQUEST['id_estatus_eq'])){
            $esteq = $this->model->Obtener($_REQUEST['id_estatus_eq']);
        }
        
        require_once 'view/header.php';
        require_once 'view/estatus_equipo/estatus_equipo-editar.php';
        require_once 'view/footer.php';
    }
    
    public function Guardar(){
        $esteq = new Estatus_equipo();
       
        $esteq->id_estatus_eq = $_REQUEST['id_estatus_eq'];
        $esteq->id_equipo = $_REQUEST['id_equipo'];
        $esteq->estatus = $_REQUEST['estatus'];


        $esteq->id_estatus_eq > 0 
            ? $this->model->Actualizar($esteq)
            : $this->model->Registrar($esteq);
        
        header('Location: index.php');
    }
    
    public function Eliminar(){
        $this->model->Eliminar($_REQUEST['id_estatus_eq']);
        header('Location: index.php');
    }
}