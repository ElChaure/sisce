<?php
session_start();
require_once 'model/user_role.php';

class User_roleController{
    
    private $model;
    
    public function __CONSTRUCT(){
        $this->model = new User_role();
    }
    
    public function Index(){
        require_once 'view/header.php';
        require_once 'view/user_role/user_role.php';
        require_once 'view/footer.php';
    }
    
    public function Crud(){
        $urole = new User_role();
        
        if(isset($_REQUEST['id'])){
            $urole = $this->model->Obtener($_REQUEST['id']);
        }
        
        require_once 'view/header.php';
        require_once 'view/user_role/user_role-editar.php';
        require_once 'view/footer.php';
    }
    
    public function Guardar(){
        $urole = new User_role();
       
        $urole->id = $_REQUEST['id'];
        $urole->user_id = $_REQUEST['user_id'];
        $urole->role_id = $_REQUEST['role_id'];
        
        $urole->id > 0 
            ? $this->model->Actualizar($urole)
            : $this->model->Registrar($urole);
        
        header('Location: index.php?c=User_role');
    }
    
    public function Eliminar(){
        $this->model->Eliminar($_REQUEST['id']);
        header('Location: index.php?c=User_role');
    }
}