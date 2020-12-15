<h1 class="page-header">
    <?php echo $ord->id_orden_salida != null ? $ord->id_orden_salida : 'Nuevo Registro'; ?>
</h1>

<ol class="breadcrumb">
  <li><a href="?c=Orden_salida">Ordenes de Salida</a></li>
  <li class="active"><?php echo $ord->id_orden_salida != null ? $ord->id_orden_salida : 'Nuevo Registro'; ?></li>
</ol>

<form id="frm-alumno" action="?c=Orden_salida&a=Guardar" method="post" enctype="multipart/form-data">
    <input type="hidden" name="id_orden_salida" value="<?php echo $ord->id_orden_salida; ?>" />
    
    <div class="form-group">
        <label>Numero de Orden de Salida</label>
        <input type="text" name="num_orden" value="<?php echo $ord->num_orden; ?>" class="form-control" placeholder="Ingrese Numero de Orden de Salida" data-validacion-tipo="requerido|min:3" />
    </div>
    
    <div class="form-group">
        <label>Solicitud</label>
        <input type="text" name="id_solicitud" value="<?php echo $ord->id_solicitud; ?>" class="form-control" placeholder="Ingrese Solicitud" data-validacion-tipo="requerido|min:10" />
    </div>
    
    <div class="form-group">
        <label>Observaciones</label>
        <input type="text" name="observacion" value="<?php echo $ord->observacion; ?>" class="form-control" placeholder="Ingrese Observaciones" data-validacion-tipo="requerido|min:10" />
    </div>
    
    <div class="form-group">
        <label>Empleado</label>
        <input type="text" name="id_emp" value="<?php echo $ord->id_emp; ?>" class="form-control" placeholder="Ingrese Empleado" data-validacion-tipo="requerido|min:10" />
    </div>

    <div class="form-group">
        <label>Funcionario</label>
        <input type="text" name="id_funcionario" value="<?php echo $ord->id_funcionario; ?>" class="form-control" placeholder="Ingrese Funcionario" data-validacion-tipo="requerido|min:10" />
    </div>

    <div class="form-group">
        <label>Equipo</label>
        <input type="text" name="id_equipo" value="<?php echo $ord->id_equipo; ?>" class="form-control" placeholder="Ingrese Equipo" data-validacion-tipo="requerido|min:10" />
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