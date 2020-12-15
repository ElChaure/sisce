<script src="assets/js/tablefilter/dist/tablefilter/tablefilter.js"></script>
<link rel="stylesheet" type="text/css" href="assets/js/tablefilter/dist/tablefilter/style/filtergrid.css" media="screen"/>
<link rel="stylesheet" href="assets/css/tablefilter.css">
<?php
   session_start(); //Iniciamos la Sesion o la Continuamos
?>
<ol class="breadcrumb">
  <a class="btn btn-warning" href="?c=site&a=index">Inicio</a>
</ol>
<h1 class="page-header">Acciones del Sistema</h1>

<div class="well well-sm text-right">
    <a class="btn btn-primary" href="?c=Permissions&a=Crud">Nueva Accion</a>
</div>
<div id="dynamic_content">

<table class="table table-striped" id="permisos">
    <thead>
        <tr>
            <th>Id</th>
            <th>Descripcion</th>
            <th>Accion</th>
            <th></th>
            <th></th>
        </tr>
    </thead>
    <tbody>
    <?php foreach($this->model->Listar() as $r): ?>
        <tr>
            <td><?php echo $r->perm_id; ?></td>
            <td><?php echo $r->perm_desc; ?></td>
            <td><?php echo $r->accion; ?></td>
            <td>
                <a class="btn btn-info"  href="?c=Permissions&a=Crud&perm_id=<?php echo $r->perm_id; ?>">Editar</a>
            </td>
            <td>
                <a class="btn btn-warning"  onclick="javascript:return confirm('¿Seguro de eliminar este registro?');" href="?c=Permissions&a=Eliminar&perm_id=<?php echo $r->perm_id; ?>">Eliminar</a>
            </td>
        </tr>
    <?php endforeach; ?>


    </tbody>
</table> 

</div>



<script  type="text/javascript">
var tabla_Props =  { 
                    paging: {
                          results_per_page: ['Registros por pagina: ', [5, 10, 25, 50, 100]]
                        },
                    col_1:'select', 
                    //col_2:'none',
                    col_3:'none',
                    col_4:'none',
                    col_5:'none',
                    rows_counter: true,
                    rows_counter_text: "Registros:", 
                    col_widths: [
            "35px", //id
            "520px", //1er Nombre
            "320px", //1er Apellido
            "100px",  
            "80px",        
            "80px"                            
        ],
                }; 
var tf = new TableFilter('permisos',tabla_Props);
tf.init();
        </script>