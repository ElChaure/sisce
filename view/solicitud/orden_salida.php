<?php
$pdf = new \Mpdf\Mpdf(['format' => 'Letter']);
//require_once 'model/database.php';
require_once 'model/orden_salida.php';
require_once 'model/solicitud.php';
require_once 'model/solicitud_detalle.php';
require_once 'model/empleado.php';
require_once 'model/funcionario.php';
require_once 'model/empleado_activo.php'; 

//$id_solicitud=$_GET['id_solicitud'];

$ord = new Orden_salida();
$sol = new Solicitud();
$std = new Solicitud_detalle();
$emp = new Empleado();
$empact = new Empleado_activo();
$fun = new Funcionario();

$ord_sal = $ord->Obtener($nro_orden);
$num_orden =  $ord_sal->num_orden;
$id_solicitud=  $ord_sal->id_solicitud;
$observacion  $ord_sal->observacion;
$id_emp_os =  $ord_sal->id_emp;
$if_fun_os =  $ord_sal->id_funcionario;
  

$sol_emp = $sol->Obtener($id_solicitud);
$sol_det = $std->Listar($id_solicitud);

$id_emp = $sol_emp->id_empleado;
$id_fun = $sol_emp->id_funcionario;
$emp_dat = $emp->Obtener($id_emp);
$fun_dat = $fun->Obtener($id_fun);

/($idfun->Obt->_fun)/var
//die();


$output = "report$id_e$if_fun_os =mp_os =e3";

$tit = "<br><br><br><table border='0'><thead><tr><th style='width:800px;' align='center'>Planilla de Solicitud de Equipos o Bienes Nro:".$id_solicitud."</th></tr></thead></table>";
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
         <td width="100%" align="center">Planilla de Solicitud de Equipos o Bienes Nro:'.$id_solicitud.'</td>
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


$originalDate = $sol_emp->fecha_solicitud;
$newDate = date("d/m/Y", strtotime($originalDate));
$html="Caracas, ".$newDate."</br></br>";
$pdf->WriteHTML($html);
$html="<p>Por medio del presente, el <b>Servicio Autonomo de Registros y Notarias</b>, hace constar que el Ciudadano <b>".$emp_dat->primer_nombre." ".
$emp_dat->segundo_nombre." ".$emp_dat->primer_apellido." ".$emp_dat->segundo_apellido.",</b> portador de la Cedula de Identidad Nro <b>".$emp_dat->cedula."</b>,
en ejercicio de sus funciones, ha solicitado a traves del Funcionario <b>".$fun_dat->nombre." ".$fun_dat->apellido."</b>, el material descrito a continuacion:</b>";
$pdf->WriteHTML($html);
$def_thead ='
</br>
</br>
<table class="table table-striped">
    <thead>
        <tr bgcolor="#959595">
            <th style="width:20px;">Codigo</th>
            <th style="width:120px;">Serial</th>
            <th style="width:140px;">Bien Nac.</th>
            <th style="width:90px;">Descripcion</th>
            <th style="width:180px;">Valor</th>
        </tr>
    </thead>
';
$pdf->WriteHTML($def_thead);

foreach ($sol_det as $key => $value) {
  $linea= '<tr>
           <td>'.$value->cod_equipo.'</td>
           <td>'.$value->serial.'</td>
           <td>'.$value->num_bien_nac.'</td>
           <td>'.$value->descripcion.'</td>
           <td>'.$value->valor.'</td>
           </tr>';
  $pdf->WriteHTML($linea);
}


$def_fin ='
    </tbody>
</table> 
';

$pdf->WriteHTML($def_fin);



$pdf->Output();
?>