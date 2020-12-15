
<ol class="breadcrumb">
  <a class="btn btn-warning" href="?c=site&a=index">Inicio</a>
</ol>
<h1 class="page-header">Almacenes</h1>

<div class="well well-sm text-right">
    <a class="btn btn-primary" href="?c=Almacen&a=Crud">Nuevo Almacen</a>
</div>

<table class="table table-striped">
    <thead>
        <tr>
            <th style="width:180px;">Id</th>
            <th>Equipo</th>
            <th>Fecha Ent</th>
            <th style="width:120px;">Fecha Des</th>
            <th style="width:120px;">Telefono</th>
            <th style="width:120px;">Stock</th>
            <th style="width:60px;"></th>
            <th style="width:60px;"></th>
        </tr>
    </thead>
    <tbody>
    <?php foreach($this->model->Listar() as $r): ?>
        <tr>
            <td><?php echo $r->id_almacen; ?></td>
            <td><?php echo $r->id_equipo; ?></td>
            <td><?php echo $r->fecha_entrada; ?></td>
            <td><?php echo $r->fecha_despacho; ?></td>
            <td><?php echo $r->telefono; ?></td>
            <td><?php echo $r->stock; ?></td>
            <td>
                <a href="?c=Almacen&a=Crud&id=<?php echo $r->id; ?>">Editar</a>
            </td>
            <td>
                <a onclick="javascript:return confirm('¿Seguro de eliminar este registro?');" href="?c=Almacen&a=Eliminar&id=<?php echo $r->id; ?>">Eliminar</a>
            </td>
        </tr>
    <?php endforeach; ?>
    </tbody>
</table> 
