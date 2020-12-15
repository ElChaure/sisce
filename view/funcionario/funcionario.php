
<ol class="breadcrumb">
  <a class="btn btn-warning" href="?c=site&a=index">Inicio</a>
</ol>
<h1 class="page-header">Funcionarios</h1>

<div class="well well-sm text-right">
    <a class="btn btn-primary" href="?c=Funcionario&a=Crud">Nuevo Funcionario</a>
</div>

<table class="table table-striped">
    <thead>
        <tr>
            <th>Id</th>
            <th>Cedula</th>
            <th>Nombres</th>
            <th>Apellidos</th>
            <th>Oficina</th>
            <th>Telefono</th>
            <th>Email</th>
            <th>Cargo</th>
            <th></th>
            <th></th>
        </tr>
    </thead>
    <tbody>
    <?php foreach($this->model->Listar() as $r): ?>
        <tr>
            <td><?php echo $r->id_funcionario; ?></td>
            <td><?php echo $r->cedula; ?></td>
            <td><?php echo $r->nombre; ?></td>
            <td><?php echo $r->apellido; ?></td>
            <td><?php echo $r->id_oficina; ?></td>
            <td><?php echo $r->telefono; ?></td>
            <td><?php echo $r->email; ?></td>
            <td><?php echo $r->cargo; ?></td>
            <td>
                <a href="?c=Funcionario&a=Crud&id=<?php echo $r->id; ?>">Editar</a>
            </td>
            <td>
                <a  class="btn btn-warning" onclick="javascript:return confirm('¿Seguro de eliminar este registro?');" href="?c=Funcionario&a=Eliminar&id=<?php echo $r->id; ?>">Eliminar</a>
            </td>
        </tr>
    <?php endforeach; ?>
    </tbody>
</table> 
