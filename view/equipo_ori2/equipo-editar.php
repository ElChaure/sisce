<?php
   include ("include/funciones.php");
   require_once 'model/estatus_equipo.php';
   require_once 'model/ubicacion.php';
   require_once 'model/articulo.php';
   $esteq = new Estatus_equipo();
   $ubica = new Ubicacion();
   $artic = new Articulo();
?>
<h1 class="page-header">
    <?php echo $equ->id_equipo != null ? $equ->id_equipo : 'Nuevo Registro'; ?>
</h1>

<ol class="breadcrumb">
  <li><a href="?c=Equipo">Equipos</a></li>
  <li class="active"><?php echo $equ->id_equipo != null ? $equ->id_equipo : 'Nuevo Registro'; ?></li>
</ol>

<form id="frm-alumno" action="?c=Equipo&a=Guardar" method="post" enctype="multipart/form-data">
    <input type="hidden" name="id_equipo" value="<?php echo $equ->id_equipo; ?>" />
    <div class="form-group">
        <label>Codigo Equipo</label>
        <input type="text" name="cod_equipo" value="<?php echo $equ->cod_equipo; ?>" class="form-control" placeholder="Ingrese Codigo del Equipo" data-validacion-tipo="requerido|min:3" />
    </div>
    <div class="form-group">
        <label>Serial Equipo</label>
        <input type="text" name="serial" value="<?php echo $equ->serial; ?>" class="form-control" placeholder="Ingrese Serial del Equipo" data-validacion-tipo="requerido|min:3" />
    </div>
   <div class="form-group">
        <label>Estatus Equipo</label>
        <select id="id_estatus" name="id_estatus" style="width:200px;" title="Ingrese el Estatus del Equipo.">
           <option value="4"><-- Seleccione --></option>
           <?php $l=make_combo($esteq,"id_estatus_eq","estatus","",0);?>
       </select>
   </div>
           
   <div class="form-group">
        <label>Ubicacion Equipo</label>

        
        <select id="id_ubicacion" name="id_ubicacion" style="width:200px;" title="Ingrese Ubicacion del Equipo.">
           <option value="1"><-- Seleccione --></option>
           <?php $l=make_combo($ubica,"id_ubicacion","ubicacion","",0);?>
       </select>


    </div>      

<div class="form-group">
        <label>Tipo de Equipo o Articulo</label>

        
        <select id="id_articulo" name="id_articulo" style="width:200px;" title="Ingrese Tipo de Equipo o Articulo del Equipo.">
           <option value="1"><-- Seleccione --></option>
           <?php $l=make_combo($artic,"id_articulo","articulo","",0);?>
       </select>


    </div> 


    <div class="form-group">
        <label>Numero de Bien Nacional del Equipo</label>
        <input type="text" name="num_bien_nac" value="<?php echo $equ->num_bien_nac; ?>" class="form-control" placeholder="Ingrese Numero de Bien Nacional del Equipo" data-validacion-tipo="requerido|min:3" />
    </div> 
    <div class="form-group">
        <label>Descripcion del Equipo</label>
        <input type="text" name="descripcion" value="<?php echo $equ->descripcion; ?>" class="form-control" placeholder="Ingrese Descripcion del Equipo" data-validacion-tipo="requerido|min:3" />
    </div>     
    <div class="form-group">
        <label>Numero de Factura del Equipo</label>
        <input type="text" name="num_factura" value="<?php echo $equ->num_factura; ?>" class="form-control" placeholder="Ingrese Numero de Factura del Equipo" data-validacion-tipo="requerido|min:3" />
    </div>     
    <div class="form-group">
        <label>Fecha de Factura del Equipo</label>
        <input type="text" id="fecha_factura" name="fecha_factura" value="<?php echo $equ->fecha_factura; ?>" class="form-control" placeholder="Ingrese Fecha de Factura del Equipo" data-validacion-tipo="requerido|min:3" />
    </div>
   <div class="form-group">
        <label>Proveedor del Equipo</label>
        <input type="text" name="id_proveedor" value="<?php echo $equ->id_proveedor; ?>" class="form-control" placeholder="Ingrese Proveedor del Equipo" data-validacion-tipo="requerido|min:3" />
    </div> 
   <div class="form-group">
        <label>Valor del Equipo</label>
        <input type="text" name="valor" value="<?php echo $equ->valor; ?>" class="form-control" placeholder="Ingrese Valor del Equipo" data-validacion-tipo="requerido|min:3" />
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
        dayNamesMin: ['Do', 'Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa'],
        monthNames: ['Enero','Febrero','Martes','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'] 
    });
});
</script>
