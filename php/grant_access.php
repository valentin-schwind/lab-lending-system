<?php
	header("Content-Type: text/plain");
	$page = $_GET['page']; 
	$password = $_POST['password']; 
	if($password == <ENTER GLOBAL PASSWORD>){
		echo 'Granted';
	} else {
		echo 'Denied';
	} 
?>