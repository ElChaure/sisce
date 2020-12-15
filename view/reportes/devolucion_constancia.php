<?php
setlocale(LC_ALL,"es_ES");
$pdf = new \Mpdf\Mpdf(['format' => 'Letter']);
require_once 'model/devolucion.php';
require_once 'model/equipo.php';
require_once 'model/empleado.php';

$fecha_dev=$_GET['fecha_devolucion'];
$id_empleado_entrega=$_GET['id_empleado_entrega'];

$dev = new Devolucion();
$emp = new Empleado();


$id_emp = $id_empleado_entrega;
$emp_dat = $emp->Obtener($id_emp);
$dev_dat = $dev->Obtener_devoluciones($fecha_dev,$id_empleado_entrega);
//var_dump($dev_dat);die();

//$observacion="";

$tit = "<br><br><br><table border='0'><thead><tr><th style='width:800px;' align='center'>Constancia de Devolucion de Equipos o Bienes</th></tr></thead></table>";
$pdf_ext = ".pdf";
$enc='<table width="100%">
    <tr>
        <td width="33%" style="text-align: left;"><img src=assets/img/mpprijp.png width="150" height="75"></td>
        <td width="33%" align="center"><img src=assets/img/atodavida.jpg width="150" height="75"></td>
        <td width="33%" style="text-align: right;"><img src=assets/img/logo.png width="150" height="75"></td>
    </tr>
</table>
<table width="100%">
      <tr>
         <td width="100%" align="center">Constancia de Devolucion de Equipos o Bienes</td>
      </tr>
</table>';

//$pdf->SetMargins(0, 0, 15);

$pdf->SetHTMLHeader($enc);
$pdf->SetHTMLFooter('<div style="text-align:center;font-size:10px;font-family:opensans;">
Generado a traves del Sistema SICET en Fecha {DATE j-m-Y} por el Usuario '.$_SESSION['usuario_nombre'].'| Fuente: OSTI-2019 |  Pagina: {PAGENO}
</div>');
//$pdf->WriteHTML($tit);

$pdf->AddPageByArray([
    'margin-left' => '15',
    'margin-right' => '20',
    'margin-top' => '40',
    'margin-bottom' => '15',
]);


$originalDate = $fecha_dev;
switch (date("m")) {
    case '01':
        $nommes=" Enero ";
        break;
    case '02':
        $nommes=" Febrero ";
        break;
    case '03':
        $nommes=" Marzo ";
        break;
    case '04':
        $nommes=" Abril ";
        break;
    case '05':
        $nommes=" Mayo ";
        break;
    case '06':
        $nommes=" Junio ";
        break;
    case '07':
        $nommes=" Julio ";
        break;
    case '08':
        $nommes=" Agosto ";
        break;
    case '09':
        $nommes=" Septiembre ";
        break;
    case '10':
        $nommes=" Octubre ";
        break;
    case '11':
        $nommes=" Noviembre ";
        break;
    case '12':
        $nommes=" Diciembre ";
        break;                                    
}

$newDate = date("d") . " de " . $nommes . " de " . date("Y");
$html="Caracas, ".$newDate."</br></br>";
$pdf->WriteHTML($html);
$html="<P ALIGN='justify'>Por medio del presente, el <b>Servicio Autonomo de Registros y Notarias</b>, hace constar que el (la) Ciudadano (a) <b>".$emp_dat->primer_nombre." ".
$emp_dat->segundo_nombre." ".$emp_dat->primer_apellido." ".$emp_dat->segundo_apellido.",</b> portador de la Cedula de Identidad Nro <b>".$emp_dat->cedula."</b>,
en ejercicio de sus funciones, ha reintegrado a la Sede Central el material descrito a continuacion:</b>";
$pdf->WriteHTML($html);


$def_thead ='
</br>
</br>
<table class="table table-striped" border=1>
    <thead>
        <tr bgcolor="#959595">
            <th style="width:20px;">Nro</th>
            <th style="width:420px;">Descripcion</th>
            <th style="width:90px;">Serial</th>
            <th style="width:90px;">Bien Nac.</th>
            <th style="width:90px;">Observacion</th>
        </tr>
    </thead>
';
$pdf->WriteHTML($def_thead);
$nro=1;
foreach ($dev_dat as $key => $value) {
  $linea= '<tr>
           <td>'.$nro.'</td>
           <td>'.$value->descripcion.'</td>
           <td>'.$value->serial.'</td>
           <td>'.$value->num_bien_nac.'</td>
           <td>'.$value->observacion.'</td>
           </tr>';
  $pdf->WriteHTML($linea);
  $nro=$nro+1;
}


$def_fin ='
    </tbody>
</table> 
';

$pdf->WriteHTML($def_fin);



$firmas='
<table>
<td>
<tr></tr>
<tr></tr>
<tr></tr>
</td>
</table>
<table width="100%">
    <tr>
        <td width="33%">________________________________</td>
        <td width="33%">________________________________</td>
        <td width="33%">________________________________</td>
    </tr>
    <tr>
        <td width="33%" style="text-align: center;">'.$emp_dat->primer_nombre.' '.
$emp_dat->segundo_nombre.' '.$emp_dat->primer_apellido.' '.$emp_dat->segundo_apellido.'</td>
        <td width="33%" style="text-align: center;">CARLOS AMAYA</td>
        <td width="33%" style="text-align: center;">SEGURIDAD</td>
    </tr>
    <tr>
        <td width="33%" style="text-align: center;"></td>
        <td width="33%" style="text-align: center;">COORDINADOR</td>
        <td width="33%" style="text-align: center;">COORDINACION DE SEGURIDAD</td>
    </tr>
    <tr>
    <td colspan=3 align="center">___________________________________________________________________________________________________</td>
    </tr>
    <tr>
    <td colspan=3 align="center">OBSERVACIONES</td>
    </tr>
    <tr>
    <td colspan=3 align="justify">'.$observacion.'</td>
    </tr>
</table>';

$pdf->WriteHTML($firmas);

$pdf->Output();
?>