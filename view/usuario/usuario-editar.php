<?php
   include ("include/funciones.php");
   require_once 'model/roles.php';
   $rol = new Roles();
?>
<h1 class="page-header">
    <?php echo $usu->id != null ? $usu->nombres : 'Nuevo Registro'; ?>
</h1>

<ol class="breadcrumb">
  <li><a href="?c=Usuario">Usuarios</a></li>
  <li class="active"><?php echo $usu->id != null ? $usu->nombres : 'Nuevo Registro'; ?></li>
</ol>

<form id="frm-alumno" action="?c=Usuario&a=Guardar" method="post" enctype="multipart/form-data">
    <input type="hidden" name="id" value="<?php echo $usu->id; ?>" />
   <?php if($usu->id == null){; ?>
       <div class="form-group">
            <label>Cedula de Identidad del Empleado</label>
            <input class="input-integer form-control input-lg" type="text" id="cedula" name="cedula" value="" class="form-control" placeholder="Ingrese Cedula de Identidad" required onBlur="comprobarEmpleado()"/>
        </div>
    <?php }; ?>

    <div class="form-group">
        <label>Nombres</label>
        <input type="text" id="nombres" name="nombres" value="<?php echo $usu->nombres; ?>" class="form-control" placeholder="Ingrese su nombre" maxlength="80" required>
    </div>
    
    <div class="form-group">
        <label>Alias</label>
        <input type="text" id="alias" name="alias" value="<?php echo $usu->alias; ?>" class="form-control" placeholder="Ingrese su usuario" maxlength="60" required>
    </div>
    
    <div class="form-group">
        <label>Correo</label>
        <input type="email"  id="email" name="email" value="<?php echo $usu->email; ?>" class="form-control" placeholder="Ingrese su correo electrónico" maxlength="100" required>
    </div>
    
    <div class="form-group">
        <label>Password</label>
        <input type="password" id="password" name="password" value="<?php echo $usu->password; ?>" class="form-control" placeholder="Ingrese su clave" maxlength="100" required>
    </div>
    
    <!--div class="form-group">
        <label>Rol del Usuario</label>
        <input type="text" name="id_rol" value="<?php echo $usu->id_rol; ?>" class="form-control" placeholder="Ingrese el Rol del Usuario" data-validacion-tipo="requerido" /-->
   
    <select id="id_rol" name="id_rol" style="width:200px;" title="Ingrese el Rol del Usuario.">
        <option value="x999"><-- Seleccione --></option>
        <?php $l=make_combo($rol,"role_id","role_name","",0);?>
    </select>

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
    function comprobarEmpleado() {

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
    console.log(a['primer_nombre']);

    if(typeof a['primer_nombre'] == "undefined"){
        alert("Empleado No Registrado!!!!");
        $("#cedula").val("");
        $("#cedula").focus();
    }

    $("#nombres").val(a['primer_nombre']+' '+a['primer_apellido']);
    $("#email").val(a['email']);
    
    /*
    if(typeof a['primer_nombre'] != "undefined"){
      $("#nombres").attr("readonly","true");
    }
    else
    {
      $("#nombres").attr("readonly","");
    }  
    */
    },
    error: function(){
    alert("Error Procesando Cedula:"+cedula);
    }
    });

}

$('.input-integer').inputNumberFormat({ 'decimal': 0 });
</script>