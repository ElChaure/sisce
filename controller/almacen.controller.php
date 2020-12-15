<?php
session_start();
//require_once 'model/sesion.php';
require_once 'model/almacen.php';

class AlmacenController{
    
    private $model;
    
    public function __CONSTRUCT(){
        $this->model = new Almacen();
    }
    
    public function Index(){
        require_once 'view/header.php';
        require_once 'view/almacen/almacen.php';
        require_once 'view/footer.php';
    }
    
    public function Crud(){
        $alm = new Almacen();
        
        if(isset($_REQUEST['id_almacen'])){
            $alm = $this->model->Obtener($_REQUEST['id_almacen']);
        }
        
        require_once 'view/header.php';
        require_once 'view/almacen/almacen-editar.php';
        require_once 'view/footer.php';
    }
    
    public function Guardar(){
        $alm = new Almacen();
       
        $alm->id_almacen = $_REQUEST['id_almacen'];
        $alm->id_equipo = $_REQUEST['id_equipo'];
        $alm->fecha_entrada = $_REQUEST['fecha_entrada'];
        $alm->fecha_despacho = $_REQUEST['fecha_despacho'];
        $alm->telefono = $_REQUEST['telefono'];
        $alm->stock = $_REQUEST['stock'];


        $alm->id_almacen > 0 
            ? $this->model->Actualizar($alm)
            : $this->model->Registrar($alm);
        
        header('Location: index.php');
    }
    
    public function Eliminar(){
        $this->model->Eliminar($_REQUEST['id_almacen']);
        header('Location: index.php');
    }
}