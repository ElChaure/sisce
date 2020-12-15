
<ol class="breadcrumb">
  <a class="btn btn-warning" href="?c=site&a=index">Inicio</a>
</ol>
<h1 class="page-header">Ordenes de Salida</h1>

<div class="well well-sm text-right">
    <a class="btn btn-primary" href="?c=Orden_salida&a=Crud">Nuevo Orden_salida</a>
</div>

<table class="table table-striped">
    <thead>
        <tr>
            <th>Id</th>
            <th>Nro Orden</th>
            <th>Solicitud</th>
            <th>Observaciones</th>
            <th>Empleado</th>
            <th>Funcionario</th>
            <th>Equipo</th>
            <th></th>
            <th></th>
        </tr>
    </thead>
    <tbody>
    <?php foreach($this->model->Listar() as $r): ?>
        <tr>
            <td><?php echo $r->id_orden; ?></td>
            <td><?php echo $r->num_orden; ?></td>
            <td><?php echo $r->id_solicitud; ?></td>
            <td><?php echo $r->observacion; ?></td>
            <td><?php echo $r->id_emp; ?></td>
            <td><?php echo $r->id_funcionario; ?></td>
            <td><?php echo $r->id_equipo; ?></td>
            <td>
                <a  class="btn btn-info" href="?c=Orden_salida&a=Crud&id=<?php echo $r->id; ?>">Editar</a>
            </td>
            <td>
                <a  class="btn btn-warning" onclick="javascript:return confirm('¿Seguro de eliminar este registro?');" href="?c=Orden_salida&a=Eliminar&id=<?php echo $r->id; ?>">Eliminar</a>
            </td>
        </tr>
    <?php endforeach; ?>
    </tbody>
</table> 
