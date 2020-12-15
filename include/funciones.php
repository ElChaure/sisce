<?php 
// Chequea que ningun cliente llame directamente a este archivo
if (stristr($_SERVER['PHP_SELF'],'funciones.php')) {	 
    header('Location: ../index.php');          	
    die();                                     	
}

function check_iva($tip){
	$out = $tip;
	switch($out){
		case 'E' : $out = 0;
		break;
	}
	return $out;
}

function sucursal_activa(){
	global $conn;
	//echo "select $value as valor from $tabla where $arg";
	$con_val=$conn->DB_Consulta("select * from sucursal_activa");
	$row_val=$conn->DB_fetch_array($con_val);
	if ($row_val){
		$result = $row_val["valor"];
	}else{ 
		 die('Hay problemas con el valor de Sucursal Activa en la base de datos. Contacte a Tecnolog�a Area de Sistemas.');  
	}
	return $result;
	
}

function dia_aperturado()
{
	global $conn;

	$id_sucursal = sucursal_activa();
	$query  =  "select estatus from dias WHERE id_sucursal = $id_sucursal order by id_fecha DESC Limit 1;";
	$r =  $conn->DB_Consulta( $query );
	if( $conn->DB_num_rows($r) > 0 )
	{
		$row = $conn->DB_fetch_array($r);
		if( $row['estatus'] == 0 )
		{
			header("Location: home.php?ms=Para poder Facturar es necesario aperturar el Dia.");
		}
	}
	else
	{
		header("Location: home.php?ms=Facturacion no aperturada.");
	}
}

function administra_sucursales(){
   if ($_SESSION['admin_su']==1) return true;
   else return false;
}


function imprimir_ldap($usuario, $pass){
	$ds=ldap_connect("10.17.2.2");  
	ldap_set_option($ds,LDAP_OPT_PROTOCOL_VERSION, 3); 
	if ($ds) {  
		$sr=ldap_search($ds,"ou=minpal, ou=users, dc=minpal,dc=gob,dc=ve", "uid=*");  
		$info = ldap_get_entries($ds, $sr);
		//=============================
		//$info = ldap_get_entries($connect, $read);
		echo $info["count"]." entrees retournees<BR><BR>";
		for ($i = 0; $i<$info["count"]; $i++) {
		  for ($ii=0; $ii<$info[$i]["count"]; $ii++){
			 $data = $info[$i][$ii];
			 for ($iii=0; $iii<$info[$i][$data]["count"]; $iii++) {
			   echo $data.":&nbsp;&nbsp;".$info[$i][$data][$iii]."<br>";
			 }
		
			}
		echo $info[$i]["dn"]."<br>";
		echo "<BR>";
		}
	}
		//=============================
} //end del Function

function validar_login_ldap($usuario){
	$ds=ldap_connect("10.17.2.2");  
	ldap_set_option($ds,LDAP_OPT_PROTOCOL_VERSION, 3); 
	if ($ds) {  
		$sr=ldap_search($ds,"ou=minpal, ou=users, dc=minpal, dc=gob, dc=ve", "uid=$usuario"); 
		$info = ldap_get_entries($ds, $sr);
		if ($info["count"]>0){
			$info = ldap_get_entries($ds, $sr);
			$info2 = $info[0]["cn"];
			return $info2[0];     
		} else return "f";
		ldap_close($ds);
	} else {
	   return "f";
	}
} //end del Function


function validar_ldap($usuario, $pass){
	$ds=ldap_connect("10.17.2.2");  
	ldap_set_option($ds,LDAP_OPT_PROTOCOL_VERSION, 3); 
	if ($ds) {  
		$sr=ldap_search($ds,"ou=minpal, ou=users, dc=minpal, dc=gob, dc=ve", "uid=$usuario");  
		$info = ldap_get_entries($ds, $sr);
		$r=@ldap_bind($ds,$info[0]["dn"],$pass);     
		if ($r) {
			return true;
		}else{
			return false;
		}
		ldap_close($ds);
	} else {
	   return false;
	}
} //end del Function

// Permite crear el arbol para el menu seg�nh un perfil
function combo_menu01($padre, $nivel){
	global $conn;
	$sq_m = "SELECT * FROM menu WHERE id_padre=$padre ORDER BY orden";
	//echo $sq_m;
	$rs_m=$conn->DB_Consulta($sq_m);
	$nr_m=$conn->DB_num_rows($rs_m);
	if ($nr_m>0){
		while ($rw_m = $conn->DB_fetch_array($rs_m)){
			echo "<option value=\"".$rw_m["id_menu"]."\" >";
			//echo $nivel;
			echo identar($nivel).$rw_m["nb_menu"];
			echo "</option>\n";
			combo_menu01 ($rw_m["id_menu"], $nivel+1);
		}
	}
}


function identar($cantidad){
	for ($i=0;$i<$cantidad;$i++){
		echo "&nbsp;&nbsp;&nbsp;";
	}
}

function getIP() {
    if (isset($_SERVER['HTTP_X_FORWARDED_FOR'])) {
       $ip = $_SERVER['HTTP_X_FORWARDED_FOR'];
    } 
    elseif (isset($_SERVER['HTTP_VIA'])) {
       $ip = $_SERVER['HTTP_VIA'];
    } 
    elseif (isset($_SERVER['REMOTE_ADDR'])) {
       $ip = $_SERVER['REMOTE_ADDR'];
    }
    else { 
       $ip = "unknown";
    }
    
    return $ip;
}

function esta_lan(){
	$ipepa=getIP();
	$ipepe= explode( ".",$ipepa);
	$lan = $ipepe[0].".".$ipepe[1];
	//echo $lan;
	if ($lan =="10.17") return true;
	else return false;
	//return false;
}

