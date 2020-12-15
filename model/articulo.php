<?php
session_start();
class Articulo
{
	private $pdo;

	public $id_articulo;
	public $articulo;
	public $codigo_snc;
	

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

			$stm = $this->pdo->prepare("SELECT * FROM articulo  WHERE active IS NOT FALSE ORDER BY id_articulo");
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
			          ->prepare("SELECT * FROM articulo WHERE id_articulo = ?");
			          

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
			            ->prepare("UPDATE articulo 
			            	       SET active=FALSE, 
			            	       fecha_elim=NOW(), 
			            	       usr_id=".$_SESSION['uid']." WHERE id_articulo = ?");

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
			$sql = "UPDATE articulo SET 
					articulo=?, 
					codigo_snc=?
				    WHERE id_articulo = ?";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(
                        $data->articulo,
                        $data->codigo_snc,
                        $data->id_articulo
					)
				);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Registrar(articulo $data)
	{
		try 
		{
		$sql = "INSERT INTO articulo(articulo, codigo_snc)
    			VALUES (?, ?)";

		$this->pdo->prepare($sql)
		     ->execute(
				array(
                        //$data->id_articulo, 
                        $data->articulo,
                        $data->codigo_snc                )
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
		$stmt = $this->pdo->query("SELECT id_articulo AS id,articulo AS text FROM articulo  WHERE active IS NOT FALSE ORDER BY articulo");

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


/*
$data = $stmt->fetchAll(PDO::FETCH_ASSOC);
$salida = array();

while($fila = $stmt->fetch(PDO::FETCH_ASSOC))
    {
         $salida [0] = [
        "id"=>$fila['id'], 
        "text"=>$fila['text']
        ];  
    }
    $salida=json_encode($salida);
 return $salida;
 */
		}
		catch(Exception $e)
		{
			die($e->getMessage());
		}
	}

}