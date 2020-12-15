
<ol class="breadcrumb">
  <li><a href="?c=Site">Inicio</a></li>
  
</ol>
<h1 class="page-header">Roles Asignados a Usuarios</h1>

<div class="well well-sm text-right">
    <a class="btn btn-primary" href="?c=User_role&a=Crud">Nuevo Rol a Usuario</a>
</div>

<table class="table table-striped">
    <thead>
        <tr>
            <th style="width:180px;">Id</th>
            <th>Usuario</th>
            <th>Rol Asignado</th>
            <th style="width:60px;"></th>
            <th style="width:60px;"></th>
        </tr>
    </thead>
    <tbody>
    <?php foreach($this->model->Listar() as $r): ?>
        <tr>
            <td><?php echo $r->id; ?></td>
            <td><?php echo $r->user_id; ?></td>
            <td><?php echo $r->role_id; ?></td>
            <td>
                <a  class="btn btn-info" href="?c=User_role&a=Crud&id=<?php echo $r->id; ?>">Editar</a>
            </td>
            <td>
                <a  class="btn btn-warning" onclick="javascript:return confirm('¿Seguro de eliminar este registro?');" href="?c=User_role&a=Eliminar&id=<?php echo $r->id; ?>">Eliminar</a>
            </td>
        </tr>
    <?php endforeach; ?>
    </tbody>
</table> 
