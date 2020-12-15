<ol class="breadcrumb">
  <a class="btn btn-warning" href="?c=site&a=index">Inicio</a>
</ol>
<h1 class="page-header">Reservas</h1>

<div class="well well-sm text-right">
    <a class="btn btn-primary" href="?c=Reserva&a=Crud">Nueva Reserva</a>
</div>

<table class="table table-striped">
    <thead>
        <tr>
            <th>Id</th>
            <th>Solicitud</th>
            <th>Fecha Res</th>
            <th>Observaciones</th>
            <th>Equipo</th>
            <th></th>
            <th></th>
        </tr>
    </thead>
    <tbody>
    <?php foreach($this->model->Listar() as $r): ?>
        <tr>
            <td><?php echo $r->id_reserva; ?></td>
            <td><?php echo $r->id_solicitud; ?></td>
            <td><?php echo $r->fecha_reserva; ?></td>
            <td><?php echo $r->observacion; ?></td>
            <td><?php echo $r->id_equipo; ?></td>
            <td>
                <a  class="btn btn-info" href="?c=Reserva&a=Crud&id_reserva=<?php echo $r->id_reserva; ?>">Editar</a>
            </td>
            <td>
                <a  class="btn btn-warning" onclick="javascript:return confirm('¿Seguro de eliminar este registro?');" href="?c=Reserva&a=Eliminar&id_reserva=<?php echo $r->id_reserva; ?>">Eliminar</a>
            </td>
        </tr>
    <?php endforeach; ?>
    </tbody>
</table> 
