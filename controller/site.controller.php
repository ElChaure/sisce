<?php
session_start();

require_once 'model/usuario.php';

class SiteController{
    
    private $model;
    
    public function __CONSTRUCT(){
        $this->model = new Usuario();
    }
    
    public function Index(){
        $reslt = $this->model->getlogin();
        if (!isset($_SESSION['usuario']))
        {
           require_once 'view/header.php';
           require_once 'view/site/login3.php';
           require_once 'view/footer.php';
        }
        else
        {
            require_once 'view/header.php';
            require_once 'view/site/index.php';
            require_once 'view/footer.php';
        }
     
    }
	
	public function Error(){
        require_once 'view/header.php';
        require_once 'view/site/error.php';
        require_once 'view/footer.php';
    }

   public function Cerrarsesion(){
        //$usuario= new Usuario();
        //$registra_salida=$usuario->logout();
        $registra_salida = $this->model->logout();
        session_destroy();
        header('Location: index.php');
    }

}