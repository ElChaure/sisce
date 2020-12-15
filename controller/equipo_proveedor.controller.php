<?php
session_start();
require_once 'model/equipo_proveedor.php';

class Equipo_proveedorController{
    
    private $model;
    
    public function __CONSTRUCT(){
        $this->model = new Equipo_proveedor();
    }
    
    public function Index(){
        require_once 'view/header.php';
        require_once 'view/equipo_proveedor/equipo_proveedor.php';
        require_once 'view/footer.php';
    }
    
    public function Crud(){
        $eqm = new Equipo_proveedor();
        
        if(isset($_REQUEST['id'])){
            $eqm = $this->model->Obtener($_REQUEST['id']);
        }
        
        require_once 'view/header.php';
        require_once 'view/equipo_proveedor/equipo_proveedor-editar.php';
        require_once 'view/footer.php';
    }
    
    public function Guardar(){
        $eqm = new Equipo_proveedor();
       
        $eqm->id = $_REQUEST['id'];
        $eqm->id_equipo = $_REQUEST['id_equipo'];
        $eqm->id_proveedor = $_REQUEST['id_proveedor'];


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