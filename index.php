<?php
ini_set("session.use_only_cookies","1");
ini_set("session.use_trans_sid","0"); 
date_default_timezone_set('America/Caracas');
session_start();
ini_set('display_errors', 'Off');
//error_reporting(E_ALL);


$GLOBALS['ingreso'] = ''; 

require_once 'model/database.php';
require_once 'model/usuario.php';
require_once __DIR__ . '/vendor/autoload.php';

$controller = 'site';


// Todo esta lógica hara el papel de un FrontController
if(!isset($_REQUEST['c']))
{
    require_once "controller/$controller.controller.php";
    $controller = ucwords($controller) . 'Controller';
    $controller = new $controller;
    $controller->Index();    
}
else
{
    // Obtenemos el controlador que queremos cargar
    $controller = strtolower($_REQUEST['c']);
    $accion = isset($_REQUEST['a']) ? $_REQUEST['a'] : 'Index';
    
    $usuario_acciona = New Usuario();
    $perm  = $usuario_acciona->Obtener_permiso($controller,$accion);


    if ($perm->count > 0){ 
       // Instanciamos el controlador
       require_once "controller/$controller.controller.php";
       $controller = ucwords($controller) . 'Controller';
       $controller = new $controller;
       call_user_func( array( $controller, $accion ) );
    }
    else
    {
        //$controller='site';
        //require_once "controller/$controller.controller.php";
        //$controller = ucwords($controller) . 'Controller';
        //$controller = new $controller;
        //$controller->Error();  

    print '<script>
            alert("Lo sentimos, la sesión ha expirado o no dispone de los privilegios necesarios para acceder a este Módulo del Sistema. Contacte al Administrador.");
           </script>'; 

    require_once "controller/$controller.controller.php";
    $controller = ucwords($controller) . 'Controller';
    $controller = new $controller;
    $controller->Index();


    }
    // Llama la accion
    
}
