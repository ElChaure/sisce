<?php
$pdf = new \Mpdf\Mpdf(['format' => 'Letter']);
require_once 'model/usuario.php';
require_once 'model/roles.php';

$rol = new Roles();


$output = "reporte3";

$tit = "<br><br><br><table border='0'><thead><tr><th style='width:800px;' align='center'>Reporte de Usuarios del Sistema</th></tr></thead></table>";
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
         <td width="100%" align="center">Reporte de Usuarios del Sistema</td>
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


/* Inicio de Cuerpo del reporte*/
$def_thead ='
<table class="table table-striped">
    <thead>
        <tr bgcolor="#959595">
            <th style="width:20px;">Id</th>
            <th style="width:120px;">Usuario</th>
            <th style="width:140px;">Nombres</th>
            <th style="width:90px;">Email</th>
            <th style="width:180px;">Rol</th>
        </tr>
    </thead>
';
$pdf->WriteHTML($def_thead);

foreach($this->model->Listar() as $r): 
   $rol_usu = $rol->Obtener($r->id_rol);
   
   $linea= '<tr><td>'.$r->id.'</td><td>'.$r->alias.'</td><td>'.$r->nombres.'</td><td>'.$r->email.'</td><td>'.$rol_usu->role_name.'</td></tr>';
   $pdf->WriteHTML($linea);
endforeach;
$def_fin ='
    </tbody>
</table> 
';
$pdf->WriteHTML($def_fin);
//$pdf->Output($output . '-' . date(ymdhis) . $pdf_ext);
$pdf->Output();
?>