<?php
session_start();
//require_once 'model/sesion.php';
require_once 'model/reserva.php';

class ReservaController{
    
    private $model;
    
    public function __CONSTRUCT(){
        $this->model = new Reserva();
    }
    
    public function Index(){
        require_once 'view/header.php';
        require_once 'view/reserva/reserva.php';
        require_once 'view/footer.php';
    }
    
    public function Crud(){
        $res = new Reserva();
        
        if(isset($_REQUEST['id_reserva'])){
            $res = $this->model->Obtener($_REQUEST['id_reserva']);
        }
        
        require_once 'view/header.php';
        require_once 'view/reserva/reserva-editar.php';
        require_once 'view/footer.php';
    }
    
    public function Guardar(){
        $res = new Reserva();
       
        $res->id_reserva = $_REQUEST['id_reserva'];
        $res->id_solicitud = $_REQUEST['id_solicitud'];
        $res->fecha_reserva = $_REQUEST['fecha_reserva'];
        $res->observacion = $_REQUEST['observacion'];                
        $res->id_equipo = $_REQUEST['id_equipo'];        

        $res->id_reserva > 0 
            ? $this->model->Actualizar($res)
            : $this->model->Registrar($res);
        
        header('Location: index.php?c=Reserva');
    }
    
    public function Eliminar(){
        $this->model->Eliminar($_REQUEST['id_reserva']);
        header('Location: index.php?c=Reserva');
    }
}