function paginar($res,$show,$data_per_pag,$rango_pag,$total_data,$this_script){	
	global $url_mod;
	$nro_pags=ceil($total_data/$data_per_pag);
	$actual=$res;
	$anterior = $actual - 1;
	$posterior = $actual + 1;
	$ak=$actual+1;
	$texto=" P&aacute;gina <b>$ak</b> de <b>$nro_pags</b> | ";
	if ($actual!=0)
		$texto .= "<a href=\"$this_script?url=$url_mod&res=$anterior\">&laquo;</a> ";
	else
		$texto .= "<b>&laquo;</b> ";

	$r1=($actual<$rango_pag ? 1 : $actual-($rango_pag-2));
	$r1=($r1<1 ? 1 : $r1);
	$r2=(($actual+1)==$nro_pags ? $nro_pags : $actual+$rango_pag);
	$r2=($r2>$nro_pags ? $nro_pags : $r2);
	
	for ($i=$r1; $i<=$r2; $i++){
		$ik=$i-1;
		if ($i==$ak)
			$texto .= "<b>$ak</b> ";
		else
			$texto .= "<a href=\"$this_script?url=$url_mod&res=$ik\">$i</a> ";
	}

	if ($actual<$nro_pags-1)
		$texto .= "<a href=\"$this_script?url=$url_mod&res=$posterior\">&raquo;</a>";
	else
		$texto .= "<b>&raquo;</b>";
	return $texto;
}

function print_fecha(){
	$diassemana = array("Domingo","Lunes","Martes","Mi&eacute;rcoles","Jueves","Viernes","S&aacute;bado") ;
	$mesesano = array("Enero","Febrero","Marzo","Abril","Mayo","Junio","Julio","Agosto","Septiembre","Octubre","Noviembre","Diciembre") ;
	$long_date = $diassemana[date('w')]." ".date('d'). " de ". $mesesano[(date('n')-1)]." de ".date('Y').".";
	return $long_date;
}

// Consulta 1 valor en especifico
function consulta_permisos($value){
	global $conn;
	$sq ="SELECT * FROM perfiles_permisos WHERE id_perfil=".$_SESSION['id_perfil']." AND id_menu=$value";
	//return $sq;
	$con_val=$conn->DB_Consulta($sq);

	$row_val=$conn->DB_fetch_array($con_val);
	$count=$conn->DB_num_rows($con_val);
	//echo $count;die();
	if ($count>0){
		$result = "f,";
		$result.= ($row_val['vermenu']==1?'t':'f').",";
		$result.= ($row_val['insertar']==1?'t':'f').",";
		$result.= ($row_val['modificar']==1?'t':'f').",";
		$result.= ($row_val['eliminar']==1?'t':'f').",";
		$result.= ($row_val['anular']==1?'t':'f').",";
	}else{ 
		$result ="f,f,f,f,f,f";
	}
	return $result;
}

// Consulta 1 valor en especifico
function consulta_valor($tabla,$value,$arg)
{
	global $conn;
	//echo "select $value as valor from $tabla where $arg";
	$con_val=$conn->DB_Consulta("select $value as valor from $tabla where $arg");
	$row_val=$conn->DB_fetch_array($con_val);
	if ($row_val){
		$result = utf8_encode_seguro($row_val["valor"]);
	}else{ 
		$result = "-ne-";
	}
	return $result;
}

// Funcion para manejar los caracteres de forma ordenada
function utf8_encode_seguro($texto){
	return (codificacion($texto)=="ISO_8859_1") ? utf8_encode($texto) : $texto;
}

function codificacion($texto){
	$c = 0;
    $ascii = true;
    for ($i = 0;$i<strlen($texto);$i++) {
    	$byte = ord($texto[$i]);
        if ($c>0) {
        	if (($byte>>6) != 0x2) {
            	return ISO_8859_1;
            } else {
                  $c--;
            }
        } elseif ($byte&0x80) {
        	$ascii = false;
			if (($byte>>5) == 0x6) {
				$c = 1;
			} elseif (($byte>>4) == 0xE) {
				$c = 2;
			} elseif (($byte>>3) == 0x14) {
				$c = 3;
			} else {
				return ISO_8859_1;
			}
        }
    }
    return ($ascii) ? "ASCII" : "UTF_8";
}

function detectBrowser() {
   $browsers = array("msie", "firefox"); //- Add here
   $names = array ("msie" => "Microsoft Internet Explorer", "firefox" => "Mozilla Firefox"); //- The same
   $nav = "Unknown";
   $sig = strToLower ($_SERVER['HTTP_USER_AGENT']);
   foreach ($browsers as $b) {
       if ( $pos = strpos ($sig, $b) ) {
           $nav = $names[$b];
           break;
       }
   }
   if ($nav == "Unknown") return array ("app.Name" => $nav, "app.Ver" => "?", "app.Sig" => $sig);
   $ver = "";
   for ( ; $pos <= strlen ($sig); $pos ++) {
       if ( (is_numeric($sig[$pos])) || ($sig[$pos]==".") ) {
           $ver .= $sig[$pos];
       }
       else if ($ver) break;
   }
   return array("app.Name" => $nav, "app.Ver" => $ver, "app.Sig" => $sig);
}

// Funcion que cambia el formato de una fecha DD-MM-AAA, deacuerdo a lo requerido. Si recibe "es" devuelve: DD-MM-AAAA, de lo contrario devuelve el formato: AAAA-MM-DD
function traduce_fecha($fecha,$formato=''){
	$str=explode("-",$fecha);
	$str_final = $str[2]."-".$str[1]."-".$str[0];
	if ($str[2]=="" or $str[1]=="" or $str[0]=="")
		$str_final="";
	return $str_final;
}

/*function traduce_fecha2($fecha,$formato=''){
	$esta=0;
	$esta=strpos($fecha,"/");
	if ($esta > 0){
	   $str=explode("/",$fecha);
	}else{
	   $str=explode("-",$fecha);}
	$str_final = $str[2]."-".$str[0]."-".$str[1];
	if ($str[2]=="" or $str[1]=="" or $str[0]=="")
		$str_final="";
	return $str_final;
}*/

function formatoEspanol($num,$nd=0) {
     $snum = number_format($num,$nd,",",".");
     return $snum;
}

