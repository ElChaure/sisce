<h1 class="page-header">
    <?php echo $urole->id != null ? $urole->id : 'Nuevo Registro'; ?>
</h1>

<ol class="breadcrumb">
  <li><a href="?c=User_role">Asignacion de Rol a Usuario</a></li>
  <li class="active"><?php echo $urole->id != null ? $urole->id : 'Nuevo Registro'; ?></li>
</ol>

<form id="frm-alumno" action="?c=User_role&a=Guardar" method="post" enctype="multipart/form-data">
    <input type="hidden" name="id" value="<?php echo $urole->id; ?>" />
    
    <div class="form-group">
        <label>Usuario</label>
        <input type="text" name="user_id" value="<?php echo $urole->user_id; ?>" class="form-control" placeholder="Ingrese Usuario" data-validacion-tipo="requerido|min:3" />
    </div>
    
    <div class="form-group">
        <label>Rol Asignado</label>
        <input type="text" name="role_id" value="<?php echo $urole->role_id; ?>" class="form-control" placeholder="Ingrese Rol Asignado" data-validacion-tipo="requerido|min:10" />
    </div>
    
    
    <hr />
    
    <div class="text-right">
        <button class="btn btn-success">Guardar</button>
    </div>
</form>

<script>
    $(document).ready(function(){
        $("#frm-usuario").submit(function(){
            return $(this).validate();
        });
    })
</script>