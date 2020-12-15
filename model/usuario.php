<?php
session_start();
//require 'include/anexgrid.php';
class Usuario
{
	private $pdo;

	public $alias;
	public $email;
	public $id;
	public $nombres;
	public $password;
	public $id_rol;
	public $errorMsgLogin;

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

	public function Listar_pag()
	{
		try
		{
		$stmt = $this->pdo->query("SELECT 
		  usuario.id, 
		  usuario.nombres, 
		  usuario.email, 
		  roles.role_name AS rol
		FROM 
		  public.usuario, 
		  public.roles
		WHERE 
		  usuario.id_rol = roles.role_id AND
		  usuario.active IS NOT FALSE
		  ORDER BY usuario.id");		

		$stmt1= $this->pdo->query("SELECT count(id) FROM usuario WHERE active IS NOT FALSE");
		$totalRecords = (int) $stmt1->fetchColumn(); 
		$data = $stmt->fetchAll(PDO::FETCH_ASSOC);
		echo json_encode($data);


            $json_data = array(
	            //"current"  => intval( $params['current'] )
	            "current"  =>  1, 
	            "rowCount" => 10,            
	            "total"    => intval( $totalRecords ),
	            "rows"     => $data   // total data array
            );
 
            //echo json_encode($json_data);


             
            //return json_encode($json_data);
            return $json_data;
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

			$stm = $this->pdo->prepare("SELECT * FROM usuario WHERE active IS NOT FALSE ORDER BY id");
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
			          ->prepare("SELECT * FROM usuario WHERE id = ?");
			          

			$stm->execute(array($id));
			return $stm->fetch(PDO::FETCH_OBJ);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

    public function Obtener_permiso($controlador,$accion)
	{
		try 
		{
			$stm = $this->pdo
			          ->prepare("SELECT count(id) FROM roles_permisos 
			          	         WHERE 
			          	         perm_desc = ? AND
			          	         lower(accion)= lower(?) AND 
			          	         role_id=?");
			$stm->execute(array(
				          $controlador,
				          $accion,
				          $_SESSION['usuario_rol']
				      ));
			return $stm->fetch(PDO::FETCH_OBJ);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}



    public function Obtener_alfa($username)
	{
		try 
		{
			$stm = $this->pdo
			          ->prepare("SELECT count(id) FROM usuario WHERE alias = ?");
			          

			$stm->execute(array($username));
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
			            ->prepare("UPDATE usuario 
			            	       SET active=FALSE, 
			            	       fecha_elim=NOW(), 
			            	       usr_id=".$_SESSION['uid']." WHERE id = ?");			          

			$stm->execute(array($id));
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Desbloquear($id)
	{
		try 
		{
			$stm = $this->pdo
			            ->prepare("UPDATE usuario 
			            	       SET intentos=0, 
			            	       ingreso=FALSE 
			            	       WHERE id = ?");			          

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
			$enc_pass=password_hash($data->password,PASSWORD_DEFAULT);
			
			$sql = "UPDATE usuario SET 
						alias          = ?, 
						email          = ?,
						nombres        = ?, 
						password       = ?,
						id_rol         = ?
				    WHERE id = ?";

			$this->pdo->prepare($sql)
			     ->execute(
				    array(
                        $data->alias, 
                        $data->email,
                        $data->nombres,
                        $enc_pass,
                        $data->id_rol,
						$data->id
					)
				);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}

	public function Registrar(Usuario $data)
	{
		//var_dump($data);
		//die;
		
		try 
		{
	 	
		 
   	    $enc_pass=password_hash($data->password,PASSWORD_DEFAULT);	
		$sql = "INSERT INTO usuario(alias, email, nombres, id_rol, password)
	            VALUES (?, ?, ?, ?, ?)";

		$this->pdo->prepare($sql)
		     ->execute(
				array(
                        $data->alias, 
                        $data->email,
                        $data->nombres,
						$data->id_rol,
                        $enc_pass
                )
			);
		} catch (Exception $e) 
		{
			die($e->getMessage());
		}
	}
	
    public function getlogin()
	{
		if(isset($_REQUEST['username']) && isset($_REQUEST['password'])){
            $username=$_REQUEST['username'];
            $password=$_REQUEST['password'];
			$stm = $this->pdo
			          ->prepare("SELECT * FROM usuario WHERE alias = ?");
			$stm->execute(array($username));
			$registro=$stm->fetch(PDO::FETCH_OBJ);
			
			if($registro->intentos > 2){
                $GLOBALS['ingreso'] = 'Usuario alcanzo el numero maximo de intentos permitidos, dirijase al administrador del sistema'; 
			   return 'Usuario alcanzo el numero maximo de intentos permitidos, dirijase al administrador del sistema';	
			}



			//var_dump($_REQUEST);
			//die;
			if (password_verify($password, $registro->password)) {
				        //session_set_cookie_params(0, "/", $HTTP_SERVER_VARS["HTTP_HOST"], 0); 
				        $_SESSION['ultimoAcceso']= date("j-n-Y H:i:s"); 
 		               	$_SESSION['uid']=$registro->id; 
 		               	$_SESSION['usuario']=$registro->alias;
						$_SESSION['usuario_mail']=$registro->email;
						$_SESSION['usuario_nombre']=$registro->nombres;
						$_SESSION['usuario_rol']=$registro->id_rol;
                         
//***************************************************************
						$uid=$registro->id;
						$stm2 = $this->pdo
			          ->prepare("SELECT * FROM funcionario WHERE id_usuario = ?");
						$stm2->execute(array($uid));
						$registro2=$stm2->fetch(PDO::FETCH_OBJ);
						$_SESSION['id_funcionario']=$registro2->id_funcionario;
//***************************************************************						
                        $sql = "UPDATE usuario SET ingreso=TRUE WHERE id = ?";
			            $this->pdo->prepare($sql)
			            ->execute(
				        array($registro->id)
				        );
//*************************************************************** 
                        $errorMsgLogin='';
                        $ingreso=1;
                        $GLOBALS['ingreso'] = 'Credenciales correctas'; 
                return 'login';				
			}
			else {
                        $sql = "UPDATE usuario SET intentos=intentos+1 WHERE id = ?";
			            $this->pdo->prepare($sql)
			            ->execute(
				        array($registro->id)
				        );
                                $GLOBALS['ingreso'] = 'Credenciales invalidas'; 
			   return 'Credenciales invalidas';	
			}	
		}
        else{
                                $GLOBALS['ingreso'] = 'Por favor ingrese sus credenciales'; 
			return 'Credenciales invalidas';
		}
//}
}


public function logout()
	{
		try 
		{


			$stm = $this->pdo
			            ->prepare("UPDATE usuario SET intentos=0,ingreso=FALSE  
			            	       WHERE id = ?");			          

			$stm->execute(array($_SESSION['uid']));
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
			SELECT id,nombres||' - '||alias AS text FROM usuario WHERE active IS NOT FALSE ORDER BY id");		
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
