<?php
session_start();
class Tipo_solicitud
{
	private $pdo;

	public $id_tipo_solicitud;
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

			$stm = $this->pdo->prepare("SELECT * FROM tipo_solicitud  WHERE active IS NOT FALSE ORDER BY id_tipo_solicitud");
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
			          ->prepare("SELECT * FROM tipo_solicitud WHERE id_tipo_solicitud = ?");
			          

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
			            ->prepare("UPDATE tipo_solicitud 
			            	       SET active=FALSE, 
			            	       fecha_elim=NOW(), 
			            	       usr_id=".$_SESSION['uid']." WHERE id_tipo_solicitud = ?");

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
			$sql = "UPDATE tipo_solicitud SET 
					descripcion=?
				    WHERE id_tipo_solicitud = ?";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(
                        $data->descripcion,
                        $data->id_tipo_solicitud
					)
				);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Registrar(tipo_solicitud $data)
	{
		try 
		{
		$sql = "INSERT INTO tipo_solicitud(descripcion)
    			VALUES (?)";

		$this->pdo->prepare($sql)
		     ->execute(
				array(
                        //$data->id_tipo_solicitud, 
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
		$stmt = $this->pdo->query("
			SELECT id_tipo_solicitud AS id,descripcion AS text FROM tipo_solicitud WHERE active IS NOT FALSE ORDER BY id");		
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