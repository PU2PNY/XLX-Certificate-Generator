<?php
/* XLX_CERTIFICATES_OPTIONAL_HOOK_V1 */
$page=$_GET['page']??'ao-vivo';
$certificatesEnabled=is_file(__DIR__.'/certificado-view.php')&&is_file(__DIR__.'/api/certificado.php');
?>
