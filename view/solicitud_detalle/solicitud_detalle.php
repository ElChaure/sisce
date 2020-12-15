<?php
    session_start();
    $retorno=$_SESSION["retorno"];
?> 





<h1 class="page-header">Detalle Solicitud <?php echo $_REQUEST['id_solicitud']; ?></h1>
<a class="btn btn-warning" href="?c=solicitud&a=view">Regresar</a>
<?php
   $id_sol=$_REQUEST['id_solicitud'];
   $id_tip_sol=$_REQUEST['id_tipo_solicitud'];
   /*
   if (isset($_REQUEST['tipo_solicitud'])){
   $tip_sol=$_REQUEST['tipo_solicitud'];

switch ($tip_sol) {
    case "Asignacion":
        $id_tip_sol=1;
        break;
    case "Prestamo Especial":
        $id_tip_sol=2;
        break;
    case "Reparacion":
        $id_tip_sol=3;
        break;
    default:
        $id_tip_sol=4;
}
}
*/
?>

<!--form method="post" action="index.php?c=solicitud&a=view"-->
<form method="post" action="index.php?c=solicitud&a=asigna_detalle">
<input type="hidden" name="solicitud" action="asigna_detalle" />
<table class="table table-striped" name="lista_detalle_solicitud">
    <thead>
        <tr>
            

            <th>Id</th>
            <th>Equipo</th>
            <th>Codigo</th>
            <th>Serial</th>
            <th>Valor</th>
            <th style="width:60px;"></th>
            <th style="width:60px;"></th>
            <th>Procesar</th>
        </tr>
    </thead>
    <tbody>
    <?php foreach($this->model->Listar() as $r): ?>
        <tr>
     

            <td><?php echo $r->id_solicitud_detalle; ?></td>
            <td><?php echo $r->descripcion; ?></td>
            <td><?php echo $r->cod_equipo; ?></td>
            <td><?php echo $r->serial; ?></td>
            <td><?php echo $r->valor; ?></td>
<?php
            if (!$r->asignado){ ?>
            <td>
                <a  class="btn btn-info" href="?c=Solicitud_detalle&a=Crud&id_solicitud_detalle=<?php echo $r->id_solicitud_detalle; ?>&id_solicitud=<?php echo $r->id_solicitud; ?>">Editar</a>
            </td>
            <td>
                <a  class="btn btn-warning" onclick="javascript:return confirm('¿Seguro de eliminar este registro?');" 
                href="?c=Solicitud_detalle&a=Eliminar&id_solicitud_detalle=<?php echo $r->id_solicitud_detalle; ?>&id_solicitud=<?php echo $r->id_solicitud; ?>&id_equipo=<?php echo $r->id_equipo; ?>">Eliminar</a>
            </td>
            <td>
                <a  class="btn btn-success" onclick="javascript:return confirm('Desea Procesar? Confirme por favor');" href="?c=Solicitud_detalle&a=Asignar&id_solicitud_detalle=<?php echo $r->id_solicitud_detalle; ?>&id_solicitud=<?php echo $r->id_solicitud; ?>&id_equipo=<?php echo $r->id_equipo; ?>&id_tipo_solicitud=<?php echo $r->id_tipo_solicitud; ?>">Procesar</a>
            </td>
<?php }
else
{ ?>
            <td>
                Editar
            </td>
            <td>
                Eliminar
            </td>
            <td>
                Procesado
            </td>
<?php 
}
?>

           

        </tr>
    <?php endforeach; ?>
    </tbody>
</table> 
 
<a class="btn btn-info" href="?c=Solicitud_detalle&a=Crud&id_solicitud=<?php echo $id_sol; ?>">Agregar Detalle</a>
</form>
