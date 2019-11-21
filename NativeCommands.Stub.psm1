function pip.exe {
    param (
        [Parameter(
                ValueFromRemainingArguments
        )]
        [String[]]$Arguments
    )
    throw "I'm pip.exe. Throwing with $Arguments. Mock me!"
}

function virtualenv.exe {
    param (
        [Parameter(
                ValueFromRemainingArguments
        )]
        [String[]]$Arguments
    )
    throw "I'm virtualenv. Throwing with $Arguments. Mock me!"
}