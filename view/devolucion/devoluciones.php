<script src="assets/js/tablefilter/dist/tablefilter/tablefilter.js"></script>
<link rel="stylesheet" type="text/css" href="assets/js/tablefilter/dist/tablefilter/style/filtergrid.css" media="screen"/>
<link rel="stylesheet" href="assets/css/tablefilter.css">
<?php
    session_start();
    
?> 


<ol class="breadcrumb">
  
</ol>
<h1 class="page-header">Imprimir Constancia de Devolucion</h1>
<a class="btn btn-warning" href="?c=devolucion">Regresar</a>


<table id="devoluciones" class="table table-striped">
    <thead>
        <tr>
            <th>Fecha</th>
            <th>Cedula</th>
            <th>Nombre  Emp. Dev. Equipos</th>
            <th>Cant. Equipos Dev.</th>
            <th>Oficina Adscripcion</th>
            <th></th>
        </tr>
    </thead>
    <tbody>
    <?php foreach($this->model->Listar_devoluciones() as $r): ?>
        <tr>
            <td><?php echo date("d-m-Y", strtotime($r->fecha_devolucion)); ?></td>
            <td><?php echo $r->cedula; ?></td>
            <td><?php echo $r->nombre; ?></td>
            <td><?php echo $r->equipos_devueltos; ?></td>
            <td><?php echo $r->nombre_oficina; ?></td>
            <td>
                <a class="btn btn-primary" href="index.php?c=reportes&a=devolucion_constancia&fecha_devolucion=<?php echo $r->fecha_devolucion; ?>&id_empleado_entrega=<?php echo $r->id_empleado_entrega; ?>" target="_blank">Imprime Constancia</a>
            </td> 
        </tr>
    <?php endforeach; ?>
    </tbody>
</table> 
 


<script type="text/javascript">
    

    var tabla_Props =  { 
                    paging: {
                          results_per_page: ['Registros por pagina: ', [5, 10, 25, 50, 100]]
                        },
                    col_1:'select', 
                    //col_2:'none',
                    //col_3:'none',
                    col_4:'select',
                    col_5:'none',
                    col_7:'none',
                    rows_counter: true,
                    rows_counter_text: "Registros:", 
                    col_widths: [
            "90px", //id
            "100px", //1er Nombre
            "250px", //1er Apellido
            "80px",  
            "350px",        
            "180px"
                                         
        ],
                }; 
var tf = new TableFilter('devoluciones',tabla_Props);
tf.init();
</script>