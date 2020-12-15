<script src="assets/js/tablefilter/dist/tablefilter/tablefilter.js"></script>
<link rel="stylesheet" type="text/css" href="assets/js/tablefilter/dist/tablefilter/style/filtergrid.css" media="screen"/>
<link rel="stylesheet" href="assets/css/tablefilter.css"> 

 <?php
    session_start();
    $_SESSION["retorno"] = "?c=solicitud&a=view_pend";
?> 

<h1 class="page-header">Solicitudes Pendientes</h1>

<a class="btn btn-warning" href="?c=Solicitud">Regresar</a>

<div class="well well-sm text-right">
    <a class="btn btn-primary" href="?c=Solicitud&a=Crud">Nueva Solicitud</a>
</div>

<table class="table table-striped" id="tabla_solicitud">
    <thead>
        <tr>
            <th>Id</th>
            <!--th>Funcionario</th-->
            <th>Funcionario Solicitante</th>
            <th>Fecha Solicitud</th>
            <th>Descripcion</th>
            <th>Tipo Solicitud</th>
            <th>Estatus</th>
            <th></th>
            <th></th>
            <th></th>
            <th></th>
            
            
        </tr>
    </thead>
    <tbody>
    <?php foreach($this->model->Listar_pend() as $r): ?>
        <tr>
            <td><?php echo $r->id_solicitud; ?></td>
            <!--td><?php echo $r->funcionario; ?></td-->
            <td><?php echo $r->empleado; ?></td>
            <td><?php echo date("d-m-Y", strtotime($r->fecha_solicitud)); ?></td>
            <td><?php echo $r->descripcion; ?></td>
            <td><?php echo $r->tipo_solicitud; ?></td>
            <td><?php echo $r->estatus_solicitud; ?></td>
            <td>
               <a class="btn btn-warning" href="?c=Solicitud&a=Crud&id_solicitud=<?php echo $r->id_solicitud; ?>">Editar</a>
            </td>

             <td>
                <a class="btn btn-info" href="index.php?c=reportes&a=solicitud&id_solicitud=<?php echo $r->id_solicitud; ?>" target="_blank">Imprimir</a>
            </td>            

            <td>
                <a class="btn btn-primary" href="?c=Solicitud_detalle&a=Crud&id_solicitud=<?php echo $r->id_solicitud; ?>">Agregar Detalle</a>
            </td> 
            <td>
                <a class="btn btn-success" href="?c=Solicitud_detalle&id_solicitud=<?php echo $r->id_solicitud; ?>&tipo_solicitud=<?php echo $r->tipo_solicitud; ?>&id_tipo_solicitud=<?php echo $r->id_tipo_solicitud; ?>">Procesar Detalle</a>
            </td>                                          
            <!--td>
                <a onclick="javascript:return confirm('¿Seguro de eliminar este registro?');" href="?c=Solicitud&a=Eliminar&id_solicitud=<?php echo $r->id_solicitud; ?>">Eliminar</a>
            </td-->
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
                    col_6: "none",                      
                    col_7: 'none',
                    col_8: 'none',
                    col_9: 'none',
                    col_10: 'none',
                    col_11: 'none',                         
                    rows_counter: true,
                    rows_counter_text: "Registros:", 
                    col_widths: [
            "35px",
            "150px",
            "100px",
            "180px",
            "110px",
            "100px",
            "70px",
            "75px",
            "130px",
            "100px",
            "100px",
            "120px"                
        ],
                }; 
var tf = new TableFilter('tabla_solicitud',tabla_Props);
tf.init();

</script>
