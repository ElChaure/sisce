<?php
session_start();
//require_once 'model/sesion.php';
require_once 'model/departamento.php';

class DepartamentoController{
    
    private $model;
    
    public function __CONSTRUCT(){
        $this->model = new Departamento();
    }
    
    public function Index(){
        require_once 'view/header.php';
        require_once 'view/departamento/departamento.php';
        require_once 'view/footer.php';
    }
    
    public function Crud(){
        $dep = new Departamento();
        
        if(isset($_REQUEST['id_departamento'])){
            $dep = $this->model->Obtener($_REQUEST['id_departamento']);
        }
        
        require_once 'view/header.php';
        require_once 'view/departamento/departamento-editar.php';
        require_once 'view/footer.php';
    }
    
    public function Guardar(){
        $dep = new Departamento();
       
        $dep->id_departamento = $_REQUEST['id_departamento'];
        $dep->nombre = $_REQUEST['nombre'];
        $dep->telf_departamento = $_REQUEST['telf_departamento'];



        $dep->id_departamento > 0 
            ? $this->model->Actualizar($dep)
            : $this->model->Registrar($dep);
        
        header('Location: index.php?c=Departamento');
    }
    
    public function Eliminar(){
        $this->model->Eliminar($_REQUEST['id_departamento']);
        header('Location: index.php?c=Departamento');
    }
}