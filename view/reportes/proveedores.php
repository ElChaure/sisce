<?php
$pdf = new \Mpdf\Mpdf(['format' => 'Letter']);
require_once 'model/database.php';
require_once 'model/proveedor.php';
$sol = new Proveedor();
$soli = $sol->Listar();


$output = "reporte3";

$tit = "<br><br><br><table border='0'><thead><tr><th style='width:800px;' align='center'>Listado de Proveedores</th></tr></thead></table>";
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
         <td width="100%" align="center">Listado de Proveedores</td>
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
<table class="table table-striped">
    <thead>
        <tr bgcolor="#959595">
            <th style="width:20px;">Id</th>
            <th style="width:200px;">Nombre</th>
            <th style="width:400px;">Direccion</th>
            <th style="width:60px;">Telefono</th>
        </tr>
    </thead>
';
$pdf->WriteHTML($def_thead);

foreach ($soli as $key => $value) {
  $linea= '<tr>
           <td>'.$value->id_proveedor.'</td>
           <td>'.$value->nombre_prov.' '.$value->apellido_prov.'</td>
           <td>'.$value->direccion.'</td>
           <td>'.$value->telefono.'</td>
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