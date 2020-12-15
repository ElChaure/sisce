<script src="assets/js/tablefilter/dist/tablefilter/tablefilter.js"></script>
<link rel="stylesheet" type="text/css" href="assets/js/tablefilter/dist/tablefilter/style/filtergrid.css" media="screen"/>
<link rel="stylesheet" href="assets/css/tablefilter.css">

<?php
    require_once 'model/roles.php';
    $rol = new Roles();
    //$o_usu = $usu->Listar();
?>
<ol class="breadcrumb">
  <a class="btn btn-warning" href="?c=site&a=index">Inicio</a>
</ol>
<h1 class="page-header">Permisos Asignados a Roles</h1>

<div class="well well-sm text-right">
    <a class="btn btn-primary" href="?c=Role_perm&a=Crud">Nuevo Permiso a Rol</a>
</div>

<!--table class="table table-striped" id="demo"-->
<table id="demo">
    <thead>
        <tr>
            <th style="width:20px;">Id </th>
            <th style="width:20px;">Permiso Asignado</th>
            <th style="width:180px;">Descripcion Permiso</th>
            <!--th style="width:20px;">Rol</th-->
            <th style="width:180px;">Nombre Rol</th>
            <th style="width:60px;"></th>
            <th style="width:60px;"></th>
        </tr>
    </thead>
    <tbody>
    <?php foreach($this->model->Listar() as $r): ?>
        <tr>
            <td><?php echo $r->id; ?></td>
            <td><?php echo $r->perm_id; ?></td>
            <td><?php echo $r->perm_desc." Accion: ".$r->accion; ?></td>
            <!--td><?php echo $r->role_id; ?></td-->
            <td><?php echo $r->role_name; ?></td>
            <td>
                <a class="btn btn-success" href="?c=Role_perm&a=Crud&id=<?php echo $r->id; ?>">Editar</a>
            </td>
            <td>
                <a class="btn btn-warning" onclick="javascript:return confirm('¿Seguro de eliminar este registro?');" href="?c=Role_perm&a=Eliminar&id=<?php echo $r->id; ?>">Eliminar</a>
            </td>
        </tr>
    <?php endforeach; ?>
    </tbody>
</table> 

<script>
    var roleArray =  <?php echo $rol->Listar_json();?>;
    $("#id_role").select2({
      theme: "bootstrap",
      debug: true,
      language: "es",
      //minimumResultsForSearch: Infinity,
      placeholder: 'Seleccione Rol', 
      allowClear: true,
      dataType: 'json',
      data: roleArray
});

var tabla_Props =  { 
                    paging: {
                          results_per_page: ['Registros por pagina: ', [5, 10, 25, 50, 100]]
                        },
                    col_2: "select", 
                    col_3: "select", 
                    rows_counter: true,          //mostrar cantidad de filas
                    rows_counter_text: "Registros:", 
                    col_4: 'none',
                    col_5: 'none',
                    col_widths: [
            "35px", "100px", "585px",
            "200px", "100px",
            "100px"
        ],
                }; 
var tf = new TableFilter('demo',tabla_Props);
tf.init();

</script>