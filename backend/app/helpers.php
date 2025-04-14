<?php

use App\Support\Result;

/**
 * @template T
 *
 * @param  \Closure(): T  $closure
 * @return Result<T, null> | Result<null, \Throwable>
 */
function result(\Closure $closure)
{
    try {
        $result = $closure();

        return Result::Ok($result);
    } catch (\Throwable $e) {
        return Result::Err($e);
    }
}