// Funcion que crea un combo a partir de una tabla
function make_combo($tabla, $arg, $value, $descripcion, $equal='', $opt_val='', $funcion='', $event="onClick", $no_reg="<option value=\"-1\">No hay registros</option>", $seeSql=false){
	//$conn_xx = new DB_Class;
	//$conn_xx->DB_Init();
	//require_once 'model/'.$tabla.'.php';
	
	
    $combo  = '';
    foreach($tabla->Listar() as $r):
           $combo .= "<option value=\"".$r->$arg."\">".$r->$value."</option>";
    endforeach;
    var_dump($combo);
     /*
    
    die();
   

	$sql = strtolower("select $value,$descripcion from $tabla $arg");
	

	if ($seeSql)
	  echo $sql;
	$combo  = '';

	$rs_cmb =$conn_xx->DB_Consulta($sql);
	$vals   = explode(',',$descripcion);
	if(count($vals)<=1) $vals=explode('.',$descripcion);
	if ($opt_val!='')
		  $combo = $opt_val;
	if ($conn_xx->DB_num_rows($rs_cmb)>0){
		$value  = strtolower($value);
		$rs_cmb = $conn_xx->DB_Consulta($sql);
		while ($row=$conn_xx->DB_fetch_array($rs_cmb)){
			$combo .= "<option value=\"".$row[0]."\"".($row[0]==$equal ? " SELECTED":"")." title=\"";
			$cont = 0;
			foreach ($vals as $des_row){
			    $valx = explode(' as ',$des_row);
				if(count($valx)>1) $des_row = $valx[1];
				$combo .= ($cont==0) ? ucwords (utf8_encode_seguro($row["$des_row"])) : "&nbsp;".ucwords (utf8_encode_seguro($row["$des_row"]));
				$cont++;
			}
			if (isset($funcion) and $funcion!=""){
			  $combo .="\""." $event=\"".$funcion."\">";
			}else{
			  $combo .="\">";
			}
			$cont = 0;
			foreach ($vals as $des_row){
				$valx = explode(' as ',$des_row);
				if(count($valx)>1) $des_row = $valx[1];
				$combo .= ($cont==0) ? utf8_encode_seguro($row["$des_row"]) : "&nbsp;".utf8_encode_seguro($row["$des_row"]);
				$cont++;
			}
			$combo .= "</option>\n";
		}
	}else{
		if ($opt_val=='')
		  $combo = "<option value=\"-1\">No hay registros</option>";
	}
	$conn_xx->DB_Freeres();
	*/
	return $combo;
}

function number_data($valor){
	return ereg_replace("[,]", ".", ereg_replace("[^0-9,]", "",$valor));
}

function completar_ceros($valor = "", $tam = 0){
	if($tam-strlen($valor) > 0)
		return str_repeat('0',$tam-strlen($valor)).$valor;
	else
		return $valor;
}

//Funcion que dado una fecha en formato ingles la convierte a espanol
function entosp($fecha_texto, $for=0){
	$num = strtotime($fecha_texto);
	switch ($for){
	  case 0:
		$e= date('d-m-Y', $num);
	  break;
	  case 1:
	  	$e= date('d-m-Y h:i:s a', $num);
	  break;
	  case 2:
	  	$e= date('d', $num); // solo dia
	  break;
	    case 3:
	  	$e= date('m', $num); // solo mes
	  break;
	   case 4:
	  	$e= date('Y', $num); // solo ano
	  break;
	   case 5:
	  	$e= date('z', $num); // Numero de dia del ano (desde 1 hasta 365)
	  break;
	  case 6:
	  	$e= date('d F Y', $num); //formato en ingles
	  break;
	  case 7:
		$xndi=date('w', $num);
		$xdi =date('d', $num);
		$xme =date('m', $num);
		$xan =date('Y', $num);
		$diassemana = array("Domingo","Lunes","Martes","Mi&eacute;rcoles","Jueves","Viernes","S&aacute;bado") ;
		$mesesano = array("Enero","Febrero","Marzo","Abril","Mayo","Junio","Julio","Agosto","Septiembre","Octubre","Noviembre","Diciembre") ;
		$e = $diassemana[$xndi]." ".$xdi. " de ". $mesesano[($xme-1)]." de ".$xan.".";
	  break;
	  case 8:
		$e= date('d/m/Y', $num);
	  break;
	  case 9:
		$e= date('d/m/Y', $num);
		$e= substr($e, 0, 5).'/'.completar_ceros(substr($e, -4, 4)-2000,2);
	  break;
	  case 10:
		$e= date('Y/m/d', $num);
	  break;
	  case 11:
		$e= date('d/m/Y', $num);
		$f= date('H:i', $num);
		$e= substr($e, 0, 5).'/'.completar_ceros(substr($e, -4, 4)-2000,2)." $f";
	  break;	  
	}
	return $e;
}

function aumentar_fecha($fecha, $aumento = 0){
	$fecha = explode("-",$fecha);
	$dia = $fecha[2];
	$mes = $fecha[1];
	$anio= $fecha[0];
	$fecha = "$dia-$mes-$anio";
	
	$proximo = mktime(0,0,0,$mes,$dia+$aumento,$anio, 1);
	return $proximoFecha = date("Y-m-d",$proximo);
}

function aumentar_fecha2($tempo2, $aum){
	$nuevafecha = strtotime ( '+'.$aum.' day' , strtotime ($tempo2) ) ;
	return $tempo = date ( 'Y-m-d' , $nuevafecha);
}


