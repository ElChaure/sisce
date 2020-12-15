<?php
session_start();
require_once 'model/equipo_marca.php';

class Equipo_marcaController{
    
    private $model;
    
    public function __CONSTRUCT(){
        $this->model = new Equipo_marca();
    }
    
    public function Index(){
        require_once 'view/header.php';
        require_once 'view/equipo_marca/equipo_marca.php';
        require_once 'view/footer.php';
    }
    
    public function Crud(){
        $eqm = new Equipo_marca();
        
        if(isset($_REQUEST['id'])){
            $eqm = $this->model->Obtener($_REQUEST['id']);
        }
        
        require_once 'view/header.php';
        require_once 'view/equipo_marca/equipo_marca-editar.php';
        require_once 'view/footer.php';
    }
    
    public function Guardar(){
        $eqm = new Equipo_marca();
       
        $eqm->id = $_REQUEST['id'];
        $eqm->id_equipo = $_REQUEST['id_equipo'];
        $eqm->id_marca = $_REQUEST['id_marca'];


        $eqm->id > 0 
            ? $this->model->Actualizar($eqm)
            : $this->model->Registrar($eqm);
        
        header('Location: index.php');
    }
    
    public function Eliminar(){
        $this->model->Eliminar($_REQUEST['id']);
        header('Location: index.php');
    }
}