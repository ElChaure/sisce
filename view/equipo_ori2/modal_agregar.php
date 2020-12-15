<head>
    <!--link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/css/bootstrap.min.css" /-->
    <link data-require="select2@*" data-semver="3.5.1" rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/select2/3.5.2/select2.css" />
    <link data-require="select2@*" data-semver="3.5.1" rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/select2/3.5.2/select2-bootstrap.css" />
    <link rel="stylesheet" href="style.css" />
    <!--script data-require="jquery@2.1.3" data-semver="2.1.3" src="https://code.jquery.com/jquery-2.1.3.min.js"></script-->
    <script data-require="select2@*" data-semver="3.5.1" src="https://cdnjs.cloudflare.com/ajax/libs/select2/3.5.2/select2.js"></script>
    <script data-require="lodash.js@*" data-semver="2.4.1" src="http://cdnjs.cloudflare.com/ajax/libs/lodash.js/2.4.1/lodash.js"></script>
  </head>
<form id="guardarDatos">
<div class="modal fade" id="dataRegister" tabindex="-1" role="dialog" aria-labelledby="exampleModalLabel">
  <div class="modal-dialog" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
        <h4 class="modal-title" id="exampleModalLabel">Agregar Equipo o Bien</h4>
      </div>
      <div class="modal-body">
			<div id="datos_ajax_register"></div>
          <div class="form-group">
            <label for="id_equipo0" class="control-label">Id:</label>
            <input type="text" class="form-control" id="id_equipo0" name="id_equipo" required maxlength="2">
	  </div>

	   <div class="form-group">
            <label for="cod_equipo0" class="control-label">Codigo Equipo o Bien:</label>
            <input type="text" class="form-control" id="cod_equipo0" name="cod_equipo" required maxlength="45">
          </div>

	  <div class="form-group">
            <label for="serial0" class="control-label">Serial:</label>
            <input type="text" class="form-control" id="serial0" name="serial" required maxlength="3">
          </div>

	  <div class="form-group">
            <label for="id_estatus0" class="control-label">id_estatus:</label>
            <!--input type="text" class="form-control" id="id_estatus0" name="id_estatus" required maxlength="30"--> 
            <input type="hidden" class="js-data-example-ajax form-control" />
          </div>



	  <div class="form-group">
            <label for="id_ubicacion0" class="control-label">id_ubicacion:</label>
            <input type="text" class="form-control" id="id_ubicacion0" name="id_ubicacion" required maxlength="15">
          </div>
          
        
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-default" data-dismiss="modal">Cerrar</button>
        <button type="submit" class="btn btn-primary">Guardar datos</button>
      </div>
    </div>
  </div>
</div>
</form>
<script>
$(".js-data-example-ajax").select2({
  ajax: {
    url: "http://geocode-maps.yandex.ru/1.x/",
    dataType: 'json',
    delay: 250,
    data: function (query) {
      if (!query) query = 'Москва';
      
      return {
        geocode: query,
        format: 'json'
      };
    },
    results: function (data) {
      var parsed = [];
      
      try {
        parsed = _.chain(data.response.GeoObjectCollection.featureMember)
          .pluck('GeoObject')
          .map(function (item, index) {
            return {
              id: index,
              text: item.name
            };
          })
          .value();
      } catch (e) { }
      
      return {
        results: parsed
      };
    },
    cache: true
  }
});
</script>