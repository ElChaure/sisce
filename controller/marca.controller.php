<?php
session_start();
//require_once 'model/sesion.php';
require_once 'model/marca.php';

class MarcaController{
    
    private $model;
    
    public function __CONSTRUCT(){
        $this->model = new Marca();
    }
    
    public function Index(){
        require_once 'view/header.php';
        require_once 'view/marca/marca.php';
        require_once 'view/footer.php';
    }
    
    public function Crud(){
        $mar = new Marca();
        
        if(isset($_REQUEST['id_marca'])){
            $mar = $this->model->Obtener($_REQUEST['id_marca']);
        }
        
        require_once 'view/header.php';
        require_once 'view/marca/marca-editar.php';
        require_once 'view/footer.php';
    }
    
    public function Guardar(){
        $mar = new Marca();
       
        $mar->id_marca = $_REQUEST['id_marca'];
        $mar->descripcion = $_REQUEST['descripcion'];
        

        $mar->id_marca > 0 
            ? $this->model->Actualizar($mar)
            : $this->model->Registrar($mar);
        
        header('Location:index.php?c=Marca');
    }
    
    public function Eliminar(){
        $this->model->Eliminar($_REQUEST['id_marca']);
        header('Location: index.php?c=Marca');
    }
}