<script src="assets/js/tablefilter/dist/tablefilter/tablefilter.js"></script>
<link rel="stylesheet" type="text/css" href="assets/js/tablefilter/dist/tablefilter/style/filtergrid.css" media="screen"/>
<link rel="stylesheet" href="assets/css/tablefilter.css"> 

<!--ol class="breadcrumb"-->
 
<!--/ol-->
<h1 class="page-header">Equipos Disponibles</h1>
 <a class="btn btn-success" href="index.php?c=equipo">Regresar</a>


<table class="table table-striped" id="tabla_solicitud">
    <thead>
        <tr>
            <th>Id</th>
            <th>Codigo</th>
            <th>Serial</th>
            <th>Estatus</th>
            <th>Ubicacion</th>    
            <th>Nro BN</th>
            <th>Descripcion</th>
            <th>Nro Fact</th>
            <th>Fch Fact</th>
            <th>Proveedor</th>
            <th>Valor</th>
            <th></th>
        </tr>
    </thead>
    <tbody>
    <?php foreach($this->model->Listar_disponibles() as $r): ?>
        <tr>
            <td><?php echo $r->id_equipo; ?></td>
            <td><?php echo $r->cod_equipo; ?></td>
            <td><?php echo $r->serial; ?></td>
            <td><?php echo $r->estatus; ?></td>
            <td><?php echo $r->ubicacion; ?></td>
            <td><?php echo $r->num_bien_nac; ?></td>
            <td><?php echo $r->descripcion; ?></td>
            <td><?php echo $r->num_factura; ?></td>
            <td><?php echo date("d-m-Y", strtotime($r->fecha_factura)); ?></td>
            <td><?php echo $r->nombre_prov." ".$r->apellido_prov; ?></td>
            <td style="text-align:right;"><?php echo $r->valor; ?></td>
            <td>
                <a  class="btn btn-info"  href="?c=Equipo&a=historial&id_equipo=<?php echo $r->id_equipo; ?>">Ver Historial</a>
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
                    //col_1: "select",     
                    //col_2: "select", 
                    col_3: "select", 
                    col_4: "select", 
                    col_5: "select",
                    col_6: "none", 
                    col_9: "select",                     
                    col_10: "none",
                    col_11: "none",                     
                    rows_counter: true,
                    rows_counter_text: "Registros:", 
                    col_widths: [
            "35px",
            "80px",
            "160px",
            "80px",
            "80px",
            "80px",
            "200px",
            "80px", 
            "80px",
            "80px",
            "80px",
            "120px",             
        ],
                }; 
var tf = new TableFilter('tabla_solicitud',tabla_Props);
tf.init();

</script>