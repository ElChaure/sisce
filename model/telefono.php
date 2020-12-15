<?php
session_start();
class Telefono
{
	private $pdo;

	public $id_telefono;
	public $num_telefono;
	public $id_empleado;

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

			$stm = $this->pdo->prepare("SELECT * FROM telefono  WHERE active IS NOT FALSE ORDER BY id_telefono");
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
			          ->prepare("SELECT * FROM telefono WHERE id_telefono = ?");
			          

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
			            ->prepare("UPDATE telefono 
			            	       SET active=FALSE, 
			            	       fecha_elim=NOW(), 
			            	       usr_id=".$_SESSION['uid']." WHERE id_telefono = ?");

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
			$sql = "UPDATE telefono SET 
					num_telefono=?,
					id_empleado=?
				    WHERE id_telefono = ?";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(
                        $data->num_telefono,
                        $data->id_empleado,
						$data->id_telefono
					)
				);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Registrar(telefono $data)
	{
		try 
		{
		$sql = "INSERT INTO telefono(id_telefono, num_telefono, id_empleado)
    			VALUES (?, ?, ?)";

		$this->pdo->prepare($sql)
		     ->execute(
				array(
						$data->id_telefono,
                        $data->num_telefono,
                        $data->id_empleado
                    )
			);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}
}