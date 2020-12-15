<?php
session_start();
class Almacen
{
	private $pdo;

	public $id_almacen;
	public $id_equipo;
	public $fecha_entrada;
	public $fecha_despacho;
	public $telefono;
	public $stock;


	public function __CONSTRUCT()
	{
		try
		{
			$this->pdo = Database::StartUp();     
		}
		catch(Exception $e)
		{
			die($e->getMessage());
		}
	}

	public function Listar()
	{
		try
		{
			$result = array();

			$stm = $this->pdo->prepare("SELECT * FROM almacen  WHERE active IS NOT FALSE ORDER BY id_almacen");
			$stm->execute();

			return $stm->fetchAll(PDO::FETCH_OBJ);
		}
		catch(Exception $e)
		{
			die($e->getMessage());
		}
	}

	public function Obtener($id)
	{
		try 
		{
			$stm = $this->pdo
			          ->prepare("SELECT * FROM almacen WHERE id_almacen = ?");
			          

			$stm->execute(array($id));
			return $stm->fetch(PDO::FETCH_OBJ);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Eliminar($id)
	{
		try 
		{
		          

 			$stm = $this->pdo
			            ->prepare("UPDATE almacen 
			            	       SET active=FALSE, 
			            	       fecha_elim=NOW(), 
			            	       usr_id=".$_SESSION['uid']." WHERE id_almacen = ?");

			$stm->execute(array($id));
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Actualizar($data)
	{
		
		
		try 
		{
			$sql = "UPDATE almacen SET 
					id_equipo=?, 
					fecha_entrada=?, 
					fecha_despacho=?, 
					telefono=?, 
					stock=?
				    WHERE id_almacen = ?";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(
                        $data->id_equipo,
                        $data->fecha_entrada,
                        $data->fecha_despacho,
                        $data->telefono,
                        $data->stock,
                        $data->id_almacen
					)
				);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Registrar(almacen $data)
	{
		try 
		{
		$sql = "INSERT INTO almacen(id_equipo, fecha_entrada, fecha_despacho, telefono,stock)
    			VALUES (?, ?, ?, ?,?)";

		$this->pdo->prepare($sql)
		     ->execute(
				array(
                        //$data->id_almacen, 
                        $data->id_equipo,
                        $data->fecha_entrada,
                        $data->fecha_despacho,
                        $data->telefono,
                        $data->stock                )
			);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}
}