function ico($n, $tt=""){
	switch ($n) {
		case 1: 
			$route="<img src=\"images/icons/consultar.png\" border=\"0\" alt=\"Consultar\" title=\"Consultar\" align=\"absmiddle\" width='20px' height='20px'>"; //consultar
		break;
		case 2:
			$route="<img src=\"images/icons/insertar.png\" border=\"0\"  align=\"absmiddle\"  alt=\"Insertar\" title=\"Insertar\" vspace=\"3\" hspace=\"5\">"; //insertar
		break;
		case 3:
			$route="<img src=\"images/icons/editar.png\" border=\"0\"  align=\"absmiddle\" alt=\"Modificar\" title=\"Modificar\" vspace=\"3\" hspace=\"5\">"; //modificar
		break;
		case 4:
			$route="<img src=\"images/icons/eliminar.png\" border=\"0\"  align=\"absmiddle\" alt=\"Eliminar\" title=\"Eliminar\" vspace=\"3\" hspace=\"5\">"; //eliminar
		break;
		case 5:
			$route="<img src=\"images/icons/check.png\" border=\"0\"  align=\"absmiddle\" >"; //eliminar
		break;
		case 6:
			$route="<img src=\"images/icons/seguimiento.png\" border=\"0\"  align=\"absmiddle\" alt=\"Seguimiento\" title=\"Seguimiento\" vspace=\"3\" hspace=\"5\">"; //eliminar
		break;
		case 7:
			$route="<img src=\"images/icons/archivo.png\" border=\"0\"  align=\"absmiddle\" alt=\"".(($tt=='')?'Crear TXT':$tt)."\" title=\"".(($tt=='')?'Crear TXT':$tt)."\" vspace=\"3\" hspace=\"5\">";
		break;
		case 8:
			$route="<img src=\"images/icons/filesave.png\" border=\"0\"  align=\"absmiddle\" alt=\"Descargar TXT\" title=\"Descargar TXT\" vspace=\"3\" hspace=\"5\">";
		break;
		case 9:
			$route="<img src=\"images/icons/eliminar.png\" border=\"0\"  align=\"absmiddle\" alt=\"Elimina el TXT\" title=\"Elimina el TXT\" vspace=\"3\" hspace=\"5\">";
		break;
		case 10:
			$route="<img src=\"images/icons/ok.png\" border=\"0\"  align=\"absmiddle\" alt=\"Marcar como revisado\" title=\"Marcar como revisado\" vspace=\"3\" hspace=\"5\">";
		break;
		case 11:
			$route="<img src=\"images/icons/okno.png\" border=\"0\"  align=\"absmiddle\" alt=\"Marcar como NO revisado\" title=\"Marcar como NO revisado\" vspace=\"3\" hspace=\"5\">";
		break;
		case 12:
			$route="<img src=\"images/icons/consiliar.png\" border=\"0\"  align=\"absmiddle\" alt=\"Consiliar muestreo\" title=\"Consiliar muestreo\" vspace=\"3\" hspace=\"5\">";
		break;
		case 13:
			$route="<img src=\"images/icons/observacion.png\" width=\"25px\" height=\"25px\" align=\"absmiddle\" alt=\"Cargar observacion en los conteos que exista diferencia.\" title=\"Cargar observacion en los conteos que exista diferencia.\" border=\"0\">";
		break;
		case 14:
			$route="<img src=\"images/icons/arqueo.png\" width=\"25px\" height=\"30px\" align=\"absmiddle\" alt=\"Cargar arqueo.\" title=\"Cargar arqueo.\" border=\"0\">";
		break;
		case 15:
			$route="<img src=\"images/icons/impresora.png\" width=\"25px\" height=\"25px\" align=\"absmiddle\" alt=\"Imprimir.\" title=\"Imprimir.\" border=\"0\">";
		break;	
		case 16:
			$route="<img src=\"images/icons/no_factura_ni_arqueo.png\" width=\"20px\" height=\"20px\" align=\"absmiddle\" alt=\"No posee facturas pendiente ni arqueos procesados para el dia aperturado.\" title=\"No posee facturas pendiente ni arqueos procesados para el dia aperturado.\" border=\"0\">";
		break;		
		case 17:
			$route="<img src=\"images/icons/excel.png\" border=\"0\"  align=\"absmiddle\" alt=\"Exportar a Excel\" title=\"Exportar a Excel\" vspace=\"3\" hspace=\"5\">";
		break;
		case 18:
			$route="<img src=\"images/icons/b_drop1.png\" border=\"0\"  align=\"absmiddle\" alt=\"No Acceso\" title=\"No Acceso\" vspace=\"3\" hspace=\"5\">";
		break;	//
		case 19:
			$route="<img src=\"images/icons/save.png\" border=\"0\"  align=\"absmiddle\" alt=\"Si Acceso\" title=\"Si Acceso\" vspace=\"3\" hspace=\"3\">";
		break;
		case 20:
			$route="<img src=\"images/icons/observacion.png\" border=\"0\"  align=\"absmiddle\" alt=\"".(($tt=='')?'Ver HTML':$tt)."\" title=\"".(($tt=='')?'Ver HTML':$tt)."\"vspace=\"3\" hspace=\"3\" width=\"22\" height=\"22\">";
		break;
		case 21:
			$route="<img src=\"images/icons/help.png\" border=\"0\"  align=\"absmiddle\" alt=\"".(($tt=='')?'Ayuda':$tt)."\" title=\"".(($tt=='')?'Ayuda':$tt)."\"vspace=\"3\" hspace=\"3\" >";
		break;
		case 22:
			$route="<img src=\"images/icons/candado.png\" border=\"0\"  align=\"absmiddle\" alt=\"".(($tt=='')?'Bloquear':$tt)."\" title=\"".(($tt=='')?'Bloquear':$tt)."\" vspace=\"2\" hspace=\"2\" width=\"20\" height=\"15\">";
		break;
		case 23:
			$route="<img src=\"images/icons/candado1.png\" border=\"0\"  align=\"absmiddle\" alt=\"".(($tt=='')?'DesBloquear':$tt)."\" title=\"".(($tt=='')?'DesBloquear':$tt)."\" vspace=\"2\" hspace=\"2\" width=\"20\" height=\"15\">";
		break;
		case 24:
			$route="<img src=\"images/icons/archivo01.png\" border=\"0\"  align=\"absmiddle\" alt=\"".(($tt=='')?'Crear Archivo':$tt)."\" title=\"".(($tt=='')?'Crear Archivo':$tt)."\" vspace=\"3\" hspace=\"3\">";
		break;
        case 25:
			$route="<img src=\"images/icons/add1.png\" border=\"0\"  align=\"absmiddle\" alt=\"".(($tt=='')?'Colocar Disponible Inventario':$tt)."\" title=\"".(($tt=='')?'Colocar Disponible Inventario':$tt)."\" vspace=\"3\" hspace=\"3\">";
		break;
		case 26:
			$route="<img src=\"images/icons/impresora.png\" width=\"25px\" height=\"25px\" align=\"absmiddle\" alt=\"Imprimir Pedido.\" title=\"Imprimir Pedido.\" border=\"0\">";
		break;	
		case 27:
			$route="<img src=\"images/icons/icono_guia.png\" width=\"25px\" height=\"25px\" align=\"absmiddle\" alt=\"Imprimir Gu&iacute;a.\" title=\"Imprimir Gu&iacute;a.\" border=\"0\">";
		break;
		case 28:
			$route="<img src=\"images/icons/icono_imp_pdf.png\" width=\"25px\" height=\"25px\" align=\"absmiddle\" alt=\"Imprimir Comprobante de Despacho.\" title=\"Imprimir Comprobante de Despacho.\" border=\"0\">";
		break;	
		case 29:
     			$route="<img src=\"images/icons/icono_anular.png\" width=\"25px\" height=\"25px\" align=\"absmiddle\" alt=\"Anular.\" title=\"Anular.\" border=\"0\">";
     		break;
		case 30:
			$route="<img src=\"images/icons/icono_duplicado.png\" width=\"25px\" height=\"25px\" align=\"absmiddle\" alt=\"Duplicar.\" title=\"Duplicar.\" border=\"0\">";
                break;
		case 31:
       			$route="<img src=\"images/icono_acta.png\" width=\"25px\" height=\"25px\" align=\"absmiddle\" alt=\"Acta de Conformidad.\" title=\"Acta de Conformidad.\" border=\"0\">";
                break;
		case 32:
                        $route="<img src=\"images/icons/icono_liberar.png\" width=\"25px\" height=\"25px\" align=\"absmiddle\" alt=\"Liberar Pedido.\" title=\"Liberar Pedido.\" border=\"0\">";
                break;
	}
	return $route;
}

