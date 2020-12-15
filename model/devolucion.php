<?php
session_start();
class Devolucion
{
	private $pdo;

	public $id_devolucion;
	public $id_detalle_solicitud; 
	public $fecha_devolucion; 
	public $id_funcionario;
		

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

			$stm = $this->pdo->prepare("SELECT * FROM devolucion  WHERE active IS NOT FALSE ORDER BY id_devolucion DESC");
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
			          ->prepare("SELECT * FROM devolucion WHERE id_devolucion = ?");
			          

			$stm->execute(array($id));
			return $stm->fetch(PDO::FETCH_OBJ);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}


	public function Devolver($id_empleado_entrega, $id_equipo, $observacion)
	{
		
		
		try 
		{
			


			$sql = "INSERT INTO devolucion (id_solicitud_detalle,fecha_devolucion,id_funcionario,observacion,id_equipo,id_empleado_entrega) 
			VALUES (?, ?, ?, ?, ?, ?)";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(
						1,
						date('d-m-Y'),
						$_SESSION['uid'],
						$observacion,
						$id_equipo,
						$id_empleado_entrega

					)
				);


//var_dump($id_solicitud);
//var_dump(intval($id_equipo));
//var_dump(intval($_SESSION['uid']));
//var_dump($observacion);
//var_dump($id_empleado_entrega);
//die();

			   

			$sql = "UPDATE equipo SET id_estatus=5, id_ubicacion=1, id_solicitud_detalle_reserva=0,id_oficina=1, id_departamento=1 
			WHERE id_equipo=?";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(
						$id_equipo
					)
				);     
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}


	public function Obtener_devoluciones($fecha_devolucion,$id_empleado_entrega)
	{
		try
		{
			$result = array();

			$stm = $this->pdo->prepare("SELECT * FROM equipos_devueltos WHERE 
					  fecha_devolucion=? AND
					  id_empleado_entrega = ?");
			$stm->execute(array(
				$fecha_devolucion,
				$id_empleado_entrega
			));

			return $stm->fetchAll(PDO::FETCH_OBJ);
		}
		catch(Exception $e)
		{
			die($e->getMessage());
		}
	}


}
