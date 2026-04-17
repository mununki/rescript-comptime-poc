open Comptime

type user = {
  name: string,
  age: int,
  active: bool,
}

type userFieldValue = %comptime({
  let makeVariantFromFields = fields => Variant({
    constructors: fields->Array.map(field => Constructor({
      name: field.name->String.capitalize,
      payload: Single(field.typ),
    })),
  })

  let makeVariantFromRecord = _witness =>
    switch reflect() {
    | Record({fields}) => makeVariantFromFields(fields)
    | _ => failwith("userFieldValue only supports records")
    }

  makeVariantFromRecord(
    module(
      {
        type t = user
      }
    ),
  )
})

let userNameField = Name("Ada")
let userAgeField = Age(42)
let userActiveField = Active(true)

let fieldLabel = field =>
  switch field {
  | Name(_) => "Name"
  | Age(_) => "Age"
  | Active(_) => "Active"
  }

Console.log(userNameField)
Console.log(userAgeField)
Console.log(userActiveField)
Console.log(fieldLabel(userAgeField))
