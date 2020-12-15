<link rel="stylesheet" href="dist/bootstrap.min.css" type="text/css" media="all">
<link href="dist/jquery.bootgrid.css" rel="stylesheet" />
<script src="dist/jquery-1.11.1.min.js"></script>
<script src="dist/bootstrap.min.js"></script>
<script src="dist/jquery.bootgrid.min.js"></script>

<table id="employee_grid" class="table table-condensed table-hover table-striped" width="100%" cellspacing="0" data-toggle="bootgrid">
            <thead>
                <tr>
                    <th data-column-id="id" data-type="numeric">Id</th>
                    <th data-column-id="nombres">Nombres</th>
                    <th data-column-id="email">Email</th>
                    <th data-column-id="id_rol">Rol</th>
                </tr>
            </thead>
        </table>

<script>
$("#employee_grid").bootgrid({
        ajax: true,
        post: function ()
        {
            /* To accumulate custom parameter with the request object */
            return {
                id: "b0df282a-0d67-40e5-8558-c9e93b7befed"
            };
        },
        url: "?c=Usuario&a=listar_ajax",
        formatters: {
            
        }
   });
</script>>