<?php
session_start();
//require_once 'model/sesion.php';
require_once 'model/solicitud_detalle.php';
 
class Solicitud_detalleController{
    
    private $model;
    
    public function __CONSTRUCT(){
        $this->model = new Solicitud_detalle();
    }
    
    public function Index(){
        require_once 'view/header.php';
        require_once 'view/solicitud_detalle/solicitud_detalle.php';
        require_once 'view/footer.php';
    }
    
    public function Crud(){
        $soldet = new Solicitud_detalle();
        
        if(isset($_REQUEST['id_solicitud_detalle'])){
            $soldet = $this->model->Obtener($_REQUEST['id_solicitud_detalle']);
        }
        
        require_once 'view/header.php';
        require_once 'view/solicitud_detalle/solicitud_detalle-editar.php';
        require_once 'view/footer.php';
    }
    
    public function Guardar(){
        $soldet = new Solicitud_detalle();
        $soldet->id_solicitud_detalle = $_REQUEST['id_solicitud_detalle'];
        $soldet->id_solicitud = $_REQUEST['id_solicitud'];
        $soldet->id_equipo = $_REQUEST['id_equipo'];        
        $id_solicitud=$_REQUEST['id_solicitud'];               
 

        $soldet->id_solicitud_detalle > 0 
            ? $this->model->Actualizar($soldet)
            : $this->model->Registrar($soldet);
        header('Location: index.php?c=Solicitud_detalle&id_solicitud='.$id_solicitud);
        //header('Location: index.php?c=solicitud');
    }
    
    public function Eliminar(){


        $id_solicitud_detalle = $_REQUEST['id_solicitud_detalle'];
        $id_solicitud = $_REQUEST['id_solicitud'];
        $id_equipo = $_REQUEST['id_equipo'];

        $this->model->Eliminar($id_solicitud_detalle,$id_equipo,$id_solicitud);
        header('Location: index.php?c=Solicitud_detalle&id_solicitud='.$id_solicitud);
        //header('Location: index.php?c=solicitud');
    }
    public function Asignar(){
        $id_solicitud_detalle=$_REQUEST['id_solicitud_detalle'];
        $id_solicitud=$_REQUEST['id_solicitud'];
        $id_equipo=$_REQUEST['id_equipo'];
        $id_tipo_solicitud=$_REQUEST['id_tipo_solicitud'];
    $this->model->Asignar($id_solicitud_detalle,$id_solicitud,$id_equipo,$id_tipo_solicitud);
        header('Location: index.php?c=Solicitud_detalle&id_solicitud='.$id_solicitud.'&id_tipo_solicitud='.$id_tipo_solicitud);
    }
}
