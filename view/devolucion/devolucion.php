<script src="assets/js/tablefilter/dist/tablefilter/tablefilter.js"></script>
<link rel="stylesheet" type="text/css" href="assets/js/tablefilter/dist/tablefilter/style/filtergrid.css" media="screen"/>
<link rel="stylesheet" href="assets/css/tablefilter.css">
<?php
    session_start();
    require_once 'model/orden_salida.php';
    require_once 'model/empleado.php'; 
    //$ordsal = new Orden_salida();
    $empact = new Empleado();
?> 

<script type="text/javascript">    
$(document).ready(function(){
    var empArray  =  <?php echo $empact->Listar_json();?>;
    $("#id_empleado_entrega").select2({
      theme: "bootstrap",
      debug: true,
      //language: "es",
      //minimumResultsForSearch: Infinity,
      placeholder: {
                id: '-1', // the value of the option
             text: 'Indique Empleado que Entrega el Equipo'
       },
      allowClear: true,
      dataType: 'json',
      data: empArray
    });


    $('#devoluciones').on("click", "#btn_devuelve_equipo", function(){
    

        var id=$(this).val();
        var id_equipo=$(this).val();
        var observacion=$('#observacion'+id).text();
        $('#id_equipo').val(id_equipo);
        $('#id_empleado_entrega').val(id_empleado_entrega);
        $('#observacion').val(observacion);
        $('#edit').modal('show');
        
        
    });

    $("#submit").click(function(){
    $("#loaderIcon").show(); 
    //var id_solicitud_detalle_reserva =$("#id_solicitud_detalle_reserva").val();
    var id_empleado_entrega =$("#id_empleado_entrega").val();
    var id_equipo =$("#id_equipo").val();
    var observacion = $("#observacion").val();

    
    $.ajax({
    type: "POST",
    //url: "view/solicitud/orden.php",
    url: "?c=devolucion&a=devolver",
    data:{
        //"id_solicitud" : $("#id_solicitud_detalle_reserva").val(),
        "id_empleado_entrega" : $("#id_empleado_entrega").val(),
        "id_equipo" : $("#id_equipo").val(),
        "observacion"  : $("#observacion").val()
        },
        
    success: function(response){
    alert('Equipo devuelto exitosamente!!!');
    $("#loaderIcon").hide();
    $("#edit").modal('hide');
    window.location.reload();
    },
    error: function(){
    alert("Error Procesando Devolucion Equipo:"+id_equipo+" Empleado Entrega:"+id_empleado_entrega+" Observacion:"+observacion);
    }
    //)};
});

});


});
</script>



<h1 class="page-header">Devoluciones</h1>
<a class="btn btn-warning" href="?c=equipo">Regresar</a>

<div class="well well-sm text-right">
    <!--a class="btn btn-primary" href="?c=Almacen&a=Crud">Nuevo Almacen</a-->
    <a class="btn btn-info" href="?c=devolucion&a=devoluciones" >Imprime Constancias</a>
</div>


<table id="devoluciones" class="table table-striped">
    <thead>
        <tr>
            <th>Id</th>
            <th>Codigo</th>
            <th>Serial</th>
            <th>Equipo</th>
            <th>Estatus</th>
            <th>Ubicacion</th>
            <th>Solicitud</th>
            <th></th>
        </tr>
    </thead>
    <tbody>
    <?php foreach($this->model->Listar() as $r): ?>
        <tr>
            <td><?php echo $r->id_equipo; ?></td>
            <td><?php echo $r->cod_equipo; ?></td>
            <td><?php echo $r->serial; ?></td>
            <td><?php echo $r->descripcion; ?></td>
            <td><?php echo $r->estatus; ?></td>
            <td><?php echo $r->ubicacion; ?></td>
            <td><?php echo $r->id_solicitud_detalle_reserva; ?></td>
            <td>
                <button type="button" 
                        class="btn btn-primary edit" 
                        value="<?php echo $r->id_equipo; ?>"
                        id_solicitud_detalle_reserva=<?php echo $r->id_solicitud_detalle_reserva; ?> 
                        id="btn_devuelve_equipo">
                        <span class="glyphicon glyphicon-edit"></span>Devolver Equipo
                </button>
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
                
                <h4 class="modal-title" id="myModalLabel">Registro de Devolucion de Equipos</h4>
            </div>
            <span id="nrosolicitud"></span> 
            <!-- Modal Body -->
            <div class="modal-body">
                <p class="statusMsg"></p>
                <form role="form">
                    <div class="form-group">

<input type="hidden"  class="form-control" id="id_equipo" name="id_equipo" >
<!--input type="text"  class="form-control" id="id_solicitud_detalle_reserva" name="id_solicitud_detalle_reserva"  -->
<label for="id_empleado_entrega">Funcionario que Entrega el material</label>
<select id="id_empleado_entrega" name="id_empleado_entrega" class="form-control"></select>
<label for="observacion">Observacion</label>
<textarea class="form-control" id="observacion" name="observacion"placeholder="Ingrese sus Observaciones"></textarea>
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
            "35px", //id
            "80px", //1er Nombre
            "150px", //1er Apellido
            "500px",  
            "100px",        
            "100px",
            "80px",        
            "150px"                              
        ],
                }; 
var tf = new TableFilter('devoluciones',tabla_Props);
tf.init();
</script>