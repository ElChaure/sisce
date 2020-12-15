	function load(page){
		var parametros = {"action":"ajax","page":page};
		$("#loader").fadeIn('slow');
		$.ajax({
			url:'view/equipo/equipo_ajax.php',
			data: parametros,
			 beforeSend: function(objeto){
			$("#loader").html("<img src='assets/img/loader.gif'>");
			},
			success:function(data){
				$(".outer_div").html(data).fadeIn('slow');
				$("#loader").html("");
			}
		})
	}


            
		$('#dataUpdate').on('show.bs.modal', function (event) {
		  var button = $(event.relatedTarget) // Botón que activó el modal
		  var id_equipo = button.data('id_equipo') // Extraer la información de atributos de datos
		  var cod_equipo = button.data('cod_equipo') // Extraer la información de atributos de datos
		  var serial = button.data('serial') // Extraer la información de atributos de datos
		  var id_estatus = button.data('id_estatus') // Extraer la información de atributos de datos
		  var id_ubicacion = button.data('id_ubicacion') // Extraer la información de atributos de datos
		  var num_bien_nac = button.data('num_bien_nac') // Extraer la información de atributos de datos
		  var descripcion = button.data('descripcion') // Extraer la información de atributos de datos
		  var num_factura = button.data('num_factura') // Extraer la información de atributos de datos
		  var fecha_factura = button.data('fecha_factura') // Extraer la información de atributos de datos
		  var id_proveedor = button.data('id_proveedor') // Extraer la información de atributos de datos
		  var valor = button.data('valor') // Extraer la información de atributos de datos
		  
		  var modal = $(this)
		  modal.find('.modal-title').text('Modificar Equipo o Bien: '+descripcion)
		  modal.find('.modal-body #id_equipo').val(id_equipo)
		  modal.find('.modal-body #cod_equipo').val(cod_equipo)
		  modal.find('.modal-body #serial').val(serial)
		  modal.find('.modal-body #id_estatus').val(id_estatus)
		  modal.find('.modal-body #id_ubicacion').val(id_ubicacion)
		  modal.find('.modal-body #num_bien_nac').val(num_bien_nac)
		  modal.find('.modal-body #descripcion').val(descripcion)
		  modal.find('.modal-body #num_factura').val(num_factura)
		  modal.find('.modal-body #fecha_factura').val(fecha_factura)
		  modal.find('.modal-body #id_proveedor').val(id_proveedor)
		  modal.find('.modal-body #valor').val(valor)



		  $('.alert').hide();//Oculto alert
		})
		
		$('#dataDelete').on('show.bs.modal', function (event) {
		  var button = $(event.relatedTarget) // Botón que activó el modal
		  var id = button.data('id') // Extraer la información de atributos de datos
		  var modal = $(this)
		  modal.find('#id_equipo').val(id)
		})

	$( "#actualidarDatos" ).submit(function( event ) {
		var parametros = $(this).serialize();
			 $.ajax({
					type: "POST",
					url: "modificar.php",
					data: parametros,
					 beforeSend: function(objeto){
						$("#datos_ajax").html("Mensaje: Cargando...");
					  },
					success: function(datos){
					$("#datos_ajax").html(datos);
					
					load(1);
				  }
			});
		  event.preventDefault();
		});
		
		$( "#guardarDatos" ).submit(function( event ) {
		var parametros = $(this).serialize();
			 $.ajax({
					type: "POST",
					url: "agregar.php",
					data: parametros,
					 beforeSend: function(objeto){
						$("#datos_ajax_register").html("Mensaje: Cargando...");
					  },
					success: function(datos){
					$("#datos_ajax_register").html(datos);
					
					load(1);
				  }
			});
		  event.preventDefault();
		});
		
		$( "#eliminarDatos" ).submit(function( event ) {
		var parametros = $(this).serialize();
			 $.ajax({
					type: "POST",
					url: "eliminar.php",
					data: parametros,
					 beforeSend: function(objeto){
						$(".datos_ajax_delete").html("Mensaje: Cargando...");
					  },
					success: function(datos){
					$(".datos_ajax_delete").html(datos);
					
					$('#dataDelete').modal('hide');
					load(1);
				  }
			});
		  event.preventDefault();
		});
