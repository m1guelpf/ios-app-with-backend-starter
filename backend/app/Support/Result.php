<?php

namespace App\Support;

enum Type
{
    case Ok;
    case Err;
}

/**
 * @template Value
 * @template TError of \Throwable|null
 */
class Result
{
    public Type $type;

    /** @var Value | null */
    private mixed $value = null;

    /** @var TError | null */
    private mixed $error = null;

    /**
     * @param  Value|null  $value
     * @param  TError|null  $error
     */
    private function __construct(Type $type, mixed $value = null, ?\Throwable $error = null)
    {
        $this->type = $type;
        $this->value = $value;
        $this->error = $error;
    }

    /**
     * @template T
     *
     * @param  T  $value
     * @return Result<T, null>
     */
    public static function Ok(mixed $value): self
    {
        return new Result(Type::Ok, value: $value);
    }

    /**
     * @template AlwaysError of \Throwable
     *
     * @param  AlwaysError  $error
     * @return Result<null, AlwaysError>
     */
    public static function Err(\Throwable $error): self
    {
        return new Result(Type::Err, error: $error);
    }

    /**
     * @return (Value is null ? never : Value)
     *
     * @throws (TError is null ? never : TError)
     */
    public function unwrap(): mixed
    {
        if ($this->type == Type::Ok && ! is_null($this->value)) {
            return $this->value;
        }

        if (! is_null($this->error)) {
            throw $this->error;
        }

        throw new \Exception('Unreachable');
    }

    /**
     * @return (Value is null ? null : Value)
     */
    public function unwrapOrNull(): mixed
    {
        if ($this->type == Type::Ok) {
            return $this->value;
        }

        return null;
    }

    public function isError(): bool
    {
        return $this->type == Type::Err;
    }

    public function isOk(): bool
    {
        return $this->type == Type::Ok;
    }
}
