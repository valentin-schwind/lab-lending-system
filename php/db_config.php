<?php  
	$bdd = new PDO('mysql:host=<ENTER HOST NAME>;dbname=<ENTER DATABASE NAME>', '<ENTER USER NAME>', '<ENTER PASSWORD>');   
	$bdd->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
?>  