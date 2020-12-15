<?php
session_start();
class Database
{
    public static function StartUp()
    {
	$pdo_options[PDO::ATTR_ERRMODE]=PDO::ERRMODE_EXCEPTION;
        $pdo = new PDO('pgsql:host=localhost;dbname=bd_inventario','postgres','123456',$pdo_options);
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);	
        return $pdo;
    }

    public static function StartUp_saime()
    {
	$pdo_options[PDO::ATTR_ERRMODE]=PDO::ERRMODE_EXCEPTION;
        $pdo_saime = new PDO('pgsql:host=192.168.250.14;dbname=saime','postgres','123456',$pdo_options);
        $pdo_saime->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        return $pdo_saime;	
    }       

}
