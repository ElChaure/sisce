<?php
session_start();
require_once 'model/usuario.php';

class LoginController{
    
    private $model;
    
    public function __CONSTRUCT(){
        $this->model = new Usuario();
    }
    
    public function Index(){
        require_once 'view/header.php';
        require_once 'view/site/login3.php';
        require_once 'view/footer.php';
    }
}