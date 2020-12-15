<?php
session_start();
//require_once 'model/sesion.php';
require_once 'model/permissions.php';

class PermissionsController{
    
    private $model;
    
    public function __CONSTRUCT(){
        $this->model = new Permissions();
    }
    
    public function Index(){
        require_once 'view/header.php';
        require_once 'view/permissions/permissions.php';
        require_once 'view/footer.php';
    }
    
    public function Crud(){
        $perm = new Permissions();
        
        if(isset($_REQUEST['perm_id'])){
            $perm = $this->model->Obtener($_REQUEST['perm_id']);
        }
        
        require_once 'view/header.php';
        require_once 'view/permissions/permissions-editar.php';
        require_once 'view/footer.php';
    }
    
    public function Guardar(){
        $perm = new Permissions();
     
        $perm->perm_id = $_REQUEST['perm_id'];
        $perm->perm_desc = $_REQUEST['perm_desc'];
        $perm->accion = $_REQUEST['accion'];
        
        $perm->perm_id > 0 
            ? $this->model->Actualizar($perm)
            : $this->model->Registrar($perm);
        
        header('Location: index.php?c=Permissions');
    }
    
    public function Eliminar(){
        $this->model->Eliminar($_REQUEST['perm_id']);
        header('Location: index.php?c=Permissions');
    }
}