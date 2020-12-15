<script src="assets/js/tablefilter/dist/tablefilter/tablefilter.js"></script>
<link rel="stylesheet" type="text/css" href="assets/js/tablefilter/dist/tablefilter/style/filtergrid.css" media="screen"/>
<link rel="stylesheet" href="assets/css/tablefilter.css">
<ol class="breadcrumb">
  <a class="btn btn-warning" href="?c=site&a=index">Inicio</a>
</ol>
<h1 class="page-header">Marcas</h1>

<div class="well well-sm text-right">
    <a class="btn btn-primary" href="?c=Marca&a=Crud">Nueva Marca</a>
</div>

<table class="table table-striped" id="marca">
    <thead>
        <tr>
            <th>Id</th>
            <th>Descripcion</th>
            <th></th>
            <th></th>
        </tr>
    </thead>
    <tbody>
    <?php foreach($this->model->Listar() as $r): ?>
        <tr>
            <td><?php echo $r->id_marca; ?></td>
            <td><?php echo $r->descripcion; ?></td>
            <td>
                <a  class="btn btn-info" href="?c=Marca&a=Crud&id_marca=<?php echo $r->id_marca; ?>">Editar</a>
            </td>
            <td>
                <a  class="btn btn-warning" onclick="javascript:return confirm('¿Seguro de eliminar este registro?');" href="?c=Marca&a=Eliminar&id_marca=<?php echo $r->id_marca; ?>">Eliminar</a>
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
                    col_2:'none',
                    col_3:'none',
                    rows_counter: true,
                    rows_counter_text: "Registros:", 
                    col_widths: [
            "35px", //id
            "944px", //1er Nombre
            "80px",        
            "80px"                            
        ],
                }; 
var tf = new TableFilter('marca',tabla_Props);
tf.init();
</script>
