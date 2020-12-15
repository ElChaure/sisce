
<ol class="breadcrumb">
  <a class="btn btn-warning" href="?c=site&a=index">Inicio</a>
</ol>
<h1 class="page-header">Modelos</h1>

<div class="well well-sm text-right">
    <a class="btn btn-primary" href="?c=Modelo&a=Crud">Nuevo Modelo</a>
</div>

<table class="table table-striped">
    <thead>
        <tr>
            <th style="width:180px;">Id</th>
            <th>Equipo</th>
            <th>Marca</th>
            <th style="width:120px;">Descripcion</th>
            <th style="width:60px;"></th>
            <th style="width:60px;"></th>
        </tr>
    </thead>
    <tbody>
    <?php foreach($this->model->Listar() as $r): ?>
        <tr>
            <td><?php echo $r->id_modelo; ?></td>
            <td><?php echo $r->id_equipo; ?></td>
            <td><?php echo $r->id_marca; ?></td>
            <td><?php echo $r->descripcion; ?></td>
            <td>
                <a  class="btn btn-info" href="?c=Modelo&a=Crud&id=<?php echo $r->id; ?>">Editar</a>
            </td>
            <td>
                <a  class="btn btn-warning" onclick="javascript:return confirm('¿Seguro de eliminar este registro?');" href="?c=Modelo&a=Eliminar&id=<?php echo $r->id; ?>">Eliminar</a>
            </td>
        </tr>
    <?php endforeach; ?>
    </tbody>
</table> 
