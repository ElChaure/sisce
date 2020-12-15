<script type="text/javascript">
function compruebaFactura(){
  nfact=$("#num_factura").val();
  id_equipo=$("#id_equipo").val();
  var n = id_equipo.length; 
  console.log(id_equipo);
  if(nfact < 1 || nfact > 9999999){
      $("#descripcion").focus();
      alert("Numero de Factura Invalido");
      if(n==15){
         $("#num_factura").val("");
       }  
      $("#num_factura").focus();
  }
} 

function compruebaCodigo(){
  codi=$("#cod_equipo").val();
  id_equipo=$("#id_equipo").val();
  var n = id_equipo.length; 
  id_equipo=$("#id_equipo").val();
  if(codi < 1 || codi > 9999999){
      $("#descripcion").focus();
      alert("Codigo Invalido");
      if(n==15){
         $("#cod_equipo").val("");
       }  
      $("#cod_equipo").focus();
  }
} 

function compruebaSerial() {
    $.ajax({
    type: "POST",  
    url: "?c=Equipo&a=valida_serial&serial="+$("#serial").val(),
    data:{
        "serial"  : $("#serial").val(),
    },
    success:function(datos){
      //var obj = JSON.parse(datos); 
      id_equipo=$("#id_equipo").val();
      console.log(datos);
      var n = datos.length; 
      var m = id_equipo.length; 
      console.log(n);
      
      if(n > 15){
        alert("Serial de equipo ya se encuentra registrado!!!");
        if(m==15){
          $("#serial").val("");
        }  
        $("#serial").focus();
      }
      // alert(datos);  
    },
    error:function (){}
    });
  }
</script>

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

   //echo $artic->Listar_json();
   
?>
<h1 class="page-header">
    <?php echo $equ->id_equipo != null ? $equ->id_equipo : 'Nuevo Registro'; ?>
     <?php 
     
     if ($equ->id_equipo != null){
         $o_art = $artic->Obtener($equ->id_articulo);
         $o_mar = $marca->Obtener($equ->id_marca);
         $o_pro = $prove->Obtener($equ->id_proveedor);
         
         $desc_art  = $o_art->articulo;
         $desc_mar  = $o_mar->descripcion;   
         $desc_pro  = $o_pro->nombre_prov." ".$o_pro->apellido_prov;
  }
  ?>
</h1>

<ol class="breadcrumb">
  <li><a href="?c=Equipo">Equipos</a></li>
  <li class="active"><?php echo $equ->id_equipo != null ? $equ->id_equipo : 'Nuevo Registro'; ?></li>
</ol>

<form id="frm-alumno" action="?c=Equipo&a=Guardar" method="post" enctype="multipart/form-data">
    <input type="hidden" id="id_equipo" name="id_equipo" value="<?php echo $equ->id_equipo; ?>" />
    <div class="form-group">
        <label>Codigo Equipo</label>
        <input class="input-integer form-control input-lg" type="text" placeholder="Ingrese Codigo del Equipo" name="cod_equipo" id="cod_equipo" value="<?php echo $equ->cod_equipo; ?>" onBlur="compruebaCodigo()" required>
    </div>

    <div class="form-group">
        <label>Serial Equipo</label>
        <input type="text" name="serial" id="serial" value="<?php echo $equ->serial; ?>" class="form-control" placeholder="Ingrese Serial del Equipo" maxlength="20" onBlur="compruebaSerial()" required>
    </div>

   <!--div class="form-group">
        <label>Estatus Equipo</label>
        <select id="id_estatus" name="id_estatus" class="form-control"></select>
   </div-->
           
   <!--div class="form-group">
        <label>Ubicacion Equipo</label>
        <select id="id_ubicacion" name="id_ubicacion" class="form-control"></select>
   </div-->      
   
    <div class="form-group">
        <label>Tipo de Equipo o Articulo</label>
        <select id="id_articulo" name="id_articulo" class="form-control" required>
          <?php if ($equ->id_articulo != null) {
            echo '<option selected="selected" value="'.$equ->id_articulo.'">'.
            $desc_art.'</option>';
          } ?>
        </select>
    </div> 

    <div class="form-group">
        <label>Marca del Equipo o Articulo</label>
        <select id="id_marca" name="id_marca" class="form-control" required>
          <?php if ($equ->id_marca != null) {
            echo '<option selected="selected" value="'.$equ->id_marca.'">'.
            $desc_mar.'</option>';
          } ?>          
        </select>
    </div> 

    
    <?php if($equ->id_equipo != null){; ?>
    <div class="form-group">
        <label>Numero de Bien Nacional del Equipo</label>
        <input type="text" name="num_bien_nac" value="<?php echo $equ->num_bien_nac; ?>" class="form-control" disabled>
    </div> 
    <?php }; ?>

    <div class="form-group">
        <label>Numero de Factura del Equipo</label>
        <input class="input-integer form-control input-lg" type="text" id="num_factura" name="num_factura" value="<?php echo $equ->num_factura; ?>" class="form-control" placeholder="Ingrese Numero de Factura del Equipo" onBlur="compruebaFactura()" required>
    </div>   

    <div class="form-group">
        <label>Descripcion del Equipo</label>
        <input type="text" id="descripcion" name="descripcion" value="<?php echo $equ->descripcion; ?>" class="form-control" placeholder="Ingrese Descripcion del Equipo" maxlength="100" required>
    </div>     
      
    <div class="form-group">
        <label>Fecha de Factura del Equipo</label>
        <input type="text" id="fecha_factura" name="fecha_factura" value="<?php echo $equ->fecha_factura; ?>" class="form-control" placeholder="Ingrese Fecha de Factura del Equipo" required>
    </div>
    

    <div class="form-group">
        <label>Proveedor del Equipo</label>
        <select id="id_proveedor" name="id_proveedor" class="form-control" required>
          <?php if ($equ->id_proveedor != null) {
            echo '<option selected="selected" value="'.$equ->id_proveedor.'">'.
            $desc_pro.'</option>';
          } ?>                    
        </select>
    </div> 


   <div class="form-group">
        <label>Valor del Equipo</label>
        <input class="input-float form-control input-lg" type="text" name="valor" value="<?php echo $equ->valor; ?>" required>
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
        dateFormat: "dd-mm-yy",
        changeMonth: true,
        changeYear: true,
        maxDate: '0',
        dayNamesMin: ['Do', 'Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa'],
        monthNames: ['Enero','Febrero','Martes','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'] 
    });
});


