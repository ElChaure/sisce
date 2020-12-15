<script src="assets/js/tablefilter/dist/tablefilter/tablefilter.js"></script>
<link rel="stylesheet" type="text/css" href="assets/js/tablefilter/dist/tablefilter/style/filtergrid.css" media="screen"/>
<link rel="stylesheet" href="assets/css/tablefilter.css">
<ol class="breadcrumb">
  <a class="btn btn-warning" href="?c=site&a=index">Inicio</a>
</ol>
<h1 class="page-header">Articulos</h1>

<div class="well well-sm text-right">
    <a class="btn btn-primary" href="?c=Articulo&a=Crud">Nuevo Articulo</a>
</div>
<table class="table table-striped" id="articulo">
    <thead>
        <tr>
            <th>Id</th>
            <th>Nombre</th>
            <th>Codigo SNC</th>
            <th></th>
            <th></th>
        </tr>
    </thead>
    <tbody>
    <?php foreach($this->model->Listar() as $r): ?>
        <tr>
            <td><?php echo $r->id_articulo; ?></td>
            <td><?php echo $r->articulo; ?></td>
            <td><?php echo $r->codigo_snc; ?></td>
            <td>
                <a class="btn btn-info"  href="?c=Articulo&a=Crud&id_articulo=<?php echo $r->id_articulo; ?>">Editar</a>
            </td>
            <td>
                <a class="btn btn-warning"  onclick="javascript:return confirm('¿Seguro de eliminar este registro?');" href="?c=Articulo&a=Eliminar&id_articulo=<?php echo $r->id_articulo; ?>">Eliminar</a>
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
                    col_3:'select',
                    col_3:'none',
                    col_4:'none',
                    rows_counter: true,
                    rows_counter_text: "Registros:", 
                    col_widths: [
            "60px", //id
            "820px", //1er Nombre
            "100px",  
            "80px",        
            "80px"                            
        ],
                }; 
var tf = new TableFilter('articulo',tabla_Props);
tf.init();
</script>