<?php
session_start();
//require_once 'model/sesion.php';
require_once 'model/articulo.php';

class ArticuloController{
    
    private $model;
    
    public function __CONSTRUCT(){
        $this->model = new Articulo();
    }
    
    public function Index(){
        require_once 'view/header.php';
        require_once 'view/articulo/articulo.php';
        require_once 'view/footer.php';
    }
    
    public function Crud(){
        $art = new Articulo();
        
        if(isset($_REQUEST['id_articulo'])){
            $art = $this->model->Obtener($_REQUEST['id_articulo']);
        }
        
        require_once 'view/header.php';
        require_once 'view/articulo/articulo-editar.php';
        require_once 'view/footer.php';
    }
    
    public function Guardar(){
        $art = new Articulo();
       
        $art->id_articulo = $_REQUEST['id_articulo'];
        $art->articulo = $_REQUEST['articulo'];
        $art->codigo_snc = $_REQUEST['codigo_snc'];



        $art->id_articulo > 0 
            ? $this->model->Actualizar($art)
            : $this->model->Registrar($art);
        
        header('Location:index.php?c=Articulo');
    }
    
    public function Eliminar(){
        $this->model->Eliminar($_REQUEST['id_articulo']);
        header('Location: index.php?c=Articulo');
    }
}