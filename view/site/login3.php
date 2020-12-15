<?php
   ob_start();
   session_start();
   require_once 'model/usuario.php';
   $errorMsgLogin='';
?>

<?
   // error_reporting(E_ALL);
   // ini_set("display_errors", 1);
?>

<html lang = "es">
   
   <head>
      <title>Sistema de Control de Equipos Telematicos</title>
	  
      
      <style>
	  #login,#signup{
	  	margin-top: 20px;
	  	margin-left: : 120px;
		width: 300px; border: 1px solid #d6d7da; 
		padding: 0px 15px 15px 15px; 
		border-radius: 5px;font-family: arial; 
		line-height: 16px;color: #333333; font-size: 14px; 
		background: #ffffff;rgba(200,200,200,0.7) 0 4px 10px -1px
		}
		#login{float:left;}
		#signup{float:right;}
		h3{color:#365D98}
		form label{font-weight: bold;}
		form label, form input{display: block;margin-bottom: 5px;width: 90%}
		form input{ 
		border: solid 1px #666666;padding: 10px;
		border: solid 1px #BDC7D8; margin-bottom: 20px
		}
		.button {
		background-color: #5fcf80 ;
		border-color: #3ac162;
		font-weight: bold;
		padding: 12px 15px;
		max-width: 100px;
		color: #ffffff;
		}
        .errorMsg{color: #cc0000;margin-bottom: 10px;}
      </style>

  <script>
$(document).ready(function () {

        //when the page is done loading, disable autocomplete on all inputs[text]
        $('input[type="text"]').attr('autocomplete', 'off');

        //do the same when a bootstrap modal dialog is opened
        $(window).on('shown.bs.modal', function () {
            $('input[type="text"]').attr('autocomplete', 'off');
        });
});

    
  function comprobarUsuario() {
    $("#loaderIcon").show();
    jQuery.ajax({
    url: "view/site/comprobarusuario.php",
    data:'username='+$("#userInput").val(),
    type: "POST",
    success:function(data){
      $("#estadousuario").html(data);
      $("#loaderIcon").hide();
      if($("span").hasClass("estado-no-registrado-usuario")){
        $('#userInput').focus();
      }
      if($("span").hasClass("estado-ingresado-usuario")){
        $('#userInput').focus();
      }
    },
    error:function (){}
    });
  }
</script>


      
   </head>
	
<body>
<div class="form-group">
                                    	  
<div id="login">
<h3>Login</h3>
<form method="post" action="" name="login">
<label>Usuario o Correo</label>

<div class="input-group"> <span class="input-group-addon"><i class="glyphicon glyphicon-user color-blue"></i></span>
   <input type="text" name="username" autocomplete="off" id="userInput"  onBlur="comprobarUsuario()" class="form-control" />
   
</div>
</br>
  <span id="estadousuario"></span> 
  <p><img src="assets/img/loader.gif" id="loaderIcon" style="display:none" /></p>
</br>


<label>Clave</label>
<div class="input-group"> <span class="input-group-addon"><i class="glyphicon glyphicon-lock color-blue"></i></span>
   <input type="password" name="password" autocomplete="off" id="passwordInput" class="form-control"/>
</div>
<div class="errorMsg"><?php 
//echo $GLOBALS['ingreso']; 
$mens=$GLOBALS['ingreso'];
//echo $mens;
echo "<script type=\"text/javascript\">alert(\"".$mens."\");</script>";
?></div>
<input type="submit" class="button" name="loginSubmit" value="Ingresar">
</form>
</div>
<p> 
<img src="assets/img/collage1.jpg" align="right">
</p>
</div>
 </body>
</html>



