<?php
ini_set('display_errors', 'On');
error_reporting(E_ALL);

require_once 'usuario.php';
$usu = new Usuario();
/*
try {
$where =" 1=1 ";
$order_by="rating_imdb";
$rows=25;
$current=1;
$limit_l=($current * $rows) - ($rows);

$stmt1= $pdo->query("SELECT count(id) FROM usuario WHERE active IS NOT FALSE");
$totalRecords = (int) $stmt1->fetchColumn();

$sql="SELECT 
  usuario.id, 
  usuario.nombres, 
  usuario.email, 
  roles.role_name AS rol
FROM 
  public.usuario, 
  public.roles
WHERE 
  usuario.id_rol = roles.role_id AND
  usuario.active IS NOT FALSE
  ORDER BY usuario.id";

$stmt=$pdo->prepare($sql);
$stmt->execute();


$output = array(
		//"sEcho" => intval($_GET['sEcho']),
	    "sEcho" => 1,
		"iTotalRecords" => $totalRecords,
		"iTotalDisplayRecords" => $totalRecords,
		"data" => array()
);

while($fila = $stmt->fetch(PDO::FETCH_ASSOC))
	{
	  $info = array("id"=>$fila['id'],"nombres"=>$fila['nombres'],"email"=>$fila['email'],"rol"=>$fila['rol']);
	  $output['data'][] = $info;
	  
	}

header('Content-Type: application/json'); //tell the broswer JSON is coming
echo json_encode( $output );
}
catch(PDOException $e) {
echo 'SQL PDO ERROR: ' . $e->getMessage();
}*/
?>
