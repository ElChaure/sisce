<?php
session_start();
//require_once 'model/sesion.php';
require_once 'model/solicitud.php';

class SolicitudController{
    
    private $model;
    
    public function __CONSTRUCT(){
        $this->model = new Solicitud();
    }
    
    public function Index(){
        require_once 'view/header.php';
        require_once 'view/solicitud/solicitud.php';
        require_once 'view/footer.php';
    }

    public function View(){
        require_once 'view/header.php';
        require_once 'view/solicitud/solicitud-view.php';
        require_once 'view/footer.php';
    }

    public function View_pend(){
        require_once 'view/header.php';
        require_once 'view/solicitud/solicitud-view-pend.php';
        require_once 'view/footer.php';
    }

    public function View_canc(){
        require_once 'view/header.php';
        require_once 'view/solicitud/solicitud-view-canc.php';
        require_once 'view/footer.php';
    }


   public function View_orden(){
        require_once 'view/header.php';
        require_once 'view/solicitud/solicitud-view-orden.php';
        require_once 'view/footer.php';
    }

    
    public function Crud(){
        $sol = new Solicitud();
        
        if(isset($_REQUEST['id_solicitud'])){
            $sol = $this->model->Obtener($_REQUEST['id_solicitud']);
        }
        
        require_once 'view/header.php';
        require_once 'view/solicitud/solicitud-editar.php';
        require_once 'view/footer.php';
    }
    
    public function Guardar(){
        $sol = new Solicitud();
       
        $sol->id_solicitud = $_REQUEST['id_solicitud'];
        $sol->id_equipo = 0;
        //$_REQUEST['id_equipo'];        
        //$sol->id_funcionario = $_REQUEST['id_funcionario'];
        $sol->id_empleado = $_REQUEST['id_empleado'];
        $sol->descripcion = $_REQUEST['descripcion'];                
        $sol->fecha_solicitud = $_REQUEST['fecha_solicitud'];                        
        $sol->id_tipo_solicitud = $_REQUEST['id_tipo_solicitud'];
        $sol->id_ubicacion = $_REQUEST['id_ubicacion'];
        $sol->id_oficina = $_REQUEST['id_oficina'];
        $sol->id_departamento = $_REQUEST['id_departamento'];


        $sol->id_solicitud > 0 
            ? $this->model->Actualizar($sol)
            : $id_solicitud_nvo=$this->model->Registrar($sol);

        if (isset($id_solicitud_nvo)){
           $id_solicitud=$id_solicitud_nvo->nueva_solicitud;       
           //var_dump($id_solicitud_nvo);die();   
        }
        else
        {
            $id_solicitud=$_REQUEST['id_solicitud'];
        }

        //$id_solicitud=$_REQUEST['id_solicitud']; 
        header('Location: index.php?c=Solicitud_detalle&id_solicitud='.$id_solicitud);
        //header('Location: index.php');
    }
    
    public function Eliminar(){
        $this->model->Eliminar($_REQUEST['id_solicitud']);
        header('Location: index.php?c=solicitud&a=view');
    }

    public function Cancelar(){
        $this->model->Cancelar($_REQUEST['id_solicitud']);
        header('Location: index.php?c=solicitud&a=view_canc');
    }

   
}
