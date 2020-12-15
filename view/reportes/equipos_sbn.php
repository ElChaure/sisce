.<?php
$pdf = new \Mpdf\Mpdf(['format' => 'Letter'],['orientation' => 'L']);
require_once 'model/equipo.php';
require_once 'model/estatus_equipo.php';
require_once 'model/ubicacion.php';
require_once 'model/articulo.php';
require_once 'model/proveedor.php';
require_once 'model/marca.php';
require_once 'model/empleado.php';
require_once 'model/funcionario.php';

$equip = new Equipo();
$esteq = new Estatus_equipo();
$ubica = new Ubicacion();
$artic = new Articulo();
$prove = new Proveedor();
$marca = new Marca();
$emple = new Empleado();
$funci = new Funcionario();

$equipos = $equip->Listar_sin_bn();

$output = "report$id_e$if_fun_os =mp_os =e3";

$tit = "<br><br><br><table border='0'><thead><tr><th style='width:800px;' align='center'>Reporte de Equipos o Bienes Sin Bien Nacional Asignado</th></tr></thead></table>";
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
         <td width="100%" align="center">Reporte de Equipos o Bienes Sin Bien Nacional Asignado</td>
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


$def_thead ='
</br>
</br>
<table class="table table-striped" border=1>
    <thead>
        <tr bgcolor="#959595">
            <th style="width:20px;">Id</th>
            <th style="width:420px;">Descripcion</th>
            <th style="width:90px;">Serial</th>
            <th style="width:90px;">Bien Nac.</th>
            <th style="width:90px;">Estatus</th>
            <th style="width:90px;">Ubicacion</th>

        </tr>
    </thead>
';
$pdf->WriteHTML($def_thead);
$nro=1;
foreach ($equipos as $key => $value) {
  $linea= '<tr>
           <td>'.$value->id_equipo.'</td>
           <td>'.$value->descripcion.'</td>
           <td>'.$value->serial.'</td>
           <td>'.$value->num_bien_nac.'</td>
           <td>'.$value->estatus.'</td>
           <td>'.$value->ubicacion.'</td>
           </tr>';
  $pdf->WriteHTML($linea);
  $nro=$nro+1;
}


$def_fin ='
    </tbody>
</table> 
';

$pdf->WriteHTML($def_fin);


$pdf->Output();
?>