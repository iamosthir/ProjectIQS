<?php

namespace App\Support\Enums;

/**
 * The 10 manual competition categories from the client's Match-Results spec,
 * plus `other` for API-Football leagues.
 */
enum LeagueCategory: string
{
    case Premier = 'premier';
    case FirstDiv = 'first_div';
    case SecondDiv = 'second_div';
    case ThirdDiv = 'third_div';
    case NtSenior = 'nt_senior';
    case NtU21 = 'nt_u21';
    case NtU19 = 'nt_u19';
    case NtU17 = 'nt_u17';
    case NtU16 = 'nt_u16';
    case NtU14 = 'nt_u14';
    case Other = 'other';
}
