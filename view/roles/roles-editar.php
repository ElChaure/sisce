<h1 class="page-header">
    <?php echo $rol->role_id != null ? $rol->role_id : 'Nuevo Registro'; ?>
</h1>

<ol class="breadcrumb">
  <li><a href="?c=Roles">Roles</a></li>
  <li class="active"><?php echo $rol->role_id != null ? $rol->role_id : 'Nuevo Registro'; ?></li>
</ol>

<form id="frm-alumno" action="?c=Roles&a=Guardar" method="post" enctype="multipart/form-data">
    <input type="hidden" name="role_id" value="<?php echo $rol->role_id; ?>" />
    
    <div class="form-group">
        <label>Nombre del Rol</label>
        <input type="text" name="role_name" value="<?php echo $rol->role_name; ?>" class="form-control" placeholder="Nombre del Rol" data-validacion-tipo="requerido|min:3" />
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