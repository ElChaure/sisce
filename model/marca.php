<?php
session_start();
class Marca
{
	private $pdo;

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

			$stm = $this->pdo->prepare("SELECT * FROM marca  WHERE active IS NOT FALSE ORDER BY id_marca");
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
			          ->prepare("SELECT * FROM marca WHERE id_marca = ?");
			          

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
			            ->prepare("UPDATE marca 
			            	       SET active=FALSE, 
			            	       fecha_elim=NOW(), 
			            	       usr_id=".$_SESSION['uid']." WHERE id_marca = ?");


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
			$sql = "UPDATE marca SET 
					descripcion=?
				    WHERE id_marca = ?";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(
                        $data->descripcion,
                        $data->id_marca
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
		$sql = "INSERT INTO marca(descripcion)
    			VALUES (?)";

		$this->pdo->prepare($sql)
		     ->execute(
				array(
                        //$data->id_marca, 
                        $data->descripcion
                    )
			);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}


	public function Listar_json()
	{
		try
		{
		$stmt = $this->pdo->query("SELECT id_marca AS id,descripcion AS text FROM marca ORDER BY descripcion");
		$data = [];
		$data[] = [
            'id' => -1,
            'text' => ''
        ];
        while ($row = $stmt->fetch(\PDO::FETCH_ASSOC)) {
            $data[] = [
                'id' => $row['id'],
                'text' => $row['text']
            ];
        }
        $data = json_encode($data);
        return $data;
		}
		catch(Exception $e)
		{
			die($e->getMessage());
		}
	}


}