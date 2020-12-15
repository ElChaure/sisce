<script src="assets/js/tablefilter/dist/tablefilter/tablefilter.js"></script>
<link rel="stylesheet" type="text/css" href="assets/js/tablefilter/dist/tablefilter/style/filtergrid.css" media="screen"/>
<link rel="stylesheet" href="assets/css/tablefilter.css">
<?php
   require_once 'model/roles.php';
   $rol = new Roles();
?>
<ol class="breadcrumb">
  <a class="btn btn-warning" href="?c=site&a=index">Inicio</a>
</ol>
<h1 class="page-header">Usuarios</h1>

<div class="well well-sm text-right">
    <a class="btn btn-primary" href="?c=Usuario&a=Crud">Nuevo Usuario</a>
	<!--a class="btn btn-info" href="?c=Reportes&a=usuario" target="_blank">Reporte</a-->
</div>

<table id="tabla_usuarios">
    <thead>
        <tr>
            <th>Id</th>
            <th>Alias</th>
            <th>Nombres</th>
            <th>Email</th>
            <th>Rol</th>
            <th>Intentos</th>
            <th>Ingreso</th>
            <th></th>
            <th></th>
            <th></th>
        </tr>
    </thead>
    <tbody>
    <?php foreach($this->model->Listar() as $r): 
	   $rol_usu = $rol->Obtener($r->id_rol);
	?>
        <tr>
            <td><?php echo $r->id; ?></td>
            <td><?php echo $r->alias; ?></td>
            <td><?php echo $r->nombres; ?></td>
            <td><?php echo $r->email; ?></td>
            <td><?php echo $rol_usu->role_name; ?></td>
            <td><?php echo $r->intentos; ?></td>
            <td><?php echo $r->ingreso; ?></td>
            <td>
                <a class="btn btn-info" href="?c=Usuario&a=Crud&id=<?php echo $r->id; ?>">Editar</a>
            </td>
            <td>
                <a class="btn btn-warning" onclick="javascript:return confirm('¿Seguro de eliminar este registro?');" href="?c=Usuario&a=Eliminar&id=<?php echo $r->id; ?>">Eliminar</a>
            </td>
            <td>
                <?php if($r->intentos > 2 || $r->ingreso==1) { ?>
                <a class="btn btn-danger" onclick="javascript:return confirm('¿Desea Desbloquear al Usuario?');" href="?c=Usuario&a=Desbloquear&id=<?php echo $r->id; ?>">Desbloquear</a>
                <?php } ?>
            </td>
        </tr>
    <?php endforeach; ?>
    </tbody>
</table> 
<script>
    

var tabla_Props =  { 
                    paging: {
                          results_per_page: ['Registros por pagina: ', [5, 10, 25, 50, 100]]
                        },
                    col_1: "select",     
                    col_2: "select", 
                    col_3: "select", 
                    col_4: "select", 
                    col_5: "select",
                    col_6: "select",                      
                    col_7: 'none',
                    col_8: 'none',
                    col_9: 'none',                    
                    rows_counter: true,
                    rows_counter_text: "Registros:", 
                    col_widths: [
            "35px",
            "100px",
            "200px",
            "200px",
            "120px",
            "100px",
            "95px",
            "85px",
            "85px",
            "85px"  
        ],
                }; 
var tf = new TableFilter('tabla_usuarios',tabla_Props);
tf.init();

</script>
