<?php
    session_start();
    
?> 

<h1 class="page-header">Generación de Orden de Salida de Equipos</h1>

<a class="btn btn-info" href="?c=site">Inicio</a></br>



<table class="table table-striped">
    <thead>
        <tr>
            <th style="width:180px;">Id</th>
            <th>Funcionario</th>
            <th>Empleado Solicitante</th>
            <th style="width:120px;">Fecha Solicitud</th>
            <th style="width:120px;">Descripcion</th>
            <th style="width:60px;">Tipo Solicitud</th>
            <th style="width:60px;">Estatus</th>
            <th style="width:60px;"></th>
            
        </tr>
    </thead>
    <tbody>
    <?php foreach($this->model->Listar_sin_orden_salida() as $r): ?>
        <tr>
            <td><?php echo $r->id_solicitud; ?></td>
            <td><?php echo $r->funcionario; ?></td>
            <td><?php echo $r->empleado; ?></td>
            <td><?php echo $r->fecha_solicitud; ?></td>
            <td><?php echo $r->descripcion; ?></td>
            <td><?php echo $r->tipo_solicitud; ?></td>
            <td><?php echo $r->estatus_solicitud; ?></td>
             <td>
                <!--a class="btn btn-info" href="index.php?c=reportes&a=solicitud&id_solicitud=<?php echo $r->id_solicitud; ?>" target="_blank">Genera Orden de Salida</a-->
                <button class="btn btn-success btn-lg" id_solicitud=<?php echo $r->id_solicitud; ?> data-toggle="modal" data-target="#modalForm" >
                    Genera Orden de Salida
                </button>
            </td>            
        </tr>
    <?php endforeach; ?>
    </tbody>
</table> 

<!-- Modal -->
<div class="modal fade" id="modalForm" role="dialog">
    <div class="modal-dialog">
        <div class="modal-content">
            <!-- Modal Header -->
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal">
                    <span aria-hidden="true">×</span>
                    <span class="sr-only">Close</span>
                </button>
                <h4 class="modal-title" id="myModalLabel">Generacion de Orden de Salida de Solicitud: <?php echo $r->id_solicitud; ?></h4>
            </div>
            
            <!-- Modal Body -->
            <div class="modal-body">
                <p class="statusMsg"></p>
                <form role="form">
                    <div class="form-group">
                        <label for="inputObservacion">Observacion</label>
                        <textarea class="form-control" id="inputObservacion" placeholder="Ingrese sus Observaciones"></textarea>
                    </div>
                </form>
            </div>
            
            <!-- Modal Footer -->
            <div class="modal-footer">
                <button type="button" class="btn btn-default" data-dismiss="modal">Cancelar</button>
                <button type="button" class="btn btn-primary submitBtn" onclick="submitContactForm()">Enviar</button>
            </div>
        </div>
    </div>
</div>