function put0($valor, $tam = 2){
	return completar_ceros($valor, $tam);
}

function fecha_hoy($tip='d'){
	switch($tip){
		case 'd': #Dia/Mes/A�o
				$strFech = put0(date('d')).'/'.put0(date('m')).'/'.date('Y');
				break;
		case 'y': #A�o-Mes-Dia
				$strFech = date('Y').'/'.put0(date('m')).'/'.put0(date('d'));
				break;
	}
	return $strFech;
}

function encrypt($decrypted, $password="Sibo-2012", $salt='SIB0!W3b53rv1c3.') {
 $key = hash('SHA256', $salt . $password, true);
 srand(); $iv = mcrypt_create_iv(mcrypt_get_iv_size(MCRYPT_RIJNDAEL_128, MCRYPT_MODE_CBC), MCRYPT_RAND);
 if (strlen($iv_base64 = rtrim(base64_encode($iv), '=')) != 22) return false;
 $encrypted = base64_encode(mcrypt_encrypt(MCRYPT_RIJNDAEL_128, $key, $decrypted . md5($decrypted), MCRYPT_MODE_CBC, $iv));
 return $iv_base64 . $encrypted;
}

function decrypt($encrypted, $password="Sibo-2012", $salt='SIB0!W3b53rv1c3.') {
 $key = hash('SHA256', $salt . $password, true);
 $iv = base64_decode(substr($encrypted, 0, 22) . '==');
 $encrypted = substr($encrypted, 22);
 $decrypted = rtrim(mcrypt_decrypt(MCRYPT_RIJNDAEL_128, $key, base64_decode($encrypted), MCRYPT_MODE_CBC, $iv), "\0\4");
 $hash = substr($decrypted, -32);
 $decrypted = substr($decrypted, 0, -32);
 if (md5($decrypted) != $hash) return false;
 return $decrypted;
}

function getcod_sucursal($cod){
  $out = 0;
  if (!empty($cod)){
	if (strlen($cod)>64){
	  $out = decrypt($cod); 	
	}
  }
  return ($out);
}

function get_t_values($id_nom, $id_cod=-1) {
  return execute_fn("SELECT fn_get_t_values('$id_nom',$id_cod)");
}

function insertData($bd_tabla, $into, $vals, $ret=null, $si_s="El Registro se ingreso correctamente", $no_s="El Registro no se ingreso", $see_sql=false){
  global $conn;
  $in = join(',', $into);
  $vl = join(',', $vals);
  $sq = "INSERT INTO $bd_tabla ($in) VALUES ($vl)".(!empty($ret)?" RETURNING $ret":'');
  if ($see_sql)
    echo "<div>$sq</div>";
  $rs_ins = $conn->DB_Consulta($sq);
  if (empty($ret)){
    $res = (($rs_ins) ? $si_s : $no_s);
  }else{
    $rw = $conn->DB_fetch_array($rs_ins);
    $res[] = (($rs_ins) ? $rw[0] : 0);
    $res[] = (($rs_ins) ? $si_s : $no_s);
  }
  return $res;
}

function execute_fn($sql){
	global $conn;
	$val = null;
	$con_val = $conn->DB_Consulta($sql);
	$chk = $conn->DB_num_rows($con_val);
	if (!empty($chk)){
	  $row_val=$conn->DB_fetch_array($con_val);
	  if ($row_val){
	  	$val = $row_val[0];
	  }
	}else
	  $val = 0;
	return $val;
}

