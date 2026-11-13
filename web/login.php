<?php
session_start();

// Senha do Rato: última entrada da wordlist /Capa_da_invisibilidade.txt.
const SENHA_RATO = 'Malfeito feito!';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Location: login.html');
    exit;
}

$senha = isset($_POST['password']) ? trim((string) $_POST['password']) : '';

if (hash_equals(SENHA_RATO, $senha)) {
    session_regenerate_id(true);
    $_SESSION['rato_autenticado'] = true;

    header('Location: rato.html');
    exit;
}

// Falhou: volta para o formulário com um aviso.
header('Location: login.html?erro=1');
exit;
