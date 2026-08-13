<?php
function parse_xml_connections(): array{return [];}
function active_and_history(array $c,int $l=30,int $s=0): array{return ['active'=>[],'history'=>[]];}
function user_lookup(string $c): array{return ['name'=>'','location'=>''];}
function country_for_call(string $c): array{return ['code'=>'','name'=>'','flag'=>''];}
