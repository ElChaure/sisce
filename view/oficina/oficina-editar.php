<?php
   include ("include/funciones.php");
   require_once 'model/estado.php';
   require_once 'model/municipio.php';
   require_once 'model/parroquia.php';
   $est = new Estado();
   $mun = new Municipio();
   $par = new Parroquia();
   $id_estado=0;
   $id_municipio=0;
?>

<h1 class="page-header">
    <?php echo $ofi->id_oficina != null ? $ofi->id_oficina : 'Nuevo Registro'; ?>
</h1>

<ol class="breadcrumb">
  <li><a href="?c=Oficina">Oficinas</a></li>
  <li class="active"><?php echo $ofi->id_oficina != null ? $ofi->id_oficina : 'Nuevo Registro'; ?></li>
</ol>

<form id="frm-alumno" action="?c=Oficina&a=Guardar" method="post" enctype="multipart/form-data">
    <input type="hidden" name="id_oficina" value="<?php echo $ofi->id_oficina; ?>">
    
    <div class="form-group">
        <label>Nombre de la Oficina</label>
        <input type="text" name="nombre_oficina" value="<?php echo $ofi->nombre_oficina; ?>" class="form-control" placeholder="Ingrese Nombre de Oficina"  maxlength="250" required>
    </div>
    
    <div class="form-group">
        <label>Direccion</label>
        <input type="textarea" name="direccion" value="<?php echo $ofi->direccion; ?>" class="form-control" placeholder="Ingrese Direccion" required>
    </div>
    
    <div class="form-group">
        <label>Telefono</label>
        <input type="text" name="telefono" value="<?php echo $ofi->telefono; ?>" class="form-control" placeholder="Ingrese Telefono" maxlength="12">
    </div>
    
    <!--div class="form-group">
        <label>Estado</label>
        <input type="text" name="id_estado" value="<?php echo $ofi->id_parroquia; ?>" class="form-control" placeholder="Ingrese Parroquia" data-validacion-tipo="requerido|min:10" />
    </div>
    <div class="form-group">
        <label>Municipio</label>
        <input type="text" name="id_municipio" value="<?php echo $ofi->id_parroquia; ?>" class="form-control" placeholder="Ingrese Parroquia" data-validacion-tipo="requerido|min:10" />
    </div-->

    <!--div class="form-group">
        <label>Parroquia</label>

       <select id="id_parroquia" name="id_parroquia" style="width:200px;" title="Ingrese Parroquia.">
           <option value="1">< Seleccione ></option>
           <?php $l=make_combo($par,"id_parroquia","nombre_parroquia","",0);?>
       </select>

    <div-->

    
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

$('.input-float').inputNumberFormat();
$('.input-integer').inputNumberFormat({ 'decimal': 0 });    
</script>