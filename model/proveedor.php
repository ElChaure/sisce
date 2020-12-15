<?php
session_start();
class Proveedor
{
	private $pdo;

	public $id_proveedor;
	public $nombre_prov;
	public $direccion;
	public $telefono;
	public $apellido_prov;

	

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

			$stm = $this->pdo->prepare("SELECT * FROM proveedor  WHERE active IS NOT FALSE ORDER BY id_proveedor");
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
			          ->prepare("SELECT * FROM proveedor WHERE id_proveedor = ?");
			          

			$stm->execute(array($id));
			return $stm->fetch(PDO::FETCH_OBJ);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}


    public function Obtener_alfa($id)
	{
		try 
		{
			$stm = $this->pdo
			          ->prepare("SELECT id_proveedor,nombre_prov||' '||apellido_prov AS nombres,direccion,telefono FROM proveedor WHERE id_proveedor = ?");
			          

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
			            ->prepare("UPDATE proveedor 
			            	       SET active=FALSE, 
			            	       fecha_elim=NOW(), 
			            	       usr_id=".$_SESSION['uid']." WHERE id_proveedor = ?");	

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
			$sql = "UPDATE proveedor SET nombre_prov=?, direccion=?, telefono=?, apellido_prov=?
				    WHERE id_proveedor = ?";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(
                        $data->nombre_prov, 
                        $data->direccion, 
                        $data->telefono, 
                        $data->apellido_prov,
						$data->id_proveedor
					)
				);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Registrar(proveedor $data)
	{
		try 
		{
		$sql = "INSERT INTO proveedor(nombre_prov, direccion, telefono, apellido_prov)
    			VALUES (?, ?, ?, ?)";

		$this->pdo->prepare($sql)
		     ->execute(
				array(
                        //$data->id_proveedor,
                        $data->nombre_prov, 
                        $data->direccion, 
                        $data->telefono, 
                        $data->apellido_prov
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
			SELECT id_proveedor AS id,nombre_prov||' '||apellido_prov AS text FROM proveedor WHERE active IS NOT FALSE ORDER BY id");		
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