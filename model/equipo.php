<?php
session_start();
class Equipo
{
	private $pdo;

	public $id_equipo;
	public $cod_equipo;
	public $serial;
	public $id_estatus;
	public $id_ubicacion;
	public $num_bien_nac;
	public $descripcion;
	public $num_factura;
	public $fecha_factura;
	public $id_proveedor;
    public $valor;
	public $id_articulo;
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

			$stm = $this->pdo->prepare("SELECT * FROM equipos  WHERE active IS NOT FALSE ORDER BY id_equipo");
			$stm->execute();

			return $stm->fetchAll(PDO::FETCH_OBJ);
		}
		catch(Exception $e)
		{
			die($e->getMessage());
		}
	}

	public function Listar_sin_bn()
	{
		try
		{
			$result = array();

			$stm = $this->pdo->prepare("SELECT * FROM equipos_sin_bn  ORDER BY id_equipo");
			$stm->execute();

			return $stm->fetchAll(PDO::FETCH_OBJ);
		}
		catch(Exception $e)
		{
			die($e->getMessage());
		}
	}

	public function Listar_disponibles()
	{
		try
		{
			$result = array();

			$stm = $this->pdo->prepare("SELECT * FROM equipos_disponibles  ORDER BY id_equipo");
			$stm->execute();

			return $stm->fetchAll(PDO::FETCH_OBJ);
		}
		catch(Exception $e)
		{
			die($e->getMessage());
		}
	}

	public function Listar_itinerantes()
	{
		try
		{
			$result = array();

			$stm = $this->pdo->prepare("SELECT * FROM equipos_itinerantes  ORDER BY id_equipo");
			$stm->execute();

			return $stm->fetchAll(PDO::FETCH_OBJ);
		}
		catch(Exception $e)
		{
			die($e->getMessage());
		}
	}

	public function Listar_reservados()
	{
		try
		{
			$result = array();

			$stm = $this->pdo->prepare("SELECT * FROM equipos_reservados  ORDER BY id_equipo");
			$stm->execute();

			return $stm->fetchAll(PDO::FETCH_OBJ);
		}
		catch(Exception $e)
		{
			die($e->getMessage());
		}
	}





    public function Contar()
	{
		try
		{
			$result = array();

			$stmt1= $this->pdo->query("SELECT count(id_equipo) FROM equipo WHERE active IS NOT FALSE");
                        $totalRecords = (int) $stmt1->fetchColumn(); 

			return $totalRecords;
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
			          ->prepare("SELECT * FROM equipo WHERE id_equipo = ?");
			          

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
			            ->prepare("UPDATE equipo 
			            	       SET active=FALSE, 
			            	       fecha_elim=NOW(), 
			            	       usr_id=".$_SESSION['uid']." WHERE id_equipo = ?");

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
			$sql = "UPDATE equipo SET cod_equipo=?, serial=?, descripcion=?, num_factura=?, fecha_factura=?, id_proveedor=?, valor=?, id_articulo=? , id_marca=?  
				    WHERE id_equipo = ?";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(

						$data->cod_equipo,
						$data->serial,
						//$data->id_estatus, 
						//$data->id_ubicacion, 
						//$data->num_bien_nac, 
						$data->descripcion, 
						$data->num_factura, 
						$data->fecha_factura, 
						$data->id_proveedor,
						$data->valor,
						$data->id_articulo,
						$data->id_marca,
						$data->id_equipo
					)
				);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

    public function Actualizarbn($data)
	{
		
		
		try 
		{
			$sql = "UPDATE equipo SET num_bien_nac=? WHERE id_equipo = ?";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(
						$data->num_bien_nac, 
						$data->id_equipo
					)
				);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}



	public function Registrar(equipo $data)
	{
		try 
		{
		$sql = "INSERT INTO equipo(cod_equipo, serial, id_estatus, id_ubicacion, descripcion, num_factura, fecha_factura, id_proveedor, valor,id_articulo, id_marca)    
		VALUES (?, ?, 5, 1, ?, ?, ?, ?, ?, ?, ?)";

		$this->pdo->prepare($sql)
		     ->execute(
				array(
						 //$data->id_equipo,
						$data->cod_equipo,
						$data->serial,
						//$data->id_estatus, 
						//$data->id_ubicacion, 
						//$data->num_bien_nac, 
						$data->descripcion, 
						$data->num_factura, 
						$data->fecha_factura, 
						$data->id_proveedor,
						$data->valor,
						$data->id_articulo,
   						$data->id_marca
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

		$result = array();	
		$stmt = $this->pdo->query("
			SELECT id_equipo AS id,descripcion AS text FROM equipo  WHERE active IS NOT FALSE ORDER BY id");		
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

	public function Listar_json2()
	{
		try
		{

		$result = array();	
		$stmt = $this->pdo->query("SELECT * FROM equipos  WHERE active IS NOT FALSE ORDER BY id_equipo");		
		$data = $stmt->fetchAll(PDO::FETCH_ASSOC);
		//$data = json_encode($data);


        
		//$result = "Result":"OK";
        $jTableResult = array();
		$jTableResult['Result'] = "OK";
		$jTableResult['Records'] = $data;
		print json_encode($jTableResult);
        //return $data;
        
        //$data = json_encode($data);
        //print $data;        
		}
		catch(Exception $e)
		{
			die($e->getMessage());
		}
	}

    public function Valida_serial($serial)
	{
		try
		{
		$serial=$_REQUEST['serial'];
		$query = 'SELECT *  FROM equipo WHERE serial=?';
	    $registros = $this->pdo->prepare($query);
	    $registros->execute( array($serial) );
	    $data = $registros->fetchAll( PDO::FETCH_OBJ ); 
        $data = json_encode($data);
	    return $data;
	    //$registros = $registros->fetchAll( PDO::FETCH_OBJ ); 

		//$serial_count = $registros[0]->existe;
    
    //return $serial_count;

	}
		catch(Exception $e)
		{
			die($e->getMessage());
		}
	}
	
}
