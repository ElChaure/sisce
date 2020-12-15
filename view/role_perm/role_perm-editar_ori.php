<script type="text/javascript" src="assets/js/prettify.min.js"></script>
<script type="text/javascript" src="assets/js/multiselect.min.js"></script>

<?php
    require_once 'model/roles.php';
     require_once 'model/permissions.php';
    $rol = new Roles();
    $per = new Permissions();
    //$o_usu = $usu->Listar();
?>


<h1 class="page-header">
    <?php echo $rolep->id != null ? $rolep->id : 'Nuevo Registro'; ?>
</h1>

<ol class="breadcrumb">
  <li><a href="?c=Role_perm">Asignacion de Permisos a Rol</a></li>
  <li class="active"><?php echo $rolep->id != null ? $rolep->id : 'Nuevo Registro'; ?></li>
</ol>

<form id="frm-alumno" action="?c=Roler_perm&a=Guardar" method="post" enctype="multipart/form-data">
    <input type="hidden" name="id" value="<?php echo $rolep->id; ?>" />

    <div class="form-group" id="usuario">
            <label>Rol de Usuario</label>
            <select id="id_role" name="id_role" class="form-control" onchange="permisos()">              
            </select>
    </div>

    <div class="row">
        <div class="col-xs-5">
            <select name="from[]" class="js-multiselect form-control" size="8" multiple="multiple" id="permisos">
                <!--option value="1">Item 1</option>
                <option value="2">Item 5</option>
                <option value="2">Item 2</option>
                <option value="2">Item 4</option>
                <option value="3">Item 3</option-->
            </select>
        </div>
        
        <div class="col-xs-2">
            <button type="button" id="js_right_All_1" class="btn btn-block"><i class="glyphicon glyphicon-forward"></i></button>
            <button type="button" id="js_right_Selected_1" class="btn btn-block"><i class="glyphicon glyphicon-chevron-right"></i></button>
            <button type="button" id="js_left_Selected_1" class="btn btn-block"><i class="glyphicon glyphicon-chevron-left"></i></button>
            <button type="button" id="js_left_All_1" class="btn btn-block"><i class="glyphicon glyphicon-backward"></i></button>
        </div>
        
        <div class="col-xs-5">
            <select name="to[]" id="js_multiselect_to_1" class="form-control" size="8" multiple="multiple"></select>
        </div>
    </div>





    
    <!--div class="form-group">
        <label>Permiso</label>
        <input type="text" name="perm_id" value="<?php echo $rolep->perm_id; ?>" class="form-control" placeholder="Ingrese Permiso" data-validacion-tipo="requerido|min:3" />
    </div>
    
    <div class="form-group">
        <label>Rol Asignado</label>
        <input type="text" name="role_id" value="<?php echo $rolep->role_id; ?>" class="form-control" placeholder="Ingrese Rol Asignado" data-validacion-tipo="requerido|min:10" />
    </div-->
    
    
    <hr />
    
    <div class="text-right">
        <button class="btn btn-success">Guardar</button>
    </div>
</form>

<script>
    var roleArray =  <?php echo $rol->Listar_json();?>;
    var permArray =  <?php echo $per->Listar_json();?>;

    jQuery(document).ready(function($) {
        $('.js-multiselect').multiselect({
            right: '#js_multiselect_to_1',
            rightAll: '#js_right_All_1',
            rightSelected: '#js_right_Selected_1',
            leftSelected: '#js_left_Selected_1',
            leftAll: '#js_left_All_1'
        });
    });


    $("#id_role").select2({
      theme: "bootstrap",
      debug: true,
      language: "es",
      //minimumResultsForSearch: Infinity,
      placeholder: {
                id: '-1', // the value of the option
             text: 'Seleccione Rol'
       },
      closeOnSelect: true,
      allowClear: true,
      dataType: 'json',
      data: roleArray
    });

   $("#permisos").select2({
      theme: "bootstrap",
      debug: true,
      multiple: true,
      language: "es",
      //minimumResultsForSearch: Infinity,
      //placeholder: 'Seleccione Permisos',
      closeOnSelect: false,
      allowClear: true,
      dataType: 'json',
      data: permArray
    });

    function permisos() {
      var rol=$("#id_role").val();
     }

</script>