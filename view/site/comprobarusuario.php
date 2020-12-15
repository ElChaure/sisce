<?php
$pdo_options[PDO::ATTR_ERRMODE]=PDO::ERRMODE_EXCEPTION;
$pdo = new PDO('pgsql:host=localhost;dbname=bd_inventario','postgres','123456',$pdo_options);
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$username     = $_POST['username'];

$query = 'SELECT count(id) AS existe,intentos,ingreso FROM usuario WHERE alias=:username AND active IS NOT FALSE  GROUP BY id,intentos,ingreso';
$registros = $pdo->prepare( $query ); //Preparamos la consulta      
$registros->execute( array(":username" => $username) ); //Le pasamos el valor al marcador, esto es un array por lo que soporta tanto valores requiera la query, separador por coma
$registros = $registros->fetchAll( PDO::FETCH_OBJ ); //convirtiendo el resultado en objetos para poder iterar en un ciclo.

$user_count = $registros[0]->existe;
$user_inten = $registros[0]->intentos;
$user_sesion = $registros[0]->ingreso;


if($user_count>0) {
      if($user_sesion==FALSE){
         echo "<span class='estado-registrado-usuario'> Usuario Registrado.</span>";
     }else{
     	 echo "<span class='estado-ingresado-usuario'> Usuario Ya posee una sesion de trabajo abierta.</span>";
     }
  }else{
      echo "<span class='estado-no-registrado-usuario'> Usuario No Registrado o Inactivo.</span>";
  }


?>