<?php
session_start();
require_once 'model/telefono.php';

class TelefonoController{
    
    private $model;
    
    public function __CONSTRUCT(){
        $this->model = new Telefono();
    }
    
    public function Index(){
        require_once 'view/header.php';
        require_once 'view/telefono/telefono.php';
        require_once 'view/footer.php';
    }
    
    public function Crud(){
        $tel = new Telefono();
        
        if(isset($_REQUEST['id_telefono'])){
            $tel = $this->model->Obtener($_REQUEST['id_telefono']);
        }
        
        require_once 'view/header.php';
        require_once 'view/telefono/telefono-editar.php';
        require_once 'view/footer.php';
    }
    
    public function Guardar(){
        $tel = new Telefono();
       
        $tel->id_telefono = $_REQUEST['id_telefono'];
        $tel->num_telefono = $_REQUEST['num_telefono'];        
        $tel->id_empleado = $_REQUEST['id_empleado'];

 

        $tel->id_telefono > 0 
            ? $this->model->Actualizar($tel)
            : $this->model->Registrar($tel);
        
        header('Location: index.php?c=Telefono');
    }
    
    public function Eliminar(){
        $this->model->Eliminar($_REQUEST['id_telefono']);
        header('Location: index.php?c=Telefono');
    }
}