function verifica_facturas_por_arquear($id_sucursal,$fecha_proceso){
	///////////////////////////////////////////////////
	// Abrir conexion con la base de datos.
		$conn = new DB_Class;
		$conn->DB_Init();
		
		$sql_chequea_facturas =  "select * from facturas where (id_sucursal=$id_sucursal and estatus_arqueo=0 and fecha > '$fecha_proceso 00:00:00' and fecha < '$fecha_proceso 23:59:59');";
		$rs_chequea_facturas  =  $conn->DB_Consulta($sql_chequea_facturas);		
		if ($conn->DB_num_rows($rs_chequea_facturas) > 0){
			$variable = $conn->DB_num_rows($rs_chequea_facturas);
		}else{
			$variable = 0;
		}
		// Cerrar conexion con la base de datos.
		$conn->DB_Freeres();
	///////////////////////////////////////////////////	
	return $variable;
}

//---------------------------------
function verificar_prod_invrot($id_invent,$lote){
	/*$invrot=consulta_valor("invrot","id_invrot","estatus=1");
	$id_producto=consulta_valor("invrotdet","id_producto","id_invrot=".$invrot);*/
	$sw=consulta_valor("inventarios","sw_inventario_rotativo","id_inventario=".$id_invent." and id_lote=".$lote."");
	if ($sw==1){
		$valor=1;//ya se realizo inventario rotativo
	}else{
		$valor=0;//no se realizo inventario rotativo
	}
	return($valor);
 }

function register_price($codigo_barra, $precio_fp){
 	include 'include/clase_db_SICM.inc.php';
	$sicm = new DB_Class_SICM;
	$sicm->DB_Init();
	$sicm->DB_Consulta("SELECT sp_precios_sibo('$codigo_barra', $precio_fp)");
}
 
function generar_muestra($tam)
{
		global $conn;
		//echo $tam;

		$sucursal_activa = consulta_valor("sucursal_activa","valor","1=1");
		$sql="  select	id_inventario, id_lote, cexistencia  
				from	inventarios 
				where	id_sucursal = $sucursal_activa and 
						cexistencia > 0 and 
						sw_inventario_rotativo = 0 
				order by id_inventario;";
		$rs_productos=$conn->DB_Consulta($sql);
		
		$cont = 0;
		$sql_insert = "";
		$invrot=consulta_valor("invrot","id_invrot"," estatus=1 and id_sucursal=".$sucursal_activa);

		$query = "select nextval('invrotmue_id_invrot_mue_seq') as id;";
		$r100 = $conn->DB_Consulta($query);
		if( $conn->DB_num_rows($r100) > 0 )
		{
			$row = $conn->DB_fetch_array( $r100 );
			$inv_rot_muestra = $row['id'];
		}
		else
		{
			$inv_rot_muestra = -1;
		}

		while($res=$conn->DB_fetch_array($rs_productos))
		{
			if( $cont < $tam )
			{
				$sql_insert .= "insert into invrotdet (id_invrot,id_lote,existencia,estatus,fecha_gen,id_invrotmue) 
										values ($invrot,{$res['id_lote']},{$res['cexistencia']},0,'now()',$inv_rot_muestra);
								update inventarios set sw_inventario_rotativo=1 where id_inventario={$res['id_inventario']};";
				$cont++;
				//break;
			}
		}
		//echo $sql_insert;
		if( $sql_insert <> "" )
		{
			$sql100 = "insert into invrotmue (id_invrot_mue,id_invrot,fecha,estatus) values ($inv_rot_muestra,$invrot,'now()',0);".$sql_insert;
			//echo $sql100;
			if( $conn->DB_Consulta($sql100) )
			{
				$valor = 1;
			}
			else
			{
				$valor = 0;
			}
		}
		else
		{
			$valor = 0;
		}
		return $valor;
}

	//---------------------------------
	/////////////////////////////////////////////////////////////////////////
	////////   Paginado para utlizar ajax con jquery. Miguel Romero    //////
	/////////////////////////////////////////////////////////////////////////	
	function paginar_ajax($numero_item,$show,$data_per_pag,$rango_pag,$total_data,$pag_que_llama,$contenedor,$datos){			
			global $url_mod;
			
			$nro_pags=ceil($total_data/$data_per_pag);
			$actual=$numero_item;
			$anterior = $actual - 1;
			$posterior = $actual + 1;
			$ak=$actual+1;
			$texto=" P&aacute;gina <b>$ak</b> de <b>$nro_pags</b> | ";
			////////////////////////
			if ($actual != 0){
				$texto .= "<a href='javascript:mover_pagina(\"$pag_que_llama\",$anterior,\"$contenedor\",\"$datos\");'>&laquo;</a> ";
			}else{
				$texto .= "<b>&laquo;</b> ";
			}
			////////////////////////
			$r1=($actual<$rango_pag ? 1 : $actual-($rango_pag-2));
			$r1=($r1<1 ? 1 : $r1);
			
			$r2=(($actual+1)==$nro_pags ? $nro_pags : $actual+$rango_pag);
			$r2=($r2>$nro_pags ? $nro_pags : $r2);
					
			for ($i=$r1; $i<=$r2; $i++){
				$ik=$i-1;
				if ($i==$ak)
					$texto .= "&nbsp;<span style='color:red'><b>$ak</b></span>&nbsp;";
				else
					$texto .= "<a href='javascript:mover_pagina(\"$pag_que_llama\",$ik,\"$contenedor\",\"$datos\");'>$i</a> ";
			}

			if ($actual<$nro_pags-1)
				$texto .= "<a href='javascript:mover_pagina(\"$pag_que_llama\",$posterior,\"$contenedor\",\"$datos\");'>&raquo;</a>";
			else
				$texto .= "<b>&raquo;</b>";
		
		return $texto;
	}
//-------------------------------------

function putVal4Db($val, $tip){
	$str = eregi_replace("[\n|\r|\n\r]", '', $val);
	$str = rtrim($str);
	$str = str_replace("�", "1/2", $str);
	$str = utf8_encode($str);
    if ($tip=='s'){
	  if (empty($val) or $val=='')
	    $str = 'null';
	  else
	   $str = "'$str'";
	}
    if ($tip=='i'){
	  if (empty($val) or $val=='')
	    $str = 'null';
	  else{
	   $str = str_replace(".", "", $str);
	   $str = str_replace(",", ".", $str);
	  }
	}
    if ($tip=='f'){
	  if (empty($val) or $val=='')
	    $str = 'null';
	  else{
	    $str = str_replace(".", "", $str);
	    $str = str_replace(",", ".", $str);
	  }
	}
	$str = str_replace("''", "null", $str);
    return $str;
}

