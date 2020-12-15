<?php
session_start();
class Cancelacion
{
	private $pdo;

	public $id_cancelacion;
	public $id_detalle_solicitud; 
	public $fecha_cancelacion; 
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

			$stm = $this->pdo->prepare("SELECT * FROM cancelacion  WHERE active IS NOT FALSE ORDER BY id_cancelacion DESC");
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
			          ->prepare("SELECT * FROM cancelacion WHERE id_cancelacion = ?");
			          

			$stm->execute(array($id));
			return $stm->fetch(PDO::FETCH_OBJ);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}


	public function Cancelar($id_empleado_entrega, $id_equipo, $observacion)
	{
		
		
		try 
		{
			


			$sql = "INSERT INTO cancelacion (id_solicitud_detalle,fecha_cancelacion,id_funcionario,observacion,id_equipo,id_empleado_entrega) 
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


}
