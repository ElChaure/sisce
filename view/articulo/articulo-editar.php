<h1 class="page-header">
    <?php echo $art->id_articulo != null ? $art->id_articulo : 'Nuevo Registro'; ?>
</h1>

<ol class="breadcrumb">
  <li><a href="?c=Articulo">Articulos</a></li>
  <li class="active"><?php echo $art->id_articulo != null ? $art->id_articulo : 'Nuevo Registro'; ?></li>
</ol>

<form id="frm-alumno" action="?c=Articulo&a=Guardar" method="post" enctype="multipart/form-data">
    <input type="hidden" name="id_articulo" value="<?php echo $art->id_articulo; ?>" />
    
    <div class="form-group">
        <label>Articulo</label>
        <input type="text" name="articulo" value="<?php echo $art->articulo; ?>" class="form-control" placeholder="Ingrese Nombre del Articulo" maxlength="150" />
    </div>
    
    <div class="form-group">
        <label>Codigo SNC del Articulo</label>
        <input class="input-integer form-control input-lg" type="text" name="codigo_snc" value="<?php echo $art->codigo_snc; ?>" class="form-control" placeholder="Ingrese Codigo SNC del Articulo" maxlength="20"  />
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
    $('.input-integer').inputNumberFormat({ 'decimal': 0 });
</script>