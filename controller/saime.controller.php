<?php
session_start();
require_once 'model/saime.php';


class SaimeController{
    
    private $model;
    
    public function __CONSTRUCT(){
        $this->model = new Saime();
    }
    
    
    public function Crud(){
        $ced = new Saime();
        
        if(isset($_REQUEST['cedula'])){
            

            $ced = $this->model->Obtener($_REQUEST['cedula']);
            
            //var_dump($ced);
            //die();
        }
        
   
    }
    
   
}