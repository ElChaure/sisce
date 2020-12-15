<?php
ini_set('display_errors', 'On');
error_reporting(E_ALL);

//require_once 'model/database.php';
$pdo_options[PDO::ATTR_ERRMODE]=PDO::ERRMODE_EXCEPTION;
$pdo = new PDO('pgsql:host=localhost;dbname=bd_inventario','postgres','123456',$pdo_options);
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

try {
// $DBH = new PDO("mysql:host=$host;dbname=$dbname", $user, $pass); //MYSQL database
//$conn = new PDO("sqlite:db/movies.db"); // SQLite Database
//$conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$where =" 1=1 ";
$order_by="rating_imdb";
$rows=25;
$current=1;
$limit_l=($current * $rows) - ($rows);
//$limit_h=$limit_lower + $rows ;
/*
//Handles Sort querystring sent from Bootgrid
if (isset($_REQUEST['sort']) && is_array($_REQUEST['sort']) )
{
$order_by="";
foreach($_REQUEST['sort'] as $key=> $value)
$order_by.=" $key $value";
}

//Handles search querystring sent from Bootgrid
if (isset($_REQUEST['searchPhrase']) )
{
$search=trim($_REQUEST['searchPhrase']);
$where.= " AND ( movie LIKE '".$search."%' OR year LIKE '".$search."%' OR genre LIKE '".$search."%' ) ";
}

//Handles determines where in the paging count this result set falls in
if (isset($_REQUEST['rowCount']) )
$rows=$_REQUEST['rowCount'];

//calculate the low and high limits for the SQL LIMIT x,y clause
if (isset($_REQUEST['current']) )
{
$current=$_REQUEST['current'];
$limit_l=($current * $rows) - ($rows);
$limit_h=$rows ;
}

if ($rows==-1)
$limit=""; //no limit
else
$limit=" LIMIT $limit_l,$limit_h ";

//NOTE: No security here please beef this up using a prepared statement - as is this is prone to SQL injection.
$sql="SELECT id, replace(movie,'\"','' ) as movie, year, rating_imdb,genre FROM films WHERE $where ORDER BY $order_by $limit";

$stmt=$conn->prepare($sql);
$stmt->execute();
$results_array=$stmt->fetchAll(PDO::FETCH_ASSOC);

$json=json_encode( $results_array );</pre>
<pre> /* specific search then how many match **
$nRows=$conn->query("SELECT count(*) FROM films WHERE $where")->fetchColumn();


$stmt = $pdo->query("SELECT 
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
  ORDER BY usuario.id");		

$stmt1= $pdo->query("SELECT count(id) FROM usuario WHERE active IS NOT FALSE");
$totalRecords = (int) $stmt1->fetchColumn(); 
$nRows =$totalRecords;
$data = $stmt->fetchAll(PDO::FETCH_ASSOC);
echo json_encode($data);
$json=json_encode($data,true);

$json2 = recordSetToJson($stmt);
*/
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
		"aaData" => array()
);

//$json=recordSetToJson($stmt);
while($fila = $stmt->fetch(PDO::FETCH_ASSOC))
	{
	  $info = array("id"=>$fila['id'],"nombres"=>$fila['nombres'],"email"=>$fila['email'],"rol"=>$fila['rol']);
	  $output['aaData'][] = $info;
	  //$salida[] = $info;
	}

//$output['aaData'][] = $json;
/*
//$json=";".$json;


            $json_data = array(
	            //"current"  => intval( $params['current'] )
	            "current"  =>  1, 
	            "rowCount" => 10,            
	            "total"    => intval( $totalRecords ),
	            "rows"     => $data   // total data array
            );

*/
header('Content-Type: application/json'); //tell the broswer JSON is coming
/*
if (isset($_REQUEST['rowCount']) ) //Means we're using bootgrid library
   echo "{ \"current\": $current, \"rowCount\":$rows, \"rows\": ".$output.", \"total\": $nRows }";
else
   echo $output; //Just plain vanillat JSON output
exit;
*/
echo json_encode( $output );
}
catch(PDOException $e) {
echo 'SQL PDO ERROR: ' . $e->getMessage();
}


function recordSetToJson($stmt) {
  /*	
  $json_result = array();
  while($tmp = $stmt->fetch() ) {
       $json_result[] = $tmp;
  }
  */
    $salida = array();
	while($fila = $stmt->fetch(PDO::FETCH_ASSOC))
	{
	  $info = array("id"=>$fila['id'],"nombres"=>$fila['nombres'],"email"=>$fila['email'],"rol"=>$fila['rol']);
	  $output['aaData'][] = $info;
	  //$salida[] = $info;
	}
  return json_encode($salida);
}
?>