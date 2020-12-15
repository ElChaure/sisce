<?php
session_start();
//require_once 'model/sesion.php';
require_once 'model/usuario.php';

class UsuarioController{
    
    private $model;
    
    public function __CONSTRUCT(){
        $this->model = new Usuario();
    }
    
    public function Index(){
        require_once 'view/header.php';
        require_once 'view/usuario/usuario.php';
        require_once 'view/footer.php';
    }
    
    public function Crud(){
        $usu = new Usuario();
        
        if(isset($_REQUEST['id'])){
            $usu = $this->model->Obtener($_REQUEST['id']);
        }
        
        require_once 'view/header.php';
        require_once 'view/usuario/usuario-editar.php';
        require_once 'view/footer.php';
    }
    
    public function Guardar(){
        $usu = new Usuario();
        
        $usu->alias = $_REQUEST['alias'];
        $usu->email = $_REQUEST['email'];
		$usu->id = $_REQUEST['id'];
        $usu->nombres = $_REQUEST['nombres'];
        $usu->password = $_REQUEST['password'];
        $usu->id_rol = $_REQUEST['id_rol'];
        

        $usu->id > 0 
            ? $this->model->Actualizar($usu)
            : $this->model->Registrar($usu);
        
        header('Location: index.php?c=Usuario');
    }
    
    public function Eliminar(){
        $this->model->Eliminar($_REQUEST['id']);
        header('Location: index.php?c=Usuario');
    }

    public function Desbloquear(){
        $this->model->Desbloquear($_REQUEST['id']);
        header('Location: index.php?c=Usuario');
    }

    public function Listar()
    {
        print_r($this->model->Listar());  
    }

    public function Listar_ajax()
    {
        $this->model->Listar_pag();
    }
}