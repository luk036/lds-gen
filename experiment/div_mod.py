def div_mod_3(n: int):
    quotient: int = 0
    remainder: int = n

    # assume 8-bit, repeat 4 times
    q, r = remainder >> 2, remainder & 3
    quotient += q
    remainder = q + r
    q, r = remainder >> 2, remainder & 3
    quotient += q
    remainder = q + r
    q, r = remainder >> 2, remainder & 3
    quotient += q
    remainder = q + r
    q, r = remainder >> 2, remainder & 3
    quotient += q
    remainder = q + r

    if remainder == 3:
        quotient += 1
        remainder = 0
    return quotient, remainder


def div_mod_7(n: int):
    quotient: int = 0
    remainder: int = n

    # assume 8-bit, repeat 3 times
    q, r = remainder >> 3, remainder & 7
    quotient += q
    remainder = q + r
    q, r = remainder >> 3, remainder & 7
    quotient += q
    remainder = q + r
    q, r = remainder >> 3, remainder & 7
    quotient += q
    remainder = q + r

    if remainder == 7:
        quotient += 1
        remainder = 0
    return quotient, remainder


if __name__ == "__main__":
    for n in range(256):
        print(n, div_mod_3(n))
    for n in range(256):
        print(n, div_mod_7(n))
