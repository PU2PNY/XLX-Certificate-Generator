<?php
declare(strict_types=1);

$options = getopt('', [
    'root:', 'site-config:', 'data-dir:', 'secret-file:', 'campaign-pack::'
]);

$root = rtrim((string)($options['root'] ?? ''), '/');
$siteFile = (string)($options['site-config'] ?? '');
$dataDir = (string)($options['data-dir'] ?? '/var/lib/xlx-certificates');
$secretFile = (string)($options['secret-file'] ?? '/etc/xlx-certificates/secret');
$campaignPack = (string)($options['campaign-pack'] ?? 'auto');

if ($root === '' || !is_dir($root)) {
    fwrite(STDERR, "Invalid --root\n"); exit(2);
}
if ($siteFile === '' || !is_file($siteFile)) {
    fwrite(STDERR, "Invalid --site-config\n"); exit(2);
}

$site = require $siteFile;
if (!is_array($site)) { fwrite(STDERR, "site config must return array\n"); exit(3); }

$name = strtoupper(trim((string)($site['reflector']['name'] ?? '')));
$title = trim((string)($site['reflector']['title'] ?? $name));
$domain = strtolower(trim((string)($site['reflector']['domain'] ?? '')));
$timezone = trim((string)($site['timezone'] ?? 'UTC'));
$locale = trim((string)($site['locale']['default'] ?? 'en'));
$anniversary = trim((string)($site['certificates']['anniversary'] ?? ''));

if (!preg_match('/^[A-Z0-9-]{3,16}$/', $name)) {
    fwrite(STDERR, "Invalid reflector.name\n"); exit(4);
}
if ($title === '' || preg_match('/[<>\x00-\x1F\x7F\'"`]/u', $title)) {
    fwrite(STDERR, "Unsafe reflector.title\n"); exit(4);
}
if (!preg_match('/^(?=.{1,253}$)([a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$/', $domain)) {
    fwrite(STDERR, "Invalid reflector.domain\n"); exit(4);
}
if (!in_array($timezone, DateTimeZone::listIdentifiers(), true)) {
    fwrite(STDERR, "Invalid timezone\n"); exit(4);
}
if ($anniversary !== '' && !preg_match('/^(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$/', $anniversary)) {
    fwrite(STDERR, "Invalid certificates.anniversary\n"); exit(4);
}
if (!str_starts_with($dataDir, '/') || str_contains($dataDir, "\0")) {
    fwrite(STDERR, "Invalid data dir\n"); exit(4);
}
if (!str_starts_with($secretFile, '/') || str_contains($secretFile, "\0")) {
    fwrite(STDERR, "Invalid secret file\n"); exit(4);
}

$key = strtolower(preg_replace('/[^A-Z0-9]+/', '-', $name) ?? 'xlx');
$key = trim($key, '-');
if ($campaignPack === 'auto' || $campaignPack === '') {
    $campaignPack = ($locale === 'pt-BR') ? 'pt-BR' : 'portable';
}
if (!in_array($campaignPack, ['pt-BR', 'portable'], true)) {
    fwrite(STDERR, "Invalid campaign pack\n"); exit(4);
}

$vars = [
    '{{REFLECTOR_NAME}}' => $name,
    '{{REFLECTOR_TITLE}}' => $title,
    '{{REFLECTOR_KEY}}' => $key,
    '{{TIMEZONE}}' => $timezone,
    '{{CERT_BASE_URL}}' => 'https://' . $domain . '/',
    '{{CERT_DATA_DIR}}' => rtrim($dataDir, '/'),
    '{{CERT_SECRET_FILE}}' => $secretFile,
    '{{ANNIVERSARY}}' => $anniversary,
    '{{CAMPAIGN_PACK}}' => $campaignPack,
];

$extensions = ['php','js','css','html','txt'];
$it = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($root, FilesystemIterator::SKIP_DOTS));
$changed = 0;
foreach ($it as $file) {
    if (!$file->isFile()) continue;
    if (!in_array(strtolower($file->getExtension()), $extensions, true)) continue;
    if (str_contains($file->getPathname(), DIRECTORY_SEPARATOR . 'vendor' . DIRECTORY_SEPARATOR)) continue;
    $path = $file->getPathname();
    $raw = file_get_contents($path);
    if ($raw === false) { fwrite(STDERR, "Cannot read $path\n"); exit(5); }
    $new = strtr($raw, $vars);
    if ($new !== $raw) {
        if (file_put_contents($path, $new) === false) { fwrite(STDERR, "Cannot write $path\n"); exit(5); }
        $changed++;
    }
}

$left = [];
$it = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($root, FilesystemIterator::SKIP_DOTS));
foreach ($it as $file) {
    if (!$file->isFile()) continue;
    if (str_contains($file->getPathname(), DIRECTORY_SEPARATOR . 'vendor' . DIRECTORY_SEPARATOR)) continue;
    $raw = file_get_contents($file->getPathname());
    if ($raw !== false && preg_match('/\{\{[A-Z0-9_]+\}\}/', $raw)) $left[] = $file->getPathname();
}
if ($left) {
    fwrite(STDERR, "Unresolved placeholders:\n" . implode("\n", $left) . "\n"); exit(6);
}
printf("Render OK: %d files changed\n", $changed);
