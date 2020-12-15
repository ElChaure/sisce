<div id="dynamic">
<table cellpadding="0" cellspacing="0" border="0" class="display" id="dt_usuario">
    <thead>
        <tr>
            <th width="20%">Id</th>
            <th width="25%">Nombres</th>
            <th width="25%">Email</th>
            <th width="15%">Rol</th>
       </tr>
    </thead>
    <tbody>
        
    </tbody>
    <tfoot>
        <tr>
            <th>Id</th>
            <th>Nombres</th>
            <th>Email</th>
            <th>Roll</th>
        </tr>
    </tfoot>
</table>
</div>
<div class="spacer"></div>

<script type="text/javascript">
$(document).on("ready", function(){
         listar();
});

var listar = function(){
    var table = $("#dt_usuario").DataTable({
        listar();
    })
}


    /**********************************************************************************
    $(document).on("ready", function(){
         alert("En la funcion");
         listar();
    });

    var listar = function(){
        var table = $("#example").DataTable({
            "ajax":{
                "method":"POST",
                "url": "view/usuario/datos.php"
            },
            "columns":[
                {"data":"id"},
                {"data":"nombres"},                    
                {"data":"email"},
                {"data":"rol"}
            ],
            "language" : idioma_espaniol
        });
    };
    var idioma_espaniol = {
    "sProcessing":     "Procesando...",
    "sLengthMenu":     "Mostrar _MENU_ registros",
    "sZeroRecords":    "No se encontraron resultados",
    "sEmptyTable":     "Ningún dato disponible en esta tabla",
    "sInfo":           "Mostrando registros del _START_ al _END_ de un total de _TOTAL_ registros",
    "sInfoEmpty":      "Mostrando registros del 0 al 0 de un total de 0 registros",
    "sInfoFiltered":   "(filtrado de un total de _MAX_ registros)",
    "sInfoPostFix":    "",
    "sSearch":         "Buscar:",
    "sUrl":            "",
    "sInfoThousands":  ",",
    "sLoadingRecords": "Cargando...",
    "oPaginate": {
        "sFirst":    "Primero",
        "sLast":     "Último",
        "sNext":     "Siguiente",
        "sPrevious": "Anterior"
    },
    "oAria": {
        "sSortAscending":  ": Activar para ordenar la columna de manera ascendente",
        "sSortDescending": ": Activar para ordenar la columna de manera descendente"
    }
    }



$(document).ready(function() {

  alert("En la funcion....");

  $('#example').dataTable( {
    "bProcessing": true,
    "bServerSide": true,
    "sAjaxSource": "view/usuario/datos.php",
    "fnServerData": function ( sSource, aoData, fnCallback, oSettings ) {
      oSettings.jqXHR = $.ajax( {
        "dataType": 'json',
        "type": "POST",
        "url": sSource,
        "data": aoData,
        "success": fnCallback
      } );
    }
  } );
} );
*************************************/

</script>