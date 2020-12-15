<?php
    # conectare la base de datos
        require_once 'model/equipo.php';
        $equ = new Equipo();

	$action = (isset($_REQUEST['action'])&& $_REQUEST['action'] !=NULL)?$_REQUEST['action']:'';
	if($action == 'ajax'){
		include 'pagination.php'; //incluir el archivo de paginación
		//las variables de paginación
		$page = (isset($_REQUEST['page']) && !empty($_REQUEST['page']))?$_REQUEST['page']:1;
		$per_page = 10; //la cantidad de registros que desea mostrar
		$adjacents  = 4; //brecha entre páginas después de varios adyacentes
		$offset = ($page - 1) * $per_page;
                
		//Cuenta el número total de filas de la tabla*/
		$numrows = $equ->contar;
                echo $numrows;
		$total_pages = ceil($numrows/$per_page);
		$reload = 'equipo.php';
		//consulta principal para recuperar los datos
		//$query = mysqli_query($con,"SELECT * FROM countries  order by countryName LIMIT $offset,$per_page");
		
		if ($numrows>0){
			?>
		<table class="table table-bordered">
			  <thead>
        <tr>
            <th style="width:20px;">Id</th>
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
        </tr>
    </thead>
			<tbody>
	<?php foreach($equ->Listar() as $r): ?>
        <tr>
            <td><?php echo $r->id_equipo; ?></td>
            <td><?php echo $r->cod_equipo; ?></td>
            <td><?php echo $r->serial; ?></td>
            <td><?php echo $r->id_estatus; ?></td>
            <td><?php echo $r->id_ubicacion; ?></td>
            <td><?php echo $r->num_bien_nac; ?></td>
            <td><?php echo $r->descripcion; ?></td>
            <td><?php echo $r->num_factura; ?></td>
            <td><?php echo $r->fecha_factura; ?></td>
            <td><?php echo $r->id_proveedor; ?></td>
            <td><?php echo $r->valor; ?></td>
            <td>
		<button type="button" class="btn btn-info" data-toggle="modal" 
		 data-target="#dataUpdate" data-id_equipo="<?php echo $r->id_equipo; ?>" 
		 data-cod_equipo="<?php echo $r->cod_equipo; ?>" 
		 data-serial="<?php echo $r->serial; ?>" 
		 data-id_estatus="<?php echo $r->id_estatus; ?>" 
		 data-id_ubicacion="<?php echo $r->id_ubicacion; ?>" 
		 data-num_bien_nac="<?php echo $r->num_bien_nac; ?>"
		 data-descripcion="<?php echo $r->descripcion; ?>" 
		 data-num_factura="<?php echo $r->num_factura; ?>" 
		 data-fecha_factura="<?php echo $r->fecha_factura; ?>" 
		 data-id_proveedor="<?php echo $r->id_proveedor; ?>" 
		 data-valor="<?php echo $r->valor; ?>">
		 <i class='glyphicon glyphicon-edit'></i> Modificar</button>
		 <button type="button" class="btn btn-danger" 
		 data-toggle="modal" data-target="#dataDelete" 
		 data-id="<?php echo $row['id']?>"  >
		<i class='glyphicon glyphicon-trash'></i> Eliminar</button>
 	    </td>
	</tr>
	<?php
	  endforeach;
	?>
	</tbody>
		</table>
		<div class="table-pagination pull-right">
			<?php echo paginate($reload, $page, $total_pages, $adjacents);?>
		</div>
		
			<?php
			
		} else {
			?>
			<div class="alert alert-warning alert-dismissable">
              <button type="button" class="close" data-dismiss="alert" aria-hidden="true">&times;</button>
              <h4>Aviso!!!</h4> No hay datos para mostrar
            </div>
			<?php
		}
	}
?>