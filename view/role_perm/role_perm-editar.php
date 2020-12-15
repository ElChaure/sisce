<?php
   require_once 'model/permissions.php';
   require_once 'model/roles.php';
   $per = new Permissions();
   $rol = new Roles();
   
?>
<h1 class="page-header">
    <?php echo $rolep->id != null ? $rolep->id : 'Nuevo Registro'; ?>
     <?php 
     if ($rolep->id != null){
         $o_per = $per->Obtener($rolep->perm_id);
         $o_rol = $rol->Obtener($rolep->role_id);

         $desc_rol  = $o_mar->role_name;   
         $desc_per  = $o_per->perm_desc." ".$o_pro->accion;
  }
  ?>
</h1>

<ol class="breadcrumb">
  <li><a href="?c=Role_perm">Asignacion de Permiso a Rol</a></li>
  <li class="active"><?php echo $rolep->id != null ? $rolep->id : 'Nuevo Registro'; ?></li>
</ol>

<form id="frm-alumno" action="?c=Role_perm&a=Guardar" method="post" enctype="multipart/form-data">
    <input type="hidden" name="id" value="<?php echo $rolep->id; ?>" />
    
    <div class="form-group">
        <label>Permiso</label>
        <select id="perm_id" name="perm_id" class="form-control"  required>
        <?php if ($rolep->perm_id != null) {
            echo '<option selected="selected" value="'.$rolep->perm_id.'">'.
            $desc_per.'</option>';
          } ?>
        </select>
    </div>
    
    <div class="form-group">
        <label>Rol Asignado</label>
        <select id="role_id" name="role_id" class="form-control"  required>
        <?php if ($rolep->role_id != null) {
            echo '<option selected="selected" value="'.$rolep->role_id.'">'.
            $desc_rol.'</option>';
          } ?>
        </select>            
    </div>
    
    
    <hr />
    
    <div class="text-right">
        <button class="btn btn-success">Guardar</button>
    </div>
</form>

<script>
    var perArray = <?php echo $per->Listar_json();?>;
    var rolArray = <?php echo $rol->Listar_json();?>;

    $("#perm_id").select2({
      theme: "bootstrap",
      debug: true,
      language: "es",
      placeholder: {
         id: '-1', // the value of the option
         text: 'Seleccione un Permiso'
      },
      allowClear: true,
      dataType: 'json',
      data: perArray
       });
    
      $("#role_id").select2({
      theme: "bootstrap",
      debug: true,
      language: "es",
      placeholder: {
         id: '-1', // the value of the option
         text: 'Seleccione un Rol'
      },
      allowClear: true,
      dataType: 'json',
      data: rolArray
       });
</script>