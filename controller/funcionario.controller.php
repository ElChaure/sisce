<?php
session_start();
require_once 'model/funcionario.php';

class FuncionarioController{
    
    private $model;
    
    public function __CONSTRUCT(){
        $this->model = new Funcionario();
    }
    
    public function Index(){
        require_once 'view/header.php';
        require_once 'view/funcionario/funcionario.php';
        require_once 'view/footer.php';
    }
    
    public function Crud(){
        $fun = new Funcionario();
        
        if(isset($_REQUEST['id_funcionario'])){
            $fun = $this->model->Obtener($_REQUEST['id_funcionario']);
        }
        
        require_once 'view/header.php';
        require_once 'view/funcionario/funcionario-editar.php';
        require_once 'view/footer.php';
    }
    
    public function Guardar(){
        $fun = new Funcionario();
       
        $fun->id_funcionario = $_REQUEST['id_funcionario'];
        $fun->id_oficina = $_REQUEST['id_oficina'];
        $fun->nombre = $_REQUEST['nombre'];
        $fun->apellido = $_REQUEST['apellido'];
        $fun->cedula = $_REQUEST['cedula'];
        $fun->telefono = $_REQUEST['telefono'];
        $fun->email = $_REQUEST['email'];
        $fun->cargo = $_REQUEST['cargo'];

        $fun->id_funcionario > 0 
            ? $this->model->Actualizar($fun)
            : $this->model->Registrar($fun);
        
        header('Location: index.php?c=Funcionario');
    }
    
    public function Eliminar(){
        $this->model->Eliminar($_REQUEST['id_funcionario']);
        header('Location: index.php?c=Funcionario');
    }
}