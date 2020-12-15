<?php
session_start();
//require_once 'model/sesion.php';
require_once 'model/proveedor.php';

class ProveedorController{
    
    private $model;
    
    public function __CONSTRUCT(){
        $this->model = new Proveedor();
    }
    
    public function Index(){
        require_once 'view/header.php';
        require_once 'view/proveedor/proveedor.php';
        require_once 'view/footer.php';
    }
    
    public function Crud(){
        $pro = new Proveedor();
        
        if(isset($_REQUEST['id_proveedor'])){
            $pro = $this->model->Obtener($_REQUEST['id_proveedor']);
        }
        
        require_once 'view/header.php';
        require_once 'view/proveedor/proveedor-editar.php';
        require_once 'view/footer.php';
    }
    
    public function Guardar(){
        $pro = new Proveedor();
       
        $pro->id_proveedor = $_REQUEST['id_proveedor'];
        $pro->nombre_prov = $_REQUEST['nombre_prov'];
        $pro->direccion = $_REQUEST['direccion'];
        $pro->telefono = $_REQUEST['telefono'];        
        $pro->apellido_prov = $_REQUEST['apellido_prov'];                

        $pro->id_proveedor > 0 
            ? $this->model->Actualizar($pro)
            : $this->model->Registrar($pro);
        
        header('Location: index.php?c=Proveedor');
    }
    
    public function Eliminar(){
        $this->model->Eliminar($_REQUEST['id_proveedor']);
        header('Location: index.php?c=Proveedor');
    }
}