<?php
session_start();


const SENHA_RATO = 'Malfeito feito!';

function render_login(int $status, bool $erro = false): void
{
    http_response_code($status);

    $html = file_get_contents(__DIR__ . '/login.html');

    if ($erro) {
        $html = str_replace(
            'id="erro" style="display:none;',
            'id="erro" style="display:block;',
            $html
        );
    }

    echo $html;
    exit;
}


if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    render_login(200);
}

$senha = isset($_POST['password']) ? trim((string) $_POST['password']) : '';

if (hash_equals(SENHA_RATO, $senha)) {
    session_regenerate_id(true);
    $_SESSION['rato_autenticado'] = true;

    // Unico caso que responde 302.
    header('Location: rato.html');
    exit;
}

// Senha errada: 401 com a propria pagina de login e a mensagem visivel.
render_login(401, true);
