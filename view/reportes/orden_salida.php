<?php
$pdf = new \Mpdf\Mpdf(['format' => 'Letter']);
//require_once 'model/database.php';
require_once 'model/orden_salida.php';
require_once 'model/solicitud.php';
require_once 'model/solicitud_detalle.php';
require_once 'model/empleado.php';
require_once 'model/funcionario.php';


$nro_orden=$_GET['id_orden'];

$ord = new Orden_salida();
$sol = new Solicitud();
$std = new Solicitud_detalle();
$emp = new Empleado();
$fun = new Funcionario();

$ord_sal = $ord->Obtener($nro_orden);

$num_orden =  $ord_sal->num_orden;
$id_solicitud=  $ord_sal->id_solicitud;
$observacion=  $ord_sal->observacion;


$id_emp_os =  $ord_sal->id_emp;
$if_fun_os =  $ord_sal->id_funcionario;
  

$sol_emp = $sol->Obtener($id_solicitud);

$sol_det = $std->Listar_asignados($id_solicitud);

$id_emp = $sol_emp->id_empleado;
$id_fun = $sol_emp->id_funcionario;
$emp_dat = $emp->Obtener($id_emp);
$fun_dat = $fun->Obtener($id_fun);

//($idfun->Obt->_fun)/var
//die();


$output = "report$id_e$if_fun_os =mp_os =e3";

$tit = "<br><br><br><table border='0'><thead><tr><th style='width:800px;' align='center'>Orden de Salidad de Almacen de Equipos o Bienes Nro:".$num_orden."</th></tr></thead></table>";
$tit2 = "<br><br><br><table border='0'><thead><tr><th style='width:800px;' align='center'>Orden de Entrega de Equipos o Bienes Nro:".$num_orden."</th></tr></thead></table>";
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
         <td width="100%" align="center">Orden de Salidad de Almacen de Equipos o Bienes Nro:'.$num_orden.'</td>
      </tr>
</table>';

$enc2='<table width="100%">
    <tr>
        <td width="33%" style="text-align: left;"><img src=assets/img/mpprijp.png width="150" height="75"></td>
        <td width="33%" align="center"><img src=assets/img/atodavida.jpg width="150" height="75"></td>
        <td width="33%" style="text-align: right;"><img src=assets/img/logo.png width="150" height="75"></td>
    </tr>
</table>
<table width="100%">
      <tr>
         <td width="100%" align="center">Orden de Entrega de Equipos o Bienes Nro:'.$num_orden.'</td>
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


$originalDate = $ord_sal->fecha_generacion;
$newDate = date("d/m/Y", strtotime($originalDate));
$html="Caracas, ".$newDate."</br></br>";
$pdf->WriteHTML($html);
$html="<P ALIGN='justify'>Por medio del presente, el <b>Servicio Autonomo de Registros y Notarias</b>, autoriza al Ciudadano <b>".$emp_dat->primer_nombre." ".
$emp_dat->segundo_nombre." ".$emp_dat->primer_apellido." ".$emp_dat->segundo_apellido.",</b> portador de la Cedula de Identidad Nro <b>".$emp_dat->cedula."</b>,
en ejercicio de sus funciones, a retirar de la Sede Central el material descrito a continuacion:</b>";
$html2="<P ALIGN='justify'>Por medio del presente, el <b>Servicio Autonomo de Registros y Notarias</b>, entrega al Ciudadano <b>".$emp_dat->primer_nombre." ".
$emp_dat->segundo_nombre." ".$emp_dat->primer_apellido." ".$emp_dat->segundo_apellido.",</b> portador de la Cedula de Identidad Nro <b>".$emp_dat->cedula."</b>,
en ejercicio de sus funciones, el material descrito a continuacion:</b>";
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
            <th style="width:90px;">Solicitud</th>
        </tr>
    </thead>
';
$pdf->WriteHTML($def_thead);
$nro=1;
foreach ($sol_det as $key => $value) {
  $linea= '<tr>
           <td>'.$nro.'</td>
           <td>'.$value->descripcion.'</td>
           <td>'.$value->serial.'</td>
           <td>'.$value->num_bien_nac.'</td>
           <td>'.$value->id_solicitud.'</td>
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

$pdf->SetHTMLHeader($enc2);
$pdf->AddPageByArray([
    'margin-left' => '15',
    'margin-right' => '20',
    'margin-top' => '40',
    'margin-bottom' => '15',
]);
$html2="Caracas, ".$newDate."</br></br>";
$pdf->WriteHTML($html2);
$html2="<P ALIGN='justify'>Por medio del presente, el <b>Servicio Autonomo de Registros y Notarias</b>, entrega al Ciudadano <b>".$emp_dat->primer_nombre." ".
$emp_dat->segundo_nombre." ".$emp_dat->primer_apellido." ".$emp_dat->segundo_apellido.",</b> portador de la Cedula de Identidad Nro <b>".$emp_dat->cedula."</b>,
en ejercicio de sus funciones, el material descrito a continuacion:</b>";
$pdf->WriteHTML($html2);
$pdf->WriteHTML($def_thead);
$nro=1;
foreach ($sol_det as $key => $value) {
  $linea= '<tr>
           <td>'.$nro.'</td>
           <td>'.$value->descripcion.'</td>
           <td>'.$value->serial.'</td>
           <td>'.$value->num_bien_nac.'</td>
           <td>'.$value->id_solicitud.'</td>
           </tr>';
  $pdf->WriteHTML($linea);
  $nro=$nro+1;
}
$def_fin ='
    </tbody>
</table>';
$pdf->WriteHTML($def_fin);
$pdf->WriteHTML($firmas);

$pdf->Output();
?>