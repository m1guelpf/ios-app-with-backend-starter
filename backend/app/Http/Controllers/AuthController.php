<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Rules\AppleJWT;
use Illuminate\Http\Request;
use Facades\Lcobucci\JWT\Token\Parser;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $request->validate([
            'device_name' => 'required',
            'token' => ['required', app(AppleJWT::class)],
        ]);

        /** @var \Lcobucci\JWT\Token\Plain $token */
        $token = Parser::parse($request->token);

        if (! $user = User::find($token->claims()->get('sub'))) {
            if (! $token->claims()->has('email')) {
                throw ValidationException::withMessages(['token' => ['tried to register with a login token.']]);
            }

            $user = User::create([
                'id' => $token->claims()->get('sub'),
                'email' => $token->claims()->get('email'),
            ]);
        }

        /** @var User $user */
        return [
            'token' => $user->createToken($request->device_name, expiresAt: now()->addMonth())->plainTextToken,
        ];
    }

    public function user(Request $request)
    {
        return $request->user();
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->noContent();
    }
}
