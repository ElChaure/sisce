<?php
session_start();
class Modelo
{
	private $pdo;

	public $id_modelo;
	public $id_equipo;
	public $id_marca;
	public $descripcion;



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

			$stm = $this->pdo->prepare("SELECT * FROM modelo  WHERE active IS NOT FALSE ORDER BY id_modelo");
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
			          ->prepare("SELECT * FROM modelo WHERE id_modelo = ?");
			          

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
			            ->prepare("UPDATE modelo 
			            	       SET active=FALSE, 
			            	       fecha_elim=NOW(), 
			            	       usr_id=".$_SESSION['uid']." WHERE id_modelo = ?");

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
			$sql = "UPDATE modelo SET id_equipo=?, id_marca=?, descripcion=?
				    WHERE id_modelo = ?";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(
						$data->id_equipo, 
						$data->id_marca, 
						$data->descripcion,
                        $data->id_modelo
					)
				);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Registrar(marca $data)
	{
		try 
		{
		$sql = "INSERT INTO marca(id_modelo, id_equipo, id_marca, descripcion)
    			VALUES (?, ?, ?, ?)";

		$this->pdo->prepare($sql)
		     ->execute(
				array(
                        $data->id_modelo,
						$data->id_equipo, 
						$data->id_marca, 
						$data->descripcion
                    )
			);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}
}