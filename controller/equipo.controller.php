<?php
session_start();
//require_once 'model/sesion.php';
require_once 'model/equipo.php';

class EquipoController{
    
    private $model;
    
    public function __CONSTRUCT(){
        $this->model = new Equipo();
    }
    
    public function Index(){
        require_once 'view/header.php';
        require_once 'view/equipo/equipo.php';
        require_once 'view/footer.php';
    }


    public function View(){
        require_once 'view/header.php';
        require_once 'view/equipo/equipo-view.php';
        require_once 'view/footer.php';
    }

    public function View_sbn(){
        require_once 'view/header.php';
        require_once 'view/equipo/equipo-view-sbn.php';
        require_once 'view/footer.php';
    }

    public function View_disp(){
        require_once 'view/header.php';
        require_once 'view/equipo/equipo-view-disp.php';
        require_once 'view/footer.php';
    }


    public function Valida_serial(){
        $equ = new Equipo();
        
        if(isset($_REQUEST['serial'])){
            $equ = $this->model->Valida_serial($_REQUEST['serial']);
            //echo $equ;
            var_dump($equ);
            //die();
        }
        
        //require_once 'view/header.php';
        //require_once 'view/equipo/equipo-editar.php';
        //require_once 'view/footer.php';
    }

    
    public function Crud(){
        $equ = new Equipo();
        
        if(isset($_REQUEST['id_equipo'])){
            $equ = $this->model->Obtener($_REQUEST['id_equipo']);
        }
        
        require_once 'view/header.php';
        require_once 'view/equipo/equipo-editar.php';
        require_once 'view/footer.php';
    }

    public function Sbn(){
        $equ = new Equipo();
        
        if(isset($_REQUEST['id_equipo'])){
            $equ = $this->model->Obtener($_REQUEST['id_equipo']);
        }
        
        require_once 'view/header.php';
        require_once 'view/equipo/equipo-editar-bien.php';
        require_once 'view/footer.php';
    }

    public function Asignabn(){
        $equ = new Equipo();
        
        if(isset($_REQUEST['id_equipo'])){
            $equ = $this->model->Obtener($_REQUEST['id_equipo']);
        }
        
        require_once 'view/header.php';
        require_once 'view/equipo/equipo-editar-bn.php';
        require_once 'view/footer.php';
    }


    
    public function Guardar(){
        $equ = new Equipo();
       
        $equ->id_equipo = $_REQUEST['id_equipo'];
        $equ->cod_equipo = $_REQUEST['cod_equipo'];
        $equ->serial = $_REQUEST['serial'];
        $equ->id_estatus = $_REQUEST['id_estatus'];
        $equ->id_ubicacion = $_REQUEST['id_ubicacion'];
        $equ->num_bien_nac = $_REQUEST['num_bien_nac'];
        $equ->descripcion = $_REQUEST['descripcion'];
        $equ->num_factura = $_REQUEST['num_factura'];
        $equ->fecha_factura = $_REQUEST['fecha_factura'];
        $equ->id_proveedor = $_REQUEST['id_proveedor'];
        $equ->valor = $_REQUEST['valor'];
        $equ->id_articulo = $_REQUEST['id_articulo'];
        $equ->id_marca = $_REQUEST['id_marca'];

//var_dump($equ);die();

        $equ->id_equipo > 0 
            ? $this->model->Actualizar($equ)
            : $this->model->Registrar($equ);
        
        header('Location: index.php?c=equipo&a=view');
    }


    public function Guardarbn(){
        $equ = new Equipo();
        $equ->id_equipo = $_REQUEST['id_equipo'];
        $equ->num_bien_nac = $_REQUEST['num_bien_nac'];
        $this->model->Actualizarbn($equ);
                
        header('Location: index.php?c=equipo&a=view_sbn');
    }
    
    public function Eliminar(){
        $this->model->Eliminar($_REQUEST['id_equipo']);
        header('Location: index.php?c=equipo&a=view');
    }

    public function ListarJSON2(){
        $this->model->Listar_json2();
        //header('Location: index.php?c=equipo');
    }


}