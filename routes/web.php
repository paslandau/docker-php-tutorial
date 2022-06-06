<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

Route::get('/', \App\Http\Controllers\HomeController::class)->name("home");

Route::get('/info', function () {
    $info = file_get_contents(__DIR__."/../build-info");
    return new \Illuminate\Http\Response($info, 200, ["Content-type" => "text/plain"]);
});
