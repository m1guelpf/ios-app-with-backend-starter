<?php

namespace App\Rules;

use Closure;
use Lcobucci\JWT\Token\Parser;
use Lcobucci\JWT\Signer\Rsa\Sha256;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Cache;
use Lcobucci\JWT\Signer\Key\InMemory;
use Lcobucci\JWT\Validation\Validator;
use Facades\Strobotti\JWK\KeyConverter;
use Facades\Strobotti\JWK\KeySetFactory;
use Symfony\Component\Clock\NativeClock;
use Lcobucci\JWT\Validation\Constraint\IssuedBy;
use Illuminate\Contracts\Validation\ValidationRule;
use Lcobucci\JWT\Validation\Constraint\LooseValidAt;
use Lcobucci\JWT\Validation\Constraint\PermittedFor;
use Lcobucci\JWT\Validation\Constraint\SignedWithOneInSet;
use Lcobucci\JWT\Validation\Constraint\SignedWithUntilDate;

class AppleJWT implements ValidationRule
{
    public function __construct(private Parser $parser, private Validator $validator) {}

    /**
     * Run the validation rule.
     */
    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        if (! $token = result(fn () => $this->parser->parse($value))->unwrapOrNull()) {
            $fail('Failed to parse the provided :attribute.');

            return;
        }

        if (! $this->validator->validate($token, new IssuedBy('https://appleid.apple.com'), new PermittedFor(config('services.apple.bundle_id')))) {
            $fail('Failed to validate the provided :attribute.');

            return;
        }

        if (! $this->validator->validate($token, new LooseValidAt(new NativeClock))) {
            $fail('The provided :attribute is no longer valid.');

            return;
        }

        if (! $this->validator->validate($token, new SignedWithOneInSet(...$this->getKeys()))) {
            $fail('Failed to verify the provided :attribute.');

            return;
        }
    }

    /**
     * @return SignedWithUntilDate[]
     */
    public function getKeys(): array
    {
        return Cache::remember('apple-keys', now()->tomorrow(), function () {
            return collect(KeySetFactory::createFromJSON(Http::get('https://appleid.apple.com/auth/keys')->body())->getKeys())
                ->map(fn ($key) => KeyConverter::keyToPem($key));
        })
            ->map(fn ($key) => new SignedWithUntilDate(new Sha256, InMemory::plainText($key), now()->tomorrow()->toDateTimeImmutable()))
            ->toArray();
    }
}
