<?php
session_start();
class Solicitud
{
	private $pdo;

	public $id_solicitud;
	//public $id_equipo;
	public $id_funcionario;
	public $id_empleado;
	public $descripcion;
	public $fecha_solicitud;
    public $id_tipo_solicitud;
    public $id_estatus_solicitud;
    public $id_ubicacion;
    public $id_oficina;
    public $id_departamento;
	
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

			$stm = $this->pdo->prepare("SELECT * FROM solicitudes  WHERE active IS NOT FALSE");
			$stm->execute();

			return $stm->fetchAll(PDO::FETCH_OBJ);
		}
		catch(Exception $e)
		{
			die($e->getMessage());
		}
	}


	public function Listar_pend()
	{
		try
		{
			$result = array();

			$stm = $this->pdo->prepare("SELECT * FROM solicitudes_pendientes  WHERE active IS NOT FALSE ORDER BY id_solicitud");
			$stm->execute();

			return $stm->fetchAll(PDO::FETCH_OBJ);
		}
		catch(Exception $e)
		{
			die($e->getMessage());
		}
	}



public function Listar_sin_orden_salida()
	{
		try
		{
			$result = array();

			$stm = $this->pdo->prepare("SELECT * FROM solicitudes_sin_orden_salida  WHERE active IS NOT FALSE ORDER BY id_solicitud");
			$stm->execute();

			return $stm->fetchAll(PDO::FETCH_OBJ);
		}
		catch(Exception $e)
		{
			die($e->getMessage());
		}
	}
 
public function Listar_parcialmente_procesadas()
	{
		try
		{
			$result = array();

			$stm = $this->pdo->prepare("SELECT * FROM solicitudes_parcialmente_procesadas WHERE active IS NOT FALSE ORDER BY id_solicitud");
			$stm->execute();

			return $stm->fetchAll(PDO::FETCH_OBJ);
		}
		catch(Exception $e)
		{
			die($e->getMessage());
		}
	}

public function Listar_procesadas()
	{
		try
		{
			$result = array();

			$stm = $this->pdo->prepare("SELECT * FROM solicitudes_procesadas WHERE active IS NOT FALSE");
			$stm->execute();

			return $stm->fetchAll(PDO::FETCH_OBJ);
		}
		catch(Exception $e)
		{
			die($e->getMessage());
		}
	}

public function Listar_canceladas()
	{
		try
		{
			$result = array();

			$stm = $this->pdo->prepare("SELECT * FROM solicitudes_canceladas WHERE active IS NOT FALSE");
			$stm->execute();

			return $stm->fetchAll(PDO::FETCH_OBJ);
		}
		catch(Exception $e)
		{
			die($e->getMessage());
		}
	}	


	public function Listar_pendientes_sin_detalle()
	{
		try
		{
			$result = array();

			$stm = $this->pdo->prepare("SELECT * FROM solicitudes_pendientes_sin_detalle WHERE active IS NOT FALSE");
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
			          ->prepare("SELECT * FROM solicitud WHERE id_solicitud = ?");
			          

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
			            ->prepare("UPDATE solicitud 
			            	       SET active=FALSE, 
			            	       fecha_elim=NOW(), 
			            	       usr_id=".$_SESSION['uid']." WHERE id_solicitud = ?");

			$stm->execute(array($id));

			$stm = $this->pdo
			            ->prepare("UPDATE equipo 
			            	       SET id_solicitud_detalle_reserva=0 
			            	       WHERE id_solicitud_detalle_reserva = ?");

			$stm->execute(array($id));


		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}


	public function Cancelar($id)
	{
		try 
		{
						          
            $stm = $this->pdo
			            ->prepare("UPDATE solicitud 
			            	       SET id_estatus_solicitud=4 WHERE id_solicitud = ?");

			$stm->execute(array($id));
			
			$stm = $this->pdo
			            ->prepare("UPDATE equipo 
			            	       SET id_solicitud_detalle_reserva=0 
			            	       WHERE id_solicitud_detalle_reserva = ? AND 
			            	             id_estatus=5 AND 
			            	             id_ubicacion=1");

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

			$sql = "UPDATE solicitud SET 
					id_funcionario=?,
					id_empleado=?,
					descripcion=?,
					fecha_solicitud=?,
					id_tipo_solicitud=?,
					id_ubicacion=?,
					id_oficina=?,
					id_departamento=?
				    WHERE id_solicitud = ?";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(
                 		$_SESSION['id_funcionario'],
						$data->id_empleado,
						$data->descripcion,
						$data->fecha_solicitud,                        
						$data->id_tipo_solicitud,                        
						$data->id_ubicacion,
						$data->id_oficina,
						$data->id_departamento,                        
						$data->id_solicitud
					)
				);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Registrar_original(solicitud $data)
	{
		try 
		{
		$sql = "INSERT INTO solicitud(
		       id_funcionario,
		       id_empleado,
		       descripcion,
		       fecha_solicitud,
		       id_tipo_solicitud,
		       id_estatus_solicitud)
    			VALUES (?, ?, ?, ?, ?, 3)";

		$this->pdo->prepare($sql)
		     ->execute(
				array(
                        //$data->id_solicitud, 
                        //$data->id_equipo,
						$data->id_funcionario,
						$data->id_empleado,
						$data->descripcion,
						$data->fecha_solicitud,
						$data->id_tipo_solicitud
                                                                             
						//$data->id_estatus_solicitud
                    )
			);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Registrar(solicitud $data)
	{
		try 
		{
		$result = array();

$stm = $this->pdo->prepare("SELECT nueva_solicitud(0, ?, ?, ?, ?, ?, 3, ?, ?, ?)");

$stm->execute(
		array(
            $_SESSION['id_funcionario'],
			$data->id_empleado,
			$data->descripcion,
			$data->fecha_solicitud,
			$data->id_tipo_solicitud,
			$data->id_ubicacion,
    		$data->id_oficina,
    		$data->id_departamento
            )
			);
		  return $stm->fetch(PDO::FETCH_OBJ);  
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
			SELECT id_solicitud AS id,descripcion AS text FROM solicitud WHERE active IS NOT FALSE ORDER BY id");		
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
