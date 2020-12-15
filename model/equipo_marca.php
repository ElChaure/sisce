<?php
session_start();
class Equipo_marca
{
	private $pdo;

	public $id;
	public $id_equipo;
	public $id_marca;


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

			$stm = $this->pdo->prepare("SELECT * FROM equipo_marca  WHERE active IS NOT FALSE ORDER BY id");
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
			          ->prepare("SELECT * FROM equipo_marca WHERE id = ?");
			          

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
			            ->prepare("UPDATE equipo_marca 
			            	       SET active=FALSE, 
			            	       fecha_elim=NOW(), 
			            	       usr_id=".$_SESSION['uid']." WHERE id = ?");

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
			$sql = "UPDATE equipo_marca
   					SET id_equipo=?, id_marca=?
				    WHERE id = ?";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(
                        $data->id_equipo,
                        $data->id_marca,
                        $data->id 
					)
				);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Registrar(equipo_marca $data)
	{
		try 
		{
		$sql = "INSERT INTO equipo_marca(id, id_equipo, id_marca)
    			VALUES (?, ?, ?)";

		$this->pdo->prepare($sql)
		     ->execute(
				array(
                        $data->id, 
                        $data->id_equipo,
                        $data->id_marca
			);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}
}