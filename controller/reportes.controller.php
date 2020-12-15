<?php
session_start();
//require_once 'model/sesion.php';
require_once 'model/usuario.php';
require_once 'vendor/autoload.php';

class ReportesController{
    
    private $model;
    
    public function __CONSTRUCT(){
        $this->model = new Usuario();
    }
    
    public function Reporte1(){
        require_once 'view/reportes/reporte1.php';
    }
	
    public function Reporte2(){
        require_once 'view/reportes/reporte2.php';
    }	

    public function Reporte3(){
        require_once 'view/reportes/reporte3.php';
    }

    public function Solicitud(){
        require_once 'view/reportes/solicitud.php';
    }

    public function Orden_salida(){
        require_once 'view/reportes/orden_salida.php';
    }

    public function Ordenes_salida(){
        require_once 'view/reportes/ordenes_salida.php';
    }

    public function Equipos_general(){
        require_once 'view/reportes/equipos_general.php';
    }
    public function Equipos_sbn(){
        require_once 'view/reportes/equipos_sbn.php';
    }
    public function Equipos_disponibles(){
        require_once 'view/reportes/equipos_disponibles.php';
    }
    public function Equipos_itinerantes(){
        require_once 'view/reportes/equipos_itinerantes.php';
    }    
    public function Equipos_reservados(){
        require_once 'view/reportes/equipos_reservados.php';
    }

    public function Solicitudes(){
        require_once 'view/reportes/solicitudes.php';
    }

    public function Solicitudes_pendientes(){
        require_once 'view/reportes/solicitudes_pendientes.php';
    }        

    public function Solicitudes_pendientes_sin_detalle(){
        require_once 'view/reportes/solicitudes_pendientes_sin_detalle.php';
    }        
	
    public function Solicitudes_pendientes_sin_orden(){
        require_once 'view/reportes/solicitudes_pendientes_sin_orden.php';
    } 

    public function Solicitudes_parcialmente_procesadas(){
        require_once 'view/reportes/solicitudes_parcialmente_procesadas.php';
    }        

    public function Solicitudes_procesadas(){
        require_once 'view/reportes/solicitudes_procesadas.php';
    }  

    public function Solicitudes_canceladas(){
        require_once 'view/reportes/solicitudes_canceladas.php';
    } 

    public function Empleados(){
        require_once 'view/reportes/empleados.php';
    }   

    public function Oficinas(){
        require_once 'view/reportes/oficinas.php';
    }   

    public function Departamentos(){
        require_once 'view/reportes/departamentos.php';
    }   

    public function Marcas(){
        require_once 'view/reportes/marcas.php';
    }   

    public function Articulos(){
        require_once 'view/reportes/articulos.php';
    }       

    public function Proveedores(){
        require_once 'view/reportes/proveedores.php';
    }   

    public function Usuario(){
        require_once 'view/reportes/usuario.php';
    }	

    public function Devolucion_constancia(){
        require_once 'view/reportes/devolucion_constancia.php';
    }    
    		
}