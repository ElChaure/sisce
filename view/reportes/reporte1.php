<?php
$pdf = new \Mpdf\Mpdf(['format' => 'Letter']);

$output = "reporte1";
$titulo = "<br><br><h3><center>Reporte en Construccion</center></h3><br>";
$pdf_ext = ".pdf";
$enc='<table width="100%">
    <tr>
        <td width="33%" style="text-align: left;"><img src=assets/img/mpprijp.png width="150" height="75"></td>
        <td width="33%" align="center"><img src=assets/img/atodavida.jpg width="150" height="75"></td>
        <td width="33%" style="text-align: right;"><img src=assets/img/logo.png width="150" height="75"></td>
    </tr>
</table>';
$pdf->SetHTMLHeader($enc);
$pdf->SetHTMLFooter('<div style="text-align:center;font-size:10px;font-family:opensans;">
Generado a traves del Sistema SICET en Fecha {DATE j-m-Y} por el Usuario '.$_SESSION['usuario_nombre'].'| Fuente: OSTI-2019 |  Pagina: {PAGENO}
</div>');
$pdf->WriteHTML($titulo);
$pdf->Output();
?>
