<h1 class="page-header">
    <?php echo $mar->id_marca != null ? $mar->id_marca : 'Nuevo Registro'; ?>
</h1>

<ol class="breadcrumb">
  <li><a href="?c=Marca">Marcas</a></li>
  <li class="active"><?php echo $mar->id_marca != null ? $mar->id_marca : 'Nuevo Registro'; ?></li>
</ol>

<form id="frm-alumno" action="?c=Marca&a=Guardar" method="post" enctype="multipart/form-data">
    <input type="hidden" name="id_marca" value="<?php echo $mar->id_marca; ?>">
    
    <div class="form-group">
        <label>Nombre de la Marca</label>
        <input type="text" name="descripcion" value="<?php echo $mar->descripcion; ?>" class="form-control" placeholder="Ingrese la Descripcion de la Marca" maxlength="30" required>
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