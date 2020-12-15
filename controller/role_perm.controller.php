<?php
session_start();
//require_once 'model/sesion.php';
require_once 'model/role_perm.php';

class Role_permController{
    
    private $model;
    
    public function __CONSTRUCT(){
        $this->model = new Role_perm();
    }
    
    public function Index(){
        require_once 'view/header.php';
        require_once 'view/role_perm/role_perm.php';
        require_once 'view/footer.php';
    }
    
    public function Crud(){
        $rolep = new Role_perm();
        
        if(isset($_REQUEST['id'])){
            $rolep = $this->model->Obtener($_REQUEST['id']);
        }
        
        require_once 'view/header.php';
        require_once 'view/role_perm/role_perm-editar.php';
        require_once 'view/footer.php';
    }
    
    public function Guardar(){
        $rolep = new Role_perm();
       
        $rolep->id = $_REQUEST['id'];
        $rolep->perm_id = $_REQUEST['perm_id'];
        $rolep->role_id = $_REQUEST['role_id'];
        
        $rolep->id > 0 
            ? $this->model->Actualizar($rolep)
            : $this->model->Registrar($rolep);
        
        header('Location: index.php?c=Role_perm');
    }
    
    public function Eliminar(){
        $this->model->Eliminar($_REQUEST['id']);
        header('Location: index.php?c=Role_perm');
    }
}