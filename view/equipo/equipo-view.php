<script src="assets/js/tablefilter/dist/tablefilter/tablefilter.js"></script>
<link rel="stylesheet" type="text/css" href="assets/js/tablefilter/dist/tablefilter/style/filtergrid.css" media="screen"/>
<link rel="stylesheet" href="assets/css/tablefilter.css">
<!--ol class="breadcrumb"-->
  
<!--/ol-->
<h1 class="page-header">Equipos</h1>
<a class="btn btn-warning" href="?c=equipo">Regresar</a>
<div class="well well-sm text-right">
    <a class="btn btn-primary" href="?c=Equipo&a=Crud">Nuevo Equipo</a>
</div>

<table id="tabla_equipos">
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
            <th>Valor</th>
            <th></th>
            <th></th>
        </tr>
    </thead>
    <tbody>
    <?php foreach($this->model->Listar() as $r): ?>
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
            <td style="text-align:right;"><?php echo $r->valor; ?></td>
           
     <?php if ($r->id_solicitud_detalle_reserva == 0) { ?>
            <td>
                <a  class="btn btn-info"  href="?c=Equipo&a=Crud&id_equipo=<?php echo $r->id_equipo; ?>">Editar</a>
            </td>
            <td>
                <a class="btn btn-warning" onclick="javascript:return confirm('¿Seguro de eliminar este registro?');" href="?c=Equipo&a=Eliminar&id_equipo=<?php echo $r->id_equipo; ?>">Eliminar</a>
            </td>
     <?php }
           else
           { ?>
            <td></td>
            <td>
               <b>Equipo en Reserva o en Itinerancia</b>
            </td>       
      <?php } 
      ?>

        </tr>
    <?php endforeach; ?>
    </tbody>
</table> 

<script>
    

var tabla_Props =  { 
                    paging: {
                          results_per_page: ['Registros por pagina: ', [5, 10, 25, 50, 100]]
                        },
                    //col_0: "none",     
                    col_1: "select",     
                    //col_2: "select", 
                    col_3: "select", 
                    col_4: "select", 
                    //col_5: "select",
                    //col_6: "select",                      
                    col_7: 'select',
                    col_8: 'select',
                    col_9: 'none',
                    col_10: 'none',
                    col_11: 'select',
                    rows_counter: true,
                    rows_counter_text: "Registros:", 
                    col_widths: [
            "35px",
            "75px",
            "160px",
            "100px",
            "100px",
            "100px",
            "170px",
            "80px",
            "80px",
            "80px",
            "80px",            
            "100px"
        ],
                }; 
var tf = new TableFilter('tabla_equipos',tabla_Props);
tf.init();

</script>