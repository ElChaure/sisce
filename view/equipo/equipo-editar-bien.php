<?php
   include ("include/funciones.php");
   require_once 'model/estatus_equipo.php';
   require_once 'model/ubicacion.php';
   require_once 'model/articulo.php';
   require_once 'model/proveedor.php';
   require_once 'model/marca.php';
   $esteq = new Estatus_equipo();
   $ubica = new Ubicacion();
   $artic = new Articulo();
   $prove = new Proveedor();
   $marca = new Marca();

   $desc_estatus = $esteq->Obtener($equ->id_estatus);
   $desc_ubicacion = $ubica->Obtener($equ->id_ubicacion);
   $desc_articulo = $artic->Obtener($equ->id_articulo);
   $desc_proveedor = $prove->Obtener_alfa($equ->id_proveedor);
   $desc_marca = $marca->Obtener($equ->id_marca);
?>
<h1 class="page-header">
    <?php echo $equ->id_equipo != null ? $equ->id_equipo : 'Nuevo Registro'; ?>
</h1>

<ol class="breadcrumb">
  <li><a href="?c=Equipo">Equipos</a></li>
  <li class="active"><?php echo $equ->id_equipo; ?></li>
</ol>

<form id="frm-alumno" action="?c=Equipo&a=Guardarbn" method="post" enctype="multipart/form-data">
    <input type="hidden" name="id_equipo" value="<?php echo $equ->id_equipo; ?>" >
    <div class="form-group">
        <label>Codigo Equipo</label>
        <input type="text" name="cod_equipo" value="<?php echo $equ->cod_equipo; ?>" class="form-control" disabled>
    </div>
    <div class="form-group">
        <label>Serial Equipo</label>
        <input type="text" name="serial" value="<?php echo $equ->serial; ?>" class="form-control" disabled>
    </div>

   <div class="form-group">
        <label>Estatus Equipo</label>
        <?php echo $desc_estatus->estatus; ?>
   </div>
           
   <div class="form-group">
        <label>Ubicacion Equipo</label>
        <?php echo $desc_ubicacion->ubicacion; ?>
   </div>      
   
    <div class="form-group">
        <label>Tipo de Equipo o Articulo</label>
        <?php echo $desc_articulo->articulo; ?>
    </div> 

    <div class="form-group">
        <label>Marca del Equipo o Articulo</label>
        <?php echo $desc_marca->descripcion; ?>
    </div> 
    
    
    <div class="form-group">
        <label>Numero de Bien Nacional del Equipo</label>
        <input type="text" name="num_bien_nac" value="<?php echo $equ->num_bien_nac; ?>" class="form-control" maxlength="15" required>
    </div> 
   

    <div class="form-group">
        <label>Descripcion del Equipo</label>
        <input type="text" name="descripcion" value="<?php echo $equ->descripcion; ?>" class="form-control" disabled>
    </div>     
    <div class="form-group">
        <label>Numero de Factura del Equipo</label>
        <input type="text" name="num_factura" value="<?php echo $equ->num_factura; ?>" class="form-control" disabled>
    </div>     
    <div class="form-group">
        <label>Fecha de Factura del Equipo</label>
        <?php echo date("d-m-Y", strtotime($equ->fecha_factura)); ?>
    </div>
    

    <div class="form-group">
        <label>Proveedor del Equipo</label>
        <?php echo $desc_proveedor->nombres; ?>
    </div> 


   <div class="form-group">
        <label>Valor del Equipo</label>
        <input type="text" name="valor" value="<?php echo $equ->valor; ?>" class="form-control" disabled>
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
    $(function(){
    $("#fecha_factura").datepicker({
        dateFormat: "yy-mm-dd",
        changeMonth: true,
        changeYear: true,
        maxDate: '0',
        dayNamesMin: ['Do', 'Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa'],
        monthNames: ['Enero','Febrero','Martes','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'] 
    });
});


</script>