function isWinorLin(){
  $pos = strripos($_SERVER['SERVER_SOFTWARE'], 'Win32');
  if ($pos === false) {
      return false;
  } else {
      return true;
  }
}

function send2printer($fac, $acc='print_invo', $host=null, $read=false){
  $port = '5180'; 
  $out = '';
  if (empty($host))
    $host = getIP();
  $socket = fsockopen($host, $port, $errno, $errstr) or die(" - ERROR: Nro:$errno. Se registro la factura, Pero No se pudo conectar a la impresora $host.");
  if ($socket){
    $pss = 'Sibo-2012!';
    $sep = ';_,';
    fwrite($socket, "$pss$sep$acc$sep$fac");
	if ($read)
      $out = fread($socket, 64);
    fclose($socket);
  }else{
    echo "ERROR:$errstr ($errno)<br />\n";
  }
  return $out;
}

function put_des_has($cmp, $desde, $hasta){
  $str = "and $cmp::date between '$desde' and '$hasta'";
  return " $str ";
}

function put_4year($cmp, $anio){
  $str = "and EXTRACT(YEAR FROM $cmp)=$anio";
  return " $str ";
}

function month_name($opc){
	$out = $opc;
	switch ($opc){
		case 1:  $out = "Enero";      break;
		case 2:  $out = "Febrero";    break;
		case 3:  $out = "Marzo";      break;
		case 4:  $out = "Abril";      break;
		case 5:  $out = "Mayo";       break;
		case 6:  $out = "Junio";      break;
		case 7:  $out = "Julio";      break;
		case 8:  $out = "Agosto";     break;
		case 9:  $out = "Septiembre"; break;
		case 10: $out = "Octubre";    break;
		case 11: $out = "Noviembre";  break;
		case 12: $out = "Diciembre";  break;
	}
	return $out;
}
/* funciones Ing. Julio Carma. */
function validar_producto( $parametro )
	/*parametro es un arreglo con varios valores*/
{
	global $conn;

	$query="select id_producto, pvp_fp 
			from productos 
			where cod_barras = '".trim($parametro['cod_barras'])."';";
	//echo $query;
	$r = $conn->DB_Consulta( $query );
	$num_row = $conn->DB_num_rows( $r );
	$id_producto = -1;

	if( $num_row > 0 )
	{
		$row = $conn->DB_fetch_array( $r );
		$id_producto = $row['id_producto'];
		if( (empty( $row['pvp_fp'] )) and ($row['pvp_fp'] <= 0 or $row['pvp_fp'] == null  ))
		{
			//actualizar producto; ajuste para obtener como minimo el 10% de ganancia
			$pvp_fp = ( $parametro['costo'] * 0.1 )+$parametro['costo'];
			$query = "update productos set pvp_fp = $pvp_fp where id_producto = $id_producto; ";
			//echo $query;
			if( !$conn->DB_Consulta( $query ) )
			{
				$id_producto = -1;
			}
		}
	}
	else
	{
			//registrar producto; ajuste para obtener como minimo el 10% de ganancia
			$pvp_fp  = ( $parametro['costo'] * 0.1 )+$parametro['costo'];
			$pvp_ref = ( $parametro['costo'] * 0.2 )+$parametro['costo'];

			$nombre = $parametro['nombre'];

			$borrar[0] = array("error"=>array("�","�","�"), "letra"=>"a");
			$borrar[1] = array("error"=>array("�","�","�"), "letra"=>"e");
			$borrar[2] = array("error"=>array("�","�","�"), "letra"=>"i");
			$borrar[3] = array("error"=>array("�","�","�"), "letra"=>"o");
			$borrar[4] = array("error"=>array("�","�","u"), "letra"=>"u");
			$borrar[5] = array("error"=>array("�","�","�"), "letra"=>"A");
			$borrar[6] = array("error"=>array("�","�","�"), "letra"=>"E");
			$borrar[7] = array("error"=>array("�","�","�"), "letra"=>"I");
			$borrar[8] = array("error"=>array("�","�","�"), "letra"=>"O");
			$borrar[9] = array("error"=>array("�","�","�"), "letra"=>"U");
			$borrar[10] = array("error"=>array("�"), "letra"=>"N");
			$borrar[11] = array("error"=>array("�"), "letra"=>"n");
			$borrar[12] = array("error"=>array("�","�","'"), "letra"=>" ");
			$borrar[13] = array("error"=>array("/"), "letra"=>"-");
			$borrar[14] = array("error"=>array("%"), "letra"=>" porc ");

			foreach( $borrar as $b )
			{
				foreach( $b["error"] as $e )
				{
					$nombre = utf8_encode( str_replace($e, $b["letra"], $nombre ) );
				}
			}
			$query = "
					insert into productos(id_producto, nb_producto, id_usuario_reg, fecha_ing, 
					cod_barras, pvp_fp, pvp_ref, id_impuesto, clab )
					values(default, '$nombre',{$parametro['id_usuario']}, now(), 
					'".trim($parametro['cod_barras'])."', $pvp_fp, $pvp_ref, 
					'{$parametro['iva']}', '-1' ) RETURNING id_producto;";
			
			//echo $query;
			
			$r2 = $conn->DB_Consulta( $query );
			$row2 = $conn->DB_fetch_array( $r2 );
			if( isset( $row2['id_producto'] ) )
			{
				$id_producto = $row2['id_producto'];
			}
	}
	return $id_producto;
}

function add_bitacora( $parametro )
{
	global $conn;
	$ip = getIP();
	$borrar = array("'");
	$cadena_sql = utf8_encode( str_replace($borrar, " ", $parametro['sql'] ) );

	$query="insert into bitacora( id_bitacora, id_usuario, id_operacion, ip_conexion, pagina, sql, fecha_reg ) 
			values ( default, {$parametro['id_usuario']}, {$parametro['opc']}, '$ip', '{$parametro['pagina']}', '$cadena_sql', now() );";
	//echo $query;
	$conn->DB_Consulta( $query );
}