$(function() { 

    var articArray = <?php echo $artic->Listar_json();?>;
    var esteqArray = <?php echo $esteq->Listar_json();?>;
    var ubicaArray = <?php echo $ubica->Listar_json();?>;
    var proveArray = <?php echo $prove->Listar_json();?>;
    var marcaArray = <?php echo $marca->Listar_json();?>;


    $("#id_articulo").select2({
      theme: "bootstrap",
      debug: true,
      language: "es",
      //minimumResultsForSearch: Infinity,
      //placeholder: 'Seleccione un Articulo', 
      placeholder: {
         id: '-1', // the value of the option
         text: 'Seleccione un Articulo'
      },
      allowClear: true,
      dataType: 'json',
      data: articArray
       });

    $("#id_ubicacion").select2({
      theme: "bootstrap",
      debug: true,
      language: "es",
      //minimumResultsForSearch: Infinity,
      
      placeholder: {
         id: '-1', // the value of the option
         text: 'Seleccione una Ubicacion'
      },
      dataType: 'json',
      data: ubicaArray
       });

    $("#id_estatus").select2({
      theme: "bootstrap",
      debug: true,
      language: "es",
      //minimumResultsForSearch: Infinity,
      //placeholder: 'Seleccione un Estatus de Equipo', 
      placeholder: {
         id: '-1', // the value of the option
         text: 'Seleccione un Estatus de Equipo'
      },
      dataType: 'json',
      data: esteqArray
       });

      $("#id_proveedor").select2({
      theme: "bootstrap",
      debug: true,
      language: "es",
      allowClear: true,
      //minimumResultsForSearch: Infinity,
      
      placeholder: {
         id: '-1', // the value of the option
         text: 'Seleccione un Proveedor'
      },
      dataType: 'json',
      data: proveArray
       });

      $("#id_marca").select2({
      theme: "bootstrap",
      debug: true,
      language: "es",
      allowClear: true,
      //minimumResultsForSearch: Infinity,
      
      placeholder: {
         id: '-1', // the value of the option
         text: 'Seleccione una Marca'
      },
      dataType: 'json',
      data: marcaArray
       });

});


$("#id_articulo").on("click", function () {
    $("#id_articulo").select2("open");
});


$('.input-float').inputNumberFormat();
$('.input-integer').inputNumberFormat({ 'decimal': 0 });


$('#id_articulo').select2({
  matcher: function(params, data) {
    // If there are no search terms, return all of the data
    if ($.trim(params.term) === "") {
      return data;
    }

    // Do not display the item if there is no 'text' property
    if (typeof data.text === "undefined") {
      return null;
    }

    console.log(params.term);
    console.log(data.id);
    console.log(data.text);

    // `params.term` is the user's search term
    // `data.id` should be checked against
    // `data.text` should be checked against
    var q = params.term.toLowerCase();
    if (
      data.text.toLowerCase().indexOf(q) > -1 ||
      data.id.toLowerCase().indexOf(q) > -1
    ) {
      return $.extend({}, data, true);
    }

    // Return `null` if the term should not be displayed
    return null;
  }
});



</script>
