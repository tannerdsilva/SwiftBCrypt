# SwiftBCrypt

A simple Swift Package wrapping the OpenWall BCrypt hashing algorithm.

## Generate Salt
```
let bcryptSalt = try BCRypt.makeSalt()
```

## Hash Phrases
```
let bcryptHash:Data = try BCrypt.hash(phrase:"ThisIsMySecurePassword1234", salt:bcryptSalt)
```

LICENSE

This package is offered under an MIT license, and is provided without warranty.