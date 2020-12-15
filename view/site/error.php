<?php



?>

<div style="text-align:center; width:350px; float:left;"><img style=""src="<?php echo Yii::app()->request->baseUrl; ?>/images/error.png"/></div>
<div class="error-msg">
	<p style="text-align:center;">
		<?php 
		 if($code == 403){?>
		 	<div style=" margin-top: 12%;color:red; font-size:48px; font-family: Arial Black;">ACCESO DENEGADO</div> 
		 	<br/>
		<?php
		echo "Lo sentimos, la sesión ha expirado o no dispone de los privilegios necesarios para acceder 
			  a este Módulo del Sistema. <br /> <b>Contacte al Administrador.</b>";}

		else{
		echo "Lo sentimos, no es posible acceder o no se ha encontrado la dirección especificada. Verifique e Intente de Nuevo";}
		 ?>
	</p>
</div>
