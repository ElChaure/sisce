<h1 class="page-header">
    <?php echo $dep->id_departamento != null ? $dep->id_departamento : 'Nuevo Registro'; ?>
</h1>

<ol class="breadcrumb">
  <li><a href="?c=Departamento">Departamentos</a></li>
  <li class="active"><?php echo $dep->id_departamento != null ? $dep->id_departamento : 'Nuevo Registro'; ?></li>
</ol>

<form id="frm-alumno" action="?c=Departamento&a=Guardar" method="post" enctype="multipart/form-data">
    <input type="hidden" name="id_departamento" value="<?php echo $dep->id_departamento; ?>" />
    
    <div class="form-group">
        <label>Departamento</label>
        <input type="text" name="nombre" value="<?php echo $dep->nombre; ?>" class="form-control" placeholder="Ingrese Nombre del Departamento"  maxlength="100"  required>
    </div>
    
    <div class="form-group">
        <label>Telefono del Departamento</label>
        <input class="input-integer form-control input-lg" type="text" name="telf_departamento" value="<?php echo $dep->telf_departamento; ?>" class="form-control" placeholder="Ingrese Telefono del Departamento" data-validacion-tipo="requerido|min:10" />
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