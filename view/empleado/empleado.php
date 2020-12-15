<script src="assets/js/tablefilter/dist/tablefilter/tablefilter.js"></script>
<link rel="stylesheet" type="text/css" href="assets/js/tablefilter/dist/tablefilter/style/filtergrid.css" media="screen"/>
<link rel="stylesheet" href="assets/css/tablefilter.css">
 <ol class="breadcrumb">
  <a class="btn btn-warning" href="?c=site&a=index">Inicio</a>
</ol>
<h1 class="page-header">Empleados</h1>
 
<div class="well well-sm text-right">
    <a class="btn btn-primary" href="?c=Empleado&a=Crud">Nuevo Empleado</a>
</div>

<table class="table table-striped" id="empleados">
    <thead>
        <tr>
            <th>ID</th> 
            <th>Cedula</th>
            <th>1er Nombre</th>
            <!--th>2do Nombre</th-->
            <th>1er Apellido</th>
            <!--th>2do Apellido</th-->
            <th>Email</th>
            <th>Depto u Oficina</th>
            <th>Estatus</th>
            <th>Cargo</th>
            <th></th>         
            <th></th>               
            <th></th>          
            <th></th>                           
        </tr>
    </thead>
    <tbody>
    <?php foreach($this->model->Listar() as $r): ?>
        <tr>
            <td id="id_empleado"><?php echo $r->id_empleado; ?></td>
            <td id="cedula"><?php echo $r->cedula; ?></td>
            <td id="primer_nombre"><?php echo $r->primer_nombre; ?></td>
            <!--td id="segundo_nombre"><?php echo $r->segundo_nombre; ?></td-->
            <td id="primer_apellido"><?php echo $r->primer_apellido; ?></td>
            <!--td id="segundo_apellido"><?php echo $r->segundo_apellido; ?></td-->
            <td id="email"><?php echo $r->email; ?></td>
            <td id="oficina"><?php 
                if($r->id_ubicacion==2){
                    echo $r->nombre_oficina;
                }else{
                    echo $r->nombre;
                } 
                ?>
                    
            </td>            
            <td id="estatus"><?php echo $r->estatus; ?></td>
            <td id="cargo"><?php echo $r->cargo; ?></td>
            <td><a class="btn btn-success" href="?c=Empleado&a=Crud&id_empleado=<?php echo $r->id_empleado; ?>">Editar</a></td>
            <td><a class="btn btn-warning" onclick="javascript:return confirm('¿Seguro de eliminar este registro?');" href="?c=Empleado&a=Eliminar&id_empleado=<?php echo $r->id_empleado; ?>">Eliminar</a></td>
            <td><button type="button" class="edit" value="<?php echo $r->id_empleado; ?>" id="btn_muestra_info"><span class="glyphicon glyphicon-eye-open"></span></button></td>
            <td><?php 
                 if ($r->id_usuario > 0){ ?>
                   <i class="fa fa-user"></i>
                <?php } ?>
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
                
                <h4 class="modal-title" id="myModalLabel">Informacion General del Empleado</h4>
            </div>
            <span id="nrosolicitud"></span> 
            <!-- Modal Body -->
            <div class="modal-body">

            </div>
            
            <!-- Modal Footer -->
            <div class="modal-footer">
                <button type="button" class="btn btn-info" data-dismiss="modal">Cerrar</button>
               
            </div>
        </div>
    </div>
</div>

<script type="text/javascript">
    $('#empleados').on("click", "#btn_muestra_info", function(){
        var id=$(this).val();
        $("#edit").find(".modal-body").load("?c=Empleado&a=cuerpo_modal&id_empleado="+id);
        $('#edit').modal('show');
    });

    var tabla_Props =  { 
                    paging: {
                          results_per_page: ['Registros por pagina: ', [5, 10, 25, 50, 100]]
                        },
                    col_2: "select", 
                    col_3: "select", 
                    col_5: "select",
                    col_6: 'select',
                    col_7: 'select',
                    col_8: 'none',
                    col_9: 'none',
                    col_10:'none',
                    col_11:'none',
                    col_12:'none',
                    col_13:'none',
                    rows_counter: true,
                    rows_counter_text: "Registros:", 
                    col_widths: [
            "35px", //id
            "70px", //cedula
            "120px", //1er Nombre
            "120px", //1er Apellido
            "180px",  //Email
            "150px",  //Depto u Oficina
            "80px", //Estatus
            "80px", //Cargo
            "80px",
            "80px",        
            "80px",
            "80px"                            
        ],
                }; 
var tf = new TableFilter('empleados',tabla_Props);
tf.init();
</script>