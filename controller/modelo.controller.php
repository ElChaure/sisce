<?php
session_start();
require_once 'model/modelo.php';

class ModeloController{
    
    private $model;
    
    public function __CONSTRUCT(){
        $this->model = new Modelo();
    }
    
    public function Index(){
        require_once 'view/header.php';
        require_once 'view/modelo/modelo.php';
        require_once 'view/footer.php';
    }
    
    public function Crud(){
        $mod = new Modelo();
        
        if(isset($_REQUEST['id_modelo'])){
            $mod = $this->model->Obtener($_REQUEST['id_modelo']);
        }
        
        require_once 'view/header.php';
        require_once 'view/modelo/modelo-editar.php';
        require_once 'view/footer.php';
    }
    
    public function Guardar(){
        $mod = new Modelo();
       
        $mod->id_modelo = $_REQUEST['id_modelo'];
        $mod->id_equipo = $_REQUEST['id_equipo'];
        $mod->id_marca = $_REQUEST['id_marca'];
        $mod->descripcion = $_REQUEST['descripcion'];
        

        $mod->id_modelo > 0 
            ? $this->model->Actualizar($mod)
            : $this->model->Registrar($mod);
        
        header('Location: index.php?c=Modelo');
    }
    
    public function Eliminar(){
        $this->model->Eliminar($_REQUEST['id_modelo']);
        header('Location: index.php?c=Modelo');
    }
}