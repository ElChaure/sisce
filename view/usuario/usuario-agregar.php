<?php
   include ("include/funciones.php");
   require_once 'model/roles.php';
   $rol = new Roles();
?>
<h1 class="page-header">
    <b>Asignacion de Usuario a Empleado</b>
</h1>

<ol class="breadcrumb">
  <li><a href="?c=Usuario">Usuarios</a></li>
</ol>

<form id="frm-alumno" action="?c=Usuario&a=Guardar" method="post" enctype="multipart/form-data">
    <input type="hidden" name="id" value="<?php echo $usu->id; ?>" />
    
    <div class="form-group">
        <label>Nombres</label>
        <input type="text" name="nombres" value="<?php echo $usu->nombres; ?>" class="form-control" placeholder="Ingrese su nombre" data-validacion-tipo="requerido|min:3" />
    </div>
    
    <div class="form-group">
        <label>Alias</label>
        <input type="text" name="alias" value="<?php echo $usu->alias; ?>" class="form-control" placeholder="Ingrese su usuario" data-validacion-tipo="requerido|min:10" />
    </div>
    
    <div class="form-group">
        <label>Correo</label>
        <input type="text" name="email" value="<?php echo $usu->email; ?>" class="form-control" placeholder="Ingrese su correo electrónico" data-validacion-tipo="requerido|email" />
    </div>
    
    <div class="form-group">
        <label>Password</label>
        <input type="text" name="password" value="<?php echo $usu->password; ?>" class="form-control" placeholder="Ingrese su clave" data-validacion-tipo="requerido|password" />
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
</script>