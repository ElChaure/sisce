<h1 class="page-header">
    <?php echo $alm->id_almacen != null ? $alm->id_almacen : 'Nuevo Registro'; ?>
</h1>

<ol class="breadcrumb">
  <li><a href="?c=Almacen">Almacenes</a></li>
  <li class="active"><?php echo $alm->id_almacen != null ? $alm->id_almacen : 'Nuevo Registro'; ?></li>
</ol>

<form id="frm-alumno" action="?c=Almacen&a=Guardar" method="post" enctype="multipart/form-data">
    <input type="hidden" name="id_almacen" value="<?php echo $alm->id_almacen; ?>" />
    
    <div class="form-group">
        <label>Equipo</label>
        <input type="text" name="id_equipo" value="<?php echo $alm->id_equipo; ?>" class="form-control" placeholder="Ingrese Equipo" data-validacion-tipo="requerido|min:3" />
    </div>
    
    <div class="form-group">
        <label>Fecha de Entrada</label>
        <input type="text" name="fecha_entrada" value="<?php echo $alm->fecha_entrada; ?>" class="form-control" placeholder="Ingrese Fecha de Entrada" data-validacion-tipo="requerido|min:10" />
    </div>
    
    <div class="form-group">
        <label>Fecha de Despacho</label>
        <input type="text" name="fecha_despacho" value="<?php echo $alm->fecha_despacho; ?>" class="form-control" placeholder="Ingrese Fecha de Despacho" data-validacion-tipo="requerido|min:10" />
    </div>
    
    <div class="form-group">
        <label>Telefono</label>
        <input type="text" name="telefono" value="<?php echo $alm->telefono; ?>" class="form-control" placeholder="Ingrese Telefono" data-validacion-tipo="requerido|min:10" />
    </div>

    <div class="form-group">
        <label>Stock</label>
        <input type="text" name="stock" value="<?php echo $alm->stock; ?>" class="form-control" placeholder="Ingrese Stock" data-validacion-tipo="requerido|min:10" />
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