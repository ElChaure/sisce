<?php
session_start();
class Desincorporacion
{
	private $pdo;

	public $id_desincorporacion;
	public $id_motivo;
	public $fecha_desincorporacion;
	public $id_funcionario;
	public $observacion;
	public $id_equipo;
	public $id_empleado_notifica;

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

			$stm = $this->pdo->prepare("SELECT * FROM desincorporacion  WHERE active IS NOT FALSE ORDER BY id_desincorporacion DESC");
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
			          ->prepare("SELECT * FROM desincorporacion WHERE id_desincorporacion = ?");
			          

			$stm->execute(array($id));
			return $stm->fetch(PDO::FETCH_OBJ);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}


	public function Desincorporar($id_motivo, $observacion,$id_equipo, $id_empleado_notifica)
	{
		try 
		{
			$sql = "INSERT INTO desincorporacion (
					id_motivo,
					id_funcionario,
					observacion,
					id_equipo,
					id_empleado_notifica
				) 
			VALUES (?, ?, ?, ?, ?)";
			$this->pdo->prepare($sql)
			     ->execute(
				    array(
						$id_motivo,
						$_SESSION['uid'],
						$observacion,
						$id_equipo,
						$id_empleado_notifica
					)
				);

			$sql = "UPDATE equipo 
			            	       SET active=FALSE, 
			            	       fecha_elim=NOW(), 
			            	       usr_id=".$_SESSION['uid']." WHERE id_equipo = ?";

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
