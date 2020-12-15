<?php
session_start();
//require_once 'model/sesion.php';
require_once 'model/empleado.php';

class EmpleadoController{
    
    private $model;
    
    public function __CONSTRUCT(){
        $this->model = new Empleado();
    }
    
    public function Index(){
        require_once 'view/header.php';
        require_once 'view/empleado/empleado.php';
        require_once 'view/footer.php';
    }
    
    public function Crud(){
        $emp = new Empleado();
        
        if(isset($_REQUEST['id_empleado'])){
            $emp = $this->model->Obtener($_REQUEST['id_empleado']);
        }
        
        require_once 'view/header.php';
        require_once 'view/empleado/empleado-editar.php';
        require_once 'view/footer.php';
    }


    public function Cuerpo_modal(){
        $emp = new Empleado();
        
        if(isset($_REQUEST['id_empleado'])){
            $emp = $this->model->Obtener_empleados($_REQUEST['id_empleado']);
        }
        
        //require_once 'view/header.php';
        require_once 'view/empleado/cuerpo_modal.php';
        //require_once 'view/footer.php';
    }


    public function Local(){
        $ced = new Empleado();
        
        if(isset($_REQUEST['cedula'])){
            $ced = $this->model->Obtener($_REQUEST['cedula']);
        }
    }    


    public function Obtener_json(){
        $emp = new Empleado();
        
        if(isset($_REQUEST['cedula'])){
            $ced = $this->model->Obtener_json($_REQUEST['cedula']);
            //var_dump($ced);
            //die();
        }
    }

    
    public function Guardar(){
        $emp = new Empleado();
       
        $emp->id_empleado = $_REQUEST['id_empleado'];
        $emp->primer_nombre = $_REQUEST['primer_nombre'];
        $emp->segundo_nombre = $_REQUEST['segundo_nombre'];
        $emp->primer_apellido = $_REQUEST['primer_apellido'];
        $emp->segundo_apellido = $_REQUEST['segundo_apellido'];
        $emp->cedula = $_REQUEST['cedula'];
        $emp->direccion = $_REQUEST['direccion'];
        $emp->email = $_REQUEST['email'];
        $emp->id_telefono = $_REQUEST['id_telefono'];
        $emp->id_estatus = $_REQUEST['id_estatus'];
        $emp->cargo = $_REQUEST['cargo'];
        $emp->id_ubicacion    = $_REQUEST['id_ubicacion'];  
        $emp->id_departamento = $_REQUEST['id_departamento'];
        $emp->id_oficina = $_REQUEST['id_oficina'];
        $emp->id_usuario =   $_REQUEST['id_usuario'];
        $emp->telefono = $_REQUEST['telefono'];


        $emp->id_empleado > 0 
            ? $this->model->Actualizar($emp)
            : $this->model->Registrar($emp);
        
        header('Location: index.php?c=Empleado');
    }
    
    public function Eliminar(){
        $this->model->Eliminar($_REQUEST['id_empleado']);
        header('Location: index.php?c=Empleado');
    }
}