<?php 
     
    $fechaGuardada = $_SESSION["ultimoAcceso"];
    $ahora = date("Y-n-j H:i:s");
    $tiempo_transcurrido = (strtotime($ahora)-strtotime($fechaGuardada)); 
    if($tiempo_transcurrido >= 600) {
        //si pasaron 10 minutos o más
        require_once 'model/usuario.php';
        $usu = new Usuario();
        $sal = $usu->logout();
        session_destroy(); // destruyo la sesión
        header("Location: index.php"); //envío al usuario a la pag. de autenticación
        //sino, actualizo la fecha de la sesión
    }else {
        $_SESSION["ultimoAcceso"] = $ahora;
   } 

?>