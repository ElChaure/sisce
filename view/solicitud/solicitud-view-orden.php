<script src="assets/js/tablefilter/dist/tablefilter/tablefilter.js"></script>
<link rel="stylesheet" type="text/css" href="assets/js/tablefilter/dist/tablefilter/style/filtergrid.css" media="screen"/>
<link rel="stylesheet" href="assets/css/tablefilter.css">
<?php
    session_start();
    require_once 'model/orden_salida.php';
    require_once 'model/empleado.php'; 
    $ordsal = new Orden_salida();
    $empact = new Empleado();
?> 

<script type="text/javascript">    
$(document).ready(function(){
    var empArray  =  <?php echo $empact->Listar_json();?>;
    $("#id_empleado_retira").select2({
      theme: "bootstrap",
      debug: true,
      language: "es",
      //minimumResultsForSearch: Infinity,
      placeholder: {
                id: '-1', // the value of the option
             text: 'Indique Empleado que Retira'
       },       
      allowClear: true,
      dataType: 'json',
      data: empArray
    });


    $('#solicitudes').on("click", "#btn_genera_orden", function(){
    

        var id=$(this).val();
        var id_solicitud=$(this).val();

        //alert(id_solicitud);

        var inputObservacion=$('#inputObservacion'+id).text();
        
        $('#id_solicitud').val(id_solicitud);
        $('#id_empleado_retira').val(id_empleado_retira);
        $('#inputObservacion').val(inputObservacion);
        $('#edit').modal('show');
        
        
    });

    $("#submit").click(function(){
    $("#loaderIcon").show(); 
    var id_solicitud =$("#id_solicitud").val();
    var id_empleado_retira =$("#id_empleado_retira").val();
    var observacion = $("#inputObservacion").val();

    
    $.ajax({
    type: "POST",
    url: "view/solicitud/orden.php",
    data:{
        "id_solicitud" : $("#id_solicitud").val(),
        "id_empleado_retira" : $("#id_empleado_retira").val(),
        "observacion"  : $("#inputObservacion").val()
        },
        
    success: function(response){
    alert('Numero de Orden de Salida Generada: '+response);
    //$("#edit").html(message);
    $("#loaderIcon").hide();
    $("#edit").modal('hide');
    window.location.reload();
    //$('#solicitudes').DataTable().ajax.reload();
    },
    error: function(){
    alert("Error Procesando Solicitud:"+id_solicitud);
    }
    //)};
});

});


});
</script>



<h1 class="page-header">Generación de Orden de Salida de Equipos</h1>

<a class="btn btn-warning" href="?c=site">Inicio</a></br>



<!--table class="table table-striped" name="solicitudes" id="solicitudes"-->
<table id="solicitudes" class="table table-striped table-bordered" style="width:100%">    
    <thead>
        <tr>
            <th>Id</th>
            <th>Funcionario Solicitante</th>
            <th>Fecha Solicitud</th>
            <th>Descripcion</th>
            <th>Tipo Solicitud</th>
            <th>Estatus</th>
            <th></th>
        </tr>
    </thead>
    <tbody>
    <?php foreach($this->model->Listar_sin_orden_salida() as $r): ?>
        <tr>
            <td><?php echo $r->id_solicitud; ?></td>
            <td><?php echo $r->empleado; ?></td>
            <td><?php echo date("d-m-Y", strtotime($r->fecha_solicitud)); ?></td>
            <td><?php echo $r->descripcion; ?></td>
            <td><?php echo $r->tipo_solicitud; ?></td>
            <td><?php echo $r->estatus_solicitud; ?></td>
             

<td><button type="button" class="btn btn-success edit" value="<?php echo $r->id_solicitud; ?>" id="btn_genera_orden"><span class="glyphicon glyphicon-edit"></span> Genera Orden de Salida</button></td>

            </td>            
        </tr>
    <?php endforeach; ?>
    </tbody>
</table> 
</br>
<h2>Ordenes de Salida Generadas</h2>
</br>
<table id="ordenes" class="table table-striped table-bordered" style="width:100%">    
    <thead>
        <tr>
            <th>Id</th>
            <th>Nro Orden Salida</th>
            <th>Observaciones</th>
            <th>Descripcion Solicitud</th>
            <th>Fecha Solicitud</th>
            <th></th>
         </tr>
    </thead>
    <tbody>
    <?php foreach($ordsal->Listar_generadas() as $s): ?>
        <tr>
            <td><?php echo $s->id_orden; ?></td>
            <td><?php echo $s->num_orden; ?></td>
            <td><?php echo $s->observacion; ?></td>
            <td><?php echo $s->descripcion; ?></td>
            <td><?php echo date("d-m-Y", strtotime($s->fecha_solicitud)); ?></td>
            <td>
                <a  class="btn btn-info" type="button" class="glyphicon glyphicon-print" href="index.php?c=reportes&a=orden_salida&id_orden=<?php echo $s->id_orden; ?>" target="_blank">Imprimir</a>
            </td>           
        </tr>
    <?php endforeach; ?>
    </tbody>
</table>



<!-- Modal -->
<div class="modal fade" id="edit" name="edit" idx="modalForm" role="dialog">
    <div class="modal-dialog">
        <div class="modal-content">
            <!-- Modal Header -->
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal">
                    <span aria-hidden="true">×</span>
                    <span class="sr-only">Close</span>
                </button>
                
                <h4 class="modal-title" id="myModalLabel">Generacion de Orden de Salida de Solicitud</h4>
            </div>
            <span id="nrosolicitud"></span> 
            <!-- Modal Body -->
            <div class="modal-body">
                <p class="statusMsg"></p>
                <form role="form">
                    <div class="form-group">
                        <input type="hidden"  class="form-control" id="id_solicitud" name="id_solicitud" >
                        <label for="id_empleado_retira">Funcionario que Retira el material</label>
                        <select id="id_empleado_retira" name="id_empleado_retira" class="form-control"></select>

                        <label for="inputObservacion">Observacion</label>
                        <textarea class="form-control" id="inputObservacion" name="inputObservacion"placeholder="Ingrese sus Observaciones"></textarea>
                    </div>
                    <p><img src="assets/img/loader.gif" id="loaderIcon" style="display:none" /></p>
                </form>
            </div>
            
            <!-- Modal Footer -->
            <div class="modal-footer">
                <button type="button" class="btn btn-default" data-dismiss="modal">Cancelar</button>
                <button type="button" class="btn btn-primary submitBtn" id="submit">Enviar</button>
            </div>
        </div>
    </div>
</div>

<script  type="text/javascript">


var tabla_ordenes =  { 
                    paging: {
                          results_per_page: ['Registros por pagina: ', [5, 10, 25, 50, 100]]
                        },
                    //col_0:'none', 
                    //col_1:'none',
                    //col_2:'none',
                    //col_3:'none', 
                    col_4:'none',
                    col_5:'none',
                    col_6:'none', 
                    rows_counter: true,
                    rows_counter_text: "Registros:", 
                    col_widths: [
            "70px", //id
            "200px", //1er Nombre
            "325px",
            "325px",
            "140px",
            "100px"                           
        ],
 };

                  
//var tf = new TableFilter('solicitudes',tabla_ordenes);
//tf.init();

var tf = new TableFilter('ordenes',tabla_ordenes);
tf.init();
</script>