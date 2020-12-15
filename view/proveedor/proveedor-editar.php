<h1 class="page-header">
    <?php echo $pro->id_proveedor != null ? $pro->id_proveedor : 'Nuevo Registro'; ?>
</h1>

<ol class="breadcrumb">
  <li><a href="?c=Proveedor">Proveedores</a></li>
  <li class="active"><?php echo $pro->id_proveedor != null ? $pro->id_proveedor : 'Nuevo Registro'; ?></li>
</ol>

<form id="frm-alumno" action="?c=Proveedor&a=Guardar" method="post" enctype="multipart/form-data">
    <input type="hidden" name="id_proveedor" value="<?php echo $pro->id_proveedor; ?>">
    
    <div class="form-group">
        <label>Nombres Proveedor</label>
        <input type="text" name="nombre_prov" value="<?php echo $pro->nombre_prov; ?>" class="form-control" placeholder="Ingrese Nombres Proveedor"  maxlength="30" required>
    </div>
    
    <div class="form-group">
        <label>Apellido Proveedor</label>
        <input type="text" name="apellido_prov" value="<?php echo $pro->apellido_prov; ?>" class="form-control" placeholder="Ingrese Apellido Proveedor"  maxlength="30" required>
    </div>
    
    <div class="form-group">
        <label>Direccion</label>
        <input type="text" name="direccion" value="<?php echo $pro->direccion; ?>" class="form-control" placeholder="Ingrese Direccion"  maxlength="100" required>
    </div>
    
    <div class="form-group">
        <label>Telefono</label>
        <input class="input-integer form-control input-lg" type="text" name="telefono" value="<?php echo $pro->telefono; ?>" class="form-control" placeholder="Ingrese Telefono" required>
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
$('.input-float').inputNumberFormat();
$('.input-integer').inputNumberFormat({ 'decimal': 0 });    
</script>