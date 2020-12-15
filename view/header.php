<!DOCTYPE html>
<html lang="es">
	<head>
		    <title>Sistema de Control de Equipos Telematicos</title>
        <meta charset="utf-8" />
        <script src="assets/js/jquery.js"></script>
		<script src="assets/js/jquery.browser.min.js"></script>
		<script src="assets/js/jquery.browser.js"></script>
        <script src="assets/js/jquery.bootpag.min.js"></script>
        <script src="assets/js/jquery.anexsoft-validator.js"></script>
        <script src="assets/js/jquery.dataTables.js"></script>
        <script src="assets/js/jquery.dataTables.min.js"></script>
        <script src="assets/js/bootstrap.min.js"></script>
        <script src="assets/js/ini.js"></script>
        <script src="assets/js/jszip.min.js"></script>
        <script src="assets/js/pdfmake.min.js"></script>
        <script src="assets/js/vfs_fonts.js"></script>
	      <script src="assets/js/jquery-ui/jquery-ui.min.js"></script>
        <script src="assets/js/input-number-format.jquery.js"></script>



	<script src="assets/js/select2.min.js"></script>
	<script src="assets/js/select2.js"></script>
	<script src="assets/js/select2.full.min.js"></script>
	<script src="assets/js/select2.full.js"></script>
  
        <!--Librerias para botones de exportación-->
        <!--<script src="assets/js/buttons.html5.min.js"></script>-->
      


         <link rel="stylesheet" href="assets/css/bootstrap.css">
        <link rel="stylesheet" href="assets/css/bootstrap.min.css">
        <link rel="stylesheet" href="assets/css/bootstrap-theme.css">
        <link rel="stylesheet" href="assets/css/bootstrap-theme.min.css">
        <link rel="stylesheet" href="assets/css/site.css">
        <link rel="stylesheet" href="assets/font-awesome-4.7.0/css/font-awesome.min.css">
	<link rel="stylesheet" href="assets/js/jquery-ui/jquery-ui.min.css">

	<!--link rel="stylesheet" href="assets/css/select2-bootstrap.css"-->
	<!--link rel="stylesheet" href="assets/css/select2-bootstrap.min.css"-->
	<!--link rel="stylesheet" href="assets/css/select2-bootstrap3.css"-->
	<link rel="stylesheet" href="assets/css/select2.css">
	<link rel="stylesheet" href="assets/css/select2-bootstrap.css">
  
        
        <script>
            // init bootpag
            $('#show_paginator').bootpag({
      total: 23,
      page: 3,
      maxVisible: 10
}).on('page', function(event, num)
{
     $("#dynamic_content").html("Page " + num); // or some ajax content loading...
});
        </script>


        
	</head>
	<header>
       <a href="?c=Site">
       <img src="assets/img/gobierno.png">
     </a>
    </header>
	<div class="banda">
      <span class="caja"><h1><center>Sistema de Control de Equipos Telematicos</h1></center></span>
  </div>
  <a href="?c=Site">
     <span class="logo"><img src="assets/img/logo.png" width="150" height="75"></span>
  </a>
  <body>
        
    <div class="container">
