<h1 class="page-header">
    <?php echo $res->id_reserva != null ? $res->id_reserva : 'Nuevo Registro'; ?>
</h1>

<ol class="breadcrumb">
  <li><a href="?c=Reserva">Reservas</a></li>
  <li class="active"><?php echo $res->id_reserva != null ? $res->id_reserva : 'Nuevo Registro'; ?></li>
</ol>

<form id="frm-alumno" action="?c=Reserva&a=Guardar" method="post" enctype="multipart/form-data">
    <input type="hidden" name="id_reserva" value="<?php echo $res->id_reserva; ?>" />
    

    
    <div class="form-group">
        <label>Solicitud</label>
        <input type="text" name="id_solicitud" value="<?php echo $res->id_solicitud; ?>" class="form-control" placeholder="Ingrese Solicitud" data-validacion-tipo="requerido|min:10" />
    </div>
    
    <div class="form-group">
        <label>Fecha de Reserva</label>
        <input type="text" name="fecha_reserva" value="<?php echo $res->fecha_reserva; ?>" class="form-control" placeholder="Ingrese Fecha de Reserva" data-validacion-tipo="requerido|min:10" />
    </div>
    
    <div class="form-group">
        <label>Observaciones</label>
        <input type="text" name="observacion" value="<?php echo $res->observacion; ?>" class="form-control" placeholder="Ingrese Observaciones" data-validacion-tipo="requerido|min:10" />
    </div>

    <div class="form-group">
        <label>Equipo</label>
        <input type="text" name="id_equipo" value="<?php echo $res->id_equipo; ?>" class="form-control" placeholder="Ingrese Equipo" data-validacion-tipo="requerido|min:3" />
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