<?php


$pdo_options[PDO::ATTR_ERRMODE]=PDO::ERRMODE_EXCEPTION;
$pdo = new PDO('pgsql:host=localhost;dbname=bd_inventario','postgres','123456',$pdo_options);
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

if (isset($_POST['id_solicitud'])) {
	
    $id_sol = $_POST['id_solicitud'];
    $id_empleado_retira = $_POST['id_empleado_retira'];
    $observacion = $_POST['observacion'];

    $query = 'SELECT * FROM solicitud WHERE id_solicitud =? ';
    $registros = $pdo->prepare( $query );
    $registros->execute( array($id_sol) );
    $registros = $registros->fetchAll( PDO::FETCH_OBJ );
    $id_emp = $registros[0]->id_empleado;
    $id_fun = $registros[0]->id_funcionario;
    $id_tipo_solicitud = $registros[0]->id_tipo_solicitud;
    $id_ubicacion = $registros[0]->id_ubicacion;
    $id_oficina = $registros[0]->id_oficina;
    $id_departamento = $registros[0]->id_departamento;
    $num_ord = date('Y').(date('z')+1);

    //var_dump($_POST);
    //die();


$stm = $pdo->prepare("update equipo set id_estatus=?,id_ubicacion=?,id_oficina=?,id_departamento=? where id_equipo in (select id_equipo from solicitud_detalle where id_solicitud=? and asignado=true)");

$stm->execute(
        array(
            $id_tipo_solicitud,
            $id_ubicacion,
            $id_oficina,
            $id_departamento,
            $id_sol
            )
);

$acteq=$stm->fetch(PDO::FETCH_OBJ);

//var_dump($acteq);
//die();


$result = array();

$stm = $pdo->prepare("SELECT nueva_orden(?, ?, ?, ?, ?,?)");

$stm->execute(
		array(
            $num_ord,
			$id_sol,
			$observacion,
			$id_emp,
			$id_fun,
            $id_empleado_retira
            )
);

$nva_orden_salida = $stm->fetch(PDO::FETCH_OBJ);

$nro_orden=$nva_orden_salida->nueva_orden;

//var_dump($nro_orden);
//die();

$stm = $pdo->prepare("UPDATE orden_salida set id_empleado_retira=? WHERE id_orden=?");
$stm->execute(
        array(
            $id_empleado_retira,
            $nro_orden
            )
);



$stm = $pdo->prepare("SELECT num_orden from orden_salida where id_orden=?");

$stm->execute(
		array(
            $nro_orden
            )
);

$nvo_num_orden = $stm->fetch(PDO::FETCH_OBJ);

$num_orden = $nvo_num_orden->num_orden; 

echo $num_orden;
}
  
?>