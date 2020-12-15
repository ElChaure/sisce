<?php
session_start();
class Reserva
{
	private $pdo;

	public $id_reserva;
	public $id_solicitud;
	public $fecha_reserva;
	public $observacion;
	public $id_equipo;

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

			$stm = $this->pdo->prepare("SELECT * FROM reserva  WHERE active IS NOT FALSE ORDER BY id_reserva");
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
			          ->prepare("SELECT * FROM reserva WHERE id_reserva = ?");
			          

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
			            ->prepare("UPDATE reserva 
			            	       SET active=FALSE, 
			            	       fecha_elim=NOW(), 
			            	       usr_id=".$_SESSION['uid']." WHERE id_reserva = ?");	


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
			$sql = "UPDATE reserva SET id_solicitud=?, fecha_reserva=?, observacion=?, id_equipo=?
				    WHERE id_reserva = ?";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(
                        $data->id_solicitud, 
                        $data->fecha_reserva, 
                        $data->observacion, 
                        $data->id_equipo,
                        $data->id_reserva
					)
				);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Registrar(reserva $data)
	{
		try 
		{
		$sql = "INSERT INTO reserva(id_reserva, id_solicitud, fecha_reserva, observacion, id_equipo)
    			VALUES (?, ?, ?, ?, ?)";

		$this->pdo->prepare($sql)
		     ->execute(
				array(
                        $data->id_reserva, 
                        $data->id_solicitud, 
                        $data->fecha_reserva, 
                        $data->observacion, 
                        $data->id_equipo
                    )
			);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}
}