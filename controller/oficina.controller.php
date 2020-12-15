<?php
session_start();
//require_once 'model/sesion.php';
require_once 'model/oficina.php';

class OficinaController{
    
    private $model;
    
    public function __CONSTRUCT(){
        $this->model = new Oficina();
    }
    
    public function Index(){
        require_once 'view/header.php';
        require_once 'view/oficina/oficina.php';
        require_once 'view/footer.php';
    }
    
    public function Crud(){
        $ofi = new Oficina();
        
        if(isset($_REQUEST['id_oficina'])){
            $ofi = $this->model->Obtener($_REQUEST['id_oficina']);
        }
        
        require_once 'view/header.php';
        require_once 'view/oficina/oficina-editar.php';
        require_once 'view/footer.php';
    }
    
    public function Guardar(){
        $ofi = new Oficina();
       
        $ofi->id_oficina = $_REQUEST['id_oficina'];
        $ofi->nombre_oficina = $_REQUEST['nombre_oficina'];
        $ofi->direccion = $_REQUEST['direccion'];
        $ofi->telefono = $_REQUEST['telefono'];
        $ofi->id_parroquia = $_REQUEST['id_parroquia'];
        

        $ofi->id_oficina > 0 
            ? $this->model->Actualizar($ofi)
            : $this->model->Registrar($ofi);
        
        header('Location: index.php?c=Oficina');
    }
    
    public function Eliminar(){
        $this->model->Eliminar($_REQUEST['id_oficina']);
        header('Location: index.php?c=Oficina');
    }
}