function inv_reb()
{
	global $conn;
	$sql_inv="select * from inventarios where cexistencia=0;";
	$rs_inv=$conn->DB_Consulta( $sql_inv );
	while ($rw_inv = $conn->DB_fetch_array($rs_inv)){
		$sql_his_inv="insert into his_inventarios values ('{$rw_inv['id_inventario']}', {$rw_inv['id_sucursal']}, {$rw_inv['id_deposito']}, '{$rw_inv['id_lote']}', {$rw_inv['cexistencia']}, {$rw_inv['cbloqueada']}, '{$rw_inv['fecha_ing']}', '{$rw_inv['fecha_act']}', {$rw_inv['id_usuario_reg']}, {$rw_inv['sw_inventario_rotativo']}, {$rw_inv['ssc']});";
	//	$rs_his_inv=$conn->DB_Consulta( $sql_his_inv );
	}
	$sql_inv2="delete from inventarios where cexistencia=0;";
	//$rs_inv2=$conn->DB_Consulta( $sql_inv2 );
}

function inv_reb_suc($id_suc)
{
	global $conn;
	$sql_inv="select * from inventarios where cexistencia=0 and id_sucursal = {$id_suc};";
	$rs_inv=$conn->DB_Consulta( $sql_inv );
	while ($rw_inv = $conn->DB_fetch_array($rs_inv)){
		$sql_his_inv="insert into his_inventarios values ('{$rw_inv['id_inventario']}', {$rw_inv['id_sucursal']}, {$rw_inv['id_deposito']}, '{$rw_inv['id_lote']}', {$rw_inv['cexistencia']}, {$rw_inv['cbloqueada']}, '{$rw_inv['fecha_ing']}', '{$rw_inv['fecha_act']}', {$rw_inv['id_usuario_reg']}, {$rw_inv['sw_inventario_rotativo']}, {$rw_inv['ssc']});";
	//	$rs_his_inv=$conn->DB_Consulta( $sql_his_inv );
	}
	$sql_inv2="delete from inventarios where cexistencia=0 and id_sucursal = {$id_suc};";
	//$rs_inv2=$conn->DB_Consulta( $sql_inv2 );
}

function inv_agregar($cant,$id_suc,$id_lote)
{

	global $conn;
	$sql_inv="select * from his_inventarios where cexistencia=0 and id_sucursal={$id_suc} and id_lote='{$id_lote}';";
	$rs_inv=$conn->DB_Consulta( $sql_inv );
	$rw_inv = $conn->DB_fetch_array($rs_inv);
	
	$sql_his_inv="insert into inventarios values ('{$rw_inv['id_inventario']}', {$rw_inv['id_sucursal']}, {$rw_inv['id_deposito']}, '{$rw_inv['id_lote']}', {$cant}, {$rw_inv['cbloqueada']}, '{$rw_inv['fecha_ing']}', '{$rw_inv['fecha_act']}', {$rw_inv['id_usuario_reg']}, {$rw_inv['sw_inventario_rotativo']}, {$rw_inv['ssc']});";
	$rs_his_inv=$conn->DB_Consulta( $sql_his_inv );
	
	$sql_inv2="delete from his_inventarios where cexistencia=0 and id_sucursal={$id_suc} and id_lote='{$id_lote}';";
	$rs_inv2=$conn->DB_Consulta( $sql_inv2 );

}

// Esta funcion calcula el numero de dias que existe entre 2 fechas dadas Miguel Romero
function dateDiff($fecha1, $fecha2) {
    $fecha1_exp =  explode("-",$fecha1);
    $fecha1     =  $fecha1_exp[2]."-".$fecha1_exp[1]."-".$fecha1_exp[0];

    $fecha2_exp =  explode("-",$fecha2);
    $fecha2     =  $fecha2_exp[2]."-".$fecha2_exp[1]."-".$fecha2_exp[0];

    $fecha1_ts  =  strtotime($fecha1);
    $fecha2_ts  =  strtotime($fecha2);
    $diff       =  $fecha2_ts - $fecha1_ts;
    return round($diff / 86400);
}

function getUltimoDiaMes($elAnio,$elMes) {

    $month = $elAnio."-".$elMes;
    $aux = date('Y-m-d', strtotime("{$month} + 1 month"));
    $fecha_ultima = date('Y-m-d', strtotime("{$aux} - 1 day"));
    return $fecha_ultima;
}

function diaSemanaEspanol($fecha){
	setlocale(LC_ALL,"es_ES@euro","es_ES","esp","es");
    $dias = array('Domingo','Lunes','Martes','Miercoles','Jueves','Viernes','Sabado','Domingo');
    $fechaSem = $dias[date('N', strtotime($fecha))];
    return $fechaSem;
}
/*
function inv_his_mod($id_suc)
{

	global $conn;
	$sql_inv="select * from his_inventarios where id_sucursal={$id_suc};";
	$rs_inv=$conn->DB_Consulta( $sql_inv );
	while($rw_inv = $conn->DB_fetch_array($rs_inv)){
		$rw_inv['id_inventario'];
		$inv=consulta_valor("inventarios","id_inventario","id_inventario='{$rw_inv['id_inventario']}' and id_sucursal={$id_suc}");
		
		if($inv!='-ne-'){
		
			$sql_inv2="delete from inventarios where id_inventario='{$inv}' and id_sucursal={$id_suc};";
			$rs_inv2=$conn->DB_Consulta( $sql_inv2 );
		
		}		
		
	}

}*/

function disponible_por_distribucion($id_pedido_almacen){
   global $conn;
   $sql_sel= "update inventarios set disponible = 1 where disponible=0 and id_pedido_almacen={$id_pedido_almacen}";
   $rs_sel=$conn->DB_Consulta($sql_sel);
   if ($rs_sel)
       return (1);
   else
       return (0);
}

?>
