<?php
session_start();
//require_once 'model/sesion.php';
require_once 'model/roles.php';

class RolesController{
    
    private $model;
    
    public function __CONSTRUCT(){
        $this->model = new Roles();
    }
    
    public function Index(){
        require_once 'view/header.php';
        require_once 'view/roles/roles.php';
        require_once 'view/footer.php';
    }
    
    public function Crud(){
        $rol = new Roles();
        
        if(isset($_REQUEST['role_id'])){
            $rol = $this->model->Obtener($_REQUEST['role_id']);
        }
        
        require_once 'view/header.php';
        require_once 'view/roles/roles-editar.php';
        require_once 'view/footer.php';
    }
    
    public function Guardar(){
        $rol = new Roles();
       
        $rol->role_id = $_REQUEST['role_id'];
        $rol->role_name = $_REQUEST['role_name'];


        $rol->role_id > 0 
            ? $this->model->Actualizar($rol)
            : $this->model->Registrar($rol);
        
        header('Location: index.php?c=Roles');
    }
    
    public function Eliminar(){
        $this->model->Eliminar($_REQUEST['role_id']);
        header('Location: index.php?c=Roles');
    }
}