<h1 class="page-header">
    <?php echo $perm->perm_id != null ? $perm->perm_id : 'Nuevo Registro'; ?>
</h1>

<ol class="breadcrumb">
  <li><a href="?c=Permissions">Acciones del Sistema</a></li>
  <li class="active"><?php echo $perm->perm_id != null ? $perm->perm_id : 'Nuevo Registro'; ?></li>
</ol>

<form id="frm-alumno" action="?c=Permissions&a=Guardar" method="post" enctype="multipart/form-data">
    <input type="hidden" name="perm_id" value="<?php echo $perm->perm_id; ?>" />
    
    <div class="form-group">
        <label>Descripcion de la Accion del Sistema</label>
        <input type="text" name="perm_desc" value="<?php echo $perm->perm_desc; ?>" class="form-control" placeholder="Ingrese Descripcion de la Accion del Sistema" data-validacion-tipo="requerido|min:3" />
    </div>
    
    <div class="form-group">
        <label>Rol Asignado</label>
        <input type="text" name="accion" value="<?php echo $perm->accion; ?>" class="form-control" placeholder="Ingrese Accion del Controlador" data-validacion-tipo="requerido|min:10" />
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