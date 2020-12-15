<?php
session_start();
require_once 'model/ubicacion.php';

class UbicacionController{
    
    private $model;
    
    public function __CONSTRUCT(){
        $this->model = new Ubicacion();
    }
    
    public function Index(){
        require_once 'view/header.php';
        require_once 'view/ubicacion/ubicacion.php';
        require_once 'view/footer.php';
    }
    
    public function Crud(){
        $ubi = new Ubicacion();
        
        if(isset($_REQUEST['id_ubicacion'])){
            $ubi = $this->model->Obtener($_REQUEST['id_ubicacion']);
        }
        
        require_once 'view/header.php';
        require_once 'view/ubicacion/ubicacion-editar.php';
        require_once 'view/footer.php';
    }
    
    public function Guardar(){
        $ubi = new Ubicacion();
       
        $ubi->id_ubicacion = $_REQUEST['id_ubicacion'];
        $ubi->ubicacion = $_REQUEST['ubicacion'];        
        $ubi->id_equipo = $_REQUEST['id_equipo'];

 

        $ubi->id_ubicacion > 0 
            ? $this->model->Actualizar($ubi)
            : $this->model->Registrar($ubi);
        
        header('Location: index.php?c=Ubicacion');
    }
    
    public function Eliminar(){
        $this->model->Eliminar($_REQUEST['id_ubicacion']);
        header('Location: index.php?c=Ubicacion');
    }
}