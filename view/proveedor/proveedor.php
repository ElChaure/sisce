<script src="assets/js/tablefilter/dist/tablefilter/tablefilter.js"></script>
<link rel="stylesheet" type="text/css" href="assets/js/tablefilter/dist/tablefilter/style/filtergrid.css" media="screen"/>
<link rel="stylesheet" href="assets/css/tablefilter.css">
<ol class="breadcrumb">
  <a class="btn btn-warning" href="?c=site&a=index">Inicio</a>
</ol>
<h1 class="page-header">Proveedores</h1>

<div class="well well-sm text-right">
    <a class="btn btn-primary" href="?c=Proveedor&a=Crud">Nuevo Proveedor</a>
</div>

<table class="table table-striped" id="proveedores">
    <thead>
        <tr>
            <th>Id</th>
            <th>Nombres</th>
            <th>Apellidos</th>
            <th>Direccion</th>
            <th>Telefono</th>            
            <th></th>
            <th></th>
        </tr>
    </thead>
    <tbody>
    <?php foreach($this->model->Listar() as $r): ?>
        <tr>
            <td><?php echo $r->id_proveedor; ?></td>
            <td><?php echo $r->nombre_prov; ?></td>
            <td><?php echo $r->apellido_prov; ?></td>
            <td><?php echo $r->direccion; ?></td>
            <td><?php echo $r->telefono; ?></td>
            <td>
                <a  class="btn btn-info" href="?c=Proveedor&a=Crud&id_proveedor=<?php echo $r->id_proveedor; ?>">Editar</a>
            </td>
            <td>
                <a  class="btn btn-warning" onclick="javascript:return confirm('¿Seguro de eliminar este registro?');" href="?c=Proveedor&a=Eliminar&id_proveedor=<?php echo $r->id_proveedor; ?>">Eliminar</a>
            </td>
        </tr>
    <?php endforeach; ?>
    </tbody>
</table> 
<script  type="text/javascript">
var tabla_Props =  { 
                    paging: {
                          results_per_page: ['Registros por pagina: ', [5, 10, 25, 50, 100]]
                        },
                    col_1:'select', 
                    col_2:'select',
                    //col_3:'none',
                    //col_4:'none',
                    col_5:'none',
                    col_6:'none',
                    rows_counter: true,
                    rows_counter_text: "Registros:", 
                    col_widths: [
            "35px", //id
            "250px", //1er Nombre
            "250px", //1er Apellido
            "350px",  
            "100px",   
            "80px",     
            "80px"                            
        ],
                }; 
var tf = new TableFilter('proveedores',tabla_Props);
tf.init();
        </script>