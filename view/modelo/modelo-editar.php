<h1 class="page-header">
    <?php echo $mod->id_modelo != null ? $mod->id_modelo : 'Nuevo Registro'; ?>
</h1>

<ol class="breadcrumb">
  <li><a href="?c=Modelo">Modelos</a></li>
  <li class="active"><?php echo $mod->id_modelo != null ? $mod->id_modelo : 'Nuevo Registro'; ?></li>
</ol>

<form id="frm-alumno" action="?c=Modelo&a=Guardar" method="post" enctype="multipart/form-data">
    <input type="hidden" name="id_modelo" value="<?php echo $mod->id_modelo; ?>" />
    
    <div class="form-group">
        <label>Equipo</label>
        <input type="text" name="id_equipo" value="<?php echo $mod->id_equipo; ?>" class="form-control" placeholder="Ingrese Equipo" data-validacion-tipo="requerido|min:3" />
    </div>
    
    <div class="form-group">
        <label>Marca</label>
        <input type="text" name="id_marca" value="<?php echo $mod->id_marca; ?>" class="form-control" placeholder="Ingrese Marca" data-validacion-tipo="requerido|min:10" />
    </div>
    
    <div class="form-group">
        <label>Descripcion</label>
        <input type="text" name="descripcion" value="<?php echo $mod->descripcion; ?>" class="form-control" placeholder="Ingrese Descripcion" data-validacion-tipo="requerido|min:10" />
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