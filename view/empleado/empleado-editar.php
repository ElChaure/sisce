<?php
  require_once 'model/ubicacion.php';
  require_once 'model/oficina.php';
  require_once 'model/departamento.php';
  require_once 'model/usuario.php';
  require_once 'model/estatus_empleado.php';
  require_once 'model/empleado.php';

   $ubica = new Ubicacion();
   $ofic = new Oficina();
   $dept = new Departamento();
   $usu = new Usuario();
   $est = new Estatus_empleado();
   $empexist = new Empleado();
   //echo $empexist->Listar_json2();
   //echo $artic->Listar_json();
?>

<h1 class="page-header">
    <?php echo $emp->id_empleado != null ? $emp->id_empleado : 'Nuevo Registro'; ?>
    <?php 
     
     if ($emp->id_empleado != null){
         $o_ubi = $ubica->Obtener($emp->id_ubicacion);
         $o_ofi = $ofic->Obtener($emp->id_oficina);
         $o_dep = $dept->Obtener($emp->id_departamento);
         $o_usu = $usu->Obtener($emp->id_usuario);
         $o_est = $est->Obtener($emp->id_estatus);
         
         $desc_ubi  = $o_ubi->ubicacion;
         $desc_ofi  = $o_ofi->nombre_oficina."-".$o_ofi->codigo;   
         $desc_dep  = $o_dep->nombre." ".$o_dep->id_departamento;
         $desc_usu  = $o_usu->nombres." ".$o_usu->alias;
         $desc_est  = $o_est->estatus;
  }
  ?>
</h1>

<ol class="breadcrumb">
  <li><a href="?c=Empleado">Empleados</a></li>
  <li class="active"><?php echo $emp->id_empleado != null ? $emp->id_empleado : 'Nuevo Registro'; ?></li>
</ol>

<form id="frm-empleado" action="?c=Empleado&a=Guardar" method="post" enctype="multipart/form-data">
    <input type="hidden" name="id_empleado" value="<?php echo $emp->id_empleado; ?>" />

    <div class="form-group">
        <label>Cedula de Identidad</label>
        <input class="input-integer form-control input-lg" type="text" id="cedula" name="cedula" value="<?php echo $emp->cedula; ?>" class="form-control" placeholder="Ingrese Cedula de Identidad" required onBlur="comprobarEmpleado()"/>
    </div>
 
    <div class="form-group">
        <label>1er Nombre</label>
        <input type="text" name="primer_nombre" id="primer_nombre" value="<?php echo $emp->primer_nombre; ?>" class="form-control" placeholder="Ingrese 1er Nombre" maxlength="20" required/>
    </div>
    <div class="form-group">
        <label>2do Nombre</label>
        <input type="text" name="segundo_nombre" id="segundo_nombre" value="<?php echo $emp->segundo_nombre; ?>" class="form-control" placeholder="Ingrese 2do Nombre" maxlength="20" />
    </div>
    <div class="form-group">
        <label>1er Apellido</label>
        <input type="text" name="primer_apellido" id="primer_apellido" value="<?php echo $emp->primer_apellido; ?>" class="form-control" placeholder="Ingrese 1er Apellido" maxlength="20" required />
    </div>
    <div class="form-group">
        <label>2do Apellido</label>
        <input type="text" name="segundo_apellido" id="segundo_apellido" value="<?php echo $emp->segundo_apellido; ?>" class="form-control" placeholder="Ingrese 2do Apellido" maxlength="20" />
    </div>
    
    <div class="form-group">
        <label>Direccion</label>
        <input type="text" name="direccion" value="<?php echo $emp->direccion; ?>" class="form-control" placeholder="Ingrese la Direccion" maxlength="20" />
    </div>
    <div class="form-group">
        <label>Telefono</label>
        <input class="input-integer form-control input-lg" type="text" name="telefono" value="<?php echo $emp->telefono; ?>" class="form-control" placeholder="Ingrese Telefono" required>
    </div>
    <div class="form-group">
        <label>Correo</label>
        <input type="email"  id="email" name="email" value="<?php echo $emp->email; ?>" class="form-control" placeholder="Ingrese su correo electrónico" maxlength="30" required>
    </div>    
    <div class="form-group">
        <label>Estatus</label>
        <select id="id_estatus" name="id_estatus" class="form-control">
          <?php if ($emp->id_estatus != null) {
            echo '<option selected="selected" value="'.$emp->id_estatus.'">'.
            $desc_est.'</option>';
          } ?> 
        </select>
    </div>
    <div class="form-group">
        <label>Cargo</label>
        <input type="text" name="cargo" value="<?php echo $emp->cargo; ?>" class="form-control" placeholder="Ingrese Cargo" maxlength="20" required>
    </div>  
    <div class="form-group">
        <label>Ubicacion del Trabajador</label>
        <select id="id_ubicacion" name="id_ubicacion" class="form-control" required>
          <?php if ($emp->id_ubicacion != null) {
            echo '<option selected="selected" value="'.$emp->id_ubicacion.'">'.
            $desc_ubi.'</option>';
          } ?> 
        </select>
    </div>

    <div class="form-group" id="departamento_form" style="display:none;">
        <label>Departamento de Ubicacion del Trabajador</label>
        <select id="id_departamento" name="id_departamento" class="form-control">
          <?php if ($emp->id_departamento != null) {
            echo '<option selected="selected" value="'.$emp->id_departamento.'">'.
            $desc_dep.'</option>';
          } ?> 
        </select>
    </div>

    <div class="form-group" id="oficina_form" style="display:none;">
        <label>Oficina de Ubicacion del Trabajador</label>
        <select id="id_oficina" name="id_oficina" class="form-control">
          <?php if ($emp->id_oficina != null) {
            echo '<option selected="selected" value="'.$emp->id_oficina.'">'.
            $desc_ofi.'</option>';
          } ?> 
        </select>
    </div>    

    <div class="form-group" id="usuario">
        <label>Usuario del Trabajador (Solo si el trabajador fungira como usuario del sistema)</label>
        <select id="id_usuario" name="id_usuario" class="form-control">
          <?php if ($emp->id_usuario != null) {
            echo '<option selected="selected" value="'.$emp->id_usuario.'">'.
            $desc_usu.'</option>';
          } ?> 
        </select>
    </div>

    <hr />
    
    <div class="text-right">
        <button class="btn btn-success">Guardar</button>
    </div>
</form>

<script>
  /*
    $(document).ready(function(){
        $("#frm-usuario").submit(function(){
            return $(this).validate();
        });
    
}
*/

var empexArray = <?php echo $empexist->Listar_json2();?>;
var ubicaArray = <?php echo $ubica->Listar_json();?>;
var oficArray =  <?php echo $ofic->Listar_json();?>;
var deptArray =  <?php echo $dept->Listar_json();?>;
var usuaArray =  <?php echo $usu->Listar_json();?>;
var estaArray =  <?php echo $est->Listar_json();?>;


function comprobarEmpleado() {

    var cedula =$("#cedula").val();
    //var myArr = JSON.parse(empexArray);
    //console.log(empexArray[0].cedula);
    //alert(myArr);  
    
    $.ajax({
    type: "POST",
    url: "?c=saime&a=crud",
    data:{
        "cedula"  : $("#cedula").val(),
        },
        
    success: function(datos){

    console.log(datos);
    a = JSON.parse(datos);
    console.log(a);
    console.log(a['primernombre']);
    console.log(a['id_empexist']);
    if (a['id_empexist']==0){
        $("#primer_nombre").val(a['primernombre']);
        $("#segundo_nombre").val(a['segundonombre']);
        $("#primer_apellido").val(a['primerapellido']);
        $("#segundo_apellido").val(a['segundoapellido']);
        
        if(typeof a['primernombre'] != "undefined"){
          $("#primer_nombre").attr("readonly","true");
          $("#segundo_nombre").attr("readonly","true");
          $("#primer_apellido").attr("readonly","true");
          $("#segundo_apellido").attr("readonly","true");
        }
        else
        {
          $("#primer_nombre").attr("readonly","");
          $("#segundo_nombre").attr("readonly","");
          $("#primer_apellido").attr("readonly","");
          $("#segundo_apellido").attr("readonly","");
        }  
    }
    else
    {
          $("#cedula").val("");
          $("#cedula").focus();
          alert("Empleado ya registrado en el sistema");     
    }
    },
    error: function(){
    alert("Error Procesando Cedula:"+cedula);
    }
    });

}

$('.input-integer').inputNumberFormat({ 'decimal': 0 });

$("#id_ubicacion").select2({
      theme: "bootstrap",
      debug: true,
      language: "es",
      //minimumResultsForSearch: Infinity,
      
      placeholder: {
         id: '-1', // the value of the option
         text: 'Indique la Ubicacion'
      },
      allowClear: true, 
      dataType: 'json',
      data: ubicaArray
});
$("#id_oficina").select2({
      theme: "bootstrap",
      debug: true,
      language: "es",
      //minimumResultsForSearch: Infinity,
      
      placeholder: {
         id: '-1', // the value of the option
         text: 'Indique la Oficina de Ubicacion'
      },      
      allowClear: true, 
      dataType: 'json',
      data: oficArray
});
$("#id_departamento").select2({
      theme: "bootstrap",
      debug: true,
      language: "es",
      //minimumResultsForSearch: Infinity,
      //placeholder: 'Indique el Departamento de Ubicacion',
      placeholder: {
         id: '-1', // the value of the option
         text: 'Indique el Departamento de Ubicacion'
      },       
      allowClear: true,
      dataType: 'json',
      data: deptArray
});

$("#id_estatus").select2({
      theme: "bootstrap",
      debug: true,
      language: "es",
      //minimumResultsForSearch: Infinity,
       
      placeholder: {
         id: '-1', // the value of the option
         text: 'Indique el Estatus del Empleado'
      },      
      allowClear: true,
      dataType: 'json',
      data: estaArray
});

$('#id_ubicacion').on("change", function(e) {
    var destino=$('#id_ubicacion').select2('data')[0].id;
    if (destino == 2) {
      $('#departamento_form').hide();
      $('#oficina_form').show();
     } else {
      $('#departamento_form').show();
      $('#oficina_form').hide();
    }
    //alert(destino);
    
}); 

$("#id_usuario").select2({
      theme: "bootstrap",
      debug: true,
      language: "es",
      //minimumResultsForSearch: Infinity,
      
      placeholder: {
         id: '-1', // the value of the option
         text: 'Indique el Usuario del Trabajador'
      },       
      allowClear: true,
      dataType: 'json',
      data: usuaArray
});

function comprobarEmpleado2() {

    var cedula =$("#cedula").val();
    
    $.ajax({
    type: "POST",
    url: "?c=empleado&a=obtener_json",
    data:{
        "cedula"  : $("#cedula").val(),
        },
        
    success: function(datos){
    
    console.log(datos);
    a = JSON.parse(datos);
    console.log(a);
    console.log(a['cedula']);
    $("#primer_nombre").attr("readonly","");
    $("#segundo_nombre").attr("readonly","");
    $("#primer_apellido").attr("readonly","");
    $("#segundo_apellido").attr("readonly","");
    $("#cedula").focus();
    alert("Empleado ya registrado en el sistema");
    },
    error: function(){
    
    }
    });

}
</script>
