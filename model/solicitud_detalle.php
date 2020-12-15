<?php
session_start();
class Solicitud_detalle
{
	private $pdo;

    public $id_solicitud_detalle;
	public $id_solicitud;
	public $id_equipo;
	public $asignado;
     
	
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
            $id_solicitud= $_REQUEST['id_solicitud'];
			$stm = $this->pdo->prepare("SELECT * FROM solicitudes_detalles  WHERE active IS NOT FALSE AND id_solicitud= ".$id_solicitud." ORDER BY id_solicitud_detalle");
			$stm->execute();

			return $stm->fetchAll(PDO::FETCH_OBJ);
		}
		catch(Exception $e)
		{
			die($e->getMessage());
		}
	}

	public function Listar_asignados($id)
	{
		try
		{
			$result = array();
            $id_solicitud= $_REQUEST['id_solicitud'];
			$stm = $this->pdo->prepare("SELECT * FROM solicitudes_detalles  WHERE active IS NOT FALSE AND id_solicitud= ? AND asignado= TRUE ORDER BY id_solicitud_detalle");
			$stm->execute(array($id));

			return $stm->fetchAll(PDO::FETCH_OBJ);
		}
		catch(Exception $e)
		{
			die($e->getMessage());
		}
	}

	public function Listar_json()
	{
		try
		{
			$result = array();
            $id_solicitud= $_REQUEST['id_solicitud'];
			$stm = $this->pdo->prepare("SELECT * FROM solicitudes_detalles  WHERE active IS NOT FALSE AND id_solicitud= ".$id_solicitud." ORDER BY id_solicitud_detalle");
			$stm->execute();

			$data= $stm->fetchAll(PDO::FETCH_OBJ);
			echo json_encode($data);

		}
		catch(Exception $e)
		{
			die($e->getMessage());
		}
	}

	public function Listar_detalle($id)
	{
		try
		{
			$result = array();

			$stm = $this->pdo->prepare("SELECT * FROM solicitud_detalle  
				WHERE
                id_solicitud = ?
				AND active IS NOT FALSE ORDER BY id_solicitud_detalle");
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
			          ->prepare("SELECT * FROM solicitud_detalle WHERE id_solicitud_detalle = ?");
			          

			$stm->execute(array($id));
			return $stm->fetch(PDO::FETCH_OBJ);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Eliminar($id_solicitud_detalle,$id_equipo,$id_solicitud)
	{
		try 
		{
						          
            $stm = $this->pdo
			            ->prepare("UPDATE solicitud_detalle 
			            	       SET active=FALSE, 
			            	       fecha_elim=NOW(), 
			            	       usr_id=".$_SESSION['uid']." WHERE id_solicitud_detalle = ?");

			$stm->execute(array($id_solicitud_detalle));

			$stm2 = $this->pdo
			            ->prepare("UPDATE equipo 
			            	       SET id_solicitud_detalle_reserva=0 
			            	       WHERE id_equipo = ?");
			$stm2->execute(array($id_equipo));            

		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}


	public function Asignar($id_solicitud_detalle,$id_solicitud,$id_equipo,$id_tipo_solicitud)
	{
		try 
		{
			 			          
            $stm = $this->pdo
			            ->prepare("UPDATE solicitud_detalle 
			            	       SET asignado=TRUE WHERE id_solicitud_detalle = ?");

			$stm->execute(array($id_solicitud_detalle));

            $stm2 = $this->pdo
			            ->prepare("SELECT act_solicitud(?)");
                   
			$stm2->execute(array($id_solicitud));

			$stm3 = $this->pdo
			            ->prepare("UPDATE equipo 
			            	       SET id_estatus=? WHERE id_equipo = ?");

			$stm3->execute(array($id_tipo_solicitud, $id_equipo));

           
            $observacion="Equipo Reservado en Solicitud Nro:".$id_solicitud;
			$sql = "INSERT INTO reserva(id_solicitud, observacion, id_equipo)
        			VALUES (?, ?, ?)";
			$this->pdo->prepare($sql)
		     ->execute(
				array(
                        $id_solicitud, 
                        $observacion,
                        $id_equipo
                    )
			);



		} catch (Exception $e) 
		{
			die($e->getMessage());
		}



	}




	public function Actualizar($data) 
	{
		
		
		try 
		{

			$sql = "UPDATE solicitud_detalle SET 
					id_equipo=?
				    WHERE id_solicitud_detalle = ?";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(
                        $data->id_equipo,                        
						$data->id_solicitud_detalle
					)
				);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Registrar(solicitud_detalle $data)
	{
		try 
		{
		$sql = "INSERT INTO solicitud_detalle (id_solicitud, id_equipo)
    			VALUES (?, ?)";

		$this->pdo->prepare($sql)
		     ->execute(
				array(
                        $data->id_solicitud, 
                        $data->id_equipo
                    )
			);
		$sql = "UPDATE equipo set id_solicitud_detalle_reserva=? where id_equipo=?";

		$this->pdo->prepare($sql)
		     ->execute(
				array(
                        $data->id_solicitud, 
                        $data->id_equipo
                    )
			);     
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}

        
		

	}

	public function Listar_json2()
	{
		try
		{
		$stmt = $this->pdo->query("SELECT id_solicitud_detalle AS id,equipo.descripcion AS text FROM solicitud_detalle
INNER JOIN equipo ON equipo.id_equipo=solicitud_detalle.id_equipo
WHERE solicitud_detalle.active IS NOT FALSE 
ORDER BY id_solicitud_detalle");		
		$data = $stmt->fetchAll(PDO::FETCH_ASSOC);
		$data = json_encode($data);
        return $data;
		}
		catch(Exception $e)
		{
			die($e->getMessage());
		}
	